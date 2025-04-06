
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_sampling.dart';
import 'package:cwms_mobile/inventory/services/item.dart';
import 'package:cwms_mobile/inventory/services/item_sampling.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Page to allow the user scan in an LPN and start the put away process
// The LPN can be in receiving stage / storage location / etc
// with or without any pre-assigned destination
class ItemSamplingPage extends StatefulWidget{

  ItemSamplingPage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _ItemSamplingPageState();

}

class _ItemSamplingPageState extends State<ItemSamplingPage> {

  // allow user to scan in LPN
  TextEditingController _itemNameController = new TextEditingController();
  TextEditingController _itemSamplingNumberController = new TextEditingController();

  ItemSampling? _currentItemSampling;
  bool _newItemSampling = true;

  FocusNode _itemNameFocusNode = FocusNode();
  FocusNode _itemSamplingNumberFocusNode = FocusNode();

  // map to save the local file to increase the loading speed
  Map<String, String> _localFile = new Map();
  final ImagePicker _picker = ImagePicker();


  @override
  void initState() {
    super.initState();
    _currentItemSampling = null;

    _itemNameFocusNode.addListener(() {
      print("_itemNumberFocusNode.hasFocus: ${_itemNameFocusNode.hasFocus}");
      if (!_itemNameFocusNode.hasFocus && _itemNameController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _onItemNameScanned();

      }
    });

    _itemNameController.clear();
    _itemNameFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Item Sampling")),
      resizeToAvoidBottomInset: true,
      body:
          Column(
              children: [
                _buildItemNameScanner(context),
                _buildButtons(context),
                _currentItemSampling == null ?
                    Container() :
                    _buildItemSamplingInformation(context),
              ],
      ),
      endDrawer: MyDrawer(),
    );
  }
  // build the information, image list and buttons once we get the item sampling data
  Widget _buildItemSamplingInformation(BuildContext context) {
    return Column(
        children: [

            buildSingleSectionInformationRow(
              CWMSLocalizations.of(context)!.itemSamplingNumber,
            ),
            buildSingleSectionInputRow(
              SystemControllerNumberTextBox(
                type: "item-sampling-number",
                controller: _itemSamplingNumberController,
                readOnly: _newItemSampling? false : true,
                showKeyboard: false,
                focusNode: _itemSamplingNumberFocusNode,
                autofocus: true,
                onValueChanged: (value) => _itemSamplingNumberChanged(value!)
              ),
            ),
            buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context)!.item,
                  _currentItemSampling?.item?.name ?? ""
            ),
            buildTwoSectionInformationRow(
                CWMSLocalizations.of(context)!.item, _currentItemSampling?.item?.description ?? ""
            ),
            _buildItemSamplingImages(),

            _buildAddItemSamplingButtons(context),

        ]);


  }

  Widget _buildItemNameScanner(BuildContext context) {
    return TextFormField(
        controller: _itemNameController,
        focusNode: _itemNameFocusNode,
        autofocus: true,
        decoration: InputDecoration(
          labelText: CWMSLocalizations.of(context)!.item,
        ),);
  }



  Widget _buildButtons(BuildContext context) {

    return
      // confirm input and clear input
      buildThreeButtonRow(context,
        ElevatedButton(
            onPressed: _onItemNameScanned,
            child: Text(CWMSLocalizations.of(context)!.confirm)
        ),
        ElevatedButton(
            onPressed: _onClear,
            child: Text(CWMSLocalizations.of(context)!.clear)
        ),
        ElevatedButton(
            onPressed: _currentItemSampling != null && !_newItemSampling ? _onAddNewItemSampling : null,
            child: Text(CWMSLocalizations.of(context)!.add)
        ),

      ) ;
  }
  // create a new item sampling for the item so we can override the original one
  _onAddNewItemSampling(){
    setState(() {

      _currentItemSampling = ItemSampling.fromItem(Global.currentWarehouse.id, _currentItemSampling!.item!);
      _newItemSampling = true;
      _itemSamplingNumberController.clear();
    });
  }

  _onClear() {

    setState(() {

      _currentItemSampling = null;
    });
  }


  _onItemNameScanned() async {

    String itemName = _itemNameController.text;
    if (itemName.isNotEmpty) {
      showLoading(context);
      try {
        // see if have an existing item sampling record for this item

        _currentItemSampling = await ItemSamplingService.getCurrentItemSamplingByItemName(itemName);

        // we don't have any enabled item sampling for this item yet,
        // let's create one
        if (_currentItemSampling == null) {

          Item? item = await ItemService.getItemByName(itemName);
          if (item == null) {
            Navigator.of(context).pop();
            showErrorDialog(context, "can't find item by name " + itemName);
            return;

          }
          _currentItemSampling = ItemSampling.fromItem(Global.currentWarehouse.id, item);
          _newItemSampling = true;
        }
        else {
          _newItemSampling = false;
        }


        Navigator.of(context).pop();
        setState(() {
          _currentItemSampling;
          _newItemSampling;
          _itemSamplingNumberController.text = _currentItemSampling?.number ?? "";
          _itemNameController.clear();
        });

      }
      on WebAPICallException catch (ex) {
        Navigator.of(context).pop();
        showErrorDialog(context, ex.errMsg());
        return;
      }
    }

  }


  _itemSamplingNumberChanged(String itemSamplingNumber) {
    printLongLogMessage("itemSamplingNumber is changed to ${itemSamplingNumber}");
    setState(() {
      _itemSamplingNumberController.text = itemSamplingNumber;
    });
  }


  Widget _buildItemSamplingImages() {

    List<String>  _itemSamplingImageUrls = _getItemSamplingImageUrls();
    if (_itemSamplingImageUrls.isEmpty) {
      return Container();
    }
    return CarouselSlider(
      options: CarouselOptions(enableInfiniteScroll: false),
      items: _itemSamplingImageUrls
          .map((imageUrl)  {
        return Container(
            child: Center(
                child:
                Stack(
                  children: <Widget>[
                    // check if we will need to load from local storage or network
                    // _localFile map stores the file name as the key and the file path as the value
                    _localFile.containsKey(imageUrl) ?
                    Image.file(File(_localFile[imageUrl]!))
                        :
                    Image.network(
                        Global.currentServer.url + "inventory/item-sampling/images/${Global.currentWarehouse.id}/${_currentItemSampling!.item!.id}/${_currentItemSampling!.number}/$imageUrl",
                        fit: BoxFit.cover, width: 1000,
                        headers: {
                          HttpHeaders.authorizationHeader: "Bearer ${Global.currentUser.token}",
                          "rfCode": Global.lastLoginRFCode,
                          "warehouseId": Global.currentWarehouse.id.toString(),
                          "companyId": Global.lastLoginCompanyId.toString()
                        }),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: (){
                          _removeImage(imageUrl);
                        },
                        child: Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                )
            ));
      })
          .toList(),
    );

  }



  _removeImage(String imageFileName) {


    setState(() {
      // if the file is from local , then remove it from the map
      _localFile.remove(imageFileName);

      // remove the file from the list and fix the comma
      _currentItemSampling!.imageUrls = _currentItemSampling!.imageUrls!.replaceAll(imageFileName, "");
      if (_currentItemSampling!.imageUrls!.startsWith(",")) {
        _currentItemSampling!.imageUrls = _currentItemSampling!.imageUrls!.substring(1);
      }
      if (_currentItemSampling!.imageUrls!.endsWith(",")) {
        _currentItemSampling!.imageUrls = _currentItemSampling!.imageUrls!.substring(0, _currentItemSampling!.imageUrls!.length - 1);
      }

    });

  }

  List<String> _getItemSamplingImageUrls() {

    List<String>  itemSamplingImageUrls = [];

    if (_currentItemSampling != null &&
        _currentItemSampling!.imageUrls!.isNotEmpty) {
      // we have files from the server, let's add it to the list
      itemSamplingImageUrls.addAll(_currentItemSampling!.imageUrls!.split(","));
    }
    // add the local uploaded file
    if (_localFile.isNotEmpty) {

      itemSamplingImageUrls.addAll(_localFile.keys);
    }
    return itemSamplingImageUrls;

  }


  Widget _buildAddItemSamplingButtons(BuildContext context) {
    return buildThreeButtonRow(
      context,
      ElevatedButton(
        onPressed: _itemSamplingNumberController.text.isEmpty ? null : _addItemSampleImage,
        child: Text(CWMSLocalizations
            .of(context)
            .addImage),
      ),
      ElevatedButton(
        onPressed: _itemSamplingNumberController.text.isEmpty ? null : _takeSamplePhoto,
        child: Text(CWMSLocalizations
            .of(context)
            .takePhoto),
      ),
      ElevatedButton(
        onPressed: _itemSamplingNumberController.text.isEmpty ? null : _onConfirm,
        child: Text(CWMSLocalizations
            .of(context)
            .confirm),
      ),
    );

  }


  _addItemSampleImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) {
        // return if the user picked nothing
        return;
      }

      await _uploadImageFile(pickedFile);

    } catch (e) {
      printLongLogMessage("error while uploading files: $e");

    }
  }
  _takeSamplePhoto() async {

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (pickedFile == null) {
        // return if the user picked nothing
        return;
      }
      await _uploadImageFile(pickedFile);

    } catch (e) {
    }
  }

  _uploadImageFile(XFile imageFile) async {

    showLoading(context);
    // for new item sampling, we will upload the file to a folder that belongs to the item
    // otherwise, we will upload teh file to a folder that belongs to the item sampling
    String fileUploadUrl =
        _newItemSampling ?
        "inventory/item-sampling/${_currentItemSampling!.item!.id}/images" :
        "inventory/item-sampling/${_currentItemSampling!.item!.id}/${_currentItemSampling!.number}/images";
    String filename = await uploadFile(imageFile, fileUploadUrl);

    setState(() {
      printLongLogMessage("we get picked file: ${imageFile.path}, server file name is ${filename}");

      // save it to map so we can load the file from local file
      _localFile.putIfAbsent(filename, () => imageFile.path);
      /**
       * for files uploaded from the local, we will add to the _workOrderQCSample when the user click
       * confirm button
          if (_workOrderQCSample.imageUrls.isEmpty) {
          _workOrderQCSample.imageUrls = filename;
          }
          else {
          _workOrderQCSample.imageUrls = _workOrderQCSample.imageUrls + "," + filename;
          }
       **/
    });
    Navigator.of(context).pop();
  }

  _onConfirm() async {
    // setup the image list for the _workOrderQCSample object
    if (_localFile.isNotEmpty) {
      if (_currentItemSampling!.imageUrls!.isEmpty) {
        _currentItemSampling!.imageUrls = _localFile.keys.join(",");
      }
      else {
        _currentItemSampling!.imageUrls  = _currentItemSampling!.imageUrls! + "," + _localFile.keys.join(",");
      }
    }

    if (_itemSamplingNumberController.text.isEmpty) {
      return;
    }

    // make sure the number doesn't exists yet
    showLoading(context);
    _currentItemSampling!.number = _itemSamplingNumberController.text;

    if (_newItemSampling == true) {
      // we are adding a new work order qc sample, make sure the number doesn't exists yet
      try {
        ItemSampling? itemSampling =
        await ItemSamplingService.getItemSamplingByNumber(_currentItemSampling!.number!);
        if (itemSampling != null) {
          // ok we are supposed to create a new work order sample but it already exists, let's
          // raise an error
          Navigator.of(context).pop();
          showErrorDialog(context, CWMSLocalizations.of(context)!.qcSampleNumberAlreadyExists);
          return;
        }

      }
      on WebAPICallException catch(ex) {

        Navigator.of(context).pop();
        showErrorDialog(context, ex.errMsg());
        return;

      }

    }

    try {
      if (_newItemSampling) {

        await ItemSamplingService.addItemSampling(_currentItemSampling!);
      }
      else {
        await ItemSamplingService.changeItemSampling(_currentItemSampling!);

      }

    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    Navigator.of(context).pop();
    showToast( CWMSLocalizations.of(context)!.qcSampleAdded);
    // we will allow the user to continue receiving with the same
    // receipt and line
    setState(() {
      _currentItemSampling = null;
      _localFile.clear();


      _itemNameController.clear();
      _itemSamplingNumberController.clear();
      _newItemSampling = false;

      _itemNameFocusNode.requestFocus();
    });
  }

}