@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:apex_file_share/models/device.dart';
import 'package:apex_file_share/services/discovery_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Seen on the owner's Windows PC (cable, Wi-Fi, hotspot, WSL): it found
/// Fedora within a second, but Fedora took a long time to find it.
///
/// Dart on Windows takes one datagram at a time: send() while the one before
/// it is still on its way returns 0 and drops it (`HasPendingWrite()` in
/// eventhandler_win.cc). The presence packet went to every network back to
/// back, so only the first address got it: 255.255.255.255, which Windows
/// sends on one network only. The socket here behaves the same way.

const _me = Device(id: 'me', name: 'This PC', type: 'desktop', ip: '127.0.0.1', port: 40000);

class _Iface implements NetworkInterface {
  _Iface(this.name, String ip) : addresses = [_Addr(ip)];
  @override
  final String name;
  @override
  final List<InterfaceAddress> addresses;
  @override
  int get index => 0;
}

/// Only what the service reads: the type and the text of the address.
class _Addr implements InterfaceAddress {
  _Addr(this.address);
  @override
  final String address;
  @override
  InternetAddressType get type => InternetAddressType.IPv4;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Takes a datagram only when the last one has left, as on Windows, and
/// records where each taken one went.
class _OneAtATime {
  final taken = <String>[];
  bool _busy = false;

  int send(RawDatagramSocket socket, List<int> data, InternetAddress to, int port) {
    if (_busy) {
      return 0;
    }
    _busy = true;
    Timer(const Duration(milliseconds: 1), () => _busy = false);
    taken.add(to.address);
    return data.length;
  }
}

Future<int> _freePort() async {
  final s = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = s.port;
  s.close();
  return port;
}

void main() {
  late _OneAtATime socket;
  late DiscoveryService svc;

  setUp(() async {
    socket = _OneAtATime();
    svc = DiscoveryService(
      port: await _freePort(),
      // Long enough that only the first announcement runs in a test.
      interval: const Duration(minutes: 1),
      listInterfaces: () async => [
        _Iface('Ethernet', '192.168.8.70'),
        _Iface('Local Area Connection* 10', '192.168.137.1'),
        _Iface('Wi-Fi', '192.168.8.28'),
        _Iface('vEthernet (WSL)', '172.17.112.1'),
      ],
      send: socket.send,
    );
  });

  tearDown(() => svc.stop());

  test('the presence packet reaches every network, not only the first address', () async {
    await svc.start(_me);
    expect(socket.taken, unorderedEquals([
      '255.255.255.255',
      '192.168.8.255',
      '192.168.137.255',
      '172.17.112.255',
    ]));
  });

  test('every favorite is pinged, not only the first one', () async {
    await svc.start(_me);
    socket.taken.clear();
    for (final ip in ['192.168.8.40', '192.168.8.41', '192.168.8.42']) {
      svc.pingDevice(Device(id: ip, name: ip, type: 'desktop', ip: ip));
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(socket.taken, ['192.168.8.40', '192.168.8.41', '192.168.8.42']);
  });

  test('after stop, nothing waiting is sent', () async {
    await svc.start(_me);
    socket.taken.clear();
    svc.pingDevice(const Device(id: 'a', name: 'a', type: 'desktop', ip: '192.168.8.40'));
    svc.pingDevice(const Device(id: 'b', name: 'b', type: 'desktop', ip: '192.168.8.41'));
    await svc.stop();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(socket.taken, hasLength(lessThanOrEqualTo(1)));
  });
}
