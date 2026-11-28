import 'dart:io';

import 'package:apex_file_share/l10n/app_delegates.dart';
import 'package:apex_file_share/l10n/generated/app_localizations.dart';
import 'package:apex_file_share/mobile/widgets/tabs/file_tile.dart';
import 'package:apex_file_share/shared/apex_colors.dart';
import 'package:apex_file_share/shared/apex_theme.dart';
import 'package:apex_file_share/shared/file_ui_utils.dart';
import 'package:apex_file_share/tv/widgets/tabs/tv_file_tile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);

void main() {
  test('what sits on the accent is black on a light accent, white on a dark one', () {
    expect(ApexColors.dark.onAccent, _black, reason: 'dark accent D0BCFF is light');
    expect(ApexColors.light.onAccent, _white, reason: 'light accent 6750A4 is dark');
    expect(ApexColors.dark.withAccent(const Color(0xFF0B57D0)).onAccent, _white);
    expect(ApexColors.light.withAccent(const Color(0xFFFFEB3B)).onAccent, _black);
  });

  group('a video file draws its icon in onAccent', () {
    late Directory root;
    late File video;
    setUp(() {
      root = Directory.systemTemp.createTempSync('apex_on_accent_');
      video = File('${root.path}/clip.mp4')..writeAsStringSync('x');
    });
    tearDown(() => root.deleteSync(recursive: true));

    Widget app(Widget child) => MaterialApp(
          theme: apexTheme(Brightness.dark),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        );
    Color? iconColour(WidgetTester tester) =>
        tester.widget<Icon>(find.byIcon(FileUiUtils.fileIcon('clip.mp4'))).color;

    testWidgets('phone tile', (tester) async {
      await tester.pumpWidget(app(FileTile(
        file: video,
        name: 'clip.mp4',
        isSelected: false,
        isSelectionMode: false,
        onTap: () {},
        onLongPress: () {},
        onOpenFile: () {},
        onOpenLocation: () {},
      )));
      expect(iconColour(tester), ApexColors.dark.onAccent);
    });

    testWidgets('TV tile', (tester) async {
      await tester.pumpWidget(app(TVFileTile(
        file: video,
        name: 'clip.mp4',
        isDark: true,
        autofocus: false,
        onOpen: () {},
        onOpenLocation: () {},
        onDelete: () {},
      )));
      expect(iconColour(tester), ApexColors.dark.onAccent);
    });
  });
}
