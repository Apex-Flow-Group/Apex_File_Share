import 'dart:io';

import 'package:apex_file_share/shared/apex_colors.dart';
import 'package:apex_file_share/shared/apex_header.dart';
import 'package:apex_file_share/shared/apex_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Every screen and sheet head is ApexHeader: one drawn by hand sat under
/// the status bar, or inside its sheet's margin, while the others filled
/// the top.
void main() {
  test('no screen draws its own head', () {
    final byHand = <String>[];
    for (final f
        in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('apex_header.dart')) {
        continue;
      }
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('bottom: Radius.circular(28)')) {
          byHand.add('${f.path}:${i + 1}');
        }
      }
    }
    expect(byHand, isEmpty,
        reason: '${byHand.length} heads by hand; use ApexHeader');
  });

  testWidgets(
      'on a phone it fills the top behind the status bar, its icon below it',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
            size: Size(400, 800), padding: EdgeInsets.only(top: 24)),
        child: Scaffold(
          body: Column(children: [
            ApexHeader(icon: Icons.folder_rounded, title: 'Files'),
          ]),
        ),
      ),
    ));
    expect(tester.getTopLeft(find.byType(ApexHeader)).dy, 0);
    expect(tester.getTopLeft(find.byIcon(Icons.folder_rounded)).dy,
        greaterThanOrEqualTo(24 + 16));
  });

  // Plain, as the system's own window bar is (owner decision): no gradient,
  // no strip, no screen's colour, no purple. The title on the window, the
  // icon in the text's colour on a neutral step.
  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name}: plain, on the window, in the roles',
        (tester) async {
      final c =
          brightness == Brightness.dark ? ApexColors.dark : ApexColors.light;
      await tester.pumpWidget(MaterialApp(
        theme: apexTheme(brightness),
        home: const Scaffold(
          body: Column(children: [
            ApexHeader(
                icon: Icons.folder_rounded,
                title: 'Files',
                subtitle: '3 files',
                detail: '192.168.1.5:8080'),
          ]),
        ),
      ));

      final inHeader = find.byType(ApexHeader);
      expect(
          find.descendant(of: inHeader, matching: find.byType(ColoredBox)),
          findsNothing);
      final boxes = tester
          .widgetList<DecoratedBox>(find.descendant(
              of: inHeader, matching: find.byType(DecoratedBox)))
          .toList();
      expect(boxes, hasLength(1),
          reason: "the icon's box only: nothing is drawn behind the title");
      final box = boxes.single.decoration as BoxDecoration;
      expect(box.gradient, isNull);
      expect(box.color, c.circle);
      expect(
          find.descendant(
              of: find.byWidget(boxes.single),
              matching: find.byIcon(Icons.folder_rounded)),
          findsOneWidget);
      expect(tester.widget<Icon>(find.byIcon(Icons.folder_rounded)).color,
          c.onCircle);

      // What the title sits on is the window: the screen's own surface.
      final under = tester.widget<Material>(find
          .ancestor(of: find.text('Files'), matching: find.byType(Material))
          .first);
      expect(under.color, c.window);

      Color? colorOf(String text) => tester
          .widget<RichText>(find.descendant(
              of: find.text(text), matching: find.byType(RichText)))
          .text
          .style
          ?.color;
      expect(colorOf('Files'), c.text);
      expect(colorOf('3 files'), c.muted);
      expect(colorOf('192.168.1.5:8080'), c.hint);

      double contrast(Color a, Color b) {
        final la = a.computeLuminance(), lb = b.computeLuminance();
        return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
      }

      expect(contrast(c.muted, c.window), greaterThanOrEqualTo(4.5),
          reason: 'the subtitle');
      expect(contrast(c.hint, c.window), greaterThanOrEqualTo(4.5),
          reason: 'the detail line');
    });
  }
}
