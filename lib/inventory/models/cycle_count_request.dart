import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'cycle_count_request.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class CycleCountRequest{
  CycleCountRequest();

  int? id;
  String? batchId;
  WarehouseLocation? location;

  // how many times this cycle count has been skiped
  // if the cycle count is skipped, then we will put it
  // to the last in the queue so as the user can skip
  // this count request for now and come back later
  int? skippedCount;

  //不同的类使用不同的mixin即可
  factory CycleCountRequest.fromJson(Map<String, dynamic> json) => _$CycleCountRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CycleCountRequestToJson(this);




}