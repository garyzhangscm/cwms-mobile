import 'package:cwms_mobile/shared/scanning/scan_app_bar.dart';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/i18n/spanish_ui.dart';
import 'package:cwms_mobile/shared/updates/update_activity.dart';
import 'package:cwms_mobile/workorder/services/qc_sampling_questionnaire.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_sample.dart';
import 'package:cwms_mobile/workorder/services/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/services/work_order_qc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WorkOrderQCSamplingPage extends StatefulWidget {
  WorkOrderQCSamplingPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WorkOrderQCSamplingPageState();
}

class _WorkOrderQCSamplingPageState extends State<WorkOrderQCSamplingPage> {
  // input batch id
  TextEditingController _productionLineController = new TextEditingController();
  TextEditingController _qcSampleNumberController = new TextEditingController();

  // existing work order QC samples for current production line
  WorkOrderQCSample? _workOrderQCSample;

  ProductionLineAssignment? _productionLineAssignment;

  FocusNode _productionLineFocusNode = FocusNode();
  FocusNode _qcSampleNumberFocusNode = FocusNode();

  // choose image
  final ImagePicker _picker = ImagePicker();

  // map to save the local file to increase the loading speed
  Map<String, String> _localFile = new Map();
  bool _newWorkOrderQCSample = false;
  bool _busy = false;
  QCSamplingQuestionnaire _questionnaire = QCSamplingQuestionnaire();
  late final String _scope;
  String get _currentScope =>
      '${Global.currentFactory?.id}:${Global.currentWarehouse?.id}:${Global.lastLoginCompanyId}:${Global.currentUser?.username}';
  bool get _locked =>
      _busy ||
      _questionnaire.savedSample != null ||
      _questionnaire.registrationUncertain;

