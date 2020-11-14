import 'package:json_annotation/json_annotation.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'cycle_count_batch.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class Menu{
  Menu();

  String name;
  String link;
  String text;





  //不同的类使用不同的mixin即可
  factory Menu.fromJson(Map<String, dynamic> json) => _$MenuFromJson(json);
  Map<String, dynamic> toJson() => _$MenuToJson(this);


  static List<Menu> decodeMenus(List<dynamic> menus) =>
      menus
          .map<Menu>((item) => Menu.fromJson(item))
          .toList();


}