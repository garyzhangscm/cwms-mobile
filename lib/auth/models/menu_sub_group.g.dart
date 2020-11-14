// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_sub_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuSubGroup _$MenuSubGroupFromJson(Map<String, dynamic> json) {
  return MenuSubGroup()
    ..name = json['name'] as String
    ..text = json['text'] as String
    ..icon = json['icon'] as String
    ..menus = (json['children'] as List)
        ?.map(
            (e) => e == null ? null : Menu.fromJson(e as Map<String, dynamic>))
        ?.toList();
}

Map<String, dynamic> _$MenuSubGroupToJson(MenuSubGroup instance) =>
    <String, dynamic>{
      'name': instance.name,
      'text': instance.text,
      'icon': instance.icon,
      'menus': instance.menus,
    };
