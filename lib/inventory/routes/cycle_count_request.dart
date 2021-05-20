import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/services/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/widgets/count_request_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
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
    // print("_CycleCountRequestPageState / didChangeDependencies / 1");
    super.didChangeDependencies();
    // print("_CycleCountRequestPageState / didChangeDependencies / 2");
    _cycleCountRequest = ModalRoute.of(context).settings.arguments;
    // print("_CycleCountRequestPageState / didChangeDependencies / 3");

    CycleCountRequestService.getInventorySummariesForCounts(_cycleCountRequest.id)
        .then((inventorySummaries) {
      // print("_CycleCountRequestPageState / didChangeDependencies / 4");

      setState(() {

        // print("_CycleCountRequestPageState / didChangeDependencies / 5");
        _inventorySummaries = inventorySummaries;
        // print("_inventorySummaries: ${_inventorySummaries.toString()}");
        // print("_CycleCountRequestPageState / didChangeDependencies / 6");
        _inventorySummaries.forEach((inventorySummary) => inventorySummary.countQuantity = inventorySummary.quantity);

        // print("_CycleCountRequestPageState / didChangeDependencies / 7");
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    // print("_CycleCountRequestPageState / rebuild!");
    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Cycle Count - ${_cycleCountRequest?.location?.name}")),
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
              onPressed: _onConfirmCycleCount,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).confirmCycleCount),
            ),

          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child:
            RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onSkipCycleCount,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).skipCycleCount),
            ),

          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onCancelCycleCount,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).cancelCycleCount),
            ),
          ),
        ],
      );
          **/
  }
  void _onActionItemTapped(int index) {
    if (index == 0) {
      _onConfirmCycleCount();
    }
    else if (index == 1) {
      _onSkipCycleCount();
    }
    else if (index == 1) {
      // index == 2
      _onCancelCycleCount();
    }
  }
  void _onAddItem() {

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
          return CountRequestListItem(
              index: index,
              cycleCountResult: _inventorySummaries[index],
              onItemValueChange: (item) => _setupUnexpectedItem(index, item),
              onQuantityValueChange:  (newValue) => _inventorySummaries[index].countQuantity = int.parse(newValue)
          );
        })
      );

  }

  _setupUnexpectedItem(int index, Item item) {
    // print("will change the item of index / $index to $item");
  }
  void _onConfirmCycleCount() async {
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

    Navigator.pop(context, true);
  }

  void _onSkipCycleCount() {

    // do nothing but return true to the previous page
    // The previous page is supposed to remove the request
    // from current assignment but since it is not finished yet
    // it will be pickup by the next count attempt
    Navigator.pop(context, true);
  }

  void _onCancelCycleCount() async {

    await CycleCountRequestService.cancelCycleCount(_cycleCountRequest);
    //return true to the previous page

    Navigator.pop(context, true);

  }
}