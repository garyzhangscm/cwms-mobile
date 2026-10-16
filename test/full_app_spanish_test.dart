import 'package:cwms_mobile/i18n/spanish_ui.dart';
import 'package:cwms_mobile/i18n/messages_es.dart' as es;
import 'package:cwms_mobile/i18n/messages_messages.dart' as en;
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/workspace_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every existing language catalog key has an explicit Spanish entry', () {
    expect(
        es.messages.messages.keys
            .toSet()
            .containsAll(en.messages.messages.keys),
        isTrue);
    for (final key in en.messages.messages.keys.where((k) =>
        !['greetingMessage', 'missingField', 'incorrectValue'].contains(k))) {
      final english =
          Function.apply(en.messages.messages[key]! as Function, const [])
              as String;
      expect(
          spanishUiTranslations.keys
              .map((k) => k.toLowerCase())
              .contains(english.toLowerCase()),
          isTrue,
          reason: 'Missing $key: $english');
    }
  });
  test('all translated templates preserve every variable', () {
    Set<String> slots(String s) =>
        RegExp(r'\{\d+\}').allMatches(s).map((m) => m[0]!).toSet();
    for (final entry in spanishUiTranslations.entries)
      expect(slots(entry.value), slots(entry.key), reason: entry.key);
  });
  test('known dynamic errors preserve identifiers and quantities', () {
    expect(spanishUi('Order TEST-ORDER-001 has no remaining quantity to pick.'),
        'El pedido TEST-ORDER-001 no tiene cantidad pendiente de preparación.');
    expect(
        spanishUi(
            'there\'s no more open quantity left for manual pick of order TEST-ORDER-001'),
        'El pedido TEST-ORDER-001 no tiene cantidad pendiente de preparación manual');
    expect(spanishUi('SAMPLE-ITEM-001'), 'SAMPLE-ITEM-001');
  });
  for (final width in [320.0, 390.0, 1024.0]) {
    testWidgets('Spanish operation labels and language switching fit at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var locale = const Locale('es', 'US');
      late StateSetter change;
      var count = 0;
      await tester.pumpWidget(StatefulBuilder(builder: (context, setState) {
        change = setState;
        return MaterialApp(
            theme: ThemeData(
                platform:
                    width == 390 ? TargetPlatform.iOS : TargetPlatform.android),
            locale: locale,
            supportedLocales: const [Locale('en', 'US'), Locale('es', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              CWMSLocalizationsDelegate()
            ],
            home: RepaintBoundary(
                key: const ValueKey('spanish-preview'),
                child: Builder(
                    builder: (context) => Scaffold(
                        body: SingleChildScrollView(
                            child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(children: [
                                  const WorkspaceHeader(
                                      title: 'Work Order',
                                      subtitle:
                                          'Choose an operation to get started.'),
                                  WorkspaceGrid(children: [
                                    for (final title in [
                                      'Produce',
                                      'Reverse Production',
                                      'QC Sampling',
                                      'Work Order QC',
                                      'Production Line Check In',
                                      'Production Line Check Out',
                                      'Pick By Work Order',
                                      'Manual Pick',
                                      'Defective'
                                    ])
                                      WorkspaceTile(
                                          title: title,
                                          identity: title,
                                          index: 0,
                                          onTap: () => count++)
                                  ]),
                                  Text(uiTemplate(
                                      context, 'Item: {0}', ['Produce'])),
                                  Text(uiTemplate(
                                      context,
                                      'Take {0} units and attach the new label. Leave {1} units with {2}.',
                                      [40, 285, 'L0000116016'])),
                                  Text(
                                      uiOptionalText(context, null) ?? 'VALID'),
                                ])))))));
      }));
      await tester.pumpAndSettle();
      expect(find.text('Orden de trabajo'), findsOneWidget);
      expect(find.text('Registrar producción'), findsOneWidget);
      expect(find.text('Producto: Produce'), findsOneWidget);
      expect(find.textContaining('40 unidades'), findsOneWidget);
      expect(find.textContaining('L0000116016'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final element in find
          .descendant(
              of: find.byType(WorkspaceTile), matching: find.byType(Text))
          .evaluate()) {
        final paragraph = element.renderObject! as RenderParagraph;
        expect(paragraph.didExceedMaxLines, isFalse,
            reason: (element.widget as Text).data);
      }
      await tester.ensureVisible(find.text('Producción defectuosa'));
      await tester.tap(find.text('Producción defectuosa'));
      expect(count, 1);
      change(() => locale = const Locale('en', 'US'));
      await tester.pumpAndSettle();
      expect(find.text('Work Order'), findsOneWidget);
      expect(find.text('Produce'), findsOneWidget);
      expect(find.text('Item: Produce'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
