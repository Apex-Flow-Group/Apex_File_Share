import 'package:apex_file_share/core/heard_addresses.dart';
import 'package:apex_file_share/models/device.dart';
import 'package:flutter_test/flutter_test.dart';

/// The owner's two machines are each on two networks; apex.log showed
/// «Chat refused: 403 wrong_identity» until a retry happened to match the
/// last address heard. A device is trusted at every address it announced
/// itself from with the same certificate.
void main() {
  Device at(String ip, {String fp = 'aa11', bool mismatch = false}) => Device(
      id: 'jawal', name: 'Jawal', type: 'desktop', ip: ip, port: 54493, fingerprint: fp, versionMismatch: mismatch);

  test('a device heard on two networks is expected at both addresses', () {
    final heard = HeardAddresses()
      ..heard(at('192.168.0.128'))
      ..heard(at('192.168.8.103'));
    expect(heard.expected('jawal', '192.168.0.128'), 'aa11');
    expect(heard.expected('jawal', '192.168.8.103'), 'aa11');
  });

  test('an address it never announced from is not expected', () {
    final heard = HeardAddresses()..heard(at('192.168.0.128'));
    expect(heard.expected('jawal', '192.168.0.99'), isNull);
    expect(heard.expected('other', '192.168.0.128'), isNull);
  });

  test('a new certificate drops the addresses heard with the old one', () {
    final heard = HeardAddresses()
      ..heard(at('192.168.0.128'))
      ..heard(at('192.168.8.103', fp: 'bb22'));
    expect(heard.expected('jawal', '192.168.0.128'), isNull);
    expect(heard.expected('jawal', '192.168.8.103'), 'bb22');
  });

  test('nothing is expected from a device of another version or without a certificate, or once lost', () {
    final heard = HeardAddresses()
      ..heard(at('192.168.0.128', mismatch: true))
      ..heard(Device(id: 'bare', name: 'Bare', type: 'desktop', ip: '192.168.0.5'));
    expect(heard.expected('jawal', '192.168.0.128'), isNull);
    expect(heard.expected('bare', '192.168.0.5'), isNull);

    final lost = HeardAddresses()..heard(at('192.168.0.128'));
    lost.forget('jawal');
    expect(lost.expected('jawal', '192.168.0.128'), isNull);
  });
}
