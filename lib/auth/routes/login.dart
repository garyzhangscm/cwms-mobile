import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/auth/services/login.dart';
import 'package:cwms_mobile/common/functions.dart';
import 'package:cwms_mobile/common/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget{

  LoginPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {

  TextEditingController _unameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  bool pwdShow = false;
  GlobalKey _formKey = new GlobalKey<FormState>();

  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    // check if auto login
    if (Global.autoLoginUser != null) {
      _processAutoLogin(Global.autoLoginUser);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.always, //开启自动校验
          child: Column(
            children: <Widget>[
              TextFormField(

                  controller: _unameController,
                  decoration: InputDecoration(
                    labelText: "username",
                    hintText: "please input username",
                    prefixIcon: Icon(Icons.person),
                  ),
                  // 校验用户名（不能为空）
                  validator: (v) {
                    return v.trim().isNotEmpty ? null : "username is required";
                  }),
              TextFormField(
                controller: _pwdController,
                decoration: InputDecoration(
                    labelText: "password",
                    hintText: "please input password",
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                          pwdShow ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          pwdShow = !pwdShow;
                        });
                      },
                    )),
                obscureText: !pwdShow,
                //校验密码（不能为空）
                validator: (v) {
                  return v.trim().isNotEmpty ? null : "password is required";
                },
              ),
              Row(
                  children: <Widget>[

                    Checkbox(
                      value: _rememberMe,
                      activeColor: Colors.blue, //选中时的颜色
                      onChanged:(value){
                        //重新构建页面
                        setState(() {
                          _rememberMe=value;
                        });
                      },

                    ),
                    Text("Remember Me"),

                  ]
              ),
              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child: RaisedButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: _onLogin,
                    textColor: Colors.white,
                    child: Text("login"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _processAutoLogin(User user) async{
    try {
      User autoLoginUser =
        await LoginService
            .login(user.username, user.password);

      Global.setCurrentUser(autoLoginUser);

      print("login with user: ${autoLoginUser.username}, token: ${autoLoginUser.token}");
      Navigator.pushNamed(context, "menus_page");
    } catch (e) {
      //登录失败则提示
      showToast(e.toString());
    }

  }
  void _onLogin() async {
    // 先验证各个表单字段是否合法
    if ((_formKey.currentState as FormState).validate()) {
      showLoading(context);
      User user;
      try {
        user = await LoginService
            .login(_unameController.text, _pwdController.text);


      } catch (e) {
        //登录失败则提示
          showToast(e.toString());
      } finally {
        // 隐藏loading框
        Navigator.of(context).pop();
      }
      if (user != null) {
        // 返回
        print("_rememberMe? $_rememberMe");
        if (_rememberMe) {
          user.password = _pwdController.text;
          Global.addAutoLoginUser(user);
        }
        Global.setCurrentUser(user);

        print("login with user: ${user.username}, token: ${user.token}");
        Navigator.pushNamed(context, "menus_page");
        // Navigator.of(context).pop();
      }
    }
  }
}