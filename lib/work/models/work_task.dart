
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/work/models/work-task-status.dart';
import 'package:cwms_mobile/work/models/work-task-type.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../auth/models/user.dart';
import 'operation_type.dart';

part 'work_task.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WorkTask{
  WorkTask();

  int? id;

  String? number;
  WorkTaskType? type;
  WorkTaskStatus? status;

  int? priority;
  int? sourceLocationId;
  WarehouseLocation? sourceLocation;
  int? destinationLocationId;
  WarehouseLocation? destinationLocation;

  String? referenceNumber;

  OperationType? operationType;

  //不同的类使用不同的mixin即可
  factory WorkTask.fromJson(Map<String, dynamic> json) => _$WorkTaskFromJson(json);
  Map<String, dynamic> toJson() => _$WorkTaskToJson(this);





}