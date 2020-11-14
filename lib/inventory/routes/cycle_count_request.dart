import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/services/cycle_count_request.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CycleCountRequestPage extends StatefulWidget{

  CycleCountRequestPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _CycleCountRequestPageState();

}

class _CycleCountRequestPageState extends State<CycleCountRequestPage> {

  // input batch

  GlobalKey _formKey = new GlobalKey<FormState>();
  List<CycleCountResult> _cycleCountResults = [];



  @override
  Widget build(BuildContext context) {
    List<CycleCountResult> _cycleCountResults  = ModalRoute.of(context).settings.arguments;

    _cycleCountResults.forEach((element) {
      print("==> Will count: ${element.location.name}");
    });
    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Cycle Count")),
      body: SizedBox(
        //Material设计规范中状态栏、导航栏、ListTile高度分别为24、56、56
        height: MediaQuery.of(context).size.height-24-56-56,
        child: ListView.separated(
          itemCount: _cycleCountResults.length,
          itemBuilder: (context, index) {
            return ListTile(title: Text("item #"));
          },
          //分割器构造器
          separatorBuilder: (context, index) => Divider(height: .0),
        ),

      )
    );
  }

  
}