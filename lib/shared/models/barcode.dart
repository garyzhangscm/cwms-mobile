

import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';


///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class Barcode {

  Barcode(this.is_2d, this.result, this.value);

  bool? is_2d;
  // result for parsing 2d barcode
  Map<String, String>? result;

  String? value;


}
