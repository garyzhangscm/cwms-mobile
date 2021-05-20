import 'package:json_annotation/json_annotation.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'cycle_count_batch.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class CycleCountBatch{
  CycleCountBatch();


  int id;
  String batchId;
  int warehouseId;

  int requestLocationCount;
  int openLocationCount;
  int finishedLocationCount;
  int cancelledLocationCount;
  int openAuditLocationCount;
  int finishedAuditLocationCount;




  //不同的类使用不同的mixin即可
  factory CycleCountBatch.fromJson(Map<String, dynamic> json) => _$CycleCountBatchFromJson(json);
  Map<String, dynamic> toJson() => _$CycleCountBatchToJson(this);




}