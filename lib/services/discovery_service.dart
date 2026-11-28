// ignore_for_file: always_put_control_body_on_new_line

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

import '../core/apex_core.dart';
import '../core/protocol/discovery_packet.dart';
import '../core/text/clean_label.dart';
import '../models/device.dart';
import '../utils/apex_logger.dart';

/// How a datagram leaves: [RawDatagramSocket.send], or a test's stand-in.
typedef SendDatagram = int Function(
    RawDatagramSocket socket, List<int> data, InternetAddress to, int port);

class DiscoveryService {
  final _deviceFoundController = StreamController<Device>.broadcast();
  final _deviceLostController = StreamController<String>.broadcast();

  Stream<Device> get onDeviceFound => _deviceFoundController.stream;
  Stream<String> get onDeviceLost => _deviceLostController.stream;

  /// callback يُسأل عنه عند كل بث — هل Share مُفعَّل؟ (desktop فقط)
  bool Function() isShareEnabled;

  DiscoveryService({
    this.isShareEnabled = _defaultFalse,
    this.port = defaultPort,
    this.interval = const Duration(seconds: 2),
    Future<List<NetworkInterface>> Function()? listInterfaces,
    @visibleForTesting SendDatagram? send,
  })  : _listInterfaces = listInterfaces ?? _systemInterfaces,
        _send = send ?? _socketSend;
  static bool _defaultFalse() => false;
  static Future<List<NetworkInterface>> _systemInterfaces() =>
      NetworkInterface.list(includeLinkLocal: false, type: InternetAddressType.IPv4);
  static int _socketSend(RawDatagramSocket s, List<int> data, InternetAddress to, int port) =>
      s.send(data, to, port);

  static const int defaultPort = 45679;
  final int port;
  final Duration interval;
  final Future<List<NetworkInterface>> Function() _listInterfaces;
  final SendDatagram _send;

  /// Every datagram waits here for the one before it.
  Future<void> _sends = Future.value();

  // Nearby (Android phone ↔ phone)
  bool _nearbyAdvertising = false;
  bool _nearbyDiscovering = false;

  // UDP broadcast (Desktop ↔ Desktop and Desktop ↔ Android)
  RawDatagramSocket? _udpSocket;
  Timer? _broadcastTimer;
  Device? _localDevice;
  bool _running = false;
  bool _binding = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  bool get isListening => _udpSocket != null;

  @visibleForTesting
  RawDatagramSocket? get debugSocket => _udpSocket;

  Future<void> start(Device localDevice) async {
    _localDevice = localDevice;
    _running = true;
    // Always start UDP so Android can talk to PC and vice versa
    await _startUdp();
    if (_isAndroid) {
      await _startNearby(localDevice);
    }
  }

  /// Opens a fresh socket and announces at once: what the refresh button does.
  Future<void> restart() async {
    if (!_running) return;
    _closeSocket();
    await _bind();
    forceBroadcast();
  }

  /// بث فوري متعدد — يُستخدم عند الضغط على refresh
  /// يرسل 3 باكتات بفاصل 300ms لتقليل احتمال الضياع
  void forceBroadcast() {
    _broadcast();
    Future.delayed(const Duration(milliseconds: 300), _broadcast);
    Future.delayed(const Duration(milliseconds: 700), _broadcast);
  }

  /// إرسال unicast مباشر لـ IP جهاز محدد (للأجهزة المثبتة)
  void pingDevice(Device device) {
    final d = _localDevice;
    if (d == null || _udpSocket == null || device.ip.isEmpty) return;
    final data = utf8.encode(DiscoveryPacket.encode(d, shareEnabled: isShareEnabled()));
    unawaited(_sendAll(data, [device.ip]));
  }

  /// Sends [data] to each address in turn, after any send already waiting.
  ///
  /// A socket that cannot take a datagram yet returns 0 from send(), and the
  /// datagram is not sent (Dart's contract). On Windows that is every send
  /// while the one before it is still on its way (`HasPendingWrite()` in
  /// Dart's eventhandler_win.cc), so sent back to back only the first
  /// address got the packet: 255.255.255.255, which Windows sends on one
  /// network only. Each one is now tried again until the socket takes it.
  Future<void> _sendAll(List<int> data, List<String> addresses) {
    final run = _sends.then((_) async {
      for (final addr in addresses) {
        await _sendUntilTaken(data, InternetAddress(addr));
      }
    });
    _sends = run.catchError((Object _) {});
    return run;
  }

  static const _sendTries = 20;
  static const _sendRetryWait = Duration(milliseconds: 5);

  Future<void> _sendUntilTaken(List<int> data, InternetAddress to) async {
    for (var i = 0; i < _sendTries; i++) {
      final socket = _udpSocket;
      if (socket == null) return;
      try {
        if (_send(socket, data, to, port) > 0) return;
      } catch (_) {
        return;
      }
      await Future<void>.delayed(_sendRetryWait);
    }
  }

  // ─── UDP Broadcast (works on all platforms) ───────────────────────────────

  Future<void> _startUdp() async {
    await _bind();
    // Each tick also reopens a socket that closed or never opened (the app
    // started offline), so discovery comes back without a restart.
    _broadcastTimer = Timer.periodic(interval, (_) async {
      if (_udpSocket == null) await _bind();
      await _broadcast();
    });
    await _broadcast();
  }

  Future<void> _bind() async {
    if (!_running || _binding || _udpSocket != null) return;
    _binding = true;
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port,
          reuseAddress: true, reusePort: false);
      if (!_running) {
        socket.close();
        return;
      }
      socket.broadcastEnabled = true;
      socket.multicastHops = 128;
      _udpSocket = socket;
      // Dart reports a failed send here, not at send(), and then closes the
      // socket: a dropped Wi-Fi did exactly that and silenced the app.
      socket.listen(
        (event) => _onSocketEvent(socket, event),
        onError: (Object e) =>
            ApexLogger.instance.log('UDP', 'Send failed: $e', LogLevel.warning),
        onDone: () {
          if (identical(_udpSocket, socket)) _udpSocket = null;
        },
      );
      ApexLogger.instance.log('UDP', '✅ Listening on port $port', LogLevel.success);
    } catch (e) {
      ApexLogger.instance.log('UDP', '❌ Failed: $e', LogLevel.error);
    } finally {
      _binding = false;
    }
  }

  void _onSocketEvent(RawDatagramSocket socket, RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = socket.receive();
    final self = _localDevice;
    if (dg == null || self == null) return;
    try {
      final text = utf8.decode(dg.data);
      final from = dg.address.address;
      final device = DiscoveryPacket.decode(text, from: from, selfId: self.id) ??
          DiscoveryPacket.otherVersion(text, from: from, selfId: self.id);
      if (device != null) _deviceFoundController.add(device);
    } catch (_) {}
  }

  Future<void> _broadcast() async {
    final d = _localDevice;
    if (d == null || _udpSocket == null) return;
    final data = utf8.encode(DiscoveryPacket.encode(d, shareEnabled: isShareEnabled()));
    List<NetworkInterface> ifaces;
    try {
      ifaces = await _listInterfaces();
    } catch (_) {
      ifaces = const [];
    }
    final ips = [
      for (final iface in ifaces)
        for (final a in iface.addresses)
          if (a.type == InternetAddressType.IPv4) a.address,
    ];
    await _sendAll(data, broadcastTargets(ips));
  }

  /// 255.255.255.255 leaves on the network the system picks; each network
  /// the device is on also gets its own broadcast, read again every time so a
  /// new address after a network change is used. A /24 mask is assumed:
  /// Dart does not report the real one.
  /// Takes plain IPv4 strings: the type of NetworkInterface.addresses differs
  /// between Dart versions.
  static List<String> broadcastTargets(Iterable<String> ipv4) {
    final targets = <String>{'255.255.255.255'};
    for (final ip in ipv4) {
      final parts = ip.split('.');
      if (parts.length != 4 || parts[0] == '127' || ip.startsWith('169.254.')) {
        continue;
      }
      targets.add('${parts[0]}.${parts[1]}.${parts[2]}.255');
    }
    return targets.toList();
  }

  void _closeSocket() {
    final socket = _udpSocket;
    _udpSocket = null;
    socket?.close();
  }

  // ─── Nearby Connections (Android phone ↔ phone) ───────────────────────────

  Future<void> _startNearby(Device localDevice) async {
    const serviceId = DiscoveryPacket.nearbyServiceId;

    try {
      await Nearby().startAdvertising(
        localDevice.name,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: (endpointId, info) async {
          ApexCore.instance
              .handleIncomingConnectionInitiated(endpointId, info.endpointName);
        },
        onConnectionResult: (endpointId, status) {
          ApexLogger.instance
              .log('NEARBY', 'Connection result: $status', LogLevel.info);
        },
        onDisconnected: (endpointId) {
          _deviceLostController.add(endpointId);
        },
        serviceId: serviceId,
      );
      _nearbyAdvertising = true;
      ApexLogger.instance.log('NEARBY', '✅ Advertising', LogLevel.success);
    } catch (e) {
      ApexLogger.instance.log('NEARBY', 'Advertise failed: $e', LogLevel.error);
    }

    try {
      await Nearby().startDiscovery(
        localDevice.name,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (endpointId, name, sid) {
          final shown = cleanLabel(name);
          _deviceFoundController.add(Device(
            id: endpointId,
            name: shown.isEmpty ? endpointId : shown,
            type: 'phone',
            endpointId: endpointId,
            lastSeen: DateTime.now(),
          ));
        },
        onEndpointLost: (endpointId) {
          if (endpointId != null) _deviceLostController.add(endpointId);
        },
        serviceId: serviceId,
      );
      _nearbyDiscovering = true;
      ApexLogger.instance.log('NEARBY', '✅ Discovering', LogLevel.success);
    } catch (e) {
      ApexLogger.instance.log('NEARBY', 'Discovery failed: $e', LogLevel.error);
    }
  }

  // ─── Stop ─────────────────────────────────────────────────────────────────

  Future<void> stop() async {
    _running = false;
    _broadcastTimer?.cancel();
    _closeSocket();

    if (_nearbyAdvertising) {
      await Nearby().stopAdvertising();
      _nearbyAdvertising = false;
    }
    if (_nearbyDiscovering) {
      await Nearby().stopDiscovery();
      _nearbyDiscovering = false;
    }
  }

  void dispose() {
    stop();
    _deviceFoundController.close();
    _deviceLostController.close();
  }
}
