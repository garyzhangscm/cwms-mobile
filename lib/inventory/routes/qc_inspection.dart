import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/qc_inspection.dart';
import 'package:cwms_mobile/inventory/widgets/inventory_deposit_request_item.dart';
import 'package:cwms_mobile/inventory/widgets/qc_inspection_item_option_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/qc_inspection_request_item.dart';
import '../models/qc_inspection_request_item_option.dart';
import '../models/qc_rule_item_type.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class QCInspectionPage extends StatefulWidget{

  QCInspectionPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _QCInspectionPageState();

}

class _QCInspectionPageState extends State<QCInspectionPage> {

  int _qcInspectionRequestItemIndex;
  QCInspectionRequest _qcInspectionRequest;
  TextEditingController _qcQuantityController = new TextEditingController();
  final  _formKey = GlobalKey<FormState>();

  // map to store the value for each option
  // so that when we refresh the screen, we can still keep the value
  Map valueMap = new Map();

  @override
  void initState() {
    super.initState();
    _qcInspectionRequestItemIndex = 0;
    _qcQuantityController.clear();

    valueMap.clear();
  }



  @override
  Widget build(BuildContext context) {

    _qcInspectionRequest  = ModalRoute.of(context).settings.arguments;
    _qcQuantityController.text = _qcInspectionRequest.qcQuantity.toString();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text("CWMS - QC")),

      body:
        Padding(padding: EdgeInsets.all(10),
          child:
            Column(
                children: [
                  // for work order qc, we will show the input to let the user input the qc quantity
                  _qcInspectionRequest.workOrderQCSampleId == null ?
                  Container() :
                  _buildQCQuantity(context),
                  _buildQCItemName(context),
                  _buildQCItemOptionList(context),
                  _buildQCResultButtons(context),
                ]),
        ),

      endDrawer: MyDrawer(),
    );
  }

  Widget _buildQCQuantity(BuildContext context) {
    return
          buildTwoSectionInputRow(CWMSLocalizations.of(context).qcQuantity,
          TextFormField(
              controller: _qcQuantityController,
              keyboardType: TextInputType.number,
              onChanged: (text) {
                _qcInspectionRequest.qcQuantity = int.parse(text);
              },

          ));
  }

  Widget _buildQCItemName(BuildContext context) {
    return
      Row(
          children: <Widget>[
            Text(_qcInspectionRequest.qcInspectionRequestItems[_qcInspectionRequestItemIndex].qcRule.name,
                textAlign: TextAlign.left,
                 style: Theme.of(context).textTheme.headline5,
            ),
          ]
      );
  }

  Widget _buildQCItemOptionList(BuildContext context) {

    List<QCInspectionRequestItemOption> enabledQCInspectionRequestItemOptions =
        getEnabledQCItemOptions(_qcInspectionRequest.qcInspectionRequestItems[_qcInspectionRequestItemIndex]);

    return
      Expanded(
          child: Stack(
            children: [
              Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 100),
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: enabledQCInspectionRequestItemOptions.length,
                    itemBuilder: (context, index) {
                      return QCInspectionItemOptionListItem(
                          qcInspectionRequestItemOption: enabledQCInspectionRequestItemOptions[index],
                          value: _getOptionValue(enabledQCInspectionRequestItemOptions[index])

                      );
                    }),
              )
            ],
          ));
  }

  Object _getOptionValue(QCInspectionRequestItemOption option) {
    switch(option.qcRuleItem.qcRuleItemType) {
      case QCRuleItemType.NUMBER:
        return option.doubleValue;
        break;
      case QCRuleItemType.STRING:
        return option.stringValue;
        break;

      default:
        return option.booleanValue;

    }
  }

  List<QCInspectionRequestItemOption> getEnabledQCItemOptions(QCInspectionRequestItem qcItem) {
    return qcItem.qcInspectionRequestItemOptions.where((option) => option.qcRuleItem.enabled
    ).toList();
  }



  Widget _buildQCResultButtons(BuildContext context) {
    return
      // confirm input and clear input
      buildTwoButtonRow(context,
        _qcInspectionRequestItemIndex < _qcInspectionRequest.qcInspectionRequestItems.length - 1 ?
            _buildNextQCInspectionRequestItemButton(context) :
            _buildComfirmButton(context),
        ElevatedButton(
            onPressed: _onCancel,
            child: Text(CWMSLocalizations.of(context).cancel)
        ),

      ) ;
  }

  Widget _buildNextQCInspectionRequestItemButton(BuildContext context) {

    return
        ElevatedButton(
            onPressed: _onNextQCInspectionRequestItem,
            child: Text(CWMSLocalizations.of(context).nextQCRule)
        );
  }
  Widget _buildComfirmButton(BuildContext context) {

    return
      ElevatedButton(
          onPressed: _onConfirm,
          child: Text(CWMSLocalizations.of(context).confirm)
      );

  }
  Future<void> _onConfirm() async {

    showLoading(context);
    try {

      await QCInspectionService.saveQCInspectionRequest([_getQCInspectionResult(_qcInspectionRequest)]);

      // flow to the previous page after we saved the result

      Navigator.of(context).pop();
      showToast(CWMSLocalizations.of(context).qcCompleted);
      Navigator.of(context).pop();
    }
    on WebAPICallException catch(ex) {


      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }
  }

  /// Calculate the result based on the user's input
  QCInspectionRequest _getQCInspectionResult(QCInspectionRequest qcInspectionRequest) {

    int passedQCInspectionRequestItem = 0;
    int failedQCInspectionRequestItem = 0;
    int pendingQCInspectionRequestItem = 0;

    qcInspectionRequest.qcInspectionRequestItems.forEach((qcInspectionRequestItem) {

      int passedQCInspectionRequestItemOption = 0;
      int failedQCInspectionRequestItemOption = 0;
      int pendingQCInspectionRequestItemOption = 0;
      qcInspectionRequestItem.qcInspectionRequestItemOptions.forEach((qcInspectionRequestItemOption) {
          if (!qcInspectionRequestItemOption.qcRuleItem.enabled) {
            // if the item is disabled, then the user won't need to do QC on the item
            // it is a pass by default
            qcInspectionRequestItemOption.qcInspectionResult = QCInspectionResult.PASS;
            passedQCInspectionRequestItemOption++;
          }
          if (qcInspectionRequestItemOption.qcInspectionResult == QCInspectionResult.PENDING) {
            pendingQCInspectionRequestItemOption++;
          }
          else if (qcInspectionRequestItemOption.qcInspectionResult == QCInspectionResult.FAIL) {
            failedQCInspectionRequestItemOption++;
          }
          else if (qcInspectionRequestItemOption.qcInspectionResult == QCInspectionResult.PASS) {
            passedQCInspectionRequestItemOption++;
          }
      });
      if (failedQCInspectionRequestItemOption > 0) {
        // we have at least one failed inspection, then the whole item is fail
        qcInspectionRequestItem.qcInspectionResult = QCInspectionResult.FAIL;
        failedQCInspectionRequestItem++;
      }
      else if (passedQCInspectionRequestItemOption == 0) {
        // the user hasn't changed anything, then this request item is still PENDING
        qcInspectionRequestItem.qcInspectionResult = QCInspectionResult.PENDING;
        pendingQCInspectionRequestItem++;
      }
      else if (pendingQCInspectionRequestItemOption > 0){
        // in here, we know we have the pending and passed qc items
        // but no fail inspection , the overall result is still fail
        qcInspectionRequestItem.qcInspectionResult = QCInspectionResult.FAIL;
        failedQCInspectionRequestItem++;
      }
      else {
        // in here, we know we don't have pending or failed items
        // it is a pass
        qcInspectionRequestItem.qcInspectionResult = QCInspectionResult.PASS;
        passedQCInspectionRequestItem++;
      }
    });

    if (failedQCInspectionRequestItem > 0) {
      // we have at least one failed inspection, then the whole item is fail
      qcInspectionRequest.qcInspectionResult = QCInspectionResult.FAIL;
    }
    else if (passedQCInspectionRequestItem == 0) {
      // the user hasn't changed anything, then this request item is still PENDING
      qcInspectionRequest.qcInspectionResult = QCInspectionResult.PENDING;
    }
    else if (pendingQCInspectionRequestItem > 0){
      // in here, we know we have the pending and passed qc items
      // but no fail inspection , the overall result is still fail
      qcInspectionRequest.qcInspectionResult = QCInspectionResult.FAIL;
    }
    else {
      // in here, we know we don't have pending or failed items
      // it is a pass
      qcInspectionRequest.qcInspectionResult = QCInspectionResult.PASS;
    }
    return qcInspectionRequest;

  }
  void _onNextQCInspectionRequestItem() {
    setState(() {
      _qcInspectionRequestItemIndex++;
    });
  }
  void _onCancel() {

    // return to the previous page
    Navigator.of(context).pop();
  }

}