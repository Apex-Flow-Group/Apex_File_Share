import '../models/device.dart';

/// Every address each device announced itself from, with the certificate it
/// showed. A request that claims to be a device must come from one of them
/// with that certificate.
///
/// More than one address, because a machine on two networks (Wi-Fi and
/// cable) announces on both and reaches this device from either: keeping only
/// the last one heard refused its messages from the other with
/// «403 wrong_identity» until a retry happened to match.
///
/// Bounded, because discovery packets are unauthenticated UDP: an address
/// leaves when [prune] finds it silent past the device timeout, a device
/// keeps its [maxAddressesPerDevice] newest, and at most [maxDevices] are kept.
class HeardAddresses {
  HeardAddresses({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const maxAddressesPerDevice = 8;
  static const maxDevices = 4096;

  final DateTime Function() _clock;
  final _byId = <String, ({String fingerprint, Map<String, DateTime> addresses})>{};

  int get deviceCount => _byId.length;
  int addressCount(String id) => _byId[id]?.addresses.length ?? 0;

  /// A discovery packet from [device] at its [Device.ip]. A packet with
  /// another certificate starts over: the old addresses belonged to the old key.
  void heard(Device device) {
    if (device.versionMismatch || device.fingerprint.isEmpty || device.ip.isEmpty) {
      _byId.remove(device.id);
      return;
    }
    final now = _clock();
    var known = _byId.remove(device.id);
    if (known == null || known.fingerprint != device.fingerprint) {
      known = (fingerprint: device.fingerprint, addresses: <String, DateTime>{});
    }
    // Re-inserted last: the map's order is the order devices were heard.
    _byId[device.id] = known;
    known.addresses
      ..remove(device.ip)
      ..[device.ip] = now;
    while (known.addresses.length > maxAddressesPerDevice) {
      known.addresses.remove(known.addresses.keys.first);
    }
    while (_byId.length > maxDevices) {
      _byId.remove(_byId.keys.first);
    }
  }

  /// Drops every address not heard within [timeout], and devices left with none.
  void prune(Duration timeout) {
    final cutoff = _clock().subtract(timeout);
    for (final known in _byId.values) {
      known.addresses.removeWhere((_, seen) => seen.isBefore(cutoff));
    }
    _byId.removeWhere((_, known) => known.addresses.isEmpty);
  }

  /// The device was lost: nothing more is expected from it.
  void forget(String id) => _byId.remove(id);

  /// Discovery stopped or restarts: nothing heard before counts.
  void clear() => _byId.clear();

  /// The certificate [id] announced from [address], or null when it never did.
  String? expected(String id, String address) {
    final known = _byId[id];
    return known != null && known.addresses.containsKey(address) ? known.fingerprint : null;
  }
}
