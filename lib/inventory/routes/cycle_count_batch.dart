import 'package:cwms_mobile/inventory/services/cycle_count_request.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class CycleCountBatchPage extends StatefulWidget{

  CycleCountBatchPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _CycleCountBatchPageState();

}

class _CycleCountBatchPageState extends State<CycleCountBatchPage> {

  // input batch id
  TextEditingController _batchIdController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Cycle Count")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.always, //开启自动校验
          child: Column(
            children: <Widget>[

              TextFormField(
                  controller: _batchIdController,
                  decoration: InputDecoration(
                    labelText: "batch ID",
                    hintText: "please input batch id",
                    suffixIcon: IconButton(
                      onPressed: () => _startBarcodeScanner(),
                      icon: Icon(Icons.scanner),
                    ),
                  ),
                  // 校验用户名（不能为空）
                  validator: (v) {
                    return v.trim().isNotEmpty ? null : "batch ID is required";
                  }),

              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child: RaisedButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: _onStartingBatch,
                    textColor: Colors.white,
                    child: Text("Start"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _onStartingBatch() {
    CycleCountRequestService.getCycleCountRequestByBatchId(_batchIdController.text)
        .then((cycleCountRequests) => {
          // get the first location and start count on the location
         if (cycleCountRequests.isNotEmpty) {
              CycleCountRequestService
                  .getInventorySummariesForCounts(cycleCountRequests[0].id)
                  .then((_cycleCountResults) => {
                      Navigator.of(context).pushNamed("cycle_cycle_request", arguments: _cycleCountResults)
                  })

         }
    });

  }
  _startBarcodeScanner(){}
}