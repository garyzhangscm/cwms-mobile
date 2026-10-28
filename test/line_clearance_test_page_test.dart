import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/workorder/routes/line_clearance_test.dart';

/// Pure UI fixture transport; no MES token or gateway / database connection.
class FixtureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  List<String> caps = ['qc', 'report'];
  String owner = 'qc';
  String stage = 'clearance';
  List<Map<String, dynamic>>? recordItems;
  final savedAnswers = <String, dynamic>{};
  bool failCompletion = false;
  int revision = 1;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    dynamic data;
    if (options.path == 'session') {
      data = {
        'actor': {
          'identity': {'name': 'UI fixture'},
          'caps': caps
        },
        'shifts': {'timezone': 'America/Los_Angeles', 'shifts': []}
      };
    } else if (options.path == 'records' && options.method == 'GET') {
      data = [
        {
          'id': 'fixture',
          'machine': 'M1',
          'workOrder': 'WO-TEST',
          'date': '2026-10-21',
          'status': 'clearance',
          'operator': 'UI fixture'
        }
      ];
    } else {
      data = {
        'id': 'fixture',
        'revision': 1,
        'version': 1,
        'stage': stage,
        'context': {
          'machine': 'M1',
          'workOrder': 'WO-TEST',
          'product': 'TEST',
          'previousProduct': 'OLD-PART',
          'shiftDate': '2026-10-21',
          'shift': {'start': '00:30:00', 'end': '08:30:00'}
        },
        'template': {
          'items': [
            {
              'key': 'check',
              'en': 'Physical line check',
              'es': 'Revisión física',
              'owner': owner,
              'phase': 'clearance',
              'fields': [
                {
                  'key': 'actual',
                  'en': 'Actual residual quantity',
                  'es': 'Cantidad restante real',
                  'type': 'number',
                  'required': true
                },
                {
                  'key': 'confirm',
                  'en': 'Physical verification',
                  'es': 'Verificación física',
                  'type': 'choice',
                  'required': true,
                  'options': ['Confirmed', 'Problem']
                }
              ]
            }
          ]
        },
        'answers': {},
        'issues': {},
        'na': {},
        'signatures': {},
        'links': {}
      };
    }
    data = jsonDecode(jsonEncode(data));
    if (data is Map && data.containsKey('template')) {
      if (recordItems != null) data['template']['items'] = recordItems;
      if (options.path.endsWith('/answer')) {
        final input = options.data as Map;
        if (failCompletion && input['complete'] == true)
          return ResponseBody.fromString(
              jsonEncode({'result': 1, 'message': 'Required evidence missing'}),
              409,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType]
              });
        savedAnswers[input['question']] = {
          'values': jsonDecode(jsonEncode(input['values'])),
          'complete': input['complete'],
          'actor': {'name': 'UI fixture'}
        };
        revision++;
      }
      data['answers'] = jsonDecode(jsonEncode(savedAnswers));
      data['revision'] = revision;
    }
    if (options.path == 'records' && options.method == 'POST') {
      final input = options.data as Map;
      final old = (input['previousWorkOrder'] as String?) ?? '';
      final next = (input['workOrder'] as String?) ?? '';
      data['context']['previousWorkOrder'] = old;
      data['context']['workOrder'] = next;
      data['context']['operation'] = old.isEmpty
          ? 'opening'
          : next.isEmpty
              ? 'closing'
              : 'changeover';
    }
    return ResponseBody.fromString(jsonEncode({'result': 0, 'data': data}), 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FixtureAdapter adapter;
  late Dio client;
  setUp(() {
    Global.currentWarehouse = Warehouse()
      ..id = 1
      ..companyId = 20901;
    Global.lastLoginCompanyId = 20901;
    Global.currentUser = User()..username = 'UI-fixture';
    adapter = FixtureAdapter();
    client = Dio(BaseOptions(baseUrl: 'http://isolated.invalid/'))
      ..httpClientAdapter = adapter;
  });
  testWidgets(
      'Loads test records and opens dynamic questionnaire without default answers',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    await tester.pumpWidget(
        MaterialApp(home: LineClearanceTestPage(testClient: client)));
    await tester.pumpAndSettle();
    expect(find.text('Line Clearance · TEST'), findsOneWidget);
    await tester.tap(find.text('M1 · WO-TEST'));
    await tester.pumpAndSettle();
    expect(find.text('Physical line check'), findsOneWidget);
    final numbers = tester.widgetList<TextField>(find.byType(TextField));
    expect(numbers.any((w) => w.controller?.text == '0'), isFalse);
    expect(
        tester
            .widget<DropdownButtonFormField<String>>(
                find.byType(DropdownButtonFormField<String>))
            .initialValue,
        isNull);
    expect(adapter.requests.last.queryParameters['companyId'], 20901);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('Scanner-size viewport has no rendering overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(
        MaterialApp(home: LineClearanceTestPage(testClient: client)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('M1 · WO-TEST'));
    await tester.tap(find.text('M1 · WO-TEST'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Revisión física'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('Empty old and new orders are rejected before sending create',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    await tester.pumpWidget(
        MaterialApp(home: LineClearanceTestPage(testClient: client)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Line Clearance'));
    await tester.pumpAndSettle();
    expect(
        adapter.requests.any((r) => r.path == 'records' && r.method == 'POST'),
        isFalse);
    expect(
        find.textContaining('Bad state: Enter at least one'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  for (final closing in [false, true])
    testWidgets(
        closing
            ? 'Old-only order can start a closing record'
            : 'New-only order can start an opening record', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1800));
      await tester.pumpWidget(
          MaterialApp(home: LineClearanceTestPage(testClient: client)));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Machine scan'), 'M1');
      await tester.enterText(
          find.widgetWithText(
              TextField,
              closing
                  ? 'Old work order (optional)'
                  : 'New work order (optional)'),
          closing ? 'OLD' : 'NEW');
      await tester.tap(find.text('Start Line Clearance'));
      await tester.pumpAndSettle();
      final request = adapter.requests
          .singleWhere((r) => r.path == 'records' && r.method == 'POST');
      expect(request.data['workOrder'], closing ? '' : 'NEW');
      expect(request.data['previousWorkOrder'], closing ? 'OLD' : '');
      expect(find.textContaining(closing ? 'Closing only' : 'Opening only'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    });
  testWidgets('An account change blocks every new test request',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: LineClearanceTestPage(testClient: client)));
    await tester.pumpAndSettle();
    final count = adapter.requests.length;
    Global.currentUser = User()..username = 'Changed account';
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(adapter.requests.length, count);
    expect(find.textContaining('session changed'), findsOneWidget);
  });
  testWidgets('A submitted scanner field cannot approve a stage by itself',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    await tester.pumpWidget(
        MaterialApp(home: LineClearanceTestPage(testClient: client)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('M1 · WO-TEST'));
    await tester.pumpAndSettle();
    final number = find.widgetWithText(TextField, 'Actual residual quantity *');
    await tester.enterText(number, '0');
    expect(find.text('Complete stage & continue'), findsNothing);
    await tester.pumpAndSettle();
    expect(adapter.requests.any((r) => r.path.endsWith('/advance')), isFalse);
    expect(find.text('Question 1 of 1 — current stage'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
      'QC completes a legacy production question with one submit and no verify button',
      (tester) async {
    adapter.owner = 'production';
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    await tester.pumpWidget(
        MaterialApp(home: LineClearanceTestPage(testClient: client)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('M1 · WO-TEST'));
    await tester.pumpAndSettle();
    expect(find.text('QC verify evidence'), findsNothing);
    await tester.enterText(
        find.widgetWithText(TextField, 'Actual residual quantity *'), '0');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmed').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Complete & next'));
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
    final writes = adapter.requests.where((r) => r.method == 'POST').toList();
    expect(writes.length, 1);
    expect(writes.single.path, 'records/fixture/answer');
    expect(writes.single.data['complete'], true);
    expect(writes.single.data['values'], {'actual': 0, 'confirm': 'Confirmed'});
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('Production-only account has no question completion button',
      (tester) async {
    adapter.caps = ['production', 'report'];
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    await tester.pumpWidget(
        MaterialApp(home: LineClearanceTestPage(testClient: client)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('M1 · WO-TEST'));
    await tester.pumpAndSettle();
    expect(find.text('Complete & next'), findsNothing);
    expect(find.text('QC verify evidence'), findsNothing);
    expect(
        tester
            .widget<TextField>(
                find.widgetWithText(TextField, 'Actual residual quantity *'))
            .enabled,
        false);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  Map<String, dynamic> check(String key, String name) => {
        'key': key,
        'en': name,
        'es': name,
        'owner': 'qc',
        'phase': 'clearance',
        'fields': [
          {
            'key': 'confirmed',
            'en': 'Visual check',
            'es': 'Revisión',
            'type': 'choice',
            'required': true,
            'options': ['Confirmed', 'Problem']
          }
        ]
      };
  Future<void> openPager(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    await tester.pumpWidget(
        MaterialApp(home: LineClearanceTestPage(testClient: client)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('M1 · WO-TEST'));
    await tester.pumpAndSettle();
  }

  Future<void> confirmPage(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmed').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Complete & next'));
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'One question per page saves then opens next and ends on stage summary',
      (tester) async {
    adapter.recordItems = [
      check('one', 'First question'),
      check('two', 'Second question')
    ];
    await openPager(tester);
    expect(find.text('First question'), findsOneWidget);
    expect(find.text('Second question'), findsNothing);
    expect(find.text('Approve temporary N/A'), findsNothing);
    await confirmPage(tester);
    expect(find.text('Second question'), findsOneWidget);
    expect(find.text('First question'), findsNothing);
    expect(adapter.savedAnswers['one']['complete'], true);
    expect(find.text('Question 2 of 2 — current stage'), findsOneWidget);
    await confirmPage(tester);
    expect(find.text('Complete & next'), findsNothing);
    expect(find.text('Stage summary'), findsOneWidget);
    expect(find.text('Complete stage & continue'), findsOneWidget);
    expect(adapter.requests.where((r) => r.path.endsWith('/answer')).length, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('Failed completion stays on the current page and preserves input',
      (tester) async {
    adapter.recordItems = [
      check('one', 'First question'),
      check('two', 'Second question')
    ];
    adapter.failCompletion = true;
    await openPager(tester);
    await confirmPage(tester);
    expect(find.text('First question'), findsOneWidget);
    expect(find.text('Second question'), findsNothing);
    expect(find.text('Required evidence missing'), findsOneWidget);
    expect(
        tester
            .widget<DropdownButtonFormField<String>>(
                find.byType(DropdownButtonFormField<String>))
            .initialValue,
        'Confirmed');
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
      'Resume skips completed questions and previous saves unfinished draft',
      (tester) async {
    adapter.recordItems = [
      check('one', 'First question'),
      check('two', 'Second question')
    ];
    adapter.savedAnswers['one'] = {
      'complete': true,
      'values': {'confirmed': 'Confirmed'}
    };
    await openPager(tester);
    expect(find.text('Second question'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmed').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Previous item'));
    await tester.pumpAndSettle();
    expect(find.text('First question'), findsOneWidget);
    expect(adapter.savedAnswers['two']['complete'], false);
    expect(adapter.savedAnswers['two']['values']['confirmed'], 'Confirmed');
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
      'Unused old material records explicit zero quantities without made-up identifier',
      (tester) async {
    adapter.recordItems = [
      {
        'key': 'old_carton',
        'en': 'Return cartons',
        'es': 'Devolver cajas',
        'owner': 'qc',
        'phase': 'clearance',
        'fields': [
          {
            'key': 'material',
            'en': 'Material ID',
            'es': 'Material',
            'type': 'scan',
            'required': true
          },
          {
            'key': 'quantity',
            'en': 'Quantity',
            'es': 'Cantidad',
            'type': 'number',
            'required': true
          },
          {
            'key': 'remaining',
            'en': 'Remaining',
            'es': 'Restante',
            'type': 'number',
            'required': true
          }
        ]
      }
    ];
    await openPager(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not used').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Material ID *'), findsNothing);
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
    expect(adapter.savedAnswers['old_carton']['values'],
        {'usage': 'Not used', 'quantity': 0, 'remaining': 0});
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  Map<String, dynamic> simpleCarton() => {
        'key': 'old_carton',
        'en': 'Confirm old cartons cleared',
        'es': 'Cajas retiradas',
        'owner': 'qc',
        'phase': 'clearance',
        'fields': [
          {
            'key': 'usage',
            'en': 'Usage',
            'es': 'Uso',
            'type': 'choice',
            'required': true,
            'options': ['Used', 'Not used']
          },
          {
            'key': 'clear',
            'en': 'All old cartons removed',
            'es': 'Todas las cajas retiradas',
            'type': 'choice',
            'required': true,
            'options': ['Confirmed', 'Problem']
          },
          {
            'key': 'photo',
            'en': 'Photo of the cleared carton area',
            'es': 'Foto del área despejada',
            'type': 'photo',
            'required': true
          }
        ]
      };
  testWidgets(
      'Simplified carton page has no identifier or quantity and submits confirmation and photo',
      (tester) async {
    adapter.recordItems = [simpleCarton()];
    adapter.savedAnswers['old_carton'] = {
      'complete': false,
      'values': {'usage': 'Used', 'photo': 'uploaded-photo'}
    };
    await openPager(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Photo of the cleared carton area *'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmed').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Complete & next'));
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
    expect(adapter.savedAnswers['old_carton']['values'],
        {'usage': 'Used', 'clear': 'Confirmed', 'photo': 'uploaded-photo'});
    expect(find.text('Stage summary'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
      'Simplified carton unused completes with usage only and no photo or numbers',
      (tester) async {
    adapter.recordItems = [simpleCarton()];
    await openPager(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not used').last);
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsNothing);
    expect(find.text('All old cartons removed *'), findsNothing);
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
    expect(adapter.savedAnswers['old_carton']['values'], {'usage': 'Not used'});
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  for (final key in ['old_labels', 'old_rfid', 'old_gtin'])
    testWidgets(
        '$key confirms cleared with photo or completes unused without identifiers',
        (tester) async {
      final q = simpleCarton();
      q['key'] = key;
      q['en'] = 'Clear $key';
      adapter.recordItems = [q];
      adapter.savedAnswers[key] = {
        'complete': false,
        'values': {'usage': 'Used', 'photo': 'uploaded-photo'}
      };
      await openPager(tester);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmed').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Complete & next'));
      await tester.tap(find.text('Complete & next'));
      await tester.pumpAndSettle();
      expect(adapter.savedAnswers[key]['values'],
          {'usage': 'Used', 'clear': 'Confirmed', 'photo': 'uploaded-photo'});
      await tester.tap(find.text('Previous item'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not used').last);
      await tester.pumpAndSettle();
      expect(find.text('Take photo'), findsNothing);
      await tester.tap(find.text('Complete & next'));
      await tester.pumpAndSettle();
      expect(adapter.savedAnswers[key]['values'], {'usage': 'Not used'});
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    });
  Map<String, dynamic> simpleResin() => {
        'key': 'old_resin',
        'en': 'Return old colorant and resin',
        'es': 'Devolver colorante y resina',
        'owner': 'qc',
        'phase': 'clearance',
        'fields': [
          {
            'key': 'usage',
            'en': 'Usage',
            'es': 'Uso',
            'type': 'choice',
            'required': true,
            'options': ['Used', 'Not used']
          },
          {
            'key': 'returned',
            'en': 'All old colorant and resin collected',
            'es': 'Todo recogido',
            'type': 'choice',
            'required': true,
            'options': ['Confirmed', 'Problem']
          },
          {
            'key': 'containers',
            'en': 'Containers and labels correct',
            'es': 'Recipientes y etiquetas correctos',
            'type': 'choice',
            'required': true,
            'options': ['Confirmed', 'Problem']
          },
          {
            'key': 'photo',
            'en': 'Photo of returned materials, containers and labels',
            'es': 'Foto de materiales, recipientes y etiquetas',
            'type': 'photo',
            'required': true
          }
        ]
      };
  testWidgets(
      'Old resin has two confirmations and photo with no scans or quantity fields',
      (tester) async {
    adapter.recordItems = [simpleResin()];
    adapter.savedAnswers['old_resin'] = {
      'complete': false,
      'values': {'usage': 'Used', 'photo': 'uploaded-photo'}
    };
    await openPager(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3));
    for (final i in [1, 2]) {
      await tester
          .ensureVisible(find.byType(DropdownButtonFormField<String>).at(i));
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(i));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmed').last);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Complete & next'));
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
    expect(adapter.savedAnswers['old_resin']['values'], {
      'usage': 'Used',
      'returned': 'Confirmed',
      'containers': 'Confirmed',
      'photo': 'uploaded-photo'
    });
    expect(find.text('Stage summary'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
      'Unused old resin hides confirmations and photo and sends usage only',
      (tester) async {
    adapter.recordItems = [simpleResin()];
    await openPager(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not used').last);
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('Take photo'), findsNothing);
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
    expect(adapter.savedAnswers['old_resin']['values'], {'usage': 'Not used'});
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  Map<String, dynamic> simpleLastShot() => {
        'key': 'last_shot',
        'en': 'Last-shot sample',
        'es': 'Última inyección',
        'owner': 'qc',
        'phase': 'clearance',
        'fields': [
          {
            'key': 'delivered',
            'en': 'Sample delivered to blue tag room',
            'es': 'Muestra entregada',
            'type': 'choice',
            'required': true,
            'options': ['Confirmed', 'Problem']
          },
          {
            'key': 'label',
            'en': 'Label machine, date and part correct',
            'es': 'Etiqueta correcta',
            'type': 'choice',
            'required': true,
            'options': ['Confirmed', 'Problem']
          },
          {
            'key': 'photo',
            'en': 'Photo of sample and readable label',
            'es': 'Foto de muestra y etiqueta',
            'type': 'photo',
            'required': true
          }
        ]
      };
  testWidgets(
      'Last shot shows two confirmations and photo, reference only, no inputs or unused option',
      (tester) async {
    adapter.recordItems = [simpleLastShot()];
    adapter.savedAnswers['last_shot'] = {
      'complete': false,
      'values': {'photo': 'uploaded-photo'}
    };
    await openPager(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    expect(
        find.textContaining('Reference — Machine: M1 · Old product: OLD-PART'),
        findsOneWidget);
    expect(find.textContaining('Was this material used'), findsNothing);
    expect(find.text('Not used'), findsNothing);
    for (final i in [0, 1]) {
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(i));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmed').last);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Complete & next'));
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
    expect(adapter.savedAnswers['last_shot']['values'], {
      'delivered': 'Confirmed',
      'label': 'Confirmed',
      'photo': 'uploaded-photo'
    });
    expect(find.text('Stage summary'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
      'Old documents need one returned confirmation and photo with no document identifiers',
      (tester) async {
    adapter.recordItems = [
      {
        'key': 'old_documents',
        'en': 'Collect old documents',
        'es': 'Recoger documentos',
        'owner': 'qc',
        'phase': 'clearance',
        'fields': [
          {
            'key': 'returned',
            'en': 'All old instructions, alerts and forms collected',
            'es': 'Todos recogidos',
            'type': 'choice',
            'required': true,
            'options': ['Confirmed', 'Problem']
          },
          {
            'key': 'photo',
            'en': 'Photo of collected old documents',
            'es': 'Foto de documentos',
            'type': 'photo',
            'required': true
          }
        ]
      }
    ];
    adapter.savedAnswers['old_documents'] = {
      'complete': false,
      'values': {'photo': 'uploaded-photo'}
    };
    await openPager(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('Not used'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmed').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Complete & next'));
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
    expect(adapter.savedAnswers['old_documents']['values'],
        {'returned': 'Confirmed', 'photo': 'uploaded-photo'});
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
      'New work order cartons need only a photo, no scans numbers or choices',
      (tester) async {
    adapter.recordItems = [
      {
        'key': 'new_carton',
        'en': 'New cartons',
        'es': 'Cajas nuevas',
        'owner': 'qc',
        'phase': 'clearance',
        'fields': [
          {
            'key': 'photo',
            'en': 'Photo of new cartons',
            'es': 'Foto de cajas',
            'type': 'photo',
            'required': true
          }
        ]
      }
    ];
    adapter.savedAnswers['new_carton'] = {
      'complete': false,
      'values': {'photo': 'uploaded-photo'}
    };
    await openPager(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Photo of new cartons *'), findsOneWidget);
    await tester.ensureVisible(find.text('Complete & next'));
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
    expect(adapter.savedAnswers['new_carton']['values'],
        {'photo': 'uploaded-photo'});
    expect(find.text('Stage summary'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
      'New colorant and resin use material/container confirmations and photo without IDs',
      (tester) async {
    adapter.recordItems = [
      {
        'key': 'new_resin',
        'en': 'Verify new colorant and resin',
        'es': 'Verificar materiales nuevos',
        'owner': 'qc',
        'phase': 'clearance',
        'fields': [
          {
            'key': 'materials',
            'en': 'Correct new materials for work order',
            'es': 'Materiales correctos',
            'type': 'choice',
            'required': true,
            'options': ['Confirmed', 'Problem']
          },
          {
            'key': 'container',
            'en': 'Correct containers and labels',
            'es': 'Recipientes y etiquetas correctos',
            'type': 'choice',
            'required': true,
            'options': ['Confirmed', 'Problem']
          },
          {
            'key': 'photo',
            'en': 'Photo of new materials containers and labels',
            'es': 'Foto de materiales',
            'type': 'photo',
            'required': true
          }
        ]
      }
    ];
    adapter.savedAnswers['new_resin'] = {
      'complete': false,
      'values': {'photo': 'uploaded-photo'}
    };
    await openPager(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    expect(find.text('Not used'), findsNothing);
    for (final i in [0, 1]) {
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(i));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmed').last);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Complete & next'));
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
    expect(adapter.savedAnswers['new_resin']['values'], {
      'materials': 'Confirmed',
      'container': 'Confirmed',
      'photo': 'uploaded-photo'
    });
    expect(find.text('Stage summary'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
      'New documents have version/onsite confirmations and photo without document IDs',
      (tester) async {
    adapter.recordItems = [
      {
        'key': 'new_documents',
        'en': 'Current documents at point of use',
        'es': 'Documentos vigentes',
        'owner': 'qc',
        'phase': 'clearance',
        'fields': [
          {
            'key': 'current',
            'en': 'Correct document versions',
            'es': 'Versiones correctas',
            'type': 'choice',
            'required': true,
            'options': ['Confirmed', 'Problem']
          },
          {
            'key': 'placed',
            'en': 'Documents placed at point of use',
            'es': 'Documentos en el punto de uso',
            'type': 'choice',
            'required': true,
            'options': ['Confirmed', 'Problem']
          },
          {
            'key': 'photo',
            'en': 'Photo of documents at point of use',
            'es': 'Foto de documentos',
            'type': 'photo',
            'required': true
          }
        ]
      }
    ];
    adapter.savedAnswers['new_documents'] = {
      'complete': false,
      'values': {'photo': 'uploaded-photo'}
    };
    await openPager(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    expect(find.text('Not used'), findsNothing);
    for (final i in [0, 1]) {
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(i));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmed').last);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Complete & next'));
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
    expect(adapter.savedAnswers['new_documents']['values'], {
      'current': 'Confirmed',
      'placed': 'Confirmed',
      'photo': 'uploaded-photo'
    });
    expect(find.text('Stage summary'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
      'Sample comparison uses confirmation/photo without tag IDs and keeps technician signing',
      (tester) async {
    adapter.stage = 'sample';
    adapter.caps = ['qc', 'technician', 'report'];
    adapter.recordItems = [
      {
        'key': 'yellow_blue',
        'en': 'Compare Yellow and Blue Tag samples',
        'es': 'Comparar muestras',
        'owner': 'qc',
        'phase': 'sample',
        'fields': [
          {
            'key': 'comparison',
            'en': 'Physical sample comparison completed',
            'es': 'Comparación completada',
            'type': 'choice',
            'required': true,
            'options': ['Confirmed', 'Problem']
          },
          {
            'key': 'photo',
            'en': 'Photo of both samples together',
            'es': 'Foto de ambas muestras',
            'type': 'photo',
            'required': true
          }
        ]
      }
    ];
    adapter.savedAnswers['yellow_blue'] = {
      'complete': false,
      'values': {'photo': 'uploaded-photo'}
    };
    await openPager(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('Not used'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmed').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Complete & next'));
    await tester.tap(find.text('Complete & next'));
    await tester.pumpAndSettle();
    expect(adapter.savedAnswers['yellow_blue']['values'],
        {'comparison': 'Confirmed', 'photo': 'uploaded-photo'});
    expect(find.text('Sign as technician — UI fixture'), findsOneWidget);
    expect(find.text('Sign as qc — UI fixture'), findsOneWidget);
    expect(find.text('Verify existing MES PASS inspection'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
}
