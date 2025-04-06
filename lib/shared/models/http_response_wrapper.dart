import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

// server.g.dart 将在我们运行生成命令后自动生成
part 'http_response_wrapper.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class HttpResponseWrapper {


  int? result ;

  String? message;

  Map<String, dynamic>? data ;

  HttpResponseWrapper({this.result, this.message, this.data});

  //不同的类使用不同的mixin即可
  factory HttpResponseWrapper.fromJson(Map<String, dynamic> json) {
    return HttpResponseWrapper(
      result: json['result'],
      message: json['message'],
      data: json['data'],
    );
  }



  Map<String, dynamic> toJson() => _$HttpResponseWrapperToJson(this);


}
