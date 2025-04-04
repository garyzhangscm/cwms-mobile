
import 'package:json_annotation/json_annotation.dart';

import 'item.dart';
import 'item_package_type.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'item_sampling.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class ItemSampling{

  ItemSampling() ;

  ItemSampling.fromItem(int warehouseId, Item item) {
     this.id = null;
     this.number = "";
     this.description = "";
     this.warehouseId = warehouseId;
     this.imageUrls = "";
     this.item = item;
     this.enabled = true;
  }

  int? id;

  String? number;
  String? description;

  int? warehouseId;

  String? imageUrls;


  Item? item;

  bool? enabled;





  //不同的类使用不同的mixin即可
  factory ItemSampling.fromJson(Map<String, dynamic> json) => _$ItemSamplingFromJson(json);
  Map<String, dynamic> toJson() => _$ItemSamplingToJson(this);




}