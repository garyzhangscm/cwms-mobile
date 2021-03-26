// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_response_wrapper.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HttpResponseWrapper _$HttpResponseWrapperFromJson(Map<String, dynamic> json) {
  return HttpResponseWrapper(
    result: json['result'] as int,
    message: json['message'] as String,
    data: json['data'] as Map<String, dynamic>,
  );
}

Map<String, dynamic> _$HttpResponseWrapperToJson(
        HttpResponseWrapper instance) =>
    <String, dynamic>{
      'result': instance.result,
      'message': instance.message,
      'data': instance.data,
    };
