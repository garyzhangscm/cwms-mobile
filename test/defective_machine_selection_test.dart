import 'dart:async';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_status.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/services/defective_machines.dart';
import 'package:cwms_mobile/workorder/routes/defective_machine_selection.dart';

WorkOrder order(int id, ProductionLine line,
        {WorkOrderStatus? status = WorkOrderStatus.INPROCESS}) =>
    WorkOrder()
      ..id = id
      ..number = 'WO-$id'
      ..status = status
      ..itemId = 99
      ..item = (Item()
        ..id = 99
        ..name = 'ABS-01'
        ..description = 'Injection molded shell'
        ..itemPackageTypes = [ItemPackageType()..id = 1])
      ..productionLineAssignments = [
        ProductionLineAssignment()
          ..id = id
          ..productionLine = line
      ];

class ApiAdapter implements HttpClientAdapter {
  ApiAdapter(this.orders);
  final List<Map<String, dynamic>> orders;
  final requests = <RequestOptions>[];
  Completer<void>? itemGate;
  int? summaryStatus;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    requests.add(options);
    if (options.path == 'inventory/items' &&
        options.queryParameters['loadDetails'] == false) {
      await itemGate?.future;
    }
    if (options.path.endsWith('active-machine-summaries') &&
        summaryStatus != null) {
      return ResponseBody.fromString('{}', summaryStatus!, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
    }
    final summaries = [
      for (final o in orders)
        for (final a in (o['productionLineAssignments'] as List? ?? []))
          if (a['deassigned'] != true)
            {
              'workOrderId': o['id'],
              'workOrderNumber': o['number'],
              'itemId': o['itemId'],
              'warehouseId': o['warehouseId'],
              'status': o['status'],
              'expectedQuantity': o['expectedQuantity'],
              'producedQuantity': o['producedQuantity'],
              'productionLineId': a['productionLine']['id'],
              'productionLineName': a['productionLine']['name'],
            }
    ];
    final data = options.path == 'inventory/items'
        ? [
            {
              'id': 99,
              'name': 'ABS-01',
              'description': 'Shell',
              'itemPackageTypes': options.queryParameters['loadDetails'] == true
                  ? [(ItemPackageType()..id = 1).toJson()]
                  : []
            }
          ]
        : options.path.endsWith('active-machine-summaries')
            ? summaries
            : orders;
    return ResponseBody.fromString(jsonEncode({'result': 0, 'data': data}), 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

Future<void> openPicker(
    WidgetTester tester, List<DefectiveMachine> machines) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
      home: DefectiveMachineSelectionPage(loader: () async => machines),
      onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => Text(
              '${(settings.arguments as Map)['workOrder'].number} / ${(settings.arguments as Map)['productionLine'].name}'))));
  await tester.pumpAndSettle();
}

