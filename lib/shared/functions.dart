import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import 'http_client.dart';

Widget gmAvatar(String url, {
  double width = 30,
  double height,
  BoxFit fit,
  BorderRadius borderRadius,
}) {
  var placeholder = Image.asset(
      "imgs/avatar-default.png", //头像默认值
      width: width,
      height: height
  );
  return ClipRRect(
    borderRadius: borderRadius ?? BorderRadius.circular(2),
    child: CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>placeholder,
      errorWidget: (context, url, error) =>placeholder,
    ),
  );
}

void showToast(String text, {
  gravity: ToastGravity.TOP,
  toastLength: Toast.LENGTH_SHORT,
}) {
  Fluttertoast.showToast(
    msg: text,
    toastLength: toastLength,
    gravity: gravity,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.grey[600],
    fontSize: 16.0,
  );
}

void showErrorToast(String text, {
  gravity: ToastGravity.TOP,
  toastLength: Toast.LENGTH_SHORT,
}) {
  Fluttertoast.showToast(
    msg: text,
    toastLength: toastLength,
    gravity: gravity,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.grey[600],
    textColor: Colors.red,
    fontSize: 16.0,
  );
}

void showLoading(context, [String text]) {
  text = text ?? "Loading...";
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return Center(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3.0),
                boxShadow: [
                  //阴影
                  BoxShadow(
                    color: Colors.black12,
                    //offset: Offset(2.0,2.0),
                    blurRadius: 10.0,
                  )
                ]),
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(16),
            constraints: BoxConstraints(minHeight: 120, minWidth: 180),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    text,
                    style: Theme
                        .of(context)
                        .textTheme.bodyText2,
                  ),
                ),
              ],
            ),
          ),
        );
      });
}

printLongLogMessage(String message) {

  int maxLogSize = 2000;
  for(int i = 0; i <= message.length / maxLogSize; i++) {
    int start = i * maxLogSize;
    int end = (i+1) * maxLogSize;
    end = end > message.length ? message.length : end;
    print("${DateTime.now().toString()} : ${message.substring(start, end)}");
  }
}

showErrorDialog(BuildContext context, String message) {

  // set up the button
  Widget okButton = FlatButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(CWMSLocalizations.of(context).error),
    content: Text(message),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

showBlockedErrorDialog(BuildContext context, String message) async {

  // set up the button
  Widget okButton = FlatButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(CWMSLocalizations.of(context).error),
    content: Text(message),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

showWarningDialog(BuildContext context, String message) {

  // set up the button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(CWMSLocalizations.of(context).warning),
    content: Text(message),
    actions: [
      okButton,
    ],
  );

  // show the dialog
   showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}


Future<bool>  showYesNoDialog(BuildContext context, String title, String message,
    Function yesOnPressed, Function noOnPressed) {

  Widget okButton = TextButton(
    child: Text(CWMSLocalizations.of(context).yes),
    onPressed: () {
      yesOnPressed();
      Navigator.of(context).pop();
    },
  );

  Widget cancelButton = TextButton(
    child: Text(CWMSLocalizations.of(context).cancel),
    onPressed: () {
      noOnPressed();
      Navigator.of(context).pop();
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      cancelButton,
      okButton,

    ],
  );

  // show the dialog
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

Future<bool>  showYesNoCancelDialog(BuildContext context, String title, String message,
    Function yesOnPressed, Function noOnPressed, Function cancelOnPressed) {

  Widget yesButton = TextButton(
    child: Text(CWMSLocalizations.of(context).yes),
    onPressed: () {
      yesOnPressed();
      Navigator.of(context).pop();
    },
  );
  Widget noButton = TextButton(
    child: Text(CWMSLocalizations.of(context).no),
    onPressed: () {
      noOnPressed();
      Navigator.of(context).pop();
    },
  );

  Widget cancelButton = TextButton(
    child: Text(CWMSLocalizations.of(context).cancel),
    onPressed: () {
      cancelOnPressed();
      Navigator.of(context).pop();
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      yesButton,
      noButton,
      cancelButton

    ],
  );

  // show the dialog
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

showInformationDialog(BuildContext context, String name, Widget content,
    {
        double verticalPadding = 0.0,
        double horizontalPadding = 0.0,
    }) {

  // set up the button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    insetPadding: EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    ),
    title: Text(name),
    content: content,
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;

    },
  );
}

Widget buildSingleButtonRow(BuildContext context, Widget button) {
  return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      //交叉轴的布局方式，对于column来说就是水平方向的布局方式
      crossAxisAlignment: CrossAxisAlignment.center,
      //就是字child的垂直布局方向，向上还是向下
      verticalDirection: VerticalDirection.down,
      children: [
        SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: button
        ),
      ]
  );
}

