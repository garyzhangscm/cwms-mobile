import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_request_action.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/services/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/widgets/count_result_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
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
  List<CycleCountResult> _inventorySummaries = [];

  CycleCountRequest _cycleCountRequest;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cycleCountRequest = ModalRoute.of(context).settings.arguments;

    CycleCountRequestService.getInventorySummariesForCounts(_cycleCountRequest.id)
        .then((inventorySummaries) {

      setState(() {

        _inventorySummaries = inventorySummaries;
        _inventorySummaries.forEach((inventorySummary) {
          if (inventorySummary.item == null) {
            inventorySummary.unexpectedItem = true;
          }
          else {
            inventorySummary.unexpectedItem = false;
          }
          inventorySummary.countQuantity = inventorySummary.quantity;
          // inventorySummary.location = _cycleCountRequest.location;
          // inventorySummary.locationId = _cycleCountRequest.location.id;
        });

      });
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Cycle Count - ${_cycleCountRequest?.location?.name}")),
      resizeToAvoidBottomInset: true,
      body: _buildInventorySummaryList(context),
      bottomNavigationBar:_buildBottomNavigationBar(context),
      floatingActionButton: FloatingActionButton( //悬浮按钮
          child: Icon(Icons.add),
            onPressed:_onAddItem
        ),
      endDrawer: MyDrawer(),
      );
  }


  Widget _buildBottomNavigationBar(BuildContext context) {

    return
      BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: CWMSLocalizations.of(context).confirmCycleCount),
          BottomNavigationBarItem(icon: Icon(Icons.next_plan), label: CWMSLocalizations.of(context).skipCycleCount),
          BottomNavigationBarItem(icon: Icon(Icons.cancel), label: CWMSLocalizations.of(context).cancelCycleCount),

        ],
        currentIndex: 0,
        fixedColor: Colors.blue,
        onTap: (index) => _onActionItemTapped(index),

      );

  }
  void _onActionItemTapped(int index) {
    if (index == 0) {
      _onConfirmCycleCount();
    }
    else if (index == 1) {
      _onSkipCycleCount();
    }
    else if (index == 2) {
      // index == 2
      _onCancelCycleCount();
    }
  }
  void _onAddItem() {
    CycleCountResult _newCycleCountResult = new CycleCountResult();
    _newCycleCountResult.batchId = _cycleCountRequest.batchId;
    _newCycleCountResult.location = _cycleCountRequest.location;
    _newCycleCountResult.locationId = _cycleCountRequest.location.id;
    _newCycleCountResult.warehouseId = Global.currentWarehouse.id;
    _newCycleCountResult.warehouse = Global.currentWarehouse;
    _newCycleCountResult.item = null;
    _newCycleCountResult.quantity = 0;
    _newCycleCountResult.countQuantity = 0;
    _newCycleCountResult.unexpectedItem = true;

    setState(() {

      _inventorySummaries.add(_newCycleCountResult);
    });
  }

  Widget _buildInventorySummaryList(BuildContext context) {
    // print("_buildInventorySummaryList: ${_inventorySummaries.length}");
    return
      Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
        child:
        ListView.separated(

      //分割器构造器
        separatorBuilder: (context, index) => Divider(height: .0),
        itemCount: _inventorySummaries.length,

        itemBuilder: (BuildContext context, int index) {
          return CountResultListItem(
              index: index,
              cycleCountResult: _inventorySummaries[index],
              onItemValueChange: (item) => _setupUnexpectedItem(index, item),
              onQuantityValueChange:  (newValue) {

                _inventorySummaries[index].countQuantity = int.parse(newValue);
              },
              onRemove: (index) => _removeInventorySummary(index),
          );
        })
      );

  }

  _removeInventorySummary(int index) {

    setState(() {

      _inventorySummaries.removeAt(index);
    });
  }
  _setupUnexpectedItem(int index, Item item) {
    // print("will change the item of index / $index to $item");
    printLongLogMessage("setup item ${item.name} for index: ${index}");
    setState(() {

      _inventorySummaries[index].item = item;
    });
  }
  void _onConfirmCycleCount() async {
    // since the user is able to confirm the cycle count, let's assume the user is
    // already in the location
    Global.setLastActivityLocation(_cycleCountRequest.location);

    FormState formState = _formKey.currentState as FormState;

    if (!formState.validate()) {
      // validation fail
      return;
    }

    showLoading(context);
    _inventorySummaries.removeWhere((inventorySummary) =>
        inventorySummary.item == null
    );


    await CycleCountRequestService.confirmCycleCount(_cycleCountRequest, _inventorySummaries);

    // hide the loading page
    Navigator.of(context).pop();

    //return true to the previous page

    Navigator.pop(context, CycleCountRequestAction.CONFIRMED);
  }

  void _onSkipCycleCount() {

    // since the user is able to skip the cycle count, let's assume the user is
    // already in the location

    // Note: we can't set the last activity location to the current location.
    // otherwise we won't be able to go back to the previous locaiton if we
    // skip all locations in the batch
    // Global.setLastActivityLocation(_cycleCountRequest.location);

    // do nothing but return true to the previous page
    // The previous page is supposed to remove the request
    // from current assignment but since it is not finished yet
    // it will be pickup by the next count attempt
    Navigator.pop(context, CycleCountRequestAction.SKIPPED);
  }

  void _onCancelCycleCount() async {

    showLoading(context);
    // since the user is able to cancel the cycle count, let's assume the user is
    // already in the location
    Global.setLastActivityLocation(_cycleCountRequest.location);


    await CycleCountRequestService.cancelCycleCount(_cycleCountRequest);
    //return true to the previous page

    // hide the loading page
    Navigator.of(context).pop();

    Navigator.pop(context, CycleCountRequestAction.CANCELLED);

  }
}