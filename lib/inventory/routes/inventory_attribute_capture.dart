import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../shared/global.dart';
import '../models/item.dart';


class InventoryAttributeCapturePage extends StatefulWidget{

  InventoryAttributeCapturePage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _InventoryAttributeCapturePageState();

}

class _InventoryAttributeCapturePageState extends State<InventoryAttributeCapturePage> {


  Map<String, TextEditingController> _inventoryAttributeControllerMap = new Map();
  Map<String, String> _inventoryAttributes = new Map();
  Item? _item;
  final  _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _item = ModalRoute.of(context)?.settings.arguments as Item;
    _initInventoryAttributeControllers();
  }
  void _initInventoryAttributeControllers() {
    if (_item?.trackingColorFlag == true) {
      _inventoryAttributeControllerMap["color"] = new TextEditingController();
    }
    if (_item?.trackingProductSizeFlag == true) {
      _inventoryAttributeControllerMap["productSize"] = new TextEditingController();
    }
    if (_item?.trackingStyleFlag == true) {
      _inventoryAttributeControllerMap["style"] = new TextEditingController();
    }
    if (_item?.trackingInventoryAttribute1Flag == true) {
      _inventoryAttributeControllerMap["attribute1"] = new TextEditingController();
    }
    if (_item?.trackingInventoryAttribute2Flag == true) {
      _inventoryAttributeControllerMap["attribute2"] = new TextEditingController();
    }
    if (_item?.trackingInventoryAttribute3Flag == true) {
      _inventoryAttributeControllerMap["attribute3"] = new TextEditingController();
    }
    if (_item?.trackingInventoryAttribute4Flag == true) {
      _inventoryAttributeControllerMap["attribute4"] = new TextEditingController();
    }
    if (_item?.trackingInventoryAttribute5Flag == true) {
      _inventoryAttributeControllerMap["attribute5"] = new TextEditingController();
    }
  }
  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context)!.captureInventoryAttribute)),
        resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Form(
          key: _formKey,
          // autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[
              _item?.trackingColorFlag == true ?
                  _buildInventoryAttribute(context, "color") : Container(),
              _item?.trackingStyleFlag == true ?
              _buildInventoryAttribute(context, "style") : Container(),
              _item?.trackingProductSizeFlag == true ?
              _buildInventoryAttribute(context, "productSize") : Container(),
              _item?.trackingInventoryAttribute1Flag == true ?
              _buildInventoryAttribute(context, "attribute1") : Container(),
              _item?.trackingInventoryAttribute2Flag == true ?
              _buildInventoryAttribute(context, "attribute2") : Container(),
              _item?.trackingInventoryAttribute3Flag == true ?
              _buildInventoryAttribute(context, "attribute3") : Container(),
              _item?.trackingInventoryAttribute4Flag == true ?
              _buildInventoryAttribute(context, "attribute4") : Container(),
              _item?.trackingInventoryAttribute5Flag == true ?
              _buildInventoryAttribute(context, "attribute5") : Container(),
              _buildButtons(context),
            ],
          ),
        ),
      ),
      //endDrawer: MyDrawer(),
      // endDrawer: MyDrawer(),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return buildSingleButtonRow(
        context,
        ElevatedButton(
          onPressed: () {
            _assignInventoryAttribute();
            Navigator.pop(context, _inventoryAttributes);
            // return the inventory
          },
          child: Text(CWMSLocalizations
              .of(context)
              .confirm),
        ),

    );

  }

  _assignInventoryAttribute() {
    _inventoryAttributeControllerMap.forEach(
            (attributeName, attributeController) {
              if (attributeController.text.isNotEmpty) {
                _inventoryAttributes[attributeName] = attributeController.text;
                print("set ${attributeName} to ${_inventoryAttributes[attributeName]}");
              }
              else {

                print("set ${attributeName} to empty");
              }
            });
  }

  Widget _buildInventoryAttribute (BuildContext context, String name){
    TextEditingController textEditingController;
    if (_inventoryAttributeControllerMap.containsKey(name)) {
      textEditingController = _inventoryAttributeControllerMap[name]!;
    }
    else {
      textEditingController = new TextEditingController();
      _inventoryAttributeControllerMap[name] = textEditingController;
    }

    return
      buildTwoSectionInputRow(
          _getInventoryAttributeDisplayName(name),
          TextFormField(
          controller: textEditingController,
          textInputAction: TextInputAction.next,
          autofocus: true)
      );
  }

  _getInventoryAttributeDisplayName(String attributeName) {

    String displayName = attributeName;
    if (attributeName == "attribute1" &&
            Global.currentInventoryConfiguration!.inventoryAttribute1DisplayName!.isNotEmpty) {
        displayName = Global.currentInventoryConfiguration!.inventoryAttribute1DisplayName!;
    }
    else if (attributeName == "attribute2" &&
      Global.currentInventoryConfiguration!.inventoryAttribute2DisplayName!.isNotEmpty) {
        displayName = Global.currentInventoryConfiguration!.inventoryAttribute2DisplayName!;
    }
    else if (attributeName == "attribute3" &&
        Global.currentInventoryConfiguration!.inventoryAttribute3DisplayName!.isNotEmpty) {
          displayName = Global.currentInventoryConfiguration!.inventoryAttribute3DisplayName!;
    }
    else if (attributeName == "attribute4" &&
        Global.currentInventoryConfiguration!.inventoryAttribute4DisplayName!.isNotEmpty) {
        displayName = Global.currentInventoryConfiguration!.inventoryAttribute4DisplayName!;
    }
    else if (attributeName == "attribute5" &&
        Global.currentInventoryConfiguration!.inventoryAttribute5DisplayName!.isNotEmpty) {
          displayName = Global.currentInventoryConfiguration!.inventoryAttribute5DisplayName!;
    }
    return displayName;


  }


}