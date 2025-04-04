import 'package:cwms_mobile/auth/models/menu.dart';
import 'package:cwms_mobile/auth/models/menu_sub_group.dart';
import 'package:json_annotation/json_annotation.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'menu_group.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class MenuGroup{
  MenuGroup();

  String? name;
  String? text;
  String? i18n;

  List<MenuSubGroup> menuSubGroups = [];





  //不同的类使用不同的mixin即可
  factory MenuGroup.fromJson(Map<String, dynamic> json) => _$MenuGroupFromJson(json);
  Map<String, dynamic> toJson() => _$MenuGroupToJson(this);

}