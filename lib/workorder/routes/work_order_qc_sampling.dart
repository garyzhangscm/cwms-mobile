import 'package:badges/badges.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inbound/models/receipt.dart';
import 'package:cwms_mobile/inbound/models/receipt_line.dart';
import 'package:cwms_mobile/inbound/services/receipt.dart';
import 'package:cwms_mobile/inbound/widgets/receipt_line_list_item.dart';
import 'package:cwms_mobile/inbound/widgets/receipt_list_item.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/models/item_unit_of_measure.dart';
import 'package:cwms_mobile/inventory/models/lpn_capture_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
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
import 'package:progress_dialog/progress_dialog.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


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


  Set<XFile> _imageFileList;
  dynamic _pickImageError;



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
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).receiving)),
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
                    readOnly: false,
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

        printLongLogMessage("we cna't get qc samples from production line id: ${productionLineAssignment.id}, we will create one");
        _workOrderQCSample = new WorkOrderQCSample.fromProductionLineAssignment(_productionLineAssignment);
      }
      setState(() {
        _workOrderQCSample;
      });
    }
    on WebAPICallException catch(ex) {
      // if we can't get from the server, then create an empty one
      setState(() {

        _workOrderQCSample = new WorkOrderQCSample();
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
          .map((imageUrl) => Container(
            child: Center(
                child:
                  Stack(
                  children: <Widget>[
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

          )))
          .toList(),
    );

  }

  _removeImage(String imageFileName) {


      printLongLogMessage("will remove images ${imageFileName}, current imagesUrls: ${_workOrderQCSample.imageUrls}");
      printLongLogMessage("_workOrderQCSample.imageUrls.contains(imageFileName): ${_workOrderQCSample.imageUrls.contains(imageFileName)}");
      setState(() {
        // remove the file from the list and fix the comma
        _workOrderQCSample.imageUrls = _workOrderQCSample.imageUrls.replaceAll(imageFileName, "");
        if (_workOrderQCSample.imageUrls.startsWith(",")) {
          _workOrderQCSample.imageUrls = _workOrderQCSample.imageUrls.substring(1);
        }
        if (_workOrderQCSample.imageUrls.endsWith(",")) {
          _workOrderQCSample.imageUrls = _workOrderQCSample.imageUrls.substring(0, _workOrderQCSample.imageUrls.length - 1);
        }
      });

      printLongLogMessage("after removed images, current imagesUrls: ${_workOrderQCSample.imageUrls}");
  }


  List<String> _getQCSampleImageUrls() {

    if (_workOrderQCSample == null ||
        _workOrderQCSample.imageUrls.isEmpty) {
      return [];
    }
    return _workOrderQCSample.imageUrls.split(",");

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
      setState(() {
        _pickImageError = e;
      });
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
      setState(() {
        _pickImageError = e;
      });
    }
  }

  _uploadImageFile(XFile imageFile) async {

    showLoading(context);
    String filename = await uploadFile(imageFile, _productionLineAssignment.id);

    setState(() {
      printLongLogMessage("we get picked file: ${imageFile.path}, server file name is ${filename}");
      if (_workOrderQCSample.imageUrls.isEmpty) {
        _workOrderQCSample.imageUrls = filename;
      }
      else {
        _workOrderQCSample.imageUrls = _workOrderQCSample.imageUrls + "," + filename;
      }
    });
    Navigator.of(context).pop();
  }

  _onConfirm() {}


}

typedef void OnPickImageCallback(
    double maxWidth, double maxHeight, int quality);