
import 'package:json_annotation/json_annotation.dart';


// user.g.dart 将在我们运行生成命令后自动生成
part 'inventory_configuration.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class InventoryConfiguration{
  InventoryConfiguration() ;

  int? id;

  int? companyId;
  int? warehouseId;

  String? lpnValidationRule;

  String? inventoryAttribute1DisplayName;
  bool? inventoryAttribute1Enabled;
  String? inventoryAttribute2DisplayName;
  bool? inventoryAttribute2Enabled;
  String? inventoryAttribute3DisplayName;
  bool? inventoryAttribute3Enabled;
  String? inventoryAttribute4DisplayName;
  bool? inventoryAttribute4Enabled;
  String? inventoryAttribute5DisplayName;
  bool? inventoryAttribute5Enabled;

  getInventoryAttributeDisplayName(String attributeName) {

    String displayName = attributeName;
    if (attributeName == "attribute1" && inventoryAttribute1DisplayName!.isNotEmpty) {
      displayName = inventoryAttribute1DisplayName!;
    }
    else if (attributeName == "attribute2" && inventoryAttribute2DisplayName!.isNotEmpty) {
      displayName = inventoryAttribute2DisplayName!;
    }
    else if (attributeName == "attribute3" && inventoryAttribute3DisplayName!.isNotEmpty) {
      displayName = inventoryAttribute3DisplayName!;
    }
    else if (attributeName == "attribute4" && inventoryAttribute4DisplayName!.isNotEmpty) {
      displayName =  inventoryAttribute4DisplayName!;
    }
    else if (attributeName == "attribute5" && inventoryAttribute5DisplayName!.isNotEmpty) {
      displayName = inventoryAttribute5DisplayName!;
    }
    return displayName;


  }

  //不同的类使用不同的mixin即可
  factory InventoryConfiguration.fromJson(Map<String, dynamic> json) => _$InventoryConfigurationFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryConfigurationToJson(this);




}