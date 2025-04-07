
import 'dart:collection';
import 'dart:core';

import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/auth/services/user.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
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
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/production_line_activity.dart';
import 'package:cwms_mobile/workorder/models/production_line_activity_type.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_labor.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:cwms_mobile/workorder/services/bill_of_material.dart';
import 'package:cwms_mobile/workorder/services/production_line.dart';
import 'package:cwms_mobile/workorder/services/production_line_activity.dart';
import 'package:cwms_mobile/workorder/services/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/services/work_order.dart';
import 'package:cwms_mobile/workorder/widgets/work_order_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:badges/badges.dart';
import 'package:intl/intl.dart';


class ProductionLineCheckOutPage extends StatefulWidget{

  ProductionLineCheckOutPage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _ProductionLineCheckOutPageState();

}

class _ProductionLineCheckOutPageState extends State<ProductionLineCheckOutPage> with SingleTickerProviderStateMixin{

  // when check out by username

  TextEditingController _usernameController = new TextEditingController();
  FocusNode _usernameFocusNode  = FocusNode();
  bool _incorrectUsername = false;
  String _currentUsername = "";
  Map<ProductionLine, bool> _assignedProductionLine = {  };
  final  _userFormKey = GlobalKey<FormState>();

  // when check out by productoin line
  List<ProductionLine> _validProductionLines = [];
  ProductionLine? _selectedProductionLine;
  FocusNode? _productionLineNode;
  Map<User, bool> _assignedUsers = {  };
  final  _productionLineFormKey = GlobalKey<FormState>();

  TabController? _tabController;

  List<WorkOrderLabor> _workOrderLaborResults = [];



  @override
  void initState() {
    super.initState();



    _tabController = TabController(vsync: this, length: 2);
    _tabController?.addListener(_handleTabSelection);

    // loading the production line that the user checked in
    // after we scan in the username
    _usernameFocusNode.addListener(() {
      print("_usernameFocusNode.hasFocus: ${_usernameFocusNode.hasFocus}");
      if (!_usernameFocusNode.hasFocus && _usernameController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _loadCheckInProductionLinesByUsername(_usernameController.text);


      }
    });
    _usernameFocusNode.requestFocus();
  }

  void _handleTabSelection() {
    if (_tabController?.indexIsChanging == true) {
      switch (_tabController!.index!) {
        case 0:
          // clear the input
          _refreshCheckoutByUserPage();
          break;
        case 1:
          _refreshCheckoutByProductionLinePage();

          break;
      }
    }
  }

  void _refreshCheckoutByUserPage() {

    setState(() {

      _usernameController.clear();
      _currentUsername = "";
      _assignedProductionLine.clear();
    });
  }

  void _refreshCheckoutByProductionLinePage() {

    showLoading(context);
    // loading the production line
    ProductionLineService.getAllAssignedProductionLines()
        .then((value) {
      setState(() {
        _validProductionLines = value;
        _selectedProductionLine = null;

        Navigator.of(context).pop();
      });
    });
    _assignedUsers.clear();
  }

  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(CWMSLocalizations.of(context)!.productionLineCheckOut),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              // check out by user
              Tab(text: CWMSLocalizations.of(context)!.productionLineCheckOutByUser),
              // check out by production line
              Tab(text: CWMSLocalizations.of(context)!.productionLineCheckOutByProductionLine),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCheckoutByUserPage(context),
            _buildCheckoutByProductionLinePage(context)
          ],
        ),
      ),
    );
  }


  Widget _buildCheckoutByUserPage(BuildContext context) {

    return
      Column(
          children: [
            _buildUserForm(context),
            _buildCheckOutByUsernameButtons(context),
          ]
    );
  }

  Widget _buildCheckoutByProductionLinePage(BuildContext context) {

    return
      Column(
          children: [
            _buildProductionLineForm(context),
            _buildCheckOutByProductionLineButtons(context),
          ]
      );
  }

  Widget _buildUserForm(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _userFormKey,

              child: Column(
                  children: <Widget>[
                    buildTwoSectionInputRow(
                      CWMSLocalizations.of(context)!.userName,
                      TextFormField(
                        focusNode: _usernameFocusNode,
                        controller: _usernameController,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (_incorrectUsername) {
                            return CWMSLocalizations.of(context)!.incorrectValue(CWMSLocalizations.of(context)!.userName);
                          }
                          return _currentUsername.isNotEmpty ? null :
                             CWMSLocalizations.of(context)!.missingField(CWMSLocalizations.of(context)!.userName);
                        },
                      ),
                    ),
                    _currentUsername.isEmpty ?
                        new Container() :
                        buildTwoSectionInformationRow(CWMSLocalizations.of(context)!.userName, _currentUsername),
                    // choose the production line that the user already checked in
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 400 > _assignedProductionLine.length * 50.0 ?
                          _assignedProductionLine.length * 50.0 : MediaQuery.of(context).size.height - 400,
                      child:
                        new ListView(
                          children: _assignedProductionLine.keys.map((ProductionLine productionLine) {
                            return new CheckboxListTile(
                              title: new Text(productionLine.name ?? ""),
                              value: _assignedProductionLine[productionLine],
                              onChanged: (bool? value) {
                                setState(() {
                                  _assignedProductionLine[productionLine] = value ?? false;
                                });
                              },
                            );
                          }).toList(),
                        ),
                    )
                  ]
              )
          )
      );
  }


  Widget _buildProductionLineForm(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _productionLineFormKey,

              child: Column(
                  children: <Widget>[
                    buildTwoSectionInputRow(
                        CWMSLocalizations.of(context)!.productionLine,
                        DropdownButton(
                          focusNode: _productionLineNode,
                          hint: Text(CWMSLocalizations.of(context)!.pleaseSelect),
                          items: _getValidProductionLines(),
                          value: _selectedProductionLine == null ?  null : _selectedProductionLine,
                          elevation: 1,
                          isExpanded: true,
                          icon: Icon(
                            Icons.list,
                            size: 20,
                          ),
                          onChanged: (ProductionLine? value) {
                            //下拉菜单item点击之后的回调
                            setState(() {
                              _selectedProductionLine = value;

                              _loadCheckInUsernamesByProductionLine(_selectedProductionLine!);
                            });
                          },
                        )
                    ),
                    // choose the user that already check in to this production line

                    SizedBox(
                      height: MediaQuery.of(context).size.height - 400 > _assignedUsers.length * 50.0 ?
                          _assignedUsers.length * 50.0 : MediaQuery.of(context).size.height - 400,
                      child:
                        new ListView(
                          children: _assignedUsers.keys.map((User user) {
                            return new CheckboxListTile(
                              title: new Text(user.username! + " (" + (user.firstname ?? "") + ", " + (user.lastname ?? "") + ")"),
                              value: _assignedUsers[user],
                              onChanged: (bool? value) {
                                setState(() {
                                  _assignedUsers[user] = value ?? false;
                                });
                              },
                            );
                          }).toList(),
                        ),
                    )
                  ]
              )
          )
      );
  }


  List<DropdownMenuItem<ProductionLine>> _getValidProductionLines() {
    List<DropdownMenuItem<ProductionLine>> items = [];
    if (_validProductionLines == null || _validProductionLines.length == 0) {
      return items;
    }

    for (int i = 0; i < _validProductionLines.length; i++) {
      items.add(DropdownMenuItem(
        value: _validProductionLines[i],
        child: Text(_validProductionLines[i].name ?? ""),
      ));
    }


    if (_validProductionLines.length == 1 ||
        _selectedProductionLine == null) {
      // if we only have one valid production line, then
      // default the selection to it
      // if the user has not select any production line yet, then
      // default the value to the first option as well
      _selectedProductionLine = _validProductionLines[0];
    }
    return items;
  }

  Widget _buildCheckOutByUsernameButtons(BuildContext context) {

    return
      SizedBox(
        width: double.infinity,
          height: 50,
        child:
          ElevatedButton(

            onPressed: _assignedProductionLine.length == 0 ?  null :
                () {
                  // clear the data we use to manually show the
                  // error and start validate the form from a
                  // clear start
                  _incorrectUsername = false;
                  if (_userFormKey.currentState!.validate()) {
                    print("form validation passed");
                    _onStartCheckOutByUser();
                  }

                },
            child: Text(CWMSLocalizations.of(context)!.productionLineCheckOut),
          )
        );


  }


  Widget _buildCheckOutByProductionLineButtons(BuildContext context) {

    return
      SizedBox(
          width: double.infinity,
          height: 50,
          child:
          ElevatedButton(

            onPressed: _assignedUsers.length == 0 ?  null :
                () {
              // clear the data we use to manually show the
              // error and start validate the form from a
              // clear start
              if (_productionLineFormKey.currentState!.validate()) {
                print("form validation passed");
                _onStartCheckOutByProductionLine();
              }

            },
            child: Text(CWMSLocalizations.of(context)!.productionLineCheckOut),
          )
      );


  }

  _loadCheckInProductionLinesByUsername(String username) async {

    showLoading(context);
    setState(() {

      _assignedProductionLine.clear();
    });
    // make sure the user is a valid user
    User? user = await UserService.findUser(Global.lastLoginCompanyId!, username);
    if (user == null) {
      setState(() {

        _currentUsername = "";
      });

      Navigator.of(context).pop();
      _usernameFocusNode.requestFocus();
      _incorrectUsername = true;
      _userFormKey.currentState?.validate();
      return;
    }


    try{

      List<ProductionLine> productionLines =
          await ProductionLineService.findAllCheckedInProductionLines(
              username
          );
      if (productionLines.isEmpty) {

        Navigator.of(context).pop();

        showToast(CWMSLocalizations.of(context)!.noCheckInProductionLineFoundForUser);
        return;
      }

      _assignedProductionLine.clear();
      productionLines.forEach((element) {

        setState(() {
          _assignedProductionLine.putIfAbsent(element, () => true);
        });
      });
    }
    on WebAPICallException catch(ex) {


      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    Navigator.of(context).pop();


    setState(() {

      _incorrectUsername = false;
      _currentUsername = user.username!;
      _usernameController.clear();
    });


    // check all production lines that the user is checked in
  }

  _loadCheckInUsernamesByProductionLine(ProductionLine productionLine) async {

    showLoading(context);

    setState(() {

      _assignedUsers.clear();
    });
    try{

      List<User> users =
        await ProductionLineService.findAllCheckedInUsers(
            productionLine
        );
      if (users.isEmpty) {

        Navigator.of(context).pop();

        showToast(CWMSLocalizations.of(context)!.noCheckInUsersFoundForProductionLine);
        return;
      }
      users.forEach((element) {

        setState(() {
          _assignedUsers.putIfAbsent(element, () => true);
        });
      });
    }
    on WebAPICallException catch(ex) {


      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    Navigator.of(context).pop();
  }

  Future<void> _onStartCheckOutByUser() async {

    if (_currentUsername.isEmpty) {

      showErrorDialog(context, CWMSLocalizations.of(context)!.pleaseSelectAUser);
      return;
    }
    showLoading(context);

    try {
      Iterable<MapEntry<ProductionLine, bool>> iterable = _assignedProductionLine.entries.where((element) => element.value == true);
      if (iterable.isEmpty) {

        Navigator.of(context).pop();
        showErrorDialog(context, CWMSLocalizations.of(context)!.pleaseSelectAProductionLine);
        return;
      }
      Iterator<MapEntry<ProductionLine, bool>> iterator = iterable.iterator;

      while(iterator.moveNext()) {

        ProductionLine productionLine = iterator.current.key;
        WorkOrderLabor _workOrderLabor =
            await ProductionLineService.checkOutUser(productionLine.id!, _currentUsername);
        setState(() {
          _workOrderLaborResults.add(_workOrderLabor);
        });
      }


    }
    on WebAPICallException catch(ex) {


      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    Navigator.of(context).pop();

    print("production line check out transaction saved!");

    showToast(CWMSLocalizations.of(context)!.actionComplete);


    _refreshCheckoutByUserPage();
  }

  Future<void> _onStartCheckOutByProductionLine() async {

    if (_selectedProductionLine == null) {

      showErrorDialog(context, CWMSLocalizations.of(context)!.pleaseSelectAProductionLine);
      return;
    }
    showLoading(context);

    try {

      Iterable<MapEntry<User, bool>> iterable = _assignedUsers.entries.where((element) => element.value == true);
      if (iterable.isEmpty) {

        Navigator.of(context).pop();
        showErrorDialog(context, CWMSLocalizations.of(context)!.pleaseSelectAProductionLine);
        return;
      }
      Iterator<MapEntry<User, bool>> iterator = iterable.iterator;

      while(iterator.moveNext()) {

        User user = iterator.current.key;
        WorkOrderLabor _workOrderLabor =
            await ProductionLineService.checkOutUser(_selectedProductionLine!.id!, user.username!);
        setState(() {
          _workOrderLaborResults.add(_workOrderLabor);
        });
      }


    }
    on WebAPICallException catch(ex) {


      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    Navigator.of(context).pop();

    print("production line check out transaction saved!");

    showToast(CWMSLocalizations.of(context)!.actionComplete);


    _refreshCheckoutByProductionLinePage();
  }



}