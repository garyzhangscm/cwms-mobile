import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/workorder/services/production_submission.dart';

void main() {
  test('scanner and button share one lock until submission finishes', () async {
    final gate = ProductionSubmission();
    final pending = Completer<void>();
    var calls = 0;
    final first = gate.run(() {
      calls++;
      return pending.future;
    });
    await gate.run(() async {
      calls++;
    });
    expect(calls, 1);
    expect(gate.busy, true);
    pending.complete();
    await first;
    expect(gate.busy, false);
    await gate.run(() async {
      calls++;
    });
    expect(calls, 2);
  });
  test('failure releases submission lock', () async {
    final gate = ProductionSubmission();
    await expectLater(gate.run(() async {
      throw StateError('failed');
    }), throwsStateError);
    expect(gate.busy, false);
  });
  test('both checks start together; one LPN validation; wait for both',
      () async {
    final lpn = Completer<String>();
    final assignment = Completer<void>();
    var lpnCalls = 0, assignmentCalls = 0;
    var finished = false;
    final result = validateProductionSubmission(() {
      lpnCalls++;
      return lpn.future;
    }, () {
      assignmentCalls++;
      return assignment.future;
    }).then((value) {
      finished = true;
      return value;
    });
    expect(lpnCalls, 1);
    expect(assignmentCalls, 1);
    lpn.complete('');
    await Future<void>.delayed(Duration.zero);
    expect(finished, false);
    assignment.complete();
    expect(await result, '');
  });
  test('assignment failure prevents successful preflight', () async {
    await expectLater(
        validateProductionSubmission(() async => '', () async {
          throw StateError('unassigned');
        }),
        throwsStateError);
  });
}
