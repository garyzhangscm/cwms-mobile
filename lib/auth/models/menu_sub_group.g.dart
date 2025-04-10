// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_sub_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuSubGroup _$MenuSubGroupFromJson(Map<String, dynamic> json) {
  return MenuSubGroup()
    ..name = json['name']
    ..text = json['text']
    ..icon = json['icon']
    ..i18n = json['i18n']
    ..link = json['link']
    ..menus = json['children'] == null ?
        [] :
        (json['children'] as List)
        .map(
            (e) => Menu.fromJson(e as Map<String, dynamic>))
        .toList();
}

Map<String, dynamic> _$MenuSubGroupToJson(MenuSubGroup instance) =>
    <String, dynamic>{
      'name': instance.name,
      'text': instance.text,
      'icon': instance.icon,
      'i18n': instance.i18n,
      'link': instance.link,
      'menus': instance.menus,
    };
