import 'package:apex_file_share/l10n/app_delegates.dart';
import 'package:apex_file_share/l10n/generated/app_localizations.dart';
import 'package:apex_file_share/models/device.dart';
import 'package:apex_file_share/shared/device_card.dart';
import 'package:apex_file_share/tv/widgets/tabs/tv_send_device_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const device = Device(
      id: 'http:192.168.1.20',
      name: 'Office PC',
      type: 'desktop',
      ip: '192.168.1.20');

  setUp(foldDeviceCards);

  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets(
        'the TV offers to send a folder, reached by the remote ($locale)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
            body: SingleChildScrollView(
                child: TVDeviceCard(device: device, autofocus: true))),
      ));
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(locale);
      // The sends are a row, walked in the reading direction.
      final next = locale.languageCode == 'ar'
          ? LogicalKeyboardKey.arrowLeft
          : LogicalKeyboardKey.arrowRight;
      await tester.sendKeyEvent(next); // file -> app
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(next); // app -> folder
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text(l10n.sendFolder))).hasFocus,
          isTrue);
    });
  }
}
