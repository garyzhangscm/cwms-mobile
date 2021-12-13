

import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_sample.dart';
import 'package:cwms_mobile/workorder/services/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/services/work_order_qc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';


class WorkOrderQCSamplingPage extends StatefulWidget{

  WorkOrderQCSamplingPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _WorkOrderQCSamplingPageState();

}

class _WorkOrderQCSamplingPageState extends State<WorkOrderQCSamplingPage> {

  // input batch id
  TextEditingController _productionLineController = new TextEditingController();
  TextEditingController _qcSampleNumberController = new TextEditingController();

  // existing work order QC samples for current production line
  WorkOrderQCSample _workOrderQCSample;


  ProductionLineAssignment _productionLineAssignment;

  FocusNode _productionLineFocusNode = FocusNode();
  FocusNode _qcSampleNumberFocusNode = FocusNode();



  // choose image
  final ImagePicker _picker = ImagePicker();

  // map to save the local file to increase the loading speed
  Map<String, String> _localFile = new Map();
  bool _newWorkOrderQCSample = false;



  @override
  void initState() {
    super.initState();

    /***
    _productionLineController.addListener(() {
      print("_receiptFocusNode.hasFocus: ${_productionLineFocusNode.hasFocus}");
      if (!_productionLineFocusNode.hasFocus && _productionLineController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _loadProductionLineAssignment(_productionLineController.text);
        // _itemFocusNode.requestFocus();

      }
    });
        **/
    _productionLineFocusNode.requestFocus();

  }
  final  _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).qcSampling)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          // autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[

              buildTwoSectionInputRow(
                CWMSLocalizations.of(context).productionLine,
                TextFormField(
                    controller: _productionLineController,
                    autofocus: true,
                    focusNode: _productionLineFocusNode,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: _loadProductionLineAssignment
                ),
              ),
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context).productionLine,
                  _productionLineAssignment == null ? "" : _productionLineAssignment.productionLine.name
              ),
              buildTwoSectionInformationRow(
                CWMSLocalizations.of(context).workOrderNumber,
                _productionLineAssignment == null ? "" : _productionLineAssignment.workOrderNumber
              ),
              buildSingleSectionInformationRow(
                CWMSLocalizations.of(context).workOrderQCSampleNumber,
              ),
              buildSingleSectionInputRow(

                  SystemControllerNumberTextBox(
                    type: "work-order-qc-sample-number",
                    controller: _qcSampleNumberController,
                    readOnly: _newWorkOrderQCSample? false : true,
                    showKeyboard: false,
                    focusNode: _qcSampleNumberFocusNode,
                    autofocus: true,
                    onValueChanged: (value) => _qcSampleNumberChanged(value)
                  ),
              ),
              // build existing QC Images
              _buildQCImages(),
              //
              _buildAddQCSamplingButtons(context),
            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }
  _qcSampleNumberChanged(String qcSampleNumber) {
    printLongLogMessage("qcSampleNumber is changed to ${qcSampleNumber}");
    setState(() {
      _qcSampleNumberController.text = qcSampleNumber;
    });
  }

  _loadProductionLineAssignment(String productionLineName) async {

    showLoading(context);
    if (productionLineName.isEmpty) {
      return;
    }
    try {
          _productionLineAssignment = await ProductionLineAssignmentService.getProductionLineAssignmentByProductionLineName(
              productionLineName
          );
        Navigator.of(context).pop();

        if (_productionLineAssignment == null) {
          // we are not able to find any assignment by this production line
          showErrorDialog(context, CWMSLocalizations.of(context).noAssignmentByProductionLine + productionLineName);
          return;
        }

        setState(() {
          _productionLineAssignment;
          _loadWorkOrderQCSample(_productionLineAssignment);
        });
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }


  }

  Future<void> _loadWorkOrderQCSample(ProductionLineAssignment productionLineAssignment) async {

    try {

      _workOrderQCSample = await WorkOrderQCService.getWorkOrderQCSampleByProductionLineAssignment(productionLineAssignment.id);
      if (_workOrderQCSample == null) {

        printLongLogMessage("we can't get qc samples from production line id: ${productionLineAssignment.id}, we will create one");
        _workOrderQCSample = new WorkOrderQCSample.fromProductionLineAssignment(_productionLineAssignment);
        _newWorkOrderQCSample = true;
      }
      else {

        printLongLogMessage("we get qc samples from production line id: ${productionLineAssignment.id}, we will create one");
        _newWorkOrderQCSample = false;
      }
      setState(() {
        _workOrderQCSample;
        _newWorkOrderQCSample;
        _qcSampleNumberController.text = _workOrderQCSample.number;
      });
    }
    on WebAPICallException catch(ex) {
      // if we can't get from the server, then create an empty one
      setState(() {

        _workOrderQCSample = new WorkOrderQCSample();
        _newWorkOrderQCSample = true;
      });
      showErrorDialog(context, ex.errMsg());
      return;

    }


  }
  Widget _buildQCImages() {

    if (_getQCSampleImageUrls().isEmpty) {
      return Container();
    }
    return CarouselSlider(
      options: CarouselOptions(enableInfiniteScroll: false),
      items: _getQCSampleImageUrls()
          .map((imageUrl)  {
              return Container(
                  child: Center(
                      child:
                      Stack(
                        children: <Widget>[
                          // check if we will need to load from local storage or network
                          // _localFile map stores the file name as the key and the file path as the value
                          _localFile.containsKey(imageUrl) ?
                          Image.file(File(_localFile[imageUrl]))
                              :
                          Image.network(
                              Global.currentServer.url + "workorder/qc-samples/images/${Global.currentWarehouse.id}/${_workOrderQCSample.productionLineAssignment.id}/$imageUrl",
                              fit: BoxFit.cover, width: 1000),
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
        _workOrderQCSample.imageUrls = _workOrderQCSample.imageUrls.replaceAll(imageFileName, "");
        if (_workOrderQCSample.imageUrls.startsWith(",")) {
          _workOrderQCSample.imageUrls = _workOrderQCSample.imageUrls.substring(1);
        }
        if (_workOrderQCSample.imageUrls.endsWith(",")) {
          _workOrderQCSample.imageUrls = _workOrderQCSample.imageUrls.substring(0, _workOrderQCSample.imageUrls.length - 1);
        }
      });

  }


  List<String> _getQCSampleImageUrls() {

    List<String>  qcSampleImageUrls = [];

    if (_workOrderQCSample != null &&
        _workOrderQCSample.imageUrls.isNotEmpty) {
      // we have files from the server, let's add it to the list
      qcSampleImageUrls.addAll(_workOrderQCSample.imageUrls.split(","));
    }
    // add the local uploaded file
    if (_localFile.isNotEmpty) {

      qcSampleImageUrls.addAll(_localFile.keys);
    }
    return qcSampleImageUrls;

  }
  Widget _buildAddQCSamplingButtons(BuildContext context) {
    return buildThreeButtonRow(
      context,
      ElevatedButton(
        onPressed: _productionLineAssignment == null || _qcSampleNumberController.text.isEmpty ? null : _addSampleImage,
        child: Text(CWMSLocalizations
            .of(context)
            .addImage),
      ),
      ElevatedButton(
        onPressed: _productionLineAssignment == null || _qcSampleNumberController.text.isEmpty ? null : _takeSamplePhoto,
        child: Text(CWMSLocalizations
            .of(context)
            .takePhoto),
      ),
      ElevatedButton(
        onPressed: _productionLineAssignment == null || _qcSampleNumberController.text.isEmpty ? null : _onConfirm,
        child: Text(CWMSLocalizations
            .of(context)
            .confirm),
      ),
    );

  }

  _addSampleImage() async {
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
    String filename = await uploadFile(imageFile,
        "workorder/qc-samples/${_productionLineAssignment.id}/images");

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
      if (_workOrderQCSample.imageUrls.isEmpty) {
        _workOrderQCSample.imageUrls = _localFile.keys.join(",");
      }
      else {
        _workOrderQCSample.imageUrls += "," + _localFile.keys.join(",");
      }
    }

    if (_qcSampleNumberController.text.isEmpty) {
      return;
    }

    // make sure the number doesn't exists yet
    showLoading(context);
    _workOrderQCSample.number = _qcSampleNumberController.text;

    if (_newWorkOrderQCSample == true) {
      // we are adding a new work order qc sample, make sure the number doesn't exists yet
      try {
        WorkOrderQCSample workOrderQCSample =
            await WorkOrderQCService.getWorkOrderQCSampleByNumber(_workOrderQCSample.number);
        if (workOrderQCSample != null) {
          // ok we are supposed to create a new work order sample but it already exists, let's
          // raise an error
          Navigator.of(context).pop();
          showErrorDialog(context, CWMSLocalizations.of(context).qcSampleNumberAlreadyExists);
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
        await WorkOrderQCService.addWorkOrderQCSample(_workOrderQCSample);

    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    Navigator.of(context).pop();
    showToast( CWMSLocalizations.of(context).qcSampleAdded);
    // we will allow the user to continue receiving with the same
    // receipt and line
    setState(() {
      _workOrderQCSample = null;
      _localFile.clear();
      _productionLineAssignment = null;
      _qcSampleNumberController.clear();
      _productionLineController.clear();
      _newWorkOrderQCSample = false;
    });
  }


}