  @override
  void dispose() {
    _productionLineController.dispose();
    _qcSampleNumberController.dispose();
    _productionLineFocusNode.dispose();
    _qcSampleNumberFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scope = _currentScope;
    _questionnaire =
        QCSamplingQuestionnaire(isCurrentScope: () => _scope == _currentScope);

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

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: ScanAppBar(title: Text(CWMSLocalizations.of(context).qcSampling)),
        resizeToAvoidBottomInset: true,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            // autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
            child: ListView(
              children: <Widget>[
                buildTwoSectionInputRow(
                  CWMSLocalizations.of(context).productionLine,
                  TextFormField(
                      enabled: !_locked,
                      controller: _productionLineController,
                      autofocus: true,
                      focusNode: _productionLineFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: _loadProductionLineAssignment),
                ),
                buildTwoSectionInformationRow(
                    CWMSLocalizations.of(context).productionLine,
                    _productionLineAssignment?.productionLine?.name ?? ""),
                buildTwoSectionInformationRow(
                    CWMSLocalizations.of(context).workOrderNumber,
                    _productionLineAssignment?.workOrderNumber ?? ""),
                buildSingleSectionInformationRow(
                  CWMSLocalizations.of(context).workOrderQCSampleNumber,
                ),
                buildSingleSectionInputRow(
                  AbsorbPointer(
                    absorbing: _locked,
                    child: SystemControllerNumberTextBox(
                        type: "work-order-qc-sample-number",
                        controller: _qcSampleNumberController,
                        readOnly: _locked || !_newWorkOrderQCSample,
                        showKeyboard: false,
                        focusNode: _qcSampleNumberFocusNode,
                        autofocus: true,
                        onValueChanged: (value) =>
                            _qcSampleNumberChanged(value!)),
                  ),
                ),
                // build existing QC Images
                _buildQCImages(),
                //
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _qcSampleNumberController,
                  builder: (context, value, child) =>
                      _buildAddQCSamplingButtons(context),
                ),
                if (_questionnaire.registrationUncertain)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(uiText(context,
                        'Registration could not be confirmed. Check this sample number in Work Order QC before continuing. Do not register it again.')),
                  ),
                if (_workOrderQCSample != null &&
                    !_questionnaire.registrationUncertain)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(uiText(
                        context,
                        _questionnaire.savedSample == null
                            ? 'Register this sample, then complete its QC questionnaire. QC is recorded only after submitting the answers.'
                            : 'Sample registered. Continue its questionnaire to submit the QC result.')),
                  ),
              ],
            ),
          ),
        ),
        endDrawer: _busy ? null : MyDrawer(),
      ),
    );
  }

  _qcSampleNumberChanged(String qcSampleNumber) {
    if (_locked) return;
    printLongLogMessage("qcSampleNumber is changed to ${qcSampleNumber}");
    setState(() {
      _qcSampleNumberController.text = qcSampleNumber;
    });
  }

  Future<void> _loadProductionLineAssignment(String productionLineName) async {
    if (_locked || productionLineName.trim().isEmpty) return;
    if (_scope != _currentScope) {
      showErrorDialog(context,
          uiText(context, 'The factory or user changed. Reopen QC Sampling.'));
      return;
    }
    setState(() {
      _busy = true;
      _workOrderQCSample = null;
      _productionLineAssignment = null;
      _qcSampleNumberController.clear();
      _localFile.clear();
    });
    showLoading(context);
    bool loading = true;
    Object? error;
    try {
      final assignment = await ProductionLineAssignmentService
          .getProductionLineAssignmentByProductionLineName(
              productionLineName.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
      loading = false;
      if (_scope != _currentScope) return;
      if (assignment == null) {
        showErrorDialog(
            context,
            CWMSLocalizations.of(context).noAssignmentByProductionLine +
                productionLineName);
        return;
      }
      _productionLineAssignment = assignment;
      await _loadWorkOrderQCSample(assignment);
    } catch (e) {
      error = e;
      if (mounted && loading) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted && error != null) {
      showErrorDialog(
          context,
          error is WebAPICallException
              ? error.errMsg()
              : uiText(context,
                  'Could not load the production line. Please try again.'));
    }
  }

  Future<void> _loadWorkOrderQCSample(
      ProductionLineAssignment productionLineAssignment) async {
    try {
      _workOrderQCSample = await WorkOrderQCService
          .getWorkOrderQCSampleByProductionLineAssignment(
              productionLineAssignment.id!);
      if (!mounted || _scope != _currentScope) return;
      if (_workOrderQCSample == null) {
        printLongLogMessage(
            "we can't get qc samples from production line id: ${productionLineAssignment.id}, we will create one");
        _workOrderQCSample = new WorkOrderQCSample.fromProductionLineAssignment(
            _productionLineAssignment!);
        _newWorkOrderQCSample = true;
      } else {
        printLongLogMessage(
            "we get qc samples from production line id: ${productionLineAssignment.id}, we will show this one");

        // show dialog to ask whether the user would like to create a new sample, or change the existing sample
        await showYesNoDialog(
            context,
            CWMSLocalizations.of(context).addOrModify,
            CWMSLocalizations.of(context).whetherAddNewSample, () {
          // the user press Yes, we will keep the current qc sample
          _newWorkOrderQCSample = false;
        }, () {
          // the user press No, we will create a new QC sample
          _workOrderQCSample =
              new WorkOrderQCSample.fromProductionLineAssignment(
                  _productionLineAssignment!);
          _newWorkOrderQCSample = true;
        });
      }

      if (!mounted || _scope != _currentScope) return;
      printLongLogMessage("_newWorkOrderQCSample? $_newWorkOrderQCSample");
      printLongLogMessage(
          "_workOrderQCSample!.number? ${_workOrderQCSample?.number}");
      setState(() {
        _workOrderQCSample;
        _newWorkOrderQCSample;
        _qcSampleNumberController.text = _workOrderQCSample!.number!;
      });
    } on WebAPICallException catch (ex) {
      if (!mounted) return;
      // Failed reads must never turn into a new registration.
      setState(() {
        _workOrderQCSample = null;
        _productionLineAssignment = null;
        _newWorkOrderQCSample = false;
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
      items: _getQCSampleImageUrls().map((imageUrl) {
        return Container(
            child: Center(
                child: Stack(
          children: <Widget>[
            // check if we will need to load from local storage or network
            // _localFile map stores the file name as the key and the file path as the value
            _localFile.containsKey(imageUrl)
                ? Image.file(File(_localFile[imageUrl]!))
                : Image.network(
                    Global.currentServer!.url! +
                        "workorder/qc-samples/images/${Global.currentWarehouse!.id}/${_workOrderQCSample!.productionLineAssignment!.id!}/$imageUrl",
                    fit: BoxFit.cover,
                    width: 1000,
                    headers: {
                        HttpHeaders.authorizationHeader:
                            "Bearer ${Global.currentUser!.token}",
                        "rfCode": Global.lastLoginRFCode!,
                        "warehouseId": Global.currentWarehouse!.id.toString(),
                        "companyId": Global.lastLoginCompanyId.toString()
                      }),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
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
        )));
      }).toList(),
    );
  }

  _removeImage(String imageFileName) {
    if (_locked) return;

    setState(() {
      // if the file is from local , then remove it from the map
      _localFile.remove(imageFileName);

      // remove the file from the list and fix the comma
      _workOrderQCSample!.imageUrls =
          _workOrderQCSample!.imageUrls!.replaceAll(imageFileName, "");
      if (_workOrderQCSample!.imageUrls!.startsWith(",")) {
        _workOrderQCSample!.imageUrls =
            _workOrderQCSample!.imageUrls!.substring(1);
      }
      if (_workOrderQCSample!.imageUrls!.endsWith(",")) {
        _workOrderQCSample!.imageUrls = _workOrderQCSample!.imageUrls!
            .substring(0, _workOrderQCSample!.imageUrls!.length - 1);
      }
    });
  }

  List<String> _getQCSampleImageUrls() {
    List<String> qcSampleImageUrls = [];

    if (_workOrderQCSample != null &&
        (_workOrderQCSample!.imageUrls?.isNotEmpty ?? false)) {
      // we have files from the server, let's add it to the list
      qcSampleImageUrls.addAll(_workOrderQCSample!.imageUrls!.split(","));
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
        onPressed: _locked ||
                _productionLineAssignment == null ||
                _qcSampleNumberController.text.isEmpty
            ? null
            : _addSampleImage,
        child: Text(CWMSLocalizations.of(context).addImage),
      ),
      ElevatedButton(
        onPressed: _locked ||
                _productionLineAssignment == null ||
                _qcSampleNumberController.text.isEmpty
            ? null
            : _takeSamplePhoto,
        child: Text(CWMSLocalizations.of(context).takePhoto),
      ),
      ElevatedButton(
        onPressed: _busy ||
                _questionnaire.registrationUncertain ||
                _productionLineAssignment == null ||
                _qcSampleNumberController.text.isEmpty
            ? null
            : _onConfirm,
        child: Text(uiText(
            context,
            _questionnaire.savedSample == null
                ? 'Register & start questionnaire'
                : 'Continue questionnaire')),
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
    } catch (e) {}
  }

  Future<void> _uploadImageFile(XFile imageFile) async {
    if (_locked || _scope != _currentScope) return;
    setState(() => _busy = true);
    await UpdateActivity.instance.run(() async {
      showLoading(context);
      String? error;
      try {
        final filename = await uploadFile(imageFile,
            'workorder/qc-samples/${_productionLineAssignment!.id}/images');
        if (mounted && _scope == _currentScope) {
          setState(
              () => _localFile.putIfAbsent(filename, () => imageFile.path));
        }
      } catch (e) {
        error = e is WebAPICallException
            ? e.errMsg()
            : 'Could not upload the image. Please try again.';
      } finally {
        if (mounted) {
          Navigator.of(context).pop();
          setState(() => _busy = false);
        }
      }
      if (mounted && error != null)
        showErrorDialog(context, uiErrorText(context, error));
    });
  }

  Future<void> _onConfirm() async {
    if (_busy ||
        _workOrderQCSample == null ||
        _qcSampleNumberController.text.trim().isEmpty) return;
    if (_scope != _currentScope) {
      showErrorDialog(context,
          uiText(context, 'The factory or user changed. Reopen QC Sampling.'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    await UpdateActivity.instance.run(() async {
      bool loading = true;
      showLoading(context);
      try {
        final sample = _workOrderQCSample!;
        sample.number = _qcSampleNumberController.text.trim();
        if (_questionnaire.savedSample == null) {
          if (_newWorkOrderQCSample) {
            final duplicate =
                await WorkOrderQCService.getWorkOrderQCSampleByNumber(
                    sample.number!);
            if (duplicate != null) {
              throw WebAPICallException(
                  CWMSLocalizations.of(context).qcSampleNumberAlreadyExists);
            }
          }
          sample.imageUrls = {
            ...?(sample.imageUrls?.split(',').where((s) => s.isNotEmpty)),
            ..._localFile.keys,
          }.join(',');
        }
        final request = await _questionnaire.open(sample);
        if (!mounted) return;
        Navigator.of(context).pop();
        loading = false;
        if (_scope != _currentScope) return;
        setState(() {
          _workOrderQCSample = _questionnaire.savedSample;
          _newWorkOrderQCSample = false;
          _localFile.clear();
        });
        // The same inspection screen validates explicit answers, exception
        // notes and failure acknowledgement and uses the confirmed backend API.
        final completed = await Navigator.of(context)
            .pushNamed('qc_inspection', arguments: request);
        if (!mounted || _scope != _currentScope) return;
        if (completed == true) {
          showToast(CWMSLocalizations.of(context).qcCompleted);
          setState(() {
            _workOrderQCSample = null;
            _productionLineAssignment = null;
            _qcSampleNumberController.clear();
            _productionLineController.clear();
            _localFile.clear();
            _questionnaire = QCSamplingQuestionnaire(
                isCurrentScope: () => _scope == _currentScope);
            _newWorkOrderQCSample = false;
          });
        }
      } catch (error) {
        if (!mounted) return;
        if (loading) {
          Navigator.of(context).pop();
          loading = false;
        }
        showErrorDialog(
            context,
            uiErrorText(
                context,
                error is WebAPICallException
                    ? error.errMsg()
                    : 'Could not open the questionnaire. The sample is retained; please try again.'));
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    });
  }
}
