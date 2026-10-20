import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_sample.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_rule_configuration.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_rule_configuration_rule.dart';
import 'package:cwms_mobile/workorder/services/qc_sampling_questionnaire.dart';

WorkOrderQCSample sample({int? id}) => WorkOrderQCSample()
  ..id = id
  ..number = 'SAMPLE-TEST'
  ..warehouseId = 1;
QCInspectionRequest inspection(
        {int id = 20,
        int sampleId = 10,
        int warehouse = 1,
        QCInspectionResult result = QCInspectionResult.PENDING}) =>
    QCInspectionRequest()
      ..id = id
      ..workOrderQCSampleId = sampleId
      ..warehouseId = warehouse
      ..type = 'BY_WORK_ORDER_SAMPLING'
      ..qcInspectionResult = result;
WorkOrderQCRuleConfiguration config(int quantity, List<int> ids) =>
    WorkOrderQCRuleConfiguration()
      ..qcQuantity = quantity
      ..workOrderQCRuleConfigurationRules = ids
          .map((id) => WorkOrderQCRuleConfigurationRule()..qcRuleId = id)
          .toList();

void main() {
  test('lookup overlaps rules but creation waits for both reads', () async {
    final inspections = Completer<List<QCInspectionRequest>>();
    final configurations = Completer<List<WorkOrderQCRuleConfiguration>>();
    final readsStarted = Completer<void>();
    var readCount = 0, creates = 0;
    void started() { if (++readCount == 2) readsStarted.complete(); }
    final flow = QCSamplingQuestionnaire(
      save: (_) async => sample(id: 10),
      inspections: (_) { started(); return inspections.future; },
      configurations: (_) { started(); return configurations.future; },
      create: (_, __, ___) async { creates++; return inspection(); },
    );
    final result = flow.open(sample());
    await readsStarted.future;
    configurations.complete([config(4, [5, 5])]);
    await Future<void>.delayed(Duration.zero);
    expect(creates, 0);
    inspections.complete([]);
    expect((await result).id, 20);
    expect(creates, 1);
  });

  test('pending recovery does not wait for slow speculative rule read', () async {
    final rules = Completer<List<WorkOrderQCRuleConfiguration>>();
    final task = inspection();
    var creates = 0;
    final flow = QCSamplingQuestionnaire(
      save: (_) async => sample(id: 10),
      inspections: (_) async => [task],
      configurations: (_) => rules.future,
      create: (_, __, ___) async { creates++; return inspection(); },
    );
    expect(await flow.open(sample()).timeout(const Duration(seconds: 1)), same(task));
    rules.completeError(StateError('unused lookup failed'));
    await Future<void>.delayed(Duration.zero);
    expect(creates, 0);
  });

  test('failed inspection lookup cannot create even when rules succeed', () async {
    var creates = 0;
    final flow = QCSamplingQuestionnaire(
      save: (_) async => sample(id: 10),
      inspections: (_) async => throw TimeoutException('read failed'),
      configurations: (_) async => [config(4, [5])],
      create: (_, __, ___) async { creates++; return inspection(); },
    );
    await expectLater(flow.open(sample()), throwsA(isA<TimeoutException>()));
    expect(creates, 0);
  });

  test('uncertain create retries only inspection recovery, not rule lookup', () async {
    var rules = 0, creates = 0;
    final flow = QCSamplingQuestionnaire(
      save: (_) async => sample(id: 10),
      inspections: (_) async => [],
      configurations: (_) async { rules++; return [config(4, [5])]; },
      create: (_, __, ___) async { creates++; throw TimeoutException('unknown'); },
    );
    await expectLater(flow.open(sample()), throwsA(isA<WebAPICallException>()));
    await expectLater(flow.open(sample()), throwsA(isA<WebAPICallException>()));
    expect(creates, 1);
    expect(rules, 1);
  });

  test('save once; deduplicate configured rules and preserve maximum quantity',
      () async {
    var saves = 0, creates = 0;
    final task = inspection();
    final flow = QCSamplingQuestionnaire(
      save: (s) async {
        saves++;
        return sample(id: 10);
      },
      inspections: (_) async => [],
      configurations: (_) async => [
        config(2, [5, 3]),
        config(4, [5])
      ],
      create: (id, ids, quantity) async {
        creates++;
        expect(id, 10);
        expect(ids, '3,5');
        expect(quantity, 4);
        return task;
      },
    );
    expect(await flow.open(sample()), same(task));
    // Returning from the questionnaire must resume the exact task.
    expect(await flow.open(sample()), same(task));
    expect(saves, 1);
    expect(creates, 1);
  });

  test(
      'reuse one pending inspection; ignore completed, other sample and warehouse',
      () async {
    final task = inspection();
    final flow = QCSamplingQuestionnaire(
      save: (_) async => sample(id: 10),
      inspections: (_) async => [
        inspection(result: QCInspectionResult.PASS),
        inspection(sampleId: 11),
        inspection(warehouse: 2),
        task
      ],
      configurations: (_) async => throw StateError('must not generate'),
    );
    expect(await flow.open(sample()), same(task));
  });

  test('multiple pending tasks never select one or create another', () async {
    final flow = QCSamplingQuestionnaire(
      save: (_) async => sample(id: 10),
      inspections: (_) async => [inspection(), inspection(id: 21)],
      create: (_, __, ___) async => throw StateError('must not generate'),
    );
    await expectLater(flow.open(sample()), throwsA(isA<WebAPICallException>()));
    expect(flow.request, isNull);
  });

  test('failed registration is never blindly resubmitted', () async {
    var saves = 0;
    final flow = QCSamplingQuestionnaire(save: (_) async {
      saves++;
      throw TimeoutException('lost response');
    });
    await expectLater(flow.open(sample()), throwsA(isA<WebAPICallException>()));
    await expectLater(flow.open(sample()), throwsA(isA<WebAPICallException>()));
    expect(saves, 1);
    expect(flow.registrationUncertain, isTrue);
  });

  test('uncertain create recovers exact persisted request without a second PUT',
      () async {
    var saves = 0, creates = 0, reads = 0;
    final task = inspection();
    final flow = QCSamplingQuestionnaire(
      save: (_) async {
        saves++;
        return sample(id: 10);
      },
      inspections: (_) async => ++reads == 1 ? [] : [task],
      configurations: (_) async => [
        config(1, [5])
      ],
      create: (_, __, ___) async {
        creates++;
        throw TimeoutException('lost response');
      },
    );
    await expectLater(flow.open(sample()), throwsA(isA<WebAPICallException>()));
    expect(await flow.open(sample()), same(task));
    expect(saves, 1);
    expect(creates, 1);
  });

  test(
      'uncertain create with no pending task remains blocked, never creates twice',
      () async {
    var creates = 0;
    final flow = QCSamplingQuestionnaire(
      save: (_) async => sample(id: 10),
      inspections: (_) async => [],
      configurations: (_) async => [
        config(1, [5])
      ],
      create: (_, __, ___) async {
        creates++;
        throw TimeoutException('lost response');
      },
    );
    await expectLater(flow.open(sample()), throwsA(isA<WebAPICallException>()));
    await expectLater(flow.open(sample()), throwsA(isA<WebAPICallException>()));
    expect(creates, 1);
  });

  test(
      'no configuration preserves registration; retry only loads configuration',
      () async {
    var saves = 0, reads = 0;
    final flow = QCSamplingQuestionnaire(
      save: (_) async {
        saves++;
        return sample(id: 10);
      },
      inspections: (_) async => [],
      configurations: (_) async => ++reads == 1
          ? []
          : [
              config(1, [5])
            ],
      create: (_, __, ___) async => inspection(),
    );
    await expectLater(flow.open(sample()), throwsA(isA<WebAPICallException>()));
    expect(flow.savedSample?.id, 10);
    expect((await flow.open(sample())).id, 20);
    expect(saves, 1);
  });

  test('simultaneous clicks cannot save or create twice', () async {
    final gate = Completer<WorkOrderQCSample>();
    var saves = 0;
    final flow = QCSamplingQuestionnaire(
      save: (_) {
        saves++;
        return gate.future;
      },
      inspections: (_) async => [inspection()],
    );
    final first = flow.open(sample());
    await expectLater(flow.open(sample()), throwsStateError);
    gate.complete(sample(id: 10));
    await first;
    expect(saves, 1);
  });

  test(
      'scope change after registration cannot start QC in another factory/user',
      () async {
    var valid = true;
    final flow = QCSamplingQuestionnaire(
      isCurrentScope: () => valid,
      save: (_) async {
        valid = false;
        return sample(id: 10);
      },
      inspections: (_) async => throw StateError('must not read another scope'),
    );
    await expectLater(flow.open(sample()), throwsA(isA<WebAPICallException>()));
  });

  test('scope change during rule lookup cannot create a request', () async {
    var valid = true, creates = 0;
    final flow = QCSamplingQuestionnaire(
      isCurrentScope: () => valid,
      save: (_) async => sample(id: 10),
      inspections: (_) async => [],
      configurations: (_) async {
        valid = false;
        return [
          config(1, [5])
        ];
      },
      create: (_, __, ___) async {
        creates++;
        return inspection();
      },
    );
    await expectLater(flow.open(sample()), throwsA(isA<WebAPICallException>()));
    expect(creates, 0);
  });

  test('mismatched sample save response cannot start inspection', () async {
    final flow = QCSamplingQuestionnaire(
      save: (_) async => sample(id: 10)..warehouseId = 2,
    );
    await expectLater(flow.open(sample()), throwsA(isA<WebAPICallException>()));
    expect(flow.savedSample, isNull);
    expect(flow.registrationUncertain, isTrue);
  });
}
