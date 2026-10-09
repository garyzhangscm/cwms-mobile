import '../services/defective_machines.dart';
import 'package:cwms_mobile/common/models/reason_code.dart';
import 'package:cwms_mobile/common/models/reason_code_type.dart';
import 'package:cwms_mobile/common/services/reason_code.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/models/item_unit_of_measure.dart';
import 'package:cwms_mobile/inventory/models/lpn_capture_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/models/cwms_http_exception.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_kpi_transaction_action.dart';
import 'package:cwms_mobile/workorder/models/work_order_line_consume_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_produced_inventory.dart';
import 'package:cwms_mobile/workorder/services/bill_of_material.dart';
import 'package:cwms_mobile/workorder/services/work_order.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

import '../../shared/global.dart';
import '../../shared/workspace_ui.dart';
import '../models/defective_production.dart';
import '../../shared/models/printing_strategy.dart';

class WorkOrderProduceInventoryPage extends StatefulWidget {
  WorkOrderProduceInventoryPage(
      {Key? key,
      this.defective = false,
      this.statusLoader,
      this.reasonLoader,
      this.autoPromptReason = true})
      : super(key: key);
  final bool defective;
  final bool autoPromptReason;
  final Future<List<InventoryStatus>> Function()? statusLoader;
  final Future<List<ReasonCode>> Function()? reasonLoader;

  @override
  State<StatefulWidget> createState() => _WorkOrderProduceInventoryPageState();
}

