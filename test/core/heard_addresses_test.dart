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

  test('an address not heard within the device timeout is pruned, as the device list is', () {
    var now = DateTime(2026, 11, 28, 19);
    final heard = HeardAddresses(clock: () => now)..heard(at('192.168.0.128'));
    now = now.add(const Duration(seconds: 40));
    heard.heard(at('192.168.8.103'));
    now = now.add(const Duration(seconds: 30));
    heard.prune(const Duration(seconds: 60));
    expect(heard.expected('jawal', '192.168.0.128'), isNull, reason: 'heard 70 s ago');
    expect(heard.expected('jawal', '192.168.8.103'), 'aa11', reason: 'heard 30 s ago');

    now = now.add(const Duration(minutes: 2));
    heard.prune(const Duration(seconds: 60));
    expect(heard.expected('jawal', '192.168.8.103'), isNull);
  });

  test('a flood of forged packets cannot grow it without end', () {
    final heard = HeardAddresses();
    for (var i = 0; i < 10000; i++) {
      heard.heard(at('10.0.${i ~/ 250}.${i % 250}'));
      heard.heard(Device(id: 'fake-$i', name: 'x', type: 'desktop', ip: '10.1.0.1', port: 1, fingerprint: 'cc33'));
    }
    expect(heard.addressCount('jawal'), lessThanOrEqualTo(HeardAddresses.maxAddressesPerDevice));
    expect(heard.deviceCount, lessThanOrEqualTo(HeardAddresses.maxDevices));
    expect(heard.expected('jawal', '10.0.39.249'), 'aa11', reason: 'the newest address stays');
  });

  test('clear forgets everything, as stopping discovery does', () {
    final heard = HeardAddresses()..heard(at('192.168.0.128'));
    heard.clear();
    expect(heard.expected('jawal', '192.168.0.128'), isNull);
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
