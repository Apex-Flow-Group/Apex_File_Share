import 'package:material_ui/material_ui.dart';

import 'generated/app_localizations.dart';

// Not AppLocalizations.localizationsDelegates: gen-l10n wires that list to
// flutter_localizations, whose Material strings material_ui widgets can't find.
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];