class _WorkOrderProduceInventoryPageState
    extends State<WorkOrderProduceInventoryPage> {
  String? _statusError;
  String? _reasonError;
  bool _reasonsLoaded = false;
  bool _reasonPromptShown = false;
  String get _pageTitle => widget.defective
      ? (workspaceIsChinese(context) ? '废品报产' : 'Defective')
      : CWMSLocalizations.of(context).workOrderProduce;

  // input batch id

  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();

  WorkOrder? _currentWorkOrder;
  ProductionLine? _currentProductionLine;

  List<InventoryStatus> _validInventoryStatus = [];
  InventoryStatus? _selectedInventoryStatus;
  ItemPackageType? _selectedItemPackageType;
  ItemUnitOfMeasure? _selectedItemUnitOfMeasure;
  ProgressDialog? _progressDialog;

  BillOfMaterial? _matchedBillOfMaterial;
  FocusNode lpnFocusNode = FocusNode();
  FocusNode _lpnControllerFocusNode = FocusNode();
  FocusNode quantityFocusNode = FocusNode();
  bool _readyToConfirm = true; // whether we can confirm the produced inventory

  List<ReasonCode> _validReasonCodes = [];
  ReasonCode? _selectedReasonCode;

  // we will force the user to receive by LPN quantity
  bool _forceLPNReceiving = true;

  @override
  void initState() {
    super.initState();

    _currentWorkOrder = new WorkOrder();
    _selectedInventoryStatus = null;
    _selectedItemPackageType = null;

    _forceLPNReceiving = !widget.defective;
    _loadStatuses();
    _loadReasons();

    if (!widget.defective || !widget.autoPromptReason) {
      quantityFocusNode.requestFocus();
    }
    // default quantity to 1
    _quantityController.text = widget.defective ? "" : "1";
  }

  Future<void> _loadStatuses() async {
    try {
      final values = await (widget.statusLoader ??
          InventoryStatusService.getAllInventoryStatus)();
      if (!mounted) return;
      setState(() {
        _validInventoryStatus = values;
        _selectedInventoryStatus = widget.defective
            ? findDefectiveInventoryStatus(values)
            : InventoryStatusService.getDefaultInventoryStatusForNewInventory(
                values);
        _statusError = widget.defective && _selectedInventoryStatus == null
            ? (workspaceIsChinese(context)
                ? '未找到唯一的 DMG / Damaged 状态，请检查仓库配置。'
                : 'A unique DMG / Damaged status is required. Check warehouse configuration.')
            : null;
      });
      _maybePromptDefectiveReason();
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusError = workspaceIsChinese(context)
          ? '库存状态加载失败，请重试。'
          : 'Unable to load inventory statuses. Retry.');
    }
  }

  Future<void> _loadReasons() async {
    try {
      final values = await (widget.reasonLoader ??
          () => ReasonCodeService.getReasonCodes(
              ReasonCodeType.Inventory_Status.name))();
      if (!mounted) return;
      setState(() {
        _validReasonCodes =
            values.where((reason) => reason.id != null).toList();
        _reasonsLoaded = true;
        _selectedReasonCode = null;
        _reasonError = _validReasonCodes.isEmpty
            ? (workspaceIsChinese(context)
                ? '暂无可用原因，请在 Master Data 中配置。'
                : 'No reasons available. Configure them in Master Data.')
            : null;
      });
      _maybePromptDefectiveReason();
    } catch (_) {
      if (!mounted) return;
      setState(() => _reasonError = workspaceIsChinese(context)
          ? '原因加载失败，请重试。'
          : 'Unable to load reasons. Retry.');
    }
  }

  void _maybePromptDefectiveReason() {
    if (!widget.defective ||
        !widget.autoPromptReason ||
        _reasonPromptShown ||
        !_reasonsLoaded ||
        _selectedInventoryStatus == null) return;
    _reasonPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chooseDefectiveReason();
    });
  }

  Future<void> _chooseDefectiveReason() async {
    final zh = workspaceIsChinese(context);
    FocusScope.of(context).unfocus();
    final reason = await showDialog<ReasonCode>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(zh ? '选择废品原因' : 'Choose defective reason'),
              content: SizedBox(
                  width: 360,
                  child: _validReasonCodes.isEmpty
                      ? Text(_reasonError ??
                          (zh
                              ? '暂无可用原因，请重试。'
                              : 'No reasons available. Please retry.'))
                      : ListView(shrinkWrap: true, children: [
                          for (final reason in _validReasonCodes)
                            ListTile(
                                title: Text(reason.name ?? ''),
                                subtitle: (reason.description ?? '').isEmpty
                                    ? null
                                    : Text(reason.description!),
                                selected: reason == _selectedReasonCode,
                                onTap: () => Navigator.pop(context, reason)),
                        ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(zh ? '关闭' : 'Close'))
              ],
            ));
    if (!mounted) return;
    if (reason != null) setState(() => _selectedReasonCode = reason);
    quantityFocusNode.requestFocus();
  }

  Widget _buildDefectiveStatus() => buildTwoSectionInputRow(
      CWMSLocalizations.of(context).inventoryStatus,
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            _selectedInventoryStatus == null
                ? 'DMG / Damaged'
                : '${_selectedInventoryStatus!.name} · ${_selectedInventoryStatus!.description ?? "Damaged"}',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
        if (_statusError != null)
          Text(_statusError!, style: const TextStyle(color: Colors.red)),
        if (_selectedInventoryStatus == null)
          TextButton(
              onPressed: _loadStatuses,
              child: Text(workspaceIsChinese(context) ? '重试' : 'Retry')),
      ]));

  Widget _buildDefectiveQuantity() {
    final units = _getItemUnitOfMeasures();
    if (_selectedItemUnitOfMeasure == null && units.isNotEmpty) {
      _selectedItemUnitOfMeasure = units.first.value;
    }
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context).quantity,
        Row(children: [
          Expanded(
              child: TextFormField(
            key: const Key('defective-quantity'),
            controller: _quantityController,
            focusNode: quantityFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
                hintText: workspaceIsChinese(context)
                    ? '废品数量'
                    : 'Defective quantity'),
            validator: (value) => (int.tryParse(value ?? '') ?? 0) > 0
                ? null
                : (workspaceIsChinese(context)
                    ? '请输入大于零的数量'
                    : 'Enter a quantity greater than zero'),
          )),
          const SizedBox(width: 12),
          SizedBox(
              width: 90,
              child: DropdownButton<ItemUnitOfMeasure>(
                key: const Key('defective-unit'),
                isExpanded: true,
                items: units,
                value: _selectedItemUnitOfMeasure,
                hint: Text(CWMSLocalizations.of(context).pleaseSelect),
                onChanged: (value) =>
                    setState(() => _selectedItemUnitOfMeasure = value),
              )),
        ]));
  }

  final _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Map arguments = ModalRoute.of(context)?.settings.arguments as Map;
    _currentWorkOrder = arguments['workOrder'];

    _currentProductionLine = arguments['productionLine'];

    _loadMatchedBillOfMaterial();
  }

  _loadMatchedBillOfMaterial() {
    if (_matchedBillOfMaterial != null) {
      return;
    } else if (_currentWorkOrder?.consumeByBom != null) {
      _matchedBillOfMaterial = _currentWorkOrder?.consumeByBom;
    } else {
      BillOfMaterialService.findMatchedBillOfMaterial(_currentWorkOrder!)
          .then((value) => _matchedBillOfMaterial = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          //autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: SingleChildScrollView(
              child: Column(
            children: <Widget>[
              buildTwoSectionInformationRowWithWidget(
                  CWMSLocalizations.of(context).workOrderNumber,
                  _getWorkOrderDisplayWidget(context, _currentWorkOrder!)),
              buildTwoSectionInformationRowWithWidget(
                  CWMSLocalizations.of(context).item,
                  _getItemDisplayWidget(context, _currentWorkOrder!.item!)),
/**
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context)!.expectedQuantity,
                _currentWorkOrder.expectedQuantity.toString()),
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context)!.billOfMaterial,
                  _matchedBillOfMaterial == null ? "" : _matchedBillOfMaterial.number),
              // show the matched BOM
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context)!.producedQuantity,
                  _currentWorkOrder.producedQuantity.toString()),
    **/
              // Allow the user to choose item package type
              buildTwoSectionInputRow(
                  CWMSLocalizations.of(context).itemPackageType,
                  DropdownButton(
                    hint: Text(CWMSLocalizations.of(context).pleaseSelect),
                    items: _getItemPackageTypeItems(),
                    value: _selectedItemPackageType,
                    elevation: 1,
                    isExpanded: true,
                    icon: Icon(
                      Icons.list,
                      size: 20,
                    ),
                    onChanged: (ItemPackageType? value) {
                      //下拉菜单item点击之后的回调
                      setState(() {
                        _selectedItemPackageType = value;
                      });
                    },
                  )),
              // Allow the user to choose inventory status
              widget.defective
                  ? _buildDefectiveStatus()
                  : buildTwoSectionInputRow(
                      CWMSLocalizations.of(context).inventoryStatus,
                      DropdownButton(
                        hint: Text(CWMSLocalizations.of(context).pleaseSelect),
                        items: _getInventoryStatusItems(),
                        value: _selectedInventoryStatus,
                        elevation: 1,
                        isExpanded: true,
                        icon: Icon(
                          Icons.list,
                          size: 20,
                        ),
                        onChanged: (InventoryStatus? value) {
                          //下拉菜单item点击之后的回调
                          setState(() {
                            _selectedInventoryStatus = value;
                          });
                        },
                      )),
              _selectedInventoryStatus != null &&
                      (widget.defective ||
                          _selectedInventoryStatus
                                  ?.reasonRequiredWhenProducing ==
                              true ||
                          _selectedInventoryStatus
                                  ?.reasonOptionalWhenProducing ==
                              true)
                  ? _buildReasonCodeDropdown()
                  : Container(),
              /***
               *
                  buildTwoSectionInputRow(
                  CWMSLocalizations.of(context)!.producingQuantity,
                  Focus(
                  child:
                  TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _quantityController,
                  focusNode: quantityFocusNode,
                  // 校验ITEM NUMBER（不能为空）
                  validator: (v) {
                  if (v.trim().isEmpty) {
                  return "please type in quantity";
                  }
                  return null;
                  }),
                  )
                  ),
               */
              widget.defective
                  ? _buildDefectiveQuantity()
                  : Container(
                      color: _forceLPNReceiving
                          ? Colors.black26
                          : Colors.transparent,
                      child: buildFourSectionRow(
                          Checkbox(
                            value: !_forceLPNReceiving,
                            onChanged: (bool? value) {
                              setState(() {
                                _forceLPNReceiving = (value == false);
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                                CWMSLocalizations.of(context).quantity + ": ",
                                textAlign: TextAlign.left),
                          ),
                          _forceLPNReceiving
                              ? SizedBox(
                                  width: 20,
                                  child: Text("1", textAlign: TextAlign.left))
                              : SizedBox(
                                  height: 20,
                                  width: 110,
                                  child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      controller: _quantityController,
                                      enabled:
                                          _forceLPNReceiving ? false : true,
                                      textInputAction: TextInputAction.next,
                                      autofocus:
                                          _forceLPNReceiving ? false : true,
                                      focusNode: quantityFocusNode,
                                      onFieldSubmitted: (v) {
                                        _lpnControllerFocusNode.requestFocus();
                                      },
                                      decoration: InputDecoration(
                                        isDense: true,
                                        fillColor: _forceLPNReceiving
                                            ? Colors.black12
                                            : Colors.white,
                                        filled: true,
                                      ),
                                      // 校验ITEM NUMBER（不能为空）
                                      validator: (v) {
                                        if (v!.trim().isEmpty) {
                                          return "please type in quantity";
                                        }
                                        return null;
                                      }),
                                ),
                          _getItemUnitOfMeasures().isEmpty
                              ? Container()
                              : _forceLPNReceiving
                                  ? SizedBox(
                                      width: 60,
                                      child: Text(_getLPNUOMName() ?? "",
                                          textAlign: TextAlign.left))
                                  : SizedBox(
                                      height: 38,
                                      width: 90,
                                      child: DropdownButton(
                                        hint: Text(CWMSLocalizations.of(context)
                                            .pleaseSelect),
                                        items: _getItemUnitOfMeasures(),
                                        value: _selectedItemUnitOfMeasure,
                                        elevation: 1,
                                        isExpanded: true,
                                        icon: Icon(
                                          Icons.list,
                                          size: 20,
                                        ),
                                        underline: Container(
                                          height: 0,
                                          color: Colors.deepPurpleAccent,
                                        ),
                                        onChanged: (ItemUnitOfMeasure? value) {
                                          //下拉菜单item点击之后的回调
                                          setState(() {
                                            _selectedItemUnitOfMeasure = value;
                                          });
                                        },
                                      )))),
              buildTwoSectionInputRow(
                CWMSLocalizations.of(context).lpn,
                Focus(
                    child: RawKeyboardListener(
                  focusNode: lpnFocusNode,
                  onKey: (event) {
                    if (event.isKeyPressed(LogicalKeyboardKey.enter) &&
                        _readyToConfirm) {
                      // Do something

                      setState(() {
                        // disable the confirm button
                        _readyToConfirm = false;
                      });

                      _enterOnLPNController(10);
                    }
                  },
                  child: SystemControllerNumberTextBox(
                    type: "lpn",
                    controller: _lpnController,
                    focusNode: _lpnControllerFocusNode,
                    readOnly: false,
                    showKeyboard: false,
                    validator: (v) {
                      final enteredQuantity =
                          int.tryParse(_quantityController.text);
                      final unitQuantity = _selectedItemUnitOfMeasure?.quantity;
                      if ((v ?? '').trim().isEmpty &&
                          enteredQuantity != null &&
                          enteredQuantity > 0 &&
                          unitQuantity != null &&
                          _getRequiredLPNCount(
                                  enteredQuantity * unitQuantity) ==
                              1) {
                        return CWMSLocalizations.of(context)
                            .missingField(CWMSLocalizations.of(context).lpn);
                      }
                      return null;
                    },
                  ),
                )),
              ),

              _buildButtons(context)
            ],
          )),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return buildSingleButtonRow(
        context,
        ElevatedButton(
          onPressed: !_readyToConfirm || _selectedInventoryStatus == null
              ? null
              : () {
                  _readyToConfirm = false;

                  if (_formKey.currentState!.validate()) {
                    _onWorkOrderProduceConfirm();
/**
            print("1. _readyToConfirm? $_readyToConfirm");
            if (_readyToConfirm == true) {
              _readyToConfirm = false;
              print("1. form validation passed");
              print("1. set _readyToConfirm to false");
              _onWorkOrderProduceConfirm();
            }
    **/
                  } else {
                    setState(() => _readyToConfirm = true);
                  }
                },
          child: Text(widget.defective
              ? (workspaceIsChinese(context) ? '确认废品报产' : 'Confirm Defective')
              : CWMSLocalizations.of(context).confirm),
        ));
  }

  Widget _buildReasonCodeDropdown() {
    // Allow the user to choose inventory status
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context).reason,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.defective)
            OutlinedButton.icon(
                key: const Key('defective-reason-picker'),
                onPressed: _chooseDefectiveReason,
                icon: const Icon(Icons.list_alt_rounded),
                label: Text(_selectedReasonCode?.name ??
                    (workspaceIsChinese(context)
                        ? '选择废品原因'
                        : 'Choose defective reason')))
          else
            DropdownButton(
              hint: Text(CWMSLocalizations.of(context).pleaseSelect),
              items: _getReasonCodeItems(),
              value: _selectedReasonCode,
              elevation: 1,
              isExpanded: true,
              icon: Icon(
                Icons.list,
                size: 20,
              ),
              onChanged: (ReasonCode? value) {
                //下拉菜单item点击之后的回调
                setState(() {
                  _selectedReasonCode = value;
                });
              },
            ),
          if (_reasonError != null)
            Text(_reasonError!, style: const TextStyle(color: Colors.orange)),
          if (_reasonError != null)
            TextButton(
                onPressed: _loadReasons,
                child: Text(workspaceIsChinese(context) ? '重试' : 'Retry')),
        ]));
  }

  String? _getLPNUOMName() {
    ItemUnitOfMeasure? lpnUOM = _getLPNUOM();
    if (lpnUOM == null) {
      return "";
    }
    return lpnUOM.unitOfMeasure?.name;
  }

  ItemUnitOfMeasure? _getLPNUOM() {
    if (_selectedItemPackageType == null ||
        _selectedItemPackageType?.itemUnitOfMeasures == null ||
        _selectedItemPackageType?.itemUnitOfMeasures.length == 0 ||
        _selectedItemPackageType?.trackingLpnUOM == null) {
      return null;
    }
    return _selectedItemPackageType?.trackingLpnUOM;
  }

  List<DropdownMenuItem<ItemUnitOfMeasure>> _getItemUnitOfMeasures() {
    List<DropdownMenuItem<ItemUnitOfMeasure>> items = [];

    if (_selectedItemPackageType == null ||
        _selectedItemPackageType?.itemUnitOfMeasures == null ||
        _selectedItemPackageType?.itemUnitOfMeasures.length == 0) {
      // if the user has not selected any item package type yet
      // return nothing
      return items;
    }

    for (int i = 0;
        i < _selectedItemPackageType!.itemUnitOfMeasures.length;
        i++) {
      items.add(DropdownMenuItem(
        value: _selectedItemPackageType?.itemUnitOfMeasures[i],
        child: Text(_selectedItemPackageType
                ?.itemUnitOfMeasures[i].unitOfMeasure?.name ??
            ""),
      ));
    }

    // we may have _selectedItemUnitOfMeasure setup by previous item package type.
    // or manually by user. If it is setup by the user, then we won't refresh it
    // otherwise, we will reload the default receiving uom
    // if _selectedItemPackageType.itemUnitOfMeasures doesn't containers the _selectedItemUnitOfMeasure
    // then we know that we just changed the item package type or item, so we will need
    // to refresh the _selectedItemUnitOfMeasure to the default inbound receiving uom as well
    if (_selectedItemUnitOfMeasure == null ||
        !_selectedItemPackageType!.itemUnitOfMeasures.any((element) =>
            element.hashCode == _selectedItemUnitOfMeasure.hashCode)) {
      // if the user has not select any item unit of measure yet, then
      // default the value to the one marked as 'default for inbound receiving'

      // printLongLogMessage("_currentWorkOrder.item: ${_currentWorkOrder.item.toJson()}");
      // printLongLogMessage("_selectedItemPackageType: ${_selectedItemPackageType.toJson()}");
      _selectedItemUnitOfMeasure = (widget.defective
              ? findDefectivePiecesUnit(
                  _selectedItemPackageType!.itemUnitOfMeasures)
              : null) ??
          _selectedItemPackageType?.itemUnitOfMeasures.firstWhereOrNull(
              (element) =>
                  element.id ==
                  _selectedItemPackageType?.defaultWorkOrderReceivingUOM?.id);
    }

    return items;
  }

  Widget _getItemDisplayWidget(BuildContext context, Item item) {
    return new RichText(
        text: new TextSpan(
      text: item.name,
      style: new TextStyle(color: Colors.blue),
      recognizer: new TapGestureRecognizer()
        ..onTap = () {
          showInformationDialog(
              context,
              item.name ?? "",
              Column(children: <Widget>[
                buildTwoSectionInformationRow(
                    CWMSLocalizations.of(context).item,
                    _currentWorkOrder?.item?.name ?? ""),
                buildTwoSectionInformationRow(
                    CWMSLocalizations.of(context).item,
                    _currentWorkOrder?.item?.description ?? ""),
              ]),
              verticalPadding: 175.0,
              horizontalPadding: 50.0);
        },
    ));
  }

  Widget _getWorkOrderDisplayWidget(BuildContext context, WorkOrder workOrder) {
    return new RichText(
        text: new TextSpan(
      text: workOrder.number,
      style: new TextStyle(color: Colors.blue),
      recognizer: new TapGestureRecognizer()
        ..onTap = () {
          showInformationDialog(
              context,
              workOrder.number ?? "",
              Column(children: <Widget>[
                buildTwoSectionInformationRow(
                    CWMSLocalizations.of(context).expectedQuantity,
                    workOrder.expectedQuantity.toString()),
                buildTwoSectionInformationRow(
                    CWMSLocalizations.of(context).billOfMaterial,
                    _matchedBillOfMaterial?.number ?? ""),
                // show the matched BOM
                buildTwoSectionInformationRow(
                    CWMSLocalizations.of(context).producedQuantity,
                    workOrder.producedQuantity.toString()),
              ]),
              verticalPadding: 175.0,
              horizontalPadding: 50.0);
        },
    ));
  }

  List<DropdownMenuItem<ReasonCode>> _getReasonCodeItems() {
    List<DropdownMenuItem<ReasonCode>> items = [];
    if (_validReasonCodes.length == 0) {
      _selectedReasonCode = null;
      return items;
    }

    // _selectedInventoryStatus = _validInventoryStatus[0];
    for (int i = 0; i < _validReasonCodes.length; i++) {
      items.add(DropdownMenuItem(
        value: _validReasonCodes[i],
        child: Text(_validReasonCodes[i].name ?? ""),
      ));
    }
    return items;
  }

  List<DropdownMenuItem<InventoryStatus>> _getInventoryStatusItems() {
    List<DropdownMenuItem<InventoryStatus>> items = [];
    if (widget.defective) return items;
    if (_validInventoryStatus.length == 0) {
      return items;
    }

    // _selectedInventoryStatus = _validInventoryStatus[0];
    for (int i = 0; i < _validInventoryStatus.length; i++) {
      items.add(DropdownMenuItem(
        value: _validInventoryStatus[i],
        child: Text(_validInventoryStatus[i].description ?? ""),
      ));
    }

    if (_validInventoryStatus.length == 1 || _selectedInventoryStatus == null) {
      // if we only have one valid inventory status, then
      // default the selection to it
      // if the user has not select any inventdry status yet, then
      // default the value to the first option as well
      _selectedInventoryStatus = _validInventoryStatus[0];
    }
    return items;
  }

  List<DropdownMenuItem<ItemPackageType>> _getItemPackageTypeItems() {
    List<DropdownMenuItem<ItemPackageType>> items = [];

    if ((_currentWorkOrder?.item?.itemPackageTypes.length ?? 0) > 0) {
      // _selectedItemPackageType = _currentWorkOrder.item.itemPackageTypes[0];

      for (int i = 0;
          i < _currentWorkOrder!.item!.itemPackageTypes.length;
          i++) {
        // printLongLogMessage("_currentWorkOrder.item.itemPackageTypes[i]: ${_currentWorkOrder.item.itemPackageTypes[i].toJson()}");
        items.add(DropdownMenuItem(
          value: _currentWorkOrder!.item!.itemPackageTypes[i],
          child: Text(
              _currentWorkOrder!.item!.itemPackageTypes[i].description ?? ""),
        ));
      }
      if (_currentWorkOrder!.item!.itemPackageTypes.length == 1 ||
          _selectedItemPackageType == null) {
        // if we only have one item package type for this item, then
        // default the selection to it
        // if the user has not select any item package type yet, then
        // default the value to the first option as well
        _selectedItemPackageType = _currentWorkOrder!.item!.itemPackageTypes[0];
      }
    }
    return items;
  }

  Future<void> _onWorkOrderProduceWithKPI(
      WorkOrder workOrder, int confirmedQuantity, String lpn) async {
    showLoading(context);

    WorkOrderProduceTransaction workOrderProduceTransaction =
        await generateWorkOrderProduceTransaction(
            _lpnController.text,
            _selectedInventoryStatus!,
            _selectedItemPackageType!,
            int.parse(_quantityController.text),
            _getReasonCodeForProducingInventory());

    Navigator.of(context).pop();
    // flow to the KPI capture page

    final result = await Navigator.of(context).pushNamed(
        "work_order_produce_kpi",
        arguments: workOrderProduceTransaction);

    if (result == null) {
      // the user press Return, let's do nothing

      return null;
    }

    if ((result as WorkOrderKPITransactionAction) ==
        WorkOrderKPITransactionAction.CANCELLED) {
      // THE USER cancelled the KPI transaction, let's do nothing and wait the user
      // to either start a new KPI capture transaction, or confirm without KPI
      return null;
    } else {
      // The user confirmed the whole produce transaction with KPI, let's
      // clear the page

      _lpnController.clear();
      // default the quantity to 1
      _quantityController.text = "1";
    }
  }

  void _enterOnLPNController(int tryTime) async {
    // we may come here when the user scan / press
    // enter in the LPN controller. In either case, we will need to make sure
    // the lpn doesn't have focus before we start confirm

    if (tryTime <= 0) {
      // do nothing as we run out of try time

      setState(() {
        // enable the confirm button
        _readyToConfirm = true;
      });
      return;
    }

    if (lpnFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
          () => _enterOnLPNController(tryTime - 1));

      return;
    }
    // if we are here, then it means we already have the full LPN
    // due to how  flutter handle the input, we will get the enter
    // action listner handler fired before the input characters are
    // full assigned to the lpnController.

    // printLongLogMessage("lpn controller lost focus, its value is ${_lpnController.text}");
    if (_formKey.currentState!.validate()) {
      // set ready to confirm to fail so other trigger point
      // won't process the receiving request
      // the issue happens when we have 2 trigger point to process
      // the receiving request
      // 1. LPN blur
      // 2. confirm button click
      // so when we blur the LPN controller by clicking the confirm button, the
      // _onRecevingConfirm function will be fired twice
      _readyToConfirm = false;
      _onWorkOrderProduceConfirm();
    }

    setState(() {
      // enable the confirm button
      _readyToConfirm = true;
    });
  }

  void _onWorkOrderProduceConfirm() async {
    if (_selectedInventoryStatus == null ||
        (widget.defective &&
            _selectedInventoryStatus !=
                findDefectiveInventoryStatus(_validInventoryStatus))) {
      _readyToConfirm = true;
      showErrorDialog(
          context, _statusError ?? 'Inventory status is not ready.');
      return;
    }
    if (!_forceLPNReceiving &&
        (_selectedItemUnitOfMeasure?.quantity == null ||
            _selectedItemUnitOfMeasure!.quantity! <= 0)) {
      _readyToConfirm = true;
      showErrorDialog(context,
          workspaceIsChinese(context) ? '请选择有效单位' : 'Select a valid unit.');
      return;
    }

    // the user start to confirm receiving from the work order
    // let's calculate the quantity first

    int inventoryQuantity = 0;

    if (_forceLPNReceiving) {
      // if we force the user to receiving by LPN, then default the
      // receiving quantity to one LPN UOM's quantity
      ItemUnitOfMeasure? lpnUOM = _getLPNUOM();
      if (lpnUOM == null) {
        showErrorDialog(context,
            "LPN UOM is not setup for the item. please specify the quantity");
        // reset ready to confirm flag so the operators can confirm the produce again
        _readyToConfirm = true;
        return;
      }
      inventoryQuantity = lpnUOM.quantity!;
    } else {
      inventoryQuantity = int.parse(_quantityController.text) *
          _selectedItemUnitOfMeasure!.quantity!;
    }

    // if the inventory status requires reason, then make sure the user input one
    if (_selectedInventoryStatus != null &&
        _selectedInventoryStatus?.reasonRequiredWhenProducing == true &&
        _selectedReasonCode == null) {
      showErrorDialog(
          context,
          "Reason for the inventory " +
              (_selectedInventoryStatus?.name ?? "") +
              " is required, please choose the reason!");
      // reset ready to confirm flag so the operators can confirm the produce again
      _readyToConfirm = true;
      return;
    }

    try {
      _confirmWorkOrderProduce(
          _currentWorkOrder!, inventoryQuantity, _lpnController.text);
    } finally {
      _lpnControllerFocusNode.requestFocus();
      // reset ready to confirm flag so the operators can confirm the produce again
      _readyToConfirm = true;
    }
  }

  void _confirmWorkOrderProduce(
      WorkOrder workOrder, int inventoryQuantity, String lpn) async {
    if (lpn.isNotEmpty) {
      showLoading(context);
      // first of all, validate the LPN
      try {
        String errorMessage = await InventoryService.validateNewLpn(lpn);
        if (errorMessage.isNotEmpty) {
          Navigator.of(context).pop();
          showErrorDialog(context, errorMessage);

          return;
        }
      } on CWMSHttpException catch (ex) {
        Navigator.of(context).pop();
        showErrorDialog(context, "${ex.code} - ${ex.message}");
        return;
      }
      Navigator.of(context).pop();
    }

    int lpnCount = _getRequiredLPNCount(inventoryQuantity);

    // see if we are receiving single lpn or multiple lpn
    if (lpnCount == 1) {
      // if we haven't specify the UOM that we will need to track the LPN
      // or we are receiving at less than LPN uom level,
      // or we are receiving at LPN uom level but we only receive 1 LPN, then proceed with single LPN

      // before we will receive one LPN, we will verify if the quantity exceed
      // the LPN's standard quantity. If so, then we will warn the user to make sure
      // they don't accidentally input a wrong number
      bool validateLPNQuantity =
          await _validateQuantityForSingleLPN(inventoryQuantity);
      if (validateLPNQuantity) {
        _onWorkOrderProduceSingleLPNConfirm(workOrder, inventoryQuantity, lpn);
      } else {
        // quantity is not valid(normally it means we only need one LPN but the total
        // quantity exceed the standard LPN's quantity
        _readyToConfirm = true;
        return;
      }
    } else {
      _onWorkOrderProduceMiltipleLPNConfirm(workOrder, inventoryQuantity, lpn);
    }
  }

  Future<bool> _validateQuantityForSingleLPN(int inventoryQuantity) async {
    if (_selectedItemPackageType?.trackingLpnUOM == null) {
      // the tracking LPN UOM is not defined for this item package type
      // so no matter what's the quantity the user input, we will always
      // take it as PASS
      return true;
    }
    // if the quantity is greater than the lpn uom's quantity, warning
    // the user to make sure it is not a typo. Since we already define the LPN
    // uom, normally the quantity of the single LPN won't exceed the standard
    // lpn UOM's quantity
    if (inventoryQuantity >
        _selectedItemPackageType!.trackingLpnUOM!.quantity!) {
      // bool continueWithExceedQuantity = await showYesNoDialog(context, "lpn validation", "lpn quantity exceed the standard quantity, continue?");
      bool continueWithExceedQuantity = false;
      await showYesNoDialog(
        context,
        CWMSLocalizations.of(context).lpnQuantityExceedWarningTitle,
        CWMSLocalizations.of(context).lpnQuantityExceedWarningMessage,
        () => continueWithExceedQuantity = true,
        () => continueWithExceedQuantity = false,
      );

      return continueWithExceedQuantity;
    }
    // current quantity doesn't exceed the standard lpn quantity, good to go
    return true;
  }

  Future<void> _ensureDefectiveAssignment() async {
    if (!widget.defective) return;
    final line = _currentProductionLine;
    if (line?.id == null || _currentWorkOrder?.id == null) {
      throw WebAPICallException('Select a valid machine and work order.');
    }
    bool valid;
    try {
      valid = await DefectiveMachineService.isStillAssigned(
          _currentWorkOrder!, line!);
    } catch (_) {
      throw WebAPICallException(workspaceIsChinese(context)
          ? '无法验证机器分配，请重试。'
          : 'Unable to verify machine assignment. Please retry.');
    }
    if (!mounted || !valid) {
      throw WebAPICallException(workspaceIsChinese(context)
          ? '工单已结束或不再分配于此机器，请返回重新选择。'
          : 'The work order has ended or is no longer assigned to this machine. Return and select again.');
    }
  }

  void _onWorkOrderProduceSingleLPNConfirm(
      WorkOrder workOrder, int inventoryQuantity, String lpn) async {
    showLoading(context);

    // make sure the user input a valid LPN
    try {
      String errorMessage = await InventoryService.validateNewLpn(lpn);
      if (errorMessage.isNotEmpty) {
        Navigator.of(context).pop();
        showErrorDialog(context, errorMessage);
        _lpnControllerFocusNode.requestFocus();
        return;
      }
    } on CWMSHttpException catch (ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, "${ex.code} - ${ex.message}");
      _lpnControllerFocusNode.requestFocus();
      return;
    }

    WorkOrderProduceTransaction workOrderProduceTransaction =
        generateWorkOrderProduceTransaction(
            lpn,
            _selectedInventoryStatus!,
            _selectedItemPackageType!,
            inventoryQuantity,
            _getReasonCodeForProducingInventory());

    try {
      await _ensureDefectiveAssignment();
      if (!mounted) return;
      await WorkOrderService.saveWorkOrderProduceTransaction(
          workOrderProduceTransaction);
    } on WebAPICallException catch (ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      _lpnControllerFocusNode.requestFocus();
      return;
    }

    if (Global.warehouseConfiguration.newLPNPrintLabelAtProducingFlag == true &&
        Global.warehouseConfiguration.printingStrategy ==
            PrintingStrategy.LOCAL_PRINTER_SERVER_DATA) {
      // we will print the LPN label
      // we will download the LPN label as PDF and then print from the printer that attached to the RF
      _printLPNLabel(lpn);
    }

    Navigator.of(context).pop();
    _refreshScreenAfterProducing();
  }

  void _printLPNLabel(String lpn) {
    // get the default printer that attached to the RF

    if (Global.getLastLoginRF().printerName == "") {
      return;
    }
    // download the LPN label
    InventoryService.autoPrintLPNLabelByLpn(context, lpn);
  }

  ReasonCode? _getReasonCodeForProducingInventory() {
    if (_selectedInventoryStatus != null &&
        (widget.defective ||
            _selectedInventoryStatus?.reasonRequiredWhenProducing == true ||
            _selectedInventoryStatus?.reasonOptionalWhenProducing == true)) {
      return _selectedReasonCode;
    } else {
      return null;
    }
  }

  _onWorkOrderProduceMiltipleLPNConfirm(
      WorkOrder workOrder, int inventoryQuantity, String lpn) async {
    // let's see how many LPNs we will need
    int lpnCount = _getRequiredLPNCount(inventoryQuantity);

    if (lpnCount == 1) {
      // before we will receive one LPN, we will verify if the quantity exceed
      // the LPN's standard quantity. If so, then we will warn the user to make sure
      // they don't accidentally input a wrong number
      bool validateLPNQuantity =
          await _validateQuantityForSingleLPN(inventoryQuantity);
      if (validateLPNQuantity) {
        _onWorkOrderProduceSingleLPNConfirm(workOrder, inventoryQuantity, lpn);
      } else {
        // quantity is not valid(normally it means we only need one LPN but the total
        // quantity exceed the standard LPN's quantity
        _readyToConfirm = true;
        return;
      }
    } else if (lpnCount > 1) {
      // we will need multiple LPNs, let's prompt a dialog to capture the lpns

      Set<String> capturedLpn = new Set();
      // if the user already scna in a lpn, then add it
      if (lpn.isNotEmpty) {
        capturedLpn.add(lpn);
      }
      LpnCaptureRequest lpnCaptureRequest = new LpnCaptureRequest.withData(
          _currentWorkOrder!.item!,
          _selectedItemPackageType!,
          _selectedItemPackageType!.trackingLpnUOM!,
          lpnCount,
          capturedLpn,
          true);

      final result = await Navigator.of(context)
          .pushNamed("lpn_capture", arguments: lpnCaptureRequest);

      // printLongLogMessage("returned from the capture lpn form. result == null? : ${result == null}");
      if (result == null) {
        // the user press Return, let's do nothing

        return null;
      }

      lpnCaptureRequest = result as LpnCaptureRequest;

      if (lpnCaptureRequest.result == false) {
        // this happens when the user click 'cancel' button
        return null;
      }
      // receive with multiple LPNs
      _produceMultipleLpns(lpnCaptureRequest);
    }
  }

  void _produceMultipleLpns(LpnCaptureRequest lpnCaptureRequest) async {
    showLoading(context);
    // make sure the user input a valid LPN
    try {
      Iterator<String> lpnIterator = lpnCaptureRequest.capturedLpn.iterator;
      while (lpnIterator.moveNext()) {
        String errorMessage =
            await InventoryService.validateNewLpn(lpnIterator.current);
        if (errorMessage.isNotEmpty) {
          Navigator.of(context).pop();
          showErrorDialog(context, errorMessage);
          return;
        }
      }
    } on CWMSHttpException catch (ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, "${ex.code} - ${ex.message}");
      return;
    }
    try {
      await _ensureDefectiveAssignment();
      if (!mounted) return;
      // start receive LPNs one by one and show the progress bar
      _setupProgressBar();
      Iterator<String> lpnIterator = lpnCaptureRequest.capturedLpn.iterator;
      int totalLPNCount = lpnCaptureRequest.capturedLpn.length;
      int currentLPNIndex = 1;

      while (lpnIterator.moveNext()) {
        String lpn = lpnIterator.current;
        double progress = currentLPNIndex * 100 / totalLPNCount;
        String message = CWMSLocalizations.of(context).receivingCurrentLpn +
            ": " +
            lpn +
            ", " +
            currentLPNIndex.toString() +
            " / " +
            totalLPNCount.toString();

        _progressDialog!.update(progress: progress, message: message);

        WorkOrderProduceTransaction workOrderProduceTransaction =
            generateWorkOrderProduceTransaction(
                lpn,
                _selectedInventoryStatus!,
                _selectedItemPackageType!,
                lpnCaptureRequest.lpnUnitOfMeasure!.quantity!,
                _getReasonCodeForProducingInventory());

        await WorkOrderService.saveWorkOrderProduceTransaction(
            workOrderProduceTransaction);
        currentLPNIndex++;
      }
    } on WebAPICallException catch (ex) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      setState(() => _readyToConfirm = true);
      return;
    } on CWMSHttpException catch (ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, "${ex.code} - ${ex.message}");
      return;
    }

    if (_progressDialog!.isShowing()) {
      _progressDialog!.hide();
    }

    Navigator.of(context).pop();

    _refreshScreenAfterProducing();
  }

  _setupProgressBar() {
    _progressDialog = new ProgressDialog(
      context,
      type: ProgressDialogType.normal,
      isDismissible: false,
      showLogs: true,
    );

    _progressDialog!
        .style(message: CWMSLocalizations.of(context).receivingMultipleLpns);
    if (!_progressDialog!.isShowing()) {
      _progressDialog!.show();
    }
  }

  _refreshScreenAfterProducing() {
    // refresh the work order to reflect the produced quantity
    _refreshWorkOrderInformation();
    showToast("inventory produced");
    // we will allow the user to continue receiving with the same
    // receipt and line
    _lpnController.clear();
    // default the quantity to 1
    _quantityController.text = "1";
    _lpnControllerFocusNode.requestFocus();
    // FocusScope.of(context).requestFocus(lpnFocusNode);

    _readyToConfirm = true;
  }

  // check how many LPNs we will need to receive
  // based on the quantity that the user input,
  // the UOM that the user select
  int _getRequiredLPNCount(int totalQuantity) {
    // if the user choose force LPN receiving, then
    // we will default to receive by 1 LPN uom
    if (_forceLPNReceiving) {
      return 1;
    }

    int lpnCount = 0;

    if (_selectedItemPackageType!.trackingLpnUOM == null) {
      // the tracking LPN UOM is not defined for this item package type, so we don't know
      // how to calculate how many LPNs we may need based on the UOM and quantity
      lpnCount = 1;
    } else if (_selectedItemUnitOfMeasure!.quantity! >=
        _selectedItemPackageType!.trackingLpnUOM!.quantity!) {
      // we are receiving at LPN uom level, then see what's the quantity the user specify
      lpnCount =
          totalQuantity ~/ _selectedItemPackageType!.trackingLpnUOM!.quantity!;
    } else {
      // we are receiving at some lower level than the tracking LPN UOM,
      // no matter how many we are receiving, we will only need one lpn, we will rely on
      // the user to input the right quantity that can be done in one single lpn
      lpnCount = 1;
    }
    return lpnCount;
  }

  _refreshWorkOrderInformation() {
    WorkOrderService.getWorkOrderByNumber(_currentWorkOrder!.number!)
        .then((workOrder) {
      setState(() {
        _currentWorkOrder!.producedQuantity = workOrder?.producedQuantity;
      });
    });
  }

  WorkOrderProduceTransaction generateWorkOrderProduceTransaction(
      String lpn,
      InventoryStatus selectedInventoryStatus,
      ItemPackageType selectedItemPackageType,
      int quantity,
      ReasonCode? reasonCode) {
    WorkOrderProduceTransaction workOrderProduceTransaction =
        new WorkOrderProduceTransaction();
    workOrderProduceTransaction.workOrder = _currentWorkOrder;
    workOrderProduceTransaction.productionLine = _currentProductionLine;

    workOrderProduceTransaction.rfCode = Global.getLastLoginRFCode();

    workOrderProduceTransaction.workOrderKPITransactions = [];

    WorkOrderProducedInventory workOrderProducedInventory =
        new WorkOrderProducedInventory();
    workOrderProducedInventory.lpn = lpn;
    workOrderProducedInventory.quantity = quantity;
    workOrderProducedInventory.inventoryStatus = selectedInventoryStatus;
    workOrderProducedInventory.inventoryStatusId = selectedInventoryStatus.id;
    workOrderProducedInventory.itemPackageType = selectedItemPackageType;
    workOrderProducedInventory.itemPackageTypeId = selectedItemPackageType.id;
    List<WorkOrderProducedInventory> workOrderProducedInventoryList = [];
    workOrderProducedInventoryList.add(workOrderProducedInventory);

    workOrderProduceTransaction.workOrderProducedInventories =
        workOrderProducedInventoryList;

    List<WorkOrderLineConsumeTransaction> workOrderLineConsumeTransactions = [];
    workOrderProduceTransaction.consumeByBomQuantity = true;
    workOrderProduceTransaction.consumeByBom = _matchedBillOfMaterial;

    // We are now only allow consume by BOM when producing from mobile
    // in case of consuming by BOM, we won't have to setup the
    // WorkOrderLineConsumeTransaction
    // setup the work order line consume transaction based on teh
    // matched bom
    /**
     *
        _currentWorkOrder.workOrderLines.forEach((workOrderLine) {

        WorkOrderLineConsumeTransaction workOrderLineConsumeTransaction
        = new WorkOrderLineConsumeTransaction();
        workOrderLineConsumeTransaction.workOrderLine = workOrderLine;
        if (_matchedBillOfMaterial != null) {

        printLongLogMessage("matchedBillOfMaterial: ${_matchedBillOfMaterial.toJson()}");
        printLongLogMessage("matchedBillOfMaterial.billOfMaterialLines: ${_matchedBillOfMaterial.billOfMaterialLines.length}");


        BillOfMaterialLine matchedBillOfMaterialLine =
        _matchedBillOfMaterial.billOfMaterialLines.firstWhere((billOfMaterialLine)  {
        printLongLogMessage("billOfMaterialLine.itemId: ${billOfMaterialLine.itemId}");
        printLongLogMessage("workOrderLine.itemId: ${workOrderLine.itemId}");
        return billOfMaterialLine.itemId == workOrderLine.itemId;
        }
        );

        workOrderLineConsumeTransaction.consumedQuantity =
        ((matchedBillOfMaterialLine.expectedQuantity * quantity) /
        _matchedBillOfMaterial.expectedQuantity).round();
        workOrderLineConsumeTransactions.add(workOrderLineConsumeTransaction);
        }
        else {

        workOrderLineConsumeTransaction.consumedQuantity = 0;
        workOrderLineConsumeTransactions.add(workOrderLineConsumeTransaction);
        }

        });
     */
    workOrderProduceTransaction.workOrderLineConsumeTransactions =
        workOrderLineConsumeTransactions;

    if (reasonCode != null) {
      workOrderProduceTransaction.reasonCodeId = reasonCode.id;
      workOrderProduceTransaction.reasonCode = reasonCode;
    } else {
      workOrderProduceTransaction.reasonCodeId = null;
      workOrderProduceTransaction.reasonCode = null;
    }

    return workOrderProduceTransaction;
  }
}