Widget buildTwoButtonRow(BuildContext context, Widget button1, Widget button2) {
  return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      //交叉轴的布局方式，对于column来说就是水平方向的布局方式
      crossAxisAlignment: CrossAxisAlignment.center,
      //就是字child的垂直布局方向，向上还是向下
      verticalDirection: VerticalDirection.down,
      children: [
        SizedBox(
            width: MediaQuery.of(context).size.width * 0.45,
            child: button1
        ),
        SizedBox(
            width: MediaQuery.of(context).size.width * 0.45,
            child: button2
        ),
      ]
  );
}


Widget buildThreeButtonRow(BuildContext context, Widget button1, Widget button2, Widget button3) {
  return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      //交叉轴的布局方式，对于column来说就是水平方向的布局方式
      crossAxisAlignment: CrossAxisAlignment.center,
      //就是字child的垂直布局方向，向上还是向下
      verticalDirection: VerticalDirection.down,
      children: [
        SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: button1
        ),
        SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: button2
        ),
        SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: button3
        ),
      ]
  );
}


Widget buildTwoSectionInformationRow(String name, String value) {
  return Padding(
    padding: EdgeInsets.only(top: 5, bottom: 5),
    child:
    Row(
        children: <Widget>[
          Padding(padding: EdgeInsets.only(right: 10),
            child: Text(name, textAlign: TextAlign.left),
          ),
          Text(value, textAlign: TextAlign.left),
        ]
    ),
  );
}

Widget buildTwoSectionInformationRowWithWidget(String name, Widget value) {
  return Padding(
    padding: EdgeInsets.only(top: 5, bottom: 5),
    child:
    Row(
        children: <Widget>[
          Padding(padding: EdgeInsets.only(right: 10),
            child: Text(name, textAlign: TextAlign.left),
          ),
          value
        ]
    ),
  );
}

Widget buildSingleSectionInformationRow(String name) {
  return Padding(
    padding: EdgeInsets.only(top: 5, bottom: 5),
    child:
    Row(
        children: <Widget>[
          Padding(padding: EdgeInsets.only(right: 10),
            child: Text(name, textAlign: TextAlign.left),
          )
        ]
    ),
  );
}

Widget buildFourSectionInformationRow(String name1, String value1, String name2, String value2) {
  return Padding(
    padding: EdgeInsets.only(top: 5, bottom: 5),
    child:
    Row(
        children: <Widget>[
          Padding(padding: EdgeInsets.only(right: 10),
            child: Text(name1, textAlign: TextAlign.left),
          ),
          Padding(padding: EdgeInsets.only(right: 30),
            child:
                Text(value1, textAlign: TextAlign.left),
          ),
          Padding(padding: EdgeInsets.only(right: 10),
            child: Text(name2, textAlign: TextAlign.left),
          ),
          Text(value2, textAlign: TextAlign.left),
        ]
    ),
  );
}

Widget buildSingleSectionInputRow(Widget inputController) {
  return Padding(
    padding: EdgeInsets.only(top: 5, bottom: 5),
    child:
    // confirm the location
    Row(
        children: <Widget>[
          Expanded(
              child: inputController
          )
        ]
    ),
  );
}

Widget buildTwoSectionInputRow(String name, Widget inputController, {bool expanded = true}) {
  return Padding(
    padding: EdgeInsets.only(top: 5, bottom: 5),
    child:
    // confirm the location
    Row(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Text(name, textAlign: TextAlign.left ),
          ),
          expanded ?
            Expanded(
                child: inputController
            )
              :
              inputController
        ]
    ),
  );
}

Widget buildThreeSectionInputRow(String name, Widget inputController1, Widget inputController2) {
  return Padding(
    padding: EdgeInsets.only(top: 5, bottom: 5),
    child:
    // confirm the location
    Row(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Text(name, textAlign: TextAlign.left ),
          ),
          Expanded(
              child: inputController1
          ),
          Expanded(
              child: inputController2
          )
        ]
    ),
  );
}

Widget buildFourSectionRow(Widget inputController1, Widget inputController2, Widget inputController3, Widget inputController4) {
  return Padding(
    padding: EdgeInsets.only(top: 5, bottom: 5),
    child:
    // confirm the location
    Row(
        children: <Widget>[
          inputController1,
          inputController2,
          inputController3,
          inputController4
        ]
    ),
  );
}

Future<String> uploadFile(XFile file, String url) async {
  Dio httpClient = CWMSHttpClient.getDio();
  var fileData = FormData.fromMap({
    'file':  await MultipartFile.fromFile(file.path,filename: file.name)
  });

  Response response = await httpClient.post(
      url,
      data:fileData);


  printLongLogMessage("response from uploadFile: $response");
  Map<String, dynamic> responseString = json.decode(response.toString());

  if (responseString["result"] as int != 0) {
    printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
    throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
  }

  printLongLogMessage("File ${file.path} uploaded! filepath: ${responseString["data"]}");
  return responseString["data"];
}