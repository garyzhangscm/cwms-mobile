
import 'dart:collection';
import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/item.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/order.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/outbound/widgets/order_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/bottom_navigation_bar.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material.dart';
import 'package:cwms_mobile/workorder/models/material-consume-timing.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_result.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_rule_configuration.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_sample.dart';
import 'package:cwms_mobile/workorder/services/bill_of_material.dart';
import 'package:cwms_mobile/workorder/services/production_line.dart';
import 'package:cwms_mobile/workorder/services/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/services/work_order.dart';
import 'package:cwms_mobile/workorder/services/work_order_qc.dart';
import 'package:cwms_mobile/workorder/widgets/work_order_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:badges/badges.dart';


class WorkOrderQCPage extends StatefulWidget{

  WorkOrderQCPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _WorkOrderQCPageState();

}

class _WorkOrderQCPageState extends State<WorkOrderQCPage> {

  // input batch id
  TextEditingController _workOrderQCSampleNumberController = new TextEditingController();
  String _workOrderQCSampleNumber;
  String _workOrderNumber;
  String _productionLineName;
  String _itemName;
  String _itemDescription;
  WorkOrderQCSample _workOrderQCSample;
  final CarouselController _controller = CarouselController();

  bool _readyForQCResult = false;


  GlobalKey _formKey = new GlobalKey<FormState>();
  FocusNode _workOrderQCSampleNumberFocusNode = FocusNode();
  FocusNode _startQCButtonFocusNode = FocusNode();


  @override
  void initState() {
    super.initState();
    _workOrderQCSampleNumber = "";
    _workOrderNumber = "";
    _productionLineName = "";
    _itemName = "";
    _itemDescription = "";
    _readyForQCResult = false;

    _workOrderQCSampleNumberFocusNode.addListener(() {
      if (!_workOrderQCSampleNumberFocusNode.hasFocus && _workOrderQCSampleNumberController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _onWorkOrderQCSampleNumberScanned();

      }
    });

    _workOrderQCSampleNumberController.clear();
    _workOrderQCSampleNumberFocusNode.requestFocus();

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).workOrderQC)),
      resizeToAvoidBottomInset: true,
      body:
          Column(
            children: [
              _buildWorkOrderQCNumberAndProductionLineScanner(context),
              _buildButtons(context),
              buildTwoSectionInformationRow(CWMSLocalizations.of(context).workOrderQCSampleNumber, _workOrderQCSampleNumber),
              buildTwoSectionInformationRow(CWMSLocalizations.of(context).workOrderNumber, _workOrderNumber),
              buildTwoSectionInformationRow(CWMSLocalizations.of(context).productionLine, _productionLineName),
              buildTwoSectionInformationRow(CWMSLocalizations.of(context).item, _itemName),
              buildTwoSectionInformationRow(CWMSLocalizations.of(context).item, _itemDescription),
              _buildQCImages(),
              _buildQCResultButtons(context),
            ],
          ),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildWorkOrderQCNumberAndProductionLineScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _formKey,
              // autovalidateMode: AutovalidateMode.always, //开启自动校验
              child: Column(
                  children: <Widget>[
                    TextFormField(
                      textInputAction: TextInputAction.next,
                      controller: _workOrderQCSampleNumberController,
                      autofocus: true,
                      focusNode: _workOrderQCSampleNumberFocusNode,
                      decoration: InputDecoration(
                        labelText: CWMSLocalizations
                            .of(context)
                            .workOrderQCSampleNumber,
                      ),
                    ),

                  ]
              )
          )
      );
  }


  Widget _buildButtons(BuildContext context) {

    return
    // confirm input and clear input
      buildTwoButtonRow(context,
        ElevatedButton(
            onPressed: _onWorkOrderQCSampleNumberScanned,
            child: Text(CWMSLocalizations.of(context).confirm)
        ),
        ElevatedButton(
            onPressed: _onClear,
            child: Text(CWMSLocalizations.of(context).clear)
        ),

      ) ;
  }

  Widget _buildQCResultButtons(BuildContext context) {

    return
      // confirm input and clear input
      buildSingleButtonRow(context,
        ElevatedButton(
            focusNode: _startQCButtonFocusNode,
            onPressed:
                _readyForQCResult ? _onStartQC : null,
            child: Text(CWMSLocalizations.of(context).startQC)
        ),
      ) ;
  }

  List<String> _getQCSampleImageUrls() {

    if (_workOrderQCSample == null ||
        _workOrderQCSample.imageUrls.isEmpty) {
      return [];
    }
    return _workOrderQCSample.imageUrls.split(",");

  }
  List<Widget> _getQCSampleImages() {

    return
      _getQCSampleImageUrls()
        .map((imageUrl) =>
            Container(
                child: Container(
                  margin: EdgeInsets.all(5.0),
                  child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      child: Stack(
                        children: <Widget>[
                          Image.network(
                             Global.currentServer.url + "/qc-samples/images/${Global.currentWarehouse.id}/${_workOrderQCSample.productionLineAssignment.id}/${imageUrl}",
                             fit: BoxFit.cover,
                             width: 1000.0,
                              headers: {
                                HttpHeaders.authorizationHeader: "Bearer ${Global.currentUser.token}",
                                "rfCode": Global.lastLoginRFCode,
                                "warehouseId": Global.currentWarehouse.id.toString(),
                                "companyId": Global.lastLoginCompanyId.toString()
                              }),
                          Positioned(
                            bottom: 0.0,
                            left: 0.0,
                            right: 0.0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromARGB(200, 0, 0, 0),
                                    Color.fromARGB(0, 0, 0, 0)
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 20.0),
                              child: Text(
                                'No. ${imageUrl} image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),
          ),
        )).toList();
  }
  Widget _buildQCImages() {

    if (_getQCSampleImages().isEmpty) {
      return Container();
    }
    return CarouselSlider(
      options: CarouselOptions(enableInfiniteScroll: false),
      items: _getQCSampleImageUrls()
          .map((imageUrl) => Container(
                child: Center(
                    child:
                    Image.network(
                        Global.currentServer.url + "workorder/qc-samples/images/${Global.currentWarehouse.id}/${_workOrderQCSample.productionLineAssignment.id}/${imageUrl}",
                        fit: BoxFit.cover, width: 1000,
                        headers: {
                          HttpHeaders.authorizationHeader: "Bearer ${Global.currentUser.token}",
                          "rfCode": Global.lastLoginRFCode,
                          "warehouseId": Global.currentWarehouse.id.toString(),
                          "companyId": Global.lastLoginCompanyId.toString()
                        })),
              ))
          .toList(),
    );

  }

  _onWorkOrderQCSampleNumberScanned() async {

    String workOrderQCSampleNumber = _workOrderQCSampleNumberController.text;
    if (workOrderQCSampleNumber.isNotEmpty) {
      showLoading(context);
      _workOrderQCSample = await WorkOrderQCService.getWorkOrderQCSampleByNumber(workOrderQCSampleNumber);


      if (_workOrderQCSample == null) {
          clearDisplay();
          Navigator.of(context).pop();
          showErrorDialog(context, CWMSLocalizations.of(context).noQCSampleExists);
          return;
      }

      if (_workOrderQCSample.productionLineAssignment.workOrder == null &&
          _workOrderQCSample.productionLineAssignment.workOrderId != null) {

          _workOrderQCSample.productionLineAssignment.workOrder =
              await WorkOrderService.getWorkOrderById(_workOrderQCSample.productionLineAssignment.workOrderId);


      }
      if (_workOrderQCSample.productionLineAssignment.workOrder.item == null &&
          _workOrderQCSample.productionLineAssignment.workOrder.itemId != null) {

          _workOrderQCSample.productionLineAssignment.workOrder.item =
                await ItemService.getItemById(_workOrderQCSample.productionLineAssignment.workOrder.itemId);
      }



      setupDisplay(_workOrderQCSample);
      // 隐藏loading框
      Navigator.of(context).pop();

        // once we get the sample information, move the cursor to the start qc button
      _startQCButtonFocusNode.requestFocus();

    }

  }

  clearDisplay() {


    setState(() {

      _workOrderQCSampleNumber = "";
      _workOrderNumber = "";
      _productionLineName = "";
      _itemName = "";
      _itemDescription ="";
      _readyForQCResult = false;

      _workOrderQCSampleNumberController.clear();
      // _workOrderQCSampleNumberFocusNode.requestFocus();
    });
  }
  setupDisplay(WorkOrderQCSample workOrderQCSample) {


    setState(() {

      _workOrderQCSampleNumber = workOrderQCSample.number;
      _workOrderNumber = workOrderQCSample.productionLineAssignment.workOrder.number;
      _productionLineName = workOrderQCSample.productionLineAssignment.productionLine.name;


      _itemName = workOrderQCSample.productionLineAssignment.workOrder.item.name;
      _itemDescription = workOrderQCSample.productionLineAssignment.workOrder.item.description;
      _readyForQCResult = true;

      _workOrderQCSampleNumberController.clear();
      // _workOrderQCSampleNumberFocusNode.requestFocus();
    });
  }

  _onClear() {

    setState(() {

      _workOrderQCSampleNumber = "";
      _workOrderNumber = "";
      _productionLineName = "";
      _itemName = "";
      _itemDescription = "";
      _readyForQCResult = false;
      _workOrderQCSample = null;

      _workOrderQCSampleNumberController.clear();
      _workOrderQCSampleNumberFocusNode.requestFocus();
    });
  }


  _onWorkOrderQCPass() {
    showLoading(context);
    try {

      WorkOrderQCService.recordWorkOrderQCResult(_getWorkOrderQCResult(true))
          .then((workOrderQCResult) {
        // 隐藏loading框
        Navigator.of(context).pop();
        _onClear();
        showToast(CWMSLocalizations.of(context).qcCompleted);

      });
    }
    on WebAPICallException catch(ex) {


      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

  }
  _onWorkOrderQCFail() {
    showLoading(context);
    WorkOrderQCService.recordWorkOrderQCResult(_getWorkOrderQCResult(false))
        .then((workOrderQCResult) {
      // 隐藏loading框
      Navigator.of(context).pop();
      _onClear();
      showToast(CWMSLocalizations.of(context).qcCompleted);

    });

  }

  _onStartQC() async {
    // get the qc inspection request from the qc sample and
    // flow to the QC inspection page

    showLoading(context);
    try {

      List<WorkOrderQCRuleConfiguration> matchedWorkOrderQCRuleConfiguration
          = await WorkOrderQCService.getMatchedWorkOrderQCRuleConfiguration(_workOrderQCSample.id);

      if (matchedWorkOrderQCRuleConfiguration.length == 0) {
          // no matched work order qc rule configuration
          Navigator.of(context).pop();
          showToast(CWMSLocalizations.of(context).workOrderNoQCConfig);
          return;
      }
      // ok, we get qc rules defined for this qc samples. let's generate the
      // inspection request and flow to the qc inspection form
      String ruleIds =
          matchedWorkOrderQCRuleConfiguration.expand((e) => e.workOrderQCRuleConfigurationRules)
              .map((e) => e.qcRuleId).join(",");

      // get the quantity we needs to QC for the work order, based on the configuration.
      // if we have multiple matched configuration, then get the max number
      int qcQuantity = matchedWorkOrderQCRuleConfiguration.map((e) => e.qcQuantity).reduce(max);
      printLongLogMessage("1. we will start  qc request with quantity ${qcQuantity}");

      QCInspectionRequest qcInspectionRequest =
          await WorkOrderQCService.getWorkOrderQCInspectionRequest(_workOrderQCSample.id, ruleIds, qcQuantity);
      printLongLogMessage("we will qc quantity ${qcInspectionRequest.qcQuantity}");

      Navigator.of(context).pop();

      Navigator.of(context).pushNamed("qc_inspection", arguments: qcInspectionRequest);

    }
    on WebAPICallException catch(ex) {

      printLongLogMessage("error while starting qc for work order");

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

  }
  WorkOrderQCResult _getWorkOrderQCResult(bool qcPassed) {
    WorkOrderQCResult workOrderQCResult = new WorkOrderQCResult();
    workOrderQCResult.warehouseId = Global.currentWarehouse.id;
    workOrderQCResult.workOrderQCSample = _workOrderQCSample;
    workOrderQCResult.qcInspectionResult =
        qcPassed ? QCInspectionResult.PASS : QCInspectionResult.FAIL;
    workOrderQCResult.qcRFCode = Global.lastLoginRFCode;
    return workOrderQCResult;


  }





}
