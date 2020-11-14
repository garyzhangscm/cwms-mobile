import 'package:cwms_mobile/auth/models/menu.dart';
import 'package:json_annotation/json_annotation.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'menu_sub_group.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class MenuSubGroup{
  MenuSubGroup();

  String name;
  String text;
  String icon;

  List<Menu> menus;





  //不同的类使用不同的mixin即可
  factory MenuSubGroup.fromJson(Map<String, dynamic> json) => _$MenuSubGroupFromJson(json);
  Map<String, dynamic> toJson() => _$MenuSubGroupToJson(this);

}