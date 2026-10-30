import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/outbound/models/pick_rejection.dart';
void main() {
 const lpn='L0000075801';const order='CT000005949';
 final stock=<String,dynamic>{'lpn':lpn,'quantity':36,'pickId':42};
 final pick=<String,dynamic>{'id':42,'orderNumber':order,'pickedQuantity':36,'status':'COMPLETED'};
 PickRejection? classify({List<Map<String,dynamic>>? rows,Map<String,dynamic>? p,List<Map<String,dynamic>> tasks=const []}) => PickRejection.occupied(lpn,order,rows??[stock],{42:p??pick},tasks);
 test('current picked inventory reports duplicate for same order',(){expect(classify()?.title,'LPN already picked');expect(classify()?.reason,contains(order));});
 test('other order names owner, does not imply current order completed',(){final r=classify(p:{...pick,'orderNumber':'CT000005000'});expect(r?.title,'LPN assigned to another order');expect(r?.reason,contains('CT000005000'));});
 test('queued confirmation takes precedence over partially confirmed pick',(){expect(classify(tasks:[{'pickId':42,'state':'QUEUED'}])?.title,'LPN is being processed');});
 test('allocated but not confirmed is not marked completed',(){expect(classify(rows:[{'lpn':lpn,'quantity':36,'allocatedByPickId':42}],p:{...pick,'pickedQuantity':0})?.title,'LPN already submitted');});
 test('unpicked or split free remainder never becomes duplicate',(){for(final rows in [[{'lpn':lpn,'quantity':36}],[stock,{'lpn':lpn,'quantity':12}]]){expect(classify(rows:rows),isNull);}});
 test('historical completed queue is not sufficient without current link',(){expect(classify(rows:[],tasks:[{'pickId':42,'state':'COMPLETED'}]),isNull);});
 test('cancelled pick and unknown owner do not fabricate duplicate',(){expect(classify(p:{...pick,'status':'CANCELLED'}),isNull);expect(classify(p:{...pick,'orderNumber':''}),isNull);});
 test('unrelated LPN and zero quantity are ignored',(){expect(classify(rows:[{...stock,'lpn':'OTHER'}]),isNull);expect(classify(rows:[{...stock,'quantity':0}]),isNull);});
 test('failed confirmation requires review instead of successful duplicate',(){expect(classify(tasks:[{'pickId':42,'state':'NEEDS_REVIEW'}])?.title,'LPN needs review');});
}
