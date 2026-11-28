import '../models/device.dart';

/// Every address each device announced itself from, with the certificate it
/// showed. A request that claims to be a device must come from one of them
/// with that certificate.
///
/// More than one address, because a machine on two networks (Wi-Fi and
/// cable) announces on both and reaches this device from either: keeping only
/// the last one heard refused its messages from the other with
/// «403 wrong_identity» until a retry happened to match.
class HeardAddresses {
  final _byId = <String, ({String fingerprint, Set<String> addresses})>{};

  /// A discovery packet from [device] at its [Device.ip]. A packet with
  /// another certificate starts over: the old addresses belonged to the old key.
  void heard(Device device) {
    if (device.versionMismatch || device.fingerprint.isEmpty || device.ip.isEmpty) {
      _byId.remove(device.id);
      return;
    }
    final known = _byId[device.id];
    if (known == null || known.fingerprint != device.fingerprint) {
      _byId[device.id] = (fingerprint: device.fingerprint, addresses: {device.ip});
    } else {
      known.addresses.add(device.ip);
    }
  }

  /// The device was lost: nothing more is expected from it.
  void forget(String id) => _byId.remove(id);

  /// The certificate [id] announced from [address], or null when it never did.
  String? expected(String id, String address) {
    final known = _byId[id];
    return known != null && known.addresses.contains(address) ? known.fingerprint : null;
  }
}