void main() {
  test('summary preserves two machines assigned to the same order', () async {
    final first = ProductionLine()
      ..id = 1
      ..name = 'IM-01';
    final second = ProductionLine()
      ..id = 2
      ..name = 'IM-02';
    final value = order(1, first)
      ..expectedQuantity = 100
      ..producedQuantity = 12;
    value.productionLineAssignments
        .add(ProductionLineAssignment()..productionLine = second);
    final adapter = ApiAdapter([jsonDecode(jsonEncode(value.toJson()))]);
    final client = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/'))
      ..httpClientAdapter = adapter;
    final result =
        await DefectiveMachineService.load(client: client, warehouseId: 7);
    expect(result.map((m) => m.line.name), ['IM-01', 'IM-02']);
    expect(result.first.orders.single.expectedQuantity, 100);
    expect(result.first.orders.single.producedQuantity, 12);
    expect(adapter.requests.first.path, endsWith('active-machine-summaries'));
    expect(adapter.requests.length, 2);
  });
  test('only missing endpoint falls back, server failures do not', () async {
    final line = ProductionLine()
      ..id = 1
      ..name = 'IM-01';
    for (final status in [404, 500, 401]) {
      final adapter =
          ApiAdapter([jsonDecode(jsonEncode(order(1, line).toJson()))])
            ..summaryStatus = status;
      final client = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/'))
        ..httpClientAdapter = adapter;
      if (status == 404) {
        final result =
            await DefectiveMachineService.load(client: client, warehouseId: 7);
        expect(result.single.line.id, 1);
        expect(adapter.requests[1].path, endsWith('assigned-work-orders'));
        final before = adapter.requests.length;
        await DefectiveMachineService.load(client: client, warehouseId: 7);
        expect(adapter.requests[before].path, endsWith('assigned-work-orders'));
        expect(
            adapter.requests
                .where((r) => r.path.endsWith('active-machine-summaries'))
                .length,
            1);
      } else {
        await expectLater(
            DefectiveMachineService.load(client: client, warehouseId: 7),
            throwsA(isA<DioException>()));
        expect(adapter.requests.length, 1);
      }
    }
  });
  test(
      'groups distinct machines and excludes ended, unknown and unassigned orders',
      () {
    final line = ProductionLine()
      ..id = 1
      ..name = 'IM-01';
    final first = order(1, line);
    final values = [
      first,
      first,
      order(2, line),
      for (final status in [
        WorkOrderStatus.CANCELLED,
        WorkOrderStatus.CLOSED,
        WorkOrderStatus.COMPLETED,
        null
      ])
        order(3, line, status: status),
      order(4, line)..productionLineAssignments = []
    ];
    final machines = groupDefectiveMachines(values);
    expect(machines.length, 1);
    expect(machines.single.orders.map((e) => e.id), [1, 2]);
  });
  test(
      'bulk loads unique item ids without per-machine HTTP calls and excludes historical assignments',
      () async {
    final line = ProductionLine()
      ..id = 1
      ..name = 'IM-01';
    Map<String, dynamic> raw(int id) =>
        jsonDecode(jsonEncode(order(id, line).toJson()))
            as Map<String, dynamic>;
    final first = raw(1)..['item'] = null;
    final second = raw(2)..['item'] = null;
    final historical = raw(3);
    (historical['productionLineAssignments'] as List).first['deassigned'] =
        true;
    final adapter = ApiAdapter([first, second, historical, first]);
    final client = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/'))
      ..httpClientAdapter = adapter;
    final result =
        await DefectiveMachineService.load(client: client, warehouseId: 7);
    expect(result.single.orders.length, 2);
    expect(result.single.orders.first.item!.description, 'Shell');
    expect(adapter.requests.length, 2);
    expect(adapter.requests.last.queryParameters['itemIdList'], '99');
    expect(adapter.requests.last.queryParameters['loadDetails'], isFalse);
    expect(adapter.requests.first.queryParameters['warehouseId'], 7);
    expect(adapter.requests.every((r) => r.method == 'GET'), isTrue);
  });
  test('fresh validation rejects a completed or removed work order', () async {
    final line = ProductionLine()
      ..id = 1
      ..name = 'IM-01';
    final selected = order(1, line);
    final ended = order(1, line, status: WorkOrderStatus.COMPLETED);
    final adapter = ApiAdapter([jsonDecode(jsonEncode(ended.toJson()))]);
    final client = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/'))
      ..httpClientAdapter = adapter;
    expect(
        await DefectiveMachineService.isStillAssigned(selected, line,
            client: client, warehouseId: 7),
        isFalse);
    adapter.orders.clear();
    expect(
        await DefectiveMachineService.isStillAssigned(selected, line,
            client: client, warehouseId: 7),
        isFalse);
    adapter.orders.add(jsonDecode(jsonEncode(selected.toJson())));
    expect(
        await DefectiveMachineService.isStillAssigned(selected, line,
            client: client, warehouseId: 7),
        isTrue);
    expect(adapter.requests.last.queryParameters['productionLineId'], 1);
  });
  test('selected machine alone loads full item details before reporting',
      () async {
    final line = ProductionLine()
      ..id = 1
      ..name = 'IM-01';
    final selected = order(1, line)..item!.itemPackageTypes = [];
    final adapter = ApiAdapter([]);
    final client = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/'))
      ..httpClientAdapter = adapter;
    await DefectiveMachineService.prepareOrder(selected,
        client: client, warehouseId: 7);
    expect(adapter.requests.length, 1);
    expect(adapter.requests.single.queryParameters['itemIdList'], '99');
    expect(adapter.requests.single.queryParameters['loadDetails'], isTrue);
    expect(selected.item!.itemPackageTypes.length, 1);
  });

  test(
      'machine progress is available before item names; late names cannot overwrite selected details',
      () async {
    final line = ProductionLine()
      ..id = 1
      ..name = 'IM-01';
    final raw =
        jsonDecode(jsonEncode(order(1, line).toJson())) as Map<String, dynamic>;
    raw['item'] = null;
    final adapter = ApiAdapter([raw])..itemGate = Completer<void>();
    final client = Dio(BaseOptions(baseUrl: 'https://test.invalid/api/'))
      ..httpClientAdapter = adapter;
    final progress = Completer<List<DefectiveMachine>>();
    final loading = DefectiveMachineService.load(
        client: client,
        warehouseId: 7,
        onProgress: (machines) => progress.complete(machines));
    final early = await progress.future;
    expect(early.single.line.name, 'IM-01');
    expect(early.single.orders.single.item, isNull);
    await DefectiveMachineService.prepareOrder(early.single.orders.single,
        client: client, warehouseId: 7);
    adapter.itemGate!.complete();
    final result = await loading;
    expect(result.single.orders.single.item!.itemPackageTypes.length, 1);
  });

  testWidgets(
      'refresh keeps machine cards visible while the next request is pending',
      (tester) async {
    final line = ProductionLine()
      ..id = 1
      ..name = 'IM-01';
    final refreshed = Completer<List<DefectiveMachine>>();
    var calls = 0;
    await tester.pumpWidget(
        MaterialApp(home: DefectiveMachineSelectionPage(loader: () async {
      if (++calls == 1)
        return [
          DefectiveMachine(line, [order(1, line)])
        ];
      return refreshed.future;
    })));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();
    expect(find.text('IM-01'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Updating machines…'), findsOneWidget);
    refreshed.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No machines with active assigned work orders'),
        findsOneWidget);
  });

  test(
      'prefetch shares the request, refresh reloads and a warehouse switch clears cache',
      () async {
    final oldServer = Global.currentServer;
    final oldUser = Global.currentUser;
    final oldWarehouse = Global.currentWarehouse;
    addTearDown(() {
      Global.currentServer = oldServer;
      Global.currentUser = oldUser;
      Global.currentWarehouse = oldWarehouse;
    });
    Global.currentServer = CWMSSiteInformation()
      ..url = 'https://test.invalid/api/';
    Global.currentUser = User()
      ..username = 'TEST'
      ..token = 'test-token';
    Global.currentWarehouse = Warehouse()..id = 7;
    final line = ProductionLine()
      ..id = 1
      ..name = 'IM-01';
    final adapter =
        ApiAdapter([jsonDecode(jsonEncode(order(1, line).toJson()))]);
    CWMSHttpClient.resetDio();
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
    await Future.wait(
        [DefectiveMachineService.prefetch(), DefectiveMachineService.load()]);
    expect(
        adapter.requests
            .where((r) => r.path.endsWith('active-machine-summaries'))
            .length,
        1);
    await DefectiveMachineService.load();
    expect(
        adapter.requests
            .where((r) => r.path.endsWith('active-machine-summaries'))
            .length,
        1);
    await DefectiveMachineService.load(forceRefresh: true);
    expect(
        adapter.requests
            .where((r) => r.path.endsWith('active-machine-summaries'))
            .length,
        2);
    Global.currentWarehouse = Warehouse()..id = 8;
    await DefectiveMachineService.load();
    expect(adapter.requests.length, 6);
    expect(adapter.requests.last.queryParameters['warehouseId'], 8);
  });

  testWidgets(
      'single machine opens reporting with the chosen work order and line',
      (tester) async {
    final line = ProductionLine()
      ..id = 1
      ..name = 'IM-01';
    final second = ProductionLine()
      ..id = 2
      ..name = 'CM02';
    final third = ProductionLine()
      ..id = 3
      ..name = 'CM03';
    final secondOrder = order(2, second)..item!.name = '4GBGS-19-BLUE';
    final thirdOrder = order(3, third)..item!.name = 'ABS-C-YT-WH-08';
    await openPicker(tester, [
      DefectiveMachine(line, [order(1, line)]),
      DefectiveMachine(second, [secondOrder]),
      DefectiveMachine(third, [thirdOrder]),
    ]);
    final firstPosition = tester.getCenter(find.text('IM-01'));
    final secondPosition = tester.getCenter(find.text('CM02'));
    final thirdPosition = tester.getCenter(find.text('CM03'));
    expect(firstPosition.dx, lessThan(secondPosition.dx));
    expect(secondPosition.dx, lessThan(thirdPosition.dx));
    expect((firstPosition.dy - thirdPosition.dy).abs(), lessThan(15));
    expect(find.text('ABS-01'), findsOneWidget);
    expect(find.text('Injection molded shell'), findsNothing);
    expect(find.textContaining('WO-1'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('IM-01'));
    await tester.pumpAndSettle();
    expect(find.text('WO-1 / IM-01'), findsOneWidget);
  });
  testWidgets('multiple assigned work orders require an explicit choice',
      (tester) async {
    final line = ProductionLine()
      ..id = 1
      ..name = 'IM-01';
    await openPicker(tester, [
      DefectiveMachine(line, [order(1, line), order(2, line)])
    ]);
    await tester.tap(find.text('IM-01'));
    await tester.pumpAndSettle();
    expect(find.text('IM-01 · Choose work order'), findsOneWidget);
    await tester.tap(find.text('WO-2').last);
    await tester.pumpAndSettle();
    expect(find.text('WO-2 / IM-01'), findsOneWidget);
  });
  testWidgets(
      'missing item prevents navigation and a failed load can be retried',
      (tester) async {
    final line = ProductionLine()
      ..id = 1
      ..name = 'IM-01';
    await openPicker(tester, [
      DefectiveMachine(line, [order(1, line)..item = null])
    ]);
    await tester.tap(find.text('IM-01'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Item or package details are missing. Refresh or check configuration.'),
        findsOneWidget);
    var count = 0;
    await tester.pumpWidget(MaterialApp(
        home: DefectiveMachineSelectionPage(
            key: const Key('retry'),
            loader: () async {
              if (++count == 1) throw Exception('offline');
              return [];
            })));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No machines with active assigned work orders'),
        findsOneWidget);
  });
}
