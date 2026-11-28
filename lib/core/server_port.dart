import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/apex_logger.dart';

/// Where the port of the last run is kept on this device.
const lastPortKey = 'http_port';

/// The server on the port it had last run, so a favorite not discovered this
/// run is still reached at the address and port the other device kept. A
/// port another program took since gives any free one, kept for next time,
/// so the app never fails to start over it.
Future<HttpServer> bindLastPort(SharedPreferences prefs, Future<HttpServer> Function(int port) bind) async {
  final last = prefs.getInt(lastPortKey);
  if (last != null && last > 0 && last < 1 << 16) {
    try {
      return await bind(last);
    } on SocketException catch (e) {
      // Taken: any free port below.
      ApexLogger.instance.log('HTTP', 'The last port $last is taken, using any free port: $e', LogLevel.warning);
    }
  }
  final server = await bind(0);
  await prefs.setInt(lastPortKey, server.port);
  return server;
}
