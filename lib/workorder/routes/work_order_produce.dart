
import 'dart:collection';
import 'dart:core';

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/order.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/outbound/widgets/order_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/bottom_navigation_bar.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:cwms_mobile/workorder/services/production_line.dart';
import 'package:cwms_mobile/workorder/services/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/services/work_order.dart';
import 'package:cwms_mobile/workorder/widgets/work_order_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:badges/badges.dart';


class WorkOrderProducePage extends StatefulWidget{

  WorkOrderProducePage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _WorkOrderProducePageState();

}

class _WorkOrderProducePageState extends State<WorkOrderProducePage> {

  // input batch id
  TextEditingController _workOrderNumberController = new TextEditingController();

  TextEditingController _productionLineNameController = new TextEditingController();

  GlobalKey _formKey = new GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).pickByOrder)),
      body:
          Column(
            children: [
              _buildWorkOrderNumberAndProductionLineScanner(context),
              _buildButtons(context)
            ],
          ),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }

  // scan in barcode to add a order into current batch
  Widget _buildWorkOrderNumberAndProductionLineScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _formKey,
              // autovalidateMode: AutovalidateMode.always, //开启自动校验
              child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _workOrderNumberController,
                      decoration: InputDecoration(
                        labelText: CWMSLocalizations
                            .of(context)
                            .workOrderNumber,
                        hintText: CWMSLocalizations
                            .of(context)
                            .inputWorkOrderNumberHint,
                        suffixIcon: IconButton(
                          onPressed: () => _startBarcodeScanner(),
                          icon: Icon(Icons.scanner),
                        ),
                      ),
                    ),

                    TextFormField(
                      controller: _productionLineNameController,
                      decoration: InputDecoration(
                        labelText: CWMSLocalizations
                            .of(context)
                            .productionLine,
                        hintText: CWMSLocalizations
                            .of(context)
                            .inputProductionLineHint,
                        suffixIcon: IconButton(
                          onPressed: () => _startBarcodeScanner(),
                          icon: Icon(Icons.scanner),
                        ),
                      ),
                    ),
                  ]
              )
          )
      );
  }


  Widget _buildButtons(BuildContext context) {

    return
      SizedBox(
        width: double.infinity,
        child:
          RaisedButton(
            color: Theme.of(context).primaryColor,
            onPressed: _onStartProduce,
            textColor: Colors.white,
            child: Text(CWMSLocalizations.of(context).workOrderProduce),
          )
        );
    /***
      Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        //交叉轴的布局方式，对于column来说就是水平方向的布局方式
        crossAxisAlignment: CrossAxisAlignment.center,
        //就是字child的垂直布局方向，向上还是向下
        verticalDirection: VerticalDirection.down,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child:
            RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onStartProduce,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).workOrderProduce),
            ),

          ),

        ],
    );
        **/
  }

  Future<void> _onStartProduce() async {

    showLoading(context);
    if (_productionLineNameController.text.isNotEmpty) {

      // Let's get the work order that assigned to the production line
      // TO-DO: Now we assume there's only one open work order that assign
      // to the production line at a time
      printLongLogMessage("start to get production line by ${_productionLineNameController.text}");
      ProductionLine productionLine =
          await ProductionLineService.getProductionLineByNumber(_productionLineNameController.text);
      printLongLogMessage("get production line: ${productionLine.name}");

      List<WorkOrder> workOrders =
          await ProductionLineAssignmentService.getAssignedWorkOrderByProductionLine(productionLine);

      printLongLogMessage("get ${workOrders.length} work order that assigned to this production line");

      // hide the loading indicator
      Navigator.of(context).pop();

      Map argumentMap = new HashMap();
      argumentMap['workOrder'] = workOrders[0];
      argumentMap['productionLine'] = productionLine;



      await Navigator.of(context).pushNamed("work_order_produce_inventory", arguments: argumentMap);

    }
  }





  Future<void> _startBarcodeScanner() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    _workOrderNumberController.text = barcodeScanRes;

  }





}