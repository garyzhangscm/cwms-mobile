import 'package:badges/badges.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inbound/models/receipt.dart';
import 'package:cwms_mobile/inbound/models/receipt_line.dart';
import 'package:cwms_mobile/inbound/services/receipt.dart';
import 'package:cwms_mobile/inbound/widgets/receipt_line_list_item.dart';
import 'package:cwms_mobile/inbound/widgets/receipt_list_item.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material_line.dart';
import 'package:cwms_mobile/workorder/models/kpi_measurement.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_kpi_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_line_consume_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_produced_inventory.dart';
import 'package:cwms_mobile/workorder/services/bill_of_material.dart';
import 'package:cwms_mobile/workorder/services/work_order.dart';
import 'package:cwms_mobile/workorder/widgets/work_order_kpi_item.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class WorkOrderKPIPage extends StatefulWidget{

  WorkOrderKPIPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _WorkOrderKPIPageState();

}

class _WorkOrderKPIPageState extends State<WorkOrderKPIPage> {

  WorkOrderProduceTransaction _workOrderProduceTransaction;

  TextEditingController _newKPIUsernameController = new TextEditingController();

  TextEditingController _newKPIWorkingTeamNameController = new TextEditingController();
  TextEditingController _newKPIAmountController = new TextEditingController();
  TextEditingController _newKPIMeasurementController = new TextEditingController();


  WorkOrderKPITransaction _newWorkOrderKPITransaction;

  @override
  Widget build(BuildContext context) {

    _workOrderProduceTransaction  = ModalRoute.of(context).settings.arguments;



    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).kpi)),
      body:
        Column(
          children: [
            _buildWorkOrderKPIList(context)
          ],
        ),

      bottomNavigationBar:_buildBottomNavigationBar(context),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }


  Widget _buildWorkOrderKPIList(BuildContext context) {

    return
      Expanded(
        child: ListView.separated(
            separatorBuilder: (context, index) => Divider(
              color: Colors.black,
            ),
            itemCount: _workOrderProduceTransaction.workOrderKPITransactions.length,
            itemBuilder: (BuildContext context, int index) {

              return WorkOrderKPIItem(
                  index: index,
                  workOrderKPITransaction: _workOrderProduceTransaction.workOrderKPITransactions[index],
                  onRemove:  (index) =>  _removeWorkOrderKPI(index)
              );
            }),
      );
  }


  void _removeWorkOrderKPI(int index) {

    setState(() {
      _workOrderProduceTransaction.workOrderKPITransactions.removeAt(index);
    });
  }


  Widget _buildBottomNavigationBar(BuildContext context) {

    return
      BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.done_all), label: CWMSLocalizations.of(context).confirm),
          BottomNavigationBarItem(icon: Icon(Icons.note_add), label: CWMSLocalizations.of(context).add),
          BottomNavigationBarItem(icon: Icon(Icons.cancel), label: CWMSLocalizations.of(context).cancel),

        ],
        currentIndex: 0,
        fixedColor: Colors.blue,
        onTap: (index) => _onActionItemTapped(index),

      );

  }

  void _onActionItemTapped(int index) {
    if (index == 0) {
      _onConfirmWorkOrderTransaction();
    }
    else if (index == 1) {
      _onAddNewKPITransaction();
    }
    else if (index == 2) {
      // index == 2
      _onCancelKPITransaction();
    }
  }

  // prompt an dialog to let the user input either a username
  // or choose a working team
  void _onAddNewKPITransaction() {
    //TO-DO
    printLongLogMessage("start to add new KPI transaction");
    _newWorkOrderKPITransaction = new WorkOrderKPITransaction();
    _newKPIUsernameController.clear();
    _newKPIWorkingTeamNameController.clear();
    _newKPIAmountController.clear();
    _newKPIMeasurementController.clear();
    _showKPIDialog();

  }

  Future<void> _onConfirmWorkOrderTransaction() async {

    await WorkOrderService.saveWorkOrderProduceTransaction(
        _workOrderProduceTransaction
    );
    print("work order produce transaction saved!");

    // return to the previous page to continue
    Navigator.of(context).pop();
  }

  // cancel all KPI transaction and return to the previous page
  void _onCancelKPITransaction() {

    Navigator.of(context).pop();
    // TO-DO
  }


  // show dialog to let the user input the KPI measurement
  Future<void> _showKPIDialog() async {

    printLongLogMessage("will show kpi dialog to capture new KPI");
    await showDialog<bool>(
      context: context,

      builder: (BuildContext context) {

        return StatefulBuilder(
            builder: (context, setState)
            {
              return Dialog(child:

                Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child:
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left:25.0, right: 25.0),
                          child:
                          Text(CWMSLocalizations.of(context).userName),
                        ),
                        Flexible(
                          child:
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _newWorkOrderKPITransaction.username = value;
                              });
                            },
                            controller: _newKPIUsernameController,
                          ),

                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child:
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left:25.0, right: 25.0),
                          child:
                          Text(CWMSLocalizations.of(context).workingTeamName),
                        ),
                        Flexible(
                          child:
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _newWorkOrderKPITransaction.workingTeamName = value;
                              });
                            },
                            controller: _newKPIWorkingTeamNameController,

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child:
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left:25.0, right: 25.0),
                          child:
                          Text(CWMSLocalizations.of(context).kpiAmount),
                        ),
                        Flexible(
                          child:
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _newWorkOrderKPITransaction.amount = double.parse(value);
                              });
                            },
                            controller: _newKPIAmountController,

                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child:
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left:25.0, right: 25.0),
                          child:
                          Text(CWMSLocalizations.of(context).kpiMeasurement),
                        ),
                        Expanded(
                            child:
                            DropdownButton<KPIMeasurement>(
                              hint: Text(CWMSLocalizations.of(context).pleaseSelect),
                              // items: _getValidKPIMeasurements(),
                              items: KPIMeasurement.values.map((KPIMeasurement kpiMeasurement) {
                                return DropdownMenuItem<KPIMeasurement>(
                                    value: kpiMeasurement,
                                    child: Text(kpiMeasurement.toString().substring(15)));
                              }).toList(),
                              elevation: 1,
                              isExpanded: true,
                              icon: Icon(
                                Icons.list,
                                size: 20,
                              ),
                              value: _newWorkOrderKPITransaction.kpiMeasurement,
                              onChanged: (KPIMeasurement newValue) {
                                //下拉菜单item点击之后的回调
                                setState(() {
                                   _newWorkOrderKPITransaction.kpiMeasurement = newValue;
                                  printLongLogMessage("change kpimeasurement to "
                                      + "${newValue}");

                                });
                              },
                            )
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child:
                    Row(
                      children: [

                        Padding(
                          padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                          child:
                          RaisedButton(
                            color: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                            child: Text(CWMSLocalizations
                                .of(context)
                                .cancel),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                          child:
                          RaisedButton(
                            color: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                            child: Text(CWMSLocalizations
                                .of(context)
                                .confirm),
                            onPressed: () {
                              _confirmNewKPITransaction();
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),

                  ),
                ],
              )
              );
            }
        );
        //使用AlertDialog会报错
        //return AlertDialog(content: child);
      },
    );
  }

  List<DropdownMenuItem> _getValidKPIMeasurements() {
    List<DropdownMenuItem> items = new List();

    // default to by quantity
    //_newWorkOrderKPITransaction.kpiMeasurement = KPIMeasurement.BY_QUANTITY;

    for (var kpiMeasurement in KPIMeasurement.values) {
      items.add(
          DropdownMenuItem(
            value: kpiMeasurement,
            child: Text(kpiMeasurement.toString()),
          ));
    }
    return items;
  }

  void _confirmNewKPITransaction() {
    printLongLogMessage("will add new KPI transaction ");
    printLongLogMessage("> ${_newWorkOrderKPITransaction.username}");
    printLongLogMessage("> ${_newWorkOrderKPITransaction.workingTeamName}");
    printLongLogMessage("> ${_newWorkOrderKPITransaction.amount}");
    printLongLogMessage("> ${_newWorkOrderKPITransaction.kpiMeasurement}");
    setState(() {
       _workOrderProduceTransaction.workOrderKPITransactions.add(_newWorkOrderKPITransaction);
    });


  }


}