import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/audit_count_request.dart';
import 'package:cwms_mobile/inventory/models/audit_count_request_action.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_batch.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/services/audit_count_request.dart';
import 'package:cwms_mobile/inventory/services/cycle_count_batch.dart';
import 'package:cwms_mobile/inventory/services/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/widgets/count_batch_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class AuditCountBatchPage extends StatefulWidget{

  AuditCountBatchPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _AuditCountBatchPageState();

}

class _AuditCountBatchPageState extends State<AuditCountBatchPage> {

  // input batch id
  TextEditingController _batchIdController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();


  List<CycleCountBatch> _assignedBatches = [];

  // selected batches from the batch selection pop up
  List<CycleCountBatch> _selectedBatches = [];

  List<AuditCountRequest> _assignedAuditCountRequests = [];


  AuditCountRequest _currentAuditCountRequest;

  @override
  void initState() {
    super.initState();

    _assignedBatches = [];
    _selectedBatches = [];
    _assignedAuditCountRequests = [];

    _currentAuditCountRequest = null;


  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).auditCount)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[

              _buildBatchIdScanner(context),
              _buildButtons(context),
              _buildCountBatchList(context)
            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildBatchIdScanner(BuildContext context) {
    return TextFormField(
        controller: _batchIdController,
        decoration: InputDecoration(
          labelText: "batch ID",
          hintText: "please input batch id",
          suffixIcon:
          IconButton(
            onPressed: _startBarcodeScanner,
            icon: Icon(Icons.scanner),
          ),
        ),
        // 校验用户名（不能为空）
        validator: (v) {
          return v.trim().isNotEmpty ? null : "batch ID is required";
        });
  }

  Widget _buildButtons(BuildContext context) {

    return
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
              onPressed: _onAddingCountBatch,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).addCountBatch),
            ),

          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child:
            RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onChooseCountBatch,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).chooseCountBatch),
            ),

          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onStartingAuditCount,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).start),
            ),
          ),
        ],
      );
  }
  Widget _buildCountBatchList (BuildContext context){
    return
      Expanded(
        child: ListView.separated(
            separatorBuilder: (context, index) => Divider(
              color: Colors.black,
            ),
            itemCount: _assignedBatches.length,
            itemBuilder: (BuildContext context, int index) {

              return CountBatchListItem(
                  index: index,
                  countBatch: _assignedBatches[index],
                  cycleCountFlag: false,
                  auditCountFlag: true,
                  onRemove:  (index) =>  _removeCycleCountBatch(index)
              );
            }),
      );
  }

  void _removeCycleCountBatch(int index) {

    printLongLogMessage("will remove for cycle count batch: ${_assignedBatches[index].batchId}");
    setState(() {
      // remove the order from the user
      CycleCountBatch countBatch = _assignedBatches[index];
      _removeAuditCountRequests(countBatch);
      _assignedBatches.removeAt(index);
    });
  }
  void _removeAuditCountRequests(CycleCountBatch countBatch) {
    _assignedAuditCountRequests.removeWhere(
            (auditCountRequest) => auditCountRequest.batchId == countBatch.batchId);
  }

  _startBarcodeScanner() async {
/**
 *
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
    "#ff6666", "Cancel", true, ScanMode.BARCODE);
    printLongLogMessage("barcode scanned: $barcodeScanRes");
    _batchIdController.text = barcodeScanRes;
 * */

  }

  _onAddingCountBatch() async {

    // check if hte order is already in the list
    // if so, we won't bother refresh the list
    if (_batchIdController.text.isNotEmpty &&
        !_batchAlreadyInList(_batchIdController.text)) {

      CycleCountBatch cycleCountBatch  =
          await CycleCountBatchService.getCycleCountBatchByBatchId(
              _batchIdController.text);


      if (cycleCountBatch != null) {
        _assignBatchToUser(cycleCountBatch);

      }
    }
  }
  void _assignBatchToUser(CycleCountBatch cycleCountBatch) {
    // only continue if the order is not in the list yet


    if (!_batchAlreadyInList(cycleCountBatch.batchId)) {

      setState(() {
        _assignedBatches.add(cycleCountBatch);
        _assignAuditCountRequestToUser(cycleCountBatch);


      });
    }
  }

  void _assignAuditCountRequestToUser(CycleCountBatch cycleCountBatch) async {

    List<AuditCountRequest> auditCountRequests =
        await AuditCountRequestService.getOpenAuditCountRequestByBatchId(
            cycleCountBatch.batchId);
    _assignedAuditCountRequests.addAll(auditCountRequests);
  }

  bool _batchAlreadyInList(String batchId) {
    return
      _assignedBatches.indexWhere((element) => element.batchId == batchId) >= 0;
  }

  _onChooseCountBatch(){

    _selectedBatches = [];
    _showCountBatchesWithOpenAuditCount();
  }

  // prompt a dialog for user to choose valid orders
  Future<void> _showCountBatchesWithOpenAuditCount() async {

    showLoading(context);
    List<CycleCountBatch> countBatchesWithOpenAuditCount =
        await CycleCountBatchService.getCycleCountBatchesWithOpenAuditCount();

    // 隐藏loading框
    Navigator.of(context).pop();
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        var child = Column(
          children: <Widget>[
            Row(
              children: [
                FlatButton(
                  child: Text(CWMSLocalizations
                      .of(context)
                      .cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                FlatButton(
                  child: Text(CWMSLocalizations
                      .of(context)
                      .confirm),
                  onPressed: () {
                    _confirmBatchSelection();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            ListTile(title: Text(CWMSLocalizations
                .of(context)
                .chooseCountBatch)),
            _buildListWithOpenCountBatches(context, countBatchesWithOpenAuditCount)
          ],
        );
        //使用AlertDialog会报错
        //return AlertDialog(content: child);
        return Dialog(child: child);
      },
    );
  }

  Widget _buildListWithOpenCountBatches(BuildContext context,
      List<CycleCountBatch> countBatchesWithOpenAuditCount) {
    printLongLogMessage("start to _buildListWithOpenCountBatches with size: ${countBatchesWithOpenAuditCount.length}");
    return
      Expanded(
        child: ListView.builder(
            itemCount: countBatchesWithOpenAuditCount.length,
            itemBuilder: (BuildContext context, int index) {

              return CountBatchListItem(
                  index: index,
                  countBatch: countBatchesWithOpenAuditCount[index],
                  displayOnlyFlag: true,
                  cycleCountFlag: false,
                  auditCountFlag: true,
                  onRemove:  null,
                  onToggleHightlighted:  (selected) => _selectCountBatchFromList(selected, countBatchesWithOpenAuditCount[index])
              );
            }),
      );
  }
  void _selectCountBatchFromList(bool selected, CycleCountBatch cycleCountBatch) {
    // check if the order is already in the list
    int index = _selectedBatches.indexWhere(
            (element) => element.batchId == cycleCountBatch.batchId);
    if (selected && index < 0) {
      // the user select the order but it is not in the list yet
      // let's add it to the list
      _selectedBatches.add(cycleCountBatch);
    }
    else if (!selected && index >= 0) {
      // the user unselect the order and it is already in the list
      // let's remove it from the list
      _selectedBatches.removeAt(index);
    }
  }

  void _confirmBatchSelection() {
    // let's add assign the selected orders into current user
    _selectedBatches.forEach((cycleCountBatch) {
      _assignBatchToUser(cycleCountBatch);
    });

  }

  _onStartingAuditCount() async {
    // Get the first location from the batch that assigned to the current user
    // and start counting

    showLoading(context);
    AuditCountRequest nextAuditCountRequest = await _getNextLocationForAuditCount();
    if (nextAuditCountRequest == null) {
      // no more cycle count left
      // 隐藏loading框
      Navigator.of(context).pop();
      showToast(CWMSLocalizations.of(context).noMoreAuditCountInBatch);
      _refreshCycleCountBatchQuantities();
      return;
    }



    // 隐藏loading框
    Navigator.of(context).pop();

    final result = await Navigator.of(context)
        .pushNamed("audit_count_request", arguments: nextAuditCountRequest);
    if (result ==  null) {
      // the user press Return, let's do nothing
      _refreshCycleCountBatchQuantities();
      return null;
    }

    if ((result as AuditCountRequestAction) == AuditCountRequestAction.SKIPPED) {

      // if the user skip the current location, let's just add the count
      // and put it back to the list
      nextAuditCountRequest.skippedCount++;
    }
    else {
      // The user just finished the previous cycle count, let's continue with next one
      // let's remove the one we just finished from the batch first
      _assignedAuditCountRequests.removeWhere(
              (auditCountRequest) => auditCountRequest.id == nextAuditCountRequest.id);

    }


    // continue with next audit count in the list
    _onStartingAuditCount();

  }

  Future<void> _refreshCycleCountBatchQuantities() async {

    _assignedBatches.forEach((cycleCountBatch) {
      CycleCountBatchService.getCycleCountBatchByBatchId(
          cycleCountBatch.batchId
      ).then((newCycleCountBatch) {
        setState((){
          cycleCountBatch.openLocationCount = newCycleCountBatch.openLocationCount;
          cycleCountBatch.finishedLocationCount = newCycleCountBatch.finishedLocationCount;
          cycleCountBatch.cancelledLocationCount = newCycleCountBatch.cancelledLocationCount;
          cycleCountBatch.openAuditLocationCount = newCycleCountBatch.openAuditLocationCount;
          cycleCountBatch.finishedAuditLocationCount = newCycleCountBatch.finishedAuditLocationCount;
        });

      });

    });
  }

  Future<AuditCountRequest> _getNextLocationForAuditCount() async {
     printLongLogMessage("_assignedAuditCountRequests.isEmpty: ${_assignedAuditCountRequests.isEmpty}");
    if (_assignedAuditCountRequests.isEmpty) {
      // nothing has been assigned yet
      return null;
    }
    return AuditCountRequestService.getNextLocationForCount(_assignedAuditCountRequests);
  }


}