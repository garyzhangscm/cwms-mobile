

class LoginResponseWrapper {


  int? result ;

  String? message;

  Map<String, dynamic>? user ;

  LoginResponseWrapper({this.result, this.message, this.user});

  //不同的类使用不同的mixin即可
  factory LoginResponseWrapper.fromJson(Map<String, dynamic> json) {
    return LoginResponseWrapper(
      result: json['result'],
      message: json['message'],
      user: json['user'],
    );
  }




}
