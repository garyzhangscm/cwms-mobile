// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User()
    ..username = json['username'] ?? (json['name'] ?? "")
    ..password = json['password'] ?? ""
    ..firstname = json['firstname'] ?? ""
    ..lastname = json['lastname'] ?? ""
    ..companyId = json['companyId'] ?? null
    ..token = json['token'] ?? ""
    ..refreshToken = json['refreshToken'] ?? "";
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
