// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User()
    ..username = json['username'] == null ?
           (json['name'] == null ? '' : json['name'] as String)
           :
           json['username'] as String
    ..password = json['password'] as String
    ..companyId = json['companyId'] as int
    ..token = json['token'] as String;
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'companyId': instance.companyId,
      'token': instance.token,
    };
