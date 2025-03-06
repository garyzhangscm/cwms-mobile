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
    ..firstname = json['firstname'] as String
    ..lastname = json['lastname'] as String
    ..companyId = json['companyId'] as int
    ..token = json['token'] as String
    ..refreshToken = json['refreshToken'] as String;
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
  'firstname': instance.firstname,
  'lastname': instance.lastname,
      'companyId': instance.companyId,
      'token': instance.token,
  'refreshToken': instance.refreshToken,
    };
