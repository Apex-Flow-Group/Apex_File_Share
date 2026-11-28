import 'package:material_ui/material_ui.dart';

import '../models/device.dart';
import 'apex_colors.dart';

/// One icon and color per device type, for the phone and the TV cards alike.
IconData deviceIcon(Device device) {
  switch (device.type.toLowerCase()) {
    case 'tv':
      return Icons.tv_rounded;
    case 'desktop':
      return Icons.computer_rounded;
    case 'tablet':
      return Icons.tablet_rounded;
    default:
      return Icons.smartphone_rounded;
  }
}

Color deviceColor(Device device, ApexColors c) {
  switch (device.type.toLowerCase()) {
    case 'tv':
      return c.accent;
    case 'desktop':
      return c.tintBlue;
    case 'tablet':
      return c.tintOrange;
    default:
      return c.tintGreen;
  }
}
