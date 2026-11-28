import 'package:flutter/services.dart';

import '../utils/apex_logger.dart';

class ApexAppInfo {
  final String name;
  final String apkPath;
  final String packageName;
  final Uint8List icon;
  final bool isSystemApp;

  ApexAppInfo({
    required this.name,
    required this.apkPath,
    required this.packageName,
    required this.icon,
    this.isSystemApp = false,
  });
}

class ApexAppsLoader {
  static const MethodChannel _channel = MethodChannel('com.apex.core/apps');

  static Future<List<ApexAppInfo>> getInstalledApps() async {
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('getInstalledApps');

      return result.map((app) {
        return ApexAppInfo(
          name: app['name'],
          apkPath: app['path'],
          packageName: app['package'],
          icon: app['icon'],
          isSystemApp: app['isSystem'] ?? false,
        );
      }).toList();
    } catch (e) {
      ApexLogger.instance.log('APPS', 'Could not list the installed apps: $e', LogLevel.warning);
      return [];
    }
  }
}
