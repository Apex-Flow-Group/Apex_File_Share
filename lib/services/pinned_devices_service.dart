import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/device.dart';
import '../utils/apex_logger.dart';

class PinnedDevicesService {
  static const _key = 'pinned_devices';

  Future<List<Device>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      try {
        return Device.fromJson(jsonDecode(s) as Map<String, dynamic>);
      } catch (e) {
        // The type only: the stored text is a device record, not for the log.
        ApexLogger.instance.log('PINNED', 'Dropped a pinned device that could not be read (${e.runtimeType})', LogLevel.warning);
        return null;
      }
    }).whereType<Device>().toList();
  }

  Future<void> save(List<Device> devices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      devices.map((d) => jsonEncode(d.toJson())).toList(),
    );
  }

  Future<void> pin(Device device) async {
    final list = await load();
    if (list.any((d) => d.id == device.id)) {
      return;
    }
    list.add(device);
    await save(list);
  }

  Future<void> unpin(String deviceId) async {
    final list = await load();
    list.removeWhere((d) => d.id == deviceId);
    await save(list);
  }
}
