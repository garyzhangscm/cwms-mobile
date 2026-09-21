import 'package:collection/collection.dart';

import 'package:badges/badges.dart' as badge;
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
import 'package:cwms_mobile/shared/models/cwms_http_exception.dart';
import 'package:cwms_mobile/shared/services/barcode_service.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:cwms_mobile/shared/workspace_ui.dart';
import 'package:flutter/material.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

import '../../inventory/models/item.dart';
import '../../shared/global.dart';
import '../../shared/models/barcode.dart';
import '../../shared/models/printing_strategy.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class ReceivingPage extends StatefulWidget {
  ReceivingPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ReceivingPageState();
}

class _ReceivingPageState extends State<ReceivingPage> {
  // receipt number control. We allow both receipt number and barcode for receiving
  TextEditingController _receiptNumberController = new TextEditingController();
  TextEditingController _itemController = new TextEditingController();
  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();

  Receipt? _currentReceipt;
  ReceiptLine? _currentReceiptLine;

  List<InventoryStatus> _validInventoryStatus = [];
  InventoryStatus? _selectedInventoryStatus;
  ItemPackageType? _selectedItemPackageType;
  ItemUnitOfMeasure? _selectedItemUnitOfMeasure;

  List<Inventory> inventoryOnRF = [];
  FocusNode _receiptNumberFocusNode = FocusNode();
  FocusNode _itemFocusNode = FocusNode();
  FocusNode _quantityFocusNode = FocusNode();
  FocusNode _lpnFocusNode = FocusNode();
  bool _readyToConfirm = true; // whether we can confirm the received inventory

  // save the inventory attribute we got from barcode
  Map<String, String> _inventoryAttributesFromBarcode = new Map();
  // if we are in the barcode receiving mode, then after the user receive one LPN,
  // we will clear everything and set focus back to receipt number, which allow the
  // user to receive with second barcode.
  // otherwise, we will keep the receipt and item so the user can continue with
  // the same item but new LPN
  bool _barcodeReceivingMode = false;
  final Map<String, String> _selectionErrors = {};

  static const String _packageTypeField = "packageType";
  static const String _unitOfMeasureField = "unitOfMeasure";
  static const String _inventoryStatusField = "inventoryStatus";

  static const Duration _openReceiptsCacheDuration = Duration(seconds: 30);
  static const int _recentReceiptLimit = 10;
  Future<List<Receipt>>? _openReceiptsFuture;
  DateTime? _openReceiptsLoadedAt;
  bool _isChoosingReceipt = false;

  final _formKey = GlobalKey<FormState>();
  ProgressDialog? pr;

  @override
  void initState() {
    super.initState();
    _currentReceipt = new Receipt();
    _currentReceiptLine = new ReceiptLine();
    _selectedInventoryStatus = new InventoryStatus();
    _selectedItemPackageType = null;
    _inventoryAttributesFromBarcode.clear();
    _barcodeReceivingMode = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _getOpenReceipts().catchError((_) => <Receipt>[]);
      }
    });

    InventoryStatusService.getAllInventoryStatus().then((value) {
      _validInventoryStatus = value;
      if (_validInventoryStatus.length > 0) {
        _selectedInventoryStatus = _validInventoryStatus[0];
      }
    });
    // setup the default inventory status

    inventoryOnRF = [];

    _receiptNumberFocusNode.addListener(() {
      print("_receiptFocusNode.hasFocus: ${_receiptNumberFocusNode.hasFocus}");
      print(
          "_receiptNumberController.text.isNotEmpty: ${_receiptNumberController.text.isNotEmpty}");
      if (!_receiptNumberFocusNode.hasFocus &&
          _receiptNumberController.text.isNotEmpty) {
        printLongLogMessage(
            "start to parse the barcode ${_receiptNumberController.text}");
        Barcode barcode =
            BarcodeService.parseBarcode(_receiptNumberController.text);

        print("barcode.is_2d? ${barcode.is_2d}");

        // first check if it is a barcode scanned in
        if (barcode.is_2d == true) {
          _barcodeReceivingMode = true;
          _processBarcode(barcode.result!).then((successful) {
            if (successful) {
              printLongLogMessage("send focus to the quantity node");
              _quantityFocusNode.requestFocus();
            } else {
              _receiptNumberFocusNode.requestFocus();
            }
          });
        } else {
          _barcodeReceivingMode = false;
          // if we tab out, then add the LPN to the list

          _loadReceipt(_receiptNumberController.text);
          // _itemFocusNode.requestFocus();
        }
      }
    });
    _receiptNumberFocusNode.requestFocus();

    _itemFocusNode.addListener(() {
      print("_itemFocusNode.hasFocus: ${_itemFocusNode.hasFocus}");
      if (!_itemFocusNode.hasFocus && _itemController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _loadReceiptLine(_itemController.text);
        // _quantityFocusNode.requestFocus();
      }
    });

    _lpnFocusNode.addListener(() {
      print("_lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list

        Barcode barcode = BarcodeService.parseBarcode(_lpnController.text);
        if (barcode.is_2d == true) {
          // for 2d barcode, let's get the result and set the LPN back to the text
          String lpn = BarcodeService.getLPN(barcode);
          printLongLogMessage("get lpn from lpn?: ${lpn}");
          if (lpn == "") {
            showErrorDialog(context, "can't get LPN from the barcode");
            return;
          } else {
            _lpnController.text = lpn;
          }
        }
        _enterOnLPNController();
      }
    });

    _reloadInventoryOnRF();
  }

  // if the user scan in a barcode, then we will parse the barcode and
  // automatically populate all the values
  Future<bool> _processBarcode(Map<String, String> parameters) async {
    // make sure we at least have receipt number

    if (!parameters.containsKey("receiptId") ||
        !parameters.containsKey("receiptLineId")) {
      await showBlockedErrorDialog(context, "invalid barcode format");
      return false;
    }

    String receiptIdString = parameters["receiptId"] ?? "";
    String receiptLineIdString = parameters["receiptLineId"] ?? "";

    bool loadReceiptAndLine =
        await _loadReceiptAndLineById(receiptIdString, receiptLineIdString);

    if (!loadReceiptAndLine) {
      await showBlockedErrorDialog(
          context, "invalid barcode. Can't find the receipt and line");
      return false;
    }

    if (parameters.containsKey("inventoryStatusId")) {
      setState(() {
        _selectedInventoryStatus = _validInventoryStatus.firstWhereOrNull(
            (inventoryStatus) =>
                inventoryStatus.id.toString() ==
                parameters["inventoryStatusId"]);
      });
    }

    if (parameters.containsKey("quantity")) {
      _quantityController.text = parameters["quantity"] ?? "";
    }

    if (parameters.containsKey("lpn")) {
      _lpnController.text = parameters["lpn"] ?? "";
    }

    _inventoryAttributesFromBarcode.clear();

    if (parameters.containsKey("color")) {
      _inventoryAttributesFromBarcode["color"] = parameters["color"] ?? "";
    }
    if (parameters.containsKey("productSize")) {
      _inventoryAttributesFromBarcode["productSize"] =
          parameters["productSize"] ?? "";
    }
    if (parameters.containsKey("style")) {
      _inventoryAttributesFromBarcode["style"] = parameters["style"] ?? "";
    }

    if (parameters.containsKey("inventoryAttribute1")) {
      _inventoryAttributesFromBarcode["attribute1"] =
          parameters["inventoryAttribute1"] ?? "";
    }
    if (parameters.containsKey("inventoryAttribute2")) {
      _inventoryAttributesFromBarcode["attribute2"] =
          parameters["inventoryAttribute2"] ?? "";
    }
    if (parameters.containsKey("inventoryAttribute3")) {
      _inventoryAttributesFromBarcode["attribute3"] =
          parameters["inventoryAttribute3"] ?? "";
    }
    if (parameters.containsKey("inventoryAttribute4")) {
      _inventoryAttributesFromBarcode["attribute4"] =
          parameters["inventoryAttribute4"] ?? "";
    }
    if (parameters.containsKey("inventoryAttribute5")) {
      _inventoryAttributesFromBarcode["attribute5"] =
          parameters["inventoryAttribute5"] ?? "";
    }

    // whether the kit inner inventory attribute from
    // the kit item's default attribute, or from the container's inventory attribute
    if (parameters.containsKey("kitInnerInventoryWithDefaultAttribute")) {
      _inventoryAttributesFromBarcode["kitInnerInventoryWithDefaultAttribute"] =
          parameters["kitInnerInventoryWithDefaultAttribute"] ?? "";
    }

    if (parameters.containsKey("kitInnerInventoryAttributeFromKit")) {
      _inventoryAttributesFromBarcode["kitInnerInventoryAttributeFromKit"] =
          parameters["kitInnerInventoryAttributeFromKit"] ?? "";
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CWMSLocalizations.of(context);
    return Scaffold(
      backgroundColor: workspaceBackground,
      appBar: AppBar(title: Text(l10n.receiving)),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8F9FB),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE4E9F1))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: workspaceBlue, width: 1.4)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD85D67))),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildReceivingStatusCard(context),
                        const SizedBox(height: 12),
                        _buildSectionCard(context,
                            workspaceIsChinese(context) ? '收货单' : 'Receipt', [
                          _buildReceiptNumberControl(context),
                          buildTwoSectionInputRow(
                            l10n.item,
                            TextFormField(
                              controller: _itemController,
                              textInputAction: TextInputAction.next,
                              focusNode: _itemFocusNode,
                              autofocus: true,
                              onEditingComplete: () =>
                                  _quantityFocusNode.requestFocus(),
                              decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                      onPressed: _showChoosingItemsDialog,
                                      icon: const Icon(Icons.list_rounded))),
                              validator: (v) => v?.trim().isEmpty ?? true
                                  ? "please scan in item"
                                  : null,
                            ),
                          ),
                          buildTwoSectionInformationRow(l10n.item,
                              _currentReceiptLine?.item?.description ?? ""),
                          buildFourSectionInformationRow(
                              l10n.expectedQuantity,
                              _currentReceiptLine?.expectedQuantity
                                      .toString() ??
                                  "",
                              l10n.receivedQuantity,
                              _currentReceiptLine?.receivedQuantity
                                      .toString() ??
                                  ""),
                        ]),
                        const SizedBox(height: 12),
                        _buildSectionCard(
                            context,
                            workspaceIsChinese(context)
                                ? '入库明细'
                                : 'Inventory details',
                            [
                              buildTwoSectionInputRow(
                                  l10n.itemPackageType,
                                  _buildValidatedSelectionField(
                                      _packageTypeField,
                                      _getItemPackageTypeItems().isEmpty
                                          ? const Text("Not configured")
                                          : DropdownButton(
                                              items: _getItemPackageTypeItems(),
                                              value: _selectedItemPackageType,
                                              elevation: 1,
                                              isExpanded: true,
                                              icon: const Icon(Icons
                                                  .keyboard_arrow_down_rounded),
                                              onChanged:
                                                  (ItemPackageType? value) {
                                                setState(() {
                                                  _selectedItemPackageType =
                                                      value;
                                                  _selectionErrors.remove(
                                                      _packageTypeField);
                                                  _selectionErrors.remove(
                                                      _unitOfMeasureField);
                                                });
                                              }))),
                              buildTwoSectionInputRow(
                                  l10n.inventoryStatus,
                                  _buildValidatedSelectionField(
                                      _inventoryStatusField,
                                      DropdownButton(
                                          items: _getInventoryStatusItems(),
                                          value: _selectedInventoryStatus,
                                          elevation: 1,
                                          isExpanded: true,
                                          icon: const Icon(Icons
                                              .keyboard_arrow_down_rounded),
                                          onChanged: (InventoryStatus? value) {
                                            setState(() {
                                              _selectedInventoryStatus = value;
                                              _selectionErrors.remove(
                                                  _inventoryStatusField);
                                            });
                                          }))),
                              buildThreeSectionInputRow(
                                  "RCV Quantity:",
                                  TextFormField(
                                      keyboardType: TextInputType.number,
                                      controller: _quantityController,
                                      textInputAction: TextInputAction.next,
                                      autofocus: true,
                                      focusNode: _quantityFocusNode,
                                      onFieldSubmitted: (v) =>
                                          _lpnFocusNode.requestFocus(),
                                      decoration: const InputDecoration(),
                                      validator: (v) {
                                        if (v?.trim().isEmpty ?? true)
                                          return "please type in quantity";
                                        final receivingQuantity =
                                            int.tryParse(v!.trim());
                                        if (receivingQuantity == null ||
                                            receivingQuantity <= 0)
                                          return "please type in a valid quantity";
                                        if (!_validateOverReceiving(
                                            _currentReceiptLine!,
                                            receivingQuantity))
                                          return "over receive is not allowed";
                                        return null;
                                      }),
                                  _buildValidatedSelectionField(
                                      _unitOfMeasureField,
                                      _getItemUnitOfMeasures().isEmpty
                                          ? const Text("Not configured")
                                          : DropdownButton(
                                              hint: Text(l10n.pleaseSelect),
                                              items: _getItemUnitOfMeasures(),
                                              value: _selectedItemUnitOfMeasure,
                                              elevation: 1,
                                              isExpanded: true,
                                              icon: const Icon(Icons
                                                  .keyboard_arrow_down_rounded),
                                              onChanged:
                                                  (ItemUnitOfMeasure? value) {
                                                setState(() {
                                                  _selectedItemUnitOfMeasure =
                                                      value;
                                                  _selectionErrors.remove(
                                                      _unitOfMeasureField);
                                                });
                                              }))),
                              buildTwoSectionInputRow(
                                  l10n.lpn + ": ",
                                  Focus(
                                      child: SystemControllerNumberTextBox(
                                          type: "lpn",
                                          controller: _lpnController,
                                          readOnly: false,
                                          showKeyboard: false,
                                          focusNode: _lpnFocusNode,
                                          autofocus: true,
                                          validator: (v) {
                                            if ((v?.trim().isEmpty ?? true) &&
                                                _getRequiredLPNCount(int.parse(
                                                        _quantityController
                                                            .text)) ==
                                                    1)
                                              return l10n
                                                  .missingField(l10n.lpn);
                                            return null;
                                          }))),
                            ]),
                        const SizedBox(height: 12),
                        _buildButtons(context),
                      ]),
                ),
              ),
            ),
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildReceivingStatusCard(BuildContext context) {
    final receiptNumber = _currentReceipt?.number?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      decoration: BoxDecoration(
          color: workspaceNavy, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.move_to_inbox_outlined,
                color: Color(0xFFBBD2FF), size: 23)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(workspaceIsChinese(context) ? '收货作业' : 'RECEIVING',
              style: TextStyle(
                  color: Color(0xFFB7C9E4),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 3),
          Text(
              receiptNumber.isEmpty
                  ? (workspaceIsChinese(context)
                      ? '扫描或选择收货单'
                      : 'Scan or choose a receipt')
                  : receiptNumber,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
        ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10)),
            child: Text(
                workspaceIsChinese(context)
                    ? '${inventoryOnRF.length} 个在途库存'
                    : '${inventoryOnRF.length} on RF',
                style:
                    const TextStyle(color: Color(0xFFC3D3EA), fontSize: 11))),
      ]),
    );
  }

  Widget _buildSectionCard(
      BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4E9F1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(title.toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFF7B8BA1),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2))),
        ...children,
      ]),
    );
  }

  /*
              _buildReceiptNumberControl(context),

              buildTwoSectionInputRow(
                CWMSLocalizations.of(context).item,
                TextFormField(
                    controller: _itemController,
                    textInputAction: TextInputAction.next,
                    focusNode: _itemFocusNode,
                    autofocus: true,
                    onEditingComplete: () => _quantityFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixIcon: IconButton(
                        onPressed: _showChoosingItemsDialog,
                        icon: Icon(Icons.list),
                      ),
                    ),
                    // 校验ITEM NUMBER（不能为空）
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) {
                        return "please scan in item";
                      }
                      return null;
                    }),
              ),
              // display the item
              buildTwoSectionInformationRow(
                CWMSLocalizations.of(context).item,
                _currentReceiptLine?.item?.description ?? "",
              ),
              buildFourSectionInformationRow(
                  CWMSLocalizations.of(context).expectedQuantity,
                  _currentReceiptLine?.expectedQuantity.toString() ?? "",
                  CWMSLocalizations.of(context).receivedQuantity,
                  _currentReceiptLine?.receivedQuantity.toString() ?? ""),

              // Allow the user to choose item package type

              buildTwoSectionInputRow(
                  CWMSLocalizations.of(context).itemPackageType,
                  _buildValidatedSelectionField(
                    _packageTypeField,
                    _getItemPackageTypeItems().isEmpty
                        ? Text("Not configured")
                        : DropdownButton(
                            // hint: Text(CWMSLocalizations.of(context).pleaseSelect),
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
                                _selectionErrors.remove(_packageTypeField);
                                _selectionErrors.remove(_unitOfMeasureField);
                              });
                            },
                          ),
                  )),
              // Allow the user to choose inventory status

              buildTwoSectionInputRow(
                  CWMSLocalizations.of(context).inventoryStatus,
                  _buildValidatedSelectionField(
                    _inventoryStatusField,
                    DropdownButton(
                      //  hint: Text(CWMSLocalizations.of(context).pleaseSelect),
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
                          _selectionErrors.remove(_inventoryStatusField);
                        });
                      },
                    ),
                  )),
              buildThreeSectionInputRow(
                  "RCV Quantity:",
                  TextFormField(
                      keyboardType: TextInputType.number,
                      controller: _quantityController,
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                      focusNode: _quantityFocusNode,
                      onFieldSubmitted: (v) {
                        printLongLogMessage("start to focus on lpn node");
                        _lpnFocusNode.requestFocus();
                      },
                      decoration: InputDecoration(isDense: true),
                      // 校验ITEM NUMBER（不能为空）
                      validator: (v) {
                        if (v?.trim().isEmpty ?? true) {
                          return "please type in quantity";
                        }
                        final receivingQuantity = int.tryParse(v!.trim());
                        if (receivingQuantity == null ||
                            receivingQuantity <= 0) {
                          return "please type in a valid quantity";
                        }
                        if (!_validateOverReceiving(
                            _currentReceiptLine!, receivingQuantity)) {
                          return "over receive is not allowed";
                        }
                        return null;
                      }),
                  _buildValidatedSelectionField(
                    _unitOfMeasureField,
                    _getItemUnitOfMeasures().isEmpty
                        ? Text("Not configured")
                        : DropdownButton(
                            hint: Text(
                                CWMSLocalizations.of(context).pleaseSelect),
                            items: _getItemUnitOfMeasures(),
                            value: _selectedItemUnitOfMeasure,
                            elevation: 1,
                            isExpanded: true,
                            icon: Icon(
                              Icons.list,
                              size: 20,
                            ),
                            onChanged: (ItemUnitOfMeasure? value) {
                              //下拉菜单item点击之后的回调
                              setState(() {
                                _selectedItemUnitOfMeasure = value;
                                _selectionErrors.remove(_unitOfMeasureField);
                              });
                            },
                          ),
                  )),

              buildTwoSectionInputRow(
                CWMSLocalizations.of(context).lpn + ": ",
                Focus(
                  child: SystemControllerNumberTextBox(
                      type: "lpn",
                      controller: _lpnController,
                      readOnly: false,
                      showKeyboard: false,
                      focusNode: _lpnFocusNode,
                      autofocus: true,
                      validator: (v) {
                        // if we only need one LPN, then make sure the user input the LPN in this form.
                        // otherwise, we will flow to next LPN Capture form to let the user capture
                        // more LPNs
                        if ((v?.trim().isEmpty ?? true) &&
                            _getRequiredLPNCount(
                                    int.parse(_quantityController.text)) ==
                                1) {
                          return CWMSLocalizations.of(context)
                              .missingField(CWMSLocalizations.of(context).lpn);
                        }

                        return null;
                      }),
                ),
              ),
              _buildButtons(context)
            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  */

  Widget _buildReceiptNumberControl(BuildContext context) {
    return buildTwoSectionInputRow(
      CWMSLocalizations.of(context).receiptNumber,
      TextFormField(
          controller: _receiptNumberController,
          autofocus: true,
          focusNode: _receiptNumberFocusNode,
          textInputAction: TextInputAction.next,
          onEditingComplete: () => _itemFocusNode.requestFocus(),
          decoration: InputDecoration(
            isDense: true,
            suffixIcon: Row(
              mainAxisAlignment: MainAxisAlignment.end, // added line
              mainAxisSize: MainAxisSize.min, // added line
              children: <Widget>[
                IconButton(
                  onPressed: _showChoosingReceiptDialog,
                  icon: Icon(Icons.list),
                ),
                IconButton(
                  onPressed: _clearReceipt,
                  icon: Icon(Icons.clear),
                ),
                /**
                    IconButton(
                      onPressed: _showQRCodeView,
                      icon: Icon(Icons.camera),
                    ),
                        **/
              ],
            ),
          ),
          // 校验ITEM NUMBER（不能为空）
          validator: (v) {
            if (v?.trim().isEmpty ?? true) {
              return "please scan in receipt";
            }
            return null;
          }),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return buildTwoButtonRow(
        context,
        ElevatedButton(
          onPressed: () {
            if (!_validateReceivingSelections()) {
              return;
            }
            if (_formKey.currentState?.validate() ?? false) {
              print("1. _readyToConfirm? $_readyToConfirm");
              if (_readyToConfirm == true) {
                _readyToConfirm = false;
                print("1. form validation passed");
                print("1. set _readyToConfirm to false");
                _onRecevingConfirm(_currentReceiptLine!,
                    int.parse(_quantityController.text), _lpnController.text);
              }
            }
          },
          child: Text(CWMSLocalizations.of(context).confirm),
        ),
        badge.Badge(
          showBadge: true,
          badgeStyle: badge.BadgeStyle(
            padding: EdgeInsets.all(8),
            badgeColor: Colors.deepPurple,
          ),
          badgeContent: Text(
            inventoryOnRF.length.toString(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: inventoryOnRF.length == 0 ? null : _startDeposit,
              child: Text(CWMSLocalizations.of(context).depositInventory),
            ),
          ),
        ));
  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    await Navigator.of(context)
        .pushNamed("inventory_deposit", arguments: inventoryOnRF);

    // refresh the inventory on the RF
    _reloadInventoryOnRF();
  }

  bool _validateOverReceiving(ReceiptLine receiptLine, int receivingQuantity) {
    // a rough estimation, since we don't know yet whether
    // we will need to validate the over receiving against the
    // expected quantity or the arrived quantity. It is based on configuraiton
    // and we will postponed to the actual receiving web call to
    // let the server decides whether it is a over receiving
    final expectedQuantity = receiptLine.expectedQuantity ?? 0;
    final arrivedQuantity = receiptLine.arrivedQuantity ?? expectedQuantity;
    final receivedQuantity = receiptLine.receivedQuantity ?? 0;
    final overReceivingQuantity = receiptLine.overReceivingQuantity ?? 0;
    final overReceivingPercent = receiptLine.overReceivingPercent ?? 0;
    int maxExpectedQuantity =
        arrivedQuantity > expectedQuantity ? arrivedQuantity : expectedQuantity;
    double openQuantity = (maxExpectedQuantity - receivedQuantity) * 1.0;
    if (overReceivingQuantity > 0) {
      openQuantity += overReceivingQuantity;
    } else if (overReceivingPercent > 0) {
      openQuantity =
          openQuantity + expectedQuantity * (100 + overReceivingPercent) / 100;
    }
    return openQuantity >= receivingQuantity;
  }

  bool _validateReceivingSelections() {
    final errors = <String, String>{};

    if (_currentReceiptLine?.id == null || _currentReceiptLine?.item == null) {
      errors[_packageTypeField] =
          "Select an item before choosing a package type";
    } else {
      final packageTypes = _currentReceiptLine!.item!.itemPackageTypes;
      if (packageTypes.isEmpty) {
        errors[_packageTypeField] =
            CWMSLocalizations.of(context).itemNotReceivableNoPackageType;
      } else if (_selectedItemPackageType?.id == null) {
        errors[_packageTypeField] = "Select an item package type";
      }
    }

    if (_selectedItemPackageType?.id != null) {
      if (_selectedItemPackageType!.itemUnitOfMeasures.isEmpty) {
        errors[_unitOfMeasureField] =
            "No unit of measure is configured for this package type";
      } else if (_selectedItemUnitOfMeasure?.quantity == null) {
        errors[_unitOfMeasureField] = "Select a unit of measure";
      }
    }

    if (_selectedInventoryStatus?.id == null) {
      errors[_inventoryStatusField] = "Select an inventory status";
    }

    setState(() {
      _selectionErrors
        ..clear()
        ..addAll(errors);
    });

    if (errors.isNotEmpty) {
      final message = errors.values.map((error) => "- $error").join("\n");
      showErrorDialog(
          context, "Please complete the highlighted fields:\n$message");
      return false;
    }
    return true;
  }

  Widget _buildValidatedSelectionField(String field, Widget child) {
    final error = _selectionErrors[field];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: error == null ? EdgeInsets.zero : EdgeInsets.all(6),
          decoration: error == null
              ? null
              : BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                ),
          child: child,
        ),
        if (error != null)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              error,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  List<DropdownMenuItem<InventoryStatus>> _getInventoryStatusItems() {
    List<DropdownMenuItem<InventoryStatus>> items = [];
    if (_validInventoryStatus.length == 0) {
      return items;
    }
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
    final packageTypes = _currentReceiptLine?.item?.itemPackageTypes ?? [];

    for (final packageType in packageTypes) {
      items.add(DropdownMenuItem(
        value: packageType,
        child: Text(
          (packageType.description?.trim().isNotEmpty ?? false)
              ? packageType.description!
              : (packageType.name ?? ""),
        ),
      ));
    }

    return items;
  }

  void _resetItemPackageTypeSelection() {
    _selectedItemPackageType = null;
    _selectedItemUnitOfMeasure = null;

    final packageTypes = _currentReceiptLine?.item?.itemPackageTypes ?? [];
    if (packageTypes.isNotEmpty) {
      _selectedItemPackageType =
          getDefaultItemPackageType(_currentReceiptLine!);
    }
  }

  // get the default item package type for the receipt line based on the priority
  // 1. item package type defined at the receipt line level
  // 2. default item package type of the item
  // 3. first item package type of the item
  ItemPackageType? getDefaultItemPackageType(ReceiptLine receiptLine) {
    final packageTypes = receiptLine.item?.itemPackageTypes ?? [];
    if (packageTypes.isEmpty) return null;

    if (receiptLine.itemPackageTypeId != null) {
      final linePackageType = packageTypes.firstWhereOrNull(
          (element) => element.id == receiptLine.itemPackageTypeId);
      if (linePackageType != null) return linePackageType;
    }

    final defaultItemPackageType =
        packageTypes.firstWhereOrNull((element) => element.defaultFlag == true);

    // If no configured default exists, always select the first available
    // package type so receiving can continue without an extra tap.
    return defaultItemPackageType ?? packageTypes.first;
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
        child: Text(_selectedItemPackageType!
                .itemUnitOfMeasures[i].unitOfMeasure?.name ??
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

      _selectedItemUnitOfMeasure = _selectedItemPackageType!.itemUnitOfMeasures
          .firstWhereOrNull((element) =>
              element.id ==
              _selectedItemPackageType!.defaultInboundReceivingUOM?.id);
    }

    return items;
  }

  void _onRecevingConfirm(
      ReceiptLine receiptLine, int confirmedQuantity, String lpn) async {
    if (_getItemPackageTypeItems().isEmpty) {
      showErrorToast(
        CWMSLocalizations.of(context).itemNotReceivableNoPackageType,
      );
      _readyToConfirm = true;
      return;
    }

    int lpnCount = _getRequiredLPNCount(confirmedQuantity);

    printLongLogMessage("1. lpn count: $lpnCount");

    // see if we are receiving single lpn or multiple lpn
    if (lpnCount == 1) {
      // if we haven't specify the UOM that we will need to track the LPN
      // or we are receiving at less than LPN uom level,
      // or we are receiving at LPN uom level but we only receive 1 LPN, then proceed with single LPN

      // before we will receive one LPN, we will verify if the quantity exceed
      // the LPN's standard quantity. If so, then we will warn the user to make sure
      // they don't accidentally input a wrong number
      bool validateLPNQuantity =
          await _validateQuantityForSingleLPN(confirmedQuantity);
      if (validateLPNQuantity) {
        _onRecevingSingleLpnConfirm(receiptLine, confirmedQuantity, lpn);
      } else {
        // quantity is not valid(normally it means we only need one LPN but the total
        // quantity exceed the standard LPN's quantity
        _readyToConfirm = true;
        return;
      }
    } else {
      printLongLogMessage("start to receive multiple LPNs in one transaction");
      _onRecevingMultiLpnConfirm(receiptLine, confirmedQuantity, lpn);
    }
  }

  Future<bool> _validateQuantityForSingleLPN(int confirmedQuantity) async {
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
    if (confirmedQuantity >
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
      printLongLogMessage(
          "continueWithExceedQuantity: $continueWithExceedQuantity");

      return continueWithExceedQuantity;
    }
    // current quantity doesn't exceed the standard lpn quantity, good to go
    return true;
  }

  Future<bool> _loadReceiptAndLineById(
      String receiptId, String receiptLineId) async {
    showLoading(context);
    try {
      _currentReceipt =
          await ReceiptService.getReceiptById(int.parse(receiptId));

      if (_currentReceipt == null) {
        Navigator.of(context).pop();
        return false;
      }
    } on CWMSHttpException {
      Navigator.of(context).pop();
      return false;
    }

    try {
      _currentReceiptLine =
          await ReceiptService.getReceiptLineById(int.parse(receiptLineId));

      if (_currentReceiptLine == null) {
        Navigator.of(context).pop();
        return false;
      }
    } on CWMSHttpException {
      Navigator.of(context).pop();
      return false;
    }

    _resetItemPackageTypeSelection();

    setState(() {
      _currentReceipt;
      _currentReceiptLine;
    });

    _receiptNumberController.text = _currentReceipt!.number ?? "";
    printLongLogMessage("current receipt ${_currentReceipt?.number}");

    _itemController.text = _currentReceiptLine!.item?.name ?? "";
    Navigator.of(context).pop();
    return true;
  }

  void _onRecevingSingleLpnConfirm(
      ReceiptLine receiptLine, int confirmedQuantity, String lpn) async {
    // TO-DO:Current we don't support the location code. Will add
    //      it later

    bool qcRequired = false;

    printLongLogMessage("1. _onRecevingSingleLpnConfirm / showLoading");
    showLoading(context);
    // make sure the user input a valid LPN
    try {
      String errorMessage = await InventoryService.validateNewLpn(lpn);
      if (errorMessage.isNotEmpty) {
        Navigator.of(context).pop();
        showErrorDialog(context, errorMessage);
        return;
      }
      printLongLogMessage("LPN ${lpn} passed the validation");
    } on CWMSHttpException catch (ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, "${ex.code} - ${ex.message}");
      return;
    }
    Map<String, String> inventoryAttributes = new Map();
    if (_needCaptureInventoryAttribute(_currentReceiptLine!.item!)) {
      printLongLogMessage(
          "we will need to capture the inventory attribute for current item ${_currentReceiptLine!.item!.name}");
      printLongLogMessage(
          "_inventoryAttributesFromBarcode.isNotEmpty? ${_inventoryAttributesFromBarcode.isNotEmpty}");

      if (_inventoryAttributesFromBarcode.isNotEmpty) {
        // the item needs certain attribute but we already parsed from the barcode
        // we don't need to capture them manually
        printLongLogMessage(
            "get inventory attribute from the barcode ${_inventoryAttributesFromBarcode}");
        inventoryAttributes = _inventoryAttributesFromBarcode;
      } else {
        final result = await Navigator.of(context).pushNamed(
            "inventory_attribute_capture",
            arguments: _currentReceiptLine!.item);

        inventoryAttributes = result as Map<String, String>;
      }
    }
    try {
      Inventory inventory = await ReceiptService.receiveInventory(
        _currentReceipt!,
        _currentReceiptLine!,
        _lpnController.text,
        _selectedInventoryStatus!,
        _selectedItemPackageType!,
        int.parse(_quantityController.text) *
            _selectedItemUnitOfMeasure!.quantity!,
        inventoryAttributes.containsKey("color")
            ? (inventoryAttributes["color"] ?? "")
            : "",
        inventoryAttributes.containsKey("productSize")
            ? inventoryAttributes["productSize"] ?? ""
            : "",
        inventoryAttributes.containsKey("style")
            ? inventoryAttributes["style"] ?? ""
            : "",
        inventoryAttributes.containsKey("attribute1")
            ? inventoryAttributes["attribute1"] ?? ""
            : "",
        inventoryAttributes.containsKey("attribute2")
            ? inventoryAttributes["attribute2"] ?? ""
            : "",
        inventoryAttributes.containsKey("attribute3")
            ? inventoryAttributes["attribute3"] ?? ""
            : "",
        inventoryAttributes.containsKey("attribute4")
            ? inventoryAttributes["attribute4"] ?? ""
            : "",
        inventoryAttributes.containsKey("attribute5")
            ? inventoryAttributes["attribute5"] ?? ""
            : "",
        inventoryAttributes.containsKey("kitInnerInventoryWithDefaultAttribute")
            ? (inventoryAttributes["kitInnerInventoryWithDefaultAttribute"]
                as bool)
            : false,
        inventoryAttributes.containsKey("kitInnerInventoryAttributeFromKit")
            ? (inventoryAttributes["kitInnerInventoryAttributeFromKit"] as bool)
            : false,
      );
      qcRequired = inventory.inboundQCRequired!;
      printLongLogMessage(
          "inventory ${inventory.lpn} received and need QC? ${inventory.inboundQCRequired}");
      if (qcRequired) {
        // for any inventory that needs qc, let's allocate the location automatically
        // for the inventory

        printLongLogMessage(
            "allocate location for the QC needed inventory ${inventory.lpn}");
        InventoryService.allocateLocation(inventory);
      }

      printLongLogMessage(
          "Global.warehouseConfiguration.newLPNPrintLabelAtReceivingFlag ${Global.warehouseConfiguration.newLPNPrintLabelAtReceivingFlag}");
      printLongLogMessage(
          "Global.warehouseConfiguration.printingStrategy ${Global.warehouseConfiguration.printingStrategy}");
      if (Global.warehouseConfiguration.newLPNPrintLabelAtReceivingFlag ==
              true &&
          Global.warehouseConfiguration.printingStrategy ==
              PrintingStrategy.LOCAL_PRINTER_SERVER_DATA) {
        // we will print the LPN label
        // we will download the LPN label as PDF and then print from the printer that attached to the RF
        _printLPNLabel(inventory);
      }
      _inventoryAttributesFromBarcode.clear();
    } on WebAPICallException catch (ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;
    }

    _refreshScreenAfterReceive(qcRequired);
  }

  void _printLPNLabel(Inventory inventory) {
    // get the default printer that attached to the RF
    printLongLogMessage(
        "Global.getRFConfiguration.printerName: ${Global.getLastLoginRF().printerName}");

    if (Global.getLastLoginRF().printerName == "") {
      return;
    }
    // download the LPN label
    InventoryService.autoPrintLPNLabel(context, inventory);
  }

  bool _needCaptureInventoryAttribute(Item item) {
    printLongLogMessage(
        "check if we need to capture inventory attribute for the item ${item.name}");

    printLongLogMessage("item.trackingColorFlag ${item.trackingColorFlag}");
    printLongLogMessage(
        "item.trackingProductSizeFlag ${item.trackingProductSizeFlag}");
    printLongLogMessage("item.trackingStyleFlag ${item.trackingStyleFlag}");

    return item.trackingColorFlag == true ||
        item.trackingProductSizeFlag == true ||
        item.trackingStyleFlag == true ||
        item.trackingInventoryAttribute1Flag == true ||
        item.trackingInventoryAttribute2Flag == true ||
        item.trackingInventoryAttribute3Flag == true ||
        item.trackingInventoryAttribute4Flag == true ||
        item.trackingInventoryAttribute5Flag == true;
  }

  // check how many LPNs we will need to receive
  // based on the quantity that the user input,
  // the UOM that the user select
  int _getRequiredLPNCount(int totalQuantity) {
    int lpnCount = 0;
    if (_selectedItemPackageType!.trackingLpnUOM == null) {
      // the tracking LPN UOM is not defined for this item package type, so we don't know
      // how to calculate how many LPNs we may need based on the UOM and quantity
      lpnCount = 1;
    } else if (_selectedItemUnitOfMeasure!.quantity ==
        _selectedItemPackageType!.trackingLpnUOM?.quantity) {
      // we are receiving at LPN uom level, then see what's the quantity the user specify
      lpnCount = totalQuantity;
    } else if (_selectedItemUnitOfMeasure!.quantity! >
        _selectedItemPackageType!.trackingLpnUOM!.quantity!) {
      // we are receiving at some higher level, see how many LPN uom we will need
      printLongLogMessage(
          "totalQuantity: ${totalQuantity}, _selectedItemUnitOfMeasure.quantity: ${_selectedItemUnitOfMeasure!.quantity}");
      printLongLogMessage(
          "_selectedItemPackageType.trackingLpnUOM.quantity: ${_selectedItemPackageType!.trackingLpnUOM?.quantity}");
      lpnCount = totalQuantity *
          _selectedItemUnitOfMeasure!.quantity! ~/
          _selectedItemPackageType!.trackingLpnUOM!.quantity!;
    } else {
      // we are receiving at some lower level than the tracking LPN UOM,
      // no matter how many we are receiving, we will only need one lpn, we will rely on
      // the user to input the right quantity that can be done in one single lpn

      // before we will receive one LPN, we will verify if the quantity exceed
      // the LPN's standard quantity. If so, then we will warn the user to make sure
      // they don't accidentally input a wrong number
      lpnCount = 1;
    }
    return lpnCount;
  }

  void _onRecevingMultiLpnConfirm(
      ReceiptLine receiptLine, int confirmedQuantity, String lpn) async {
    // let's see how many LPNs we will need
    int lpnCount = _getRequiredLPNCount(confirmedQuantity);

    printLongLogMessage("we will need to receive $lpnCount LPNs");
    if (lpnCount == 1) {
      // we will only need one LPN, let's just proceed with the current LPN

      // before we will receive one LPN, we will verify if the quantity exceed
      // the LPN's standard quantity. If so, then we will warn the user to make sure
      // they don't accidentally input a wrong number
      bool validateLPNQuantity =
          await _validateQuantityForSingleLPN(confirmedQuantity);
      if (validateLPNQuantity) {
        _onRecevingSingleLpnConfirm(receiptLine, confirmedQuantity, lpn);
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
        printLongLogMessage(
            "add current LPN $lpn first so that the user don't have to scan in again");
      }
      LpnCaptureRequest lpnCaptureRequest = new LpnCaptureRequest.withData(
          receiptLine.item!,
          _selectedItemPackageType!,
          _selectedItemPackageType!.trackingLpnUOM!,
          lpnCount,
          capturedLpn,
          true);

      printLongLogMessage("flow to lpn_capture screen");
      final result = await Navigator.of(context)
          .pushNamed("lpn_capture", arguments: lpnCaptureRequest);

      printLongLogMessage("returned from the capture lpn form");
      if (result == null) {
        // the user press Return, let's do nothing

        return null;
      }

      lpnCaptureRequest = result as LpnCaptureRequest;
      printLongLogMessage("start to receive lpns with request");
      printLongLogMessage(lpnCaptureRequest.toJson().toString());

      // receive with multiple LPNs
      _receiveMultipleLpns(receiptLine, lpnCaptureRequest);
    }
  }

  void _receiveMultipleLpns(
      ReceiptLine receiptLine, LpnCaptureRequest lpnCaptureRequest) async {
    bool qcRequired = false;

    printLongLogMessage("2. _receiveMultipleLpns / showLoading");
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
        printLongLogMessage("LPN ${lpnIterator.current} passed the validation");
      }
    } on CWMSHttpException catch (ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, "${ex.code} - ${ex.message}");
      return;
    }
    try {
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

        pr!.update(progress: progress, message: message);
        Inventory inventory = await ReceiptService.receiveInventory(
            _currentReceipt!,
            _currentReceiptLine!,
            lpn,
            _selectedInventoryStatus!,
            _selectedItemPackageType!,
            lpnCaptureRequest.lpnUnitOfMeasure!.quantity!,
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            false,
            false);
        if (inventory.inboundQCRequired == true) {
          // for any inventory that needs qc, let's allocate the location automatically
          // for the inventory

          printLongLogMessage(
              "allocate location for the QC needed inventory ${inventory.lpn}");
          InventoryService.allocateLocation(inventory);
          qcRequired = true;
        }

        currentLPNIndex++;
      }
    } on WebAPICallException catch (ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;
    }

    if (pr!.isShowing()) {
      pr!.hide();
    }
    _refreshScreenAfterReceive(qcRequired);
  }

  _setupProgressBar() {
    pr = new ProgressDialog(
      context,
      type: ProgressDialogType.normal,
      isDismissible: false,
      showLogs: true,
    );

    pr!.style(message: CWMSLocalizations.of(context).receivingMultipleLpns);
    if (!pr!.isShowing()) {
      pr!.show();
    }
  }

  _refreshScreenAfterReceive(bool qcRequired) {
    print("inventory received!");

    _invalidateOpenReceiptsCache();
    Navigator.of(context).pop();

    if (qcRequired == true) {
      showWarningDialog(context, CWMSLocalizations.of(context).inventoryNeedQC);
    }
    showToast("inventory received");
    // in barcode receiving mode, let's clear everything so that the user can continue
    // with new barcode.
    // otherwise we will allow the user to continue receiving with the same
    // receipt and line
    if (_barcodeReceivingMode) {
      _clearReceipt();
    } else {
      _lpnController.clear();
      _quantityController.clear();
      _quantityFocusNode.requestFocus();
    }

    // refresh the inventory on the RF
    _reloadInventoryOnRF();

    _readyToConfirm = true;
  }

  _startItemBarcodeScanner() async {
    /*
    *
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    _receiptNumberController.text = barcodeScanRes;
    _loadReceipt(_receiptNumberController.text);
    * */
  }
  _loadReceipt(String receiptNumber) {
    printLongLogMessage("start to load receipt by number $receiptNumber");

    if (receiptNumber.isEmpty) {
      return;
    }
    ReceiptService.getReceiptByNumber(receiptNumber).then((receipt) async {
      if (receipt == null) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(CWMSLocalizations.of(context).error),
              content: Text("Can't find receipt by number ${receiptNumber}"),
              actions: [
                ElevatedButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          },
        );
        // await showErrorDialog(context, "Can't find receipt by number ${receiptNumber}");

        setState(() {
          _currentReceipt = null;
          _clearReceiptLineInformation();
        });
        _receiptNumberFocusNode.requestFocus();
      } else {
        if (_currentReceipt != null && _currentReceipt!.id != receipt.id) {
          // the user scan in a new receipt, let's clear all the fields if needed
          _clearReceiptLineInformation();
        }
        setState(() {
          _currentReceipt = receipt;
        });
        if (receipt.id != null &&
            receipt.receiptLines.any((line) => line.item == null)) {
          _hydrateSelectedReceipt(receipt.id!);
        }
      }
    });
  }

  _clearReceiptLineInformation() {
    _currentReceiptLine = new ReceiptLine();
    _selectionErrors.clear();

    _itemController.clear();
    _lpnController.clear();
    _quantityController.clear();
    _selectedItemPackageType = null;
    _selectedItemUnitOfMeasure = null;
  }

  _startReceiptBarcodeScanner() async {
    /*
    *
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    _itemController.text = barcodeScanRes;
    _loadReceiptLine(_itemController.text);
    * */
  }

  _loadReceiptLine(String itemNumber) {
    // we can only load the line from current receipt
    // based on the item being scanned
    if (_currentReceipt!.receiptLines.isEmpty || itemNumber.isEmpty) {
      return;
    }

    setState(() {
      _currentReceiptLine = _currentReceipt!.receiptLines.firstWhereOrNull(
          (receiptLine) => receiptLine.item?.name == itemNumber);
      _resetItemPackageTypeSelection();
      _selectionErrors.clear();
    });
  }
  /**
  _showQRCodeView() async {

    final result = await Navigator.of(context)
        .pushNamed("qr_code_view");

    printLongLogMessage("capture the QR CODE: " + result);

    var parameters = QRCodeService.parseQRCode(result);

    printLongLogMessage("resutl after parse the code code: \n ${parameters}");

  }
      **/

  // show all open receipt that can be received
  _showChoosingReceiptDialog() async {
    if (_isChoosingReceipt) {
      return;
    }
    _isChoosingReceipt = true;
    showLoading(context);
    final stopwatch = Stopwatch()..start();

    try {
      final openReceiptForReceiving = await _getOpenReceipts();

      if (!mounted) {
        return;
      }
      // 隐藏loading框
      Navigator.of(context).pop();
      printLongLogMessage(
          "open receipt chooser ready in ${stopwatch.elapsedMilliseconds} ms");

      await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 560,
              height: MediaQuery.of(context).size.height * .72,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CWMSLocalizations.of(context).chooseReceipt,
                                style: const TextStyle(
                                  color: workspaceNavy,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                workspaceIsChinese(context)
                                    ? '选择一张收货单开始操作'
                                    : 'Select a receipt to get started',
                                style: const TextStyle(
                                  color: Color(0xFF748297),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: CWMSLocalizations.of(context).cancel,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: const Color(0xFF60728A),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE7EBF2)),
                  _ReceiptChooserList(
                    initialReceipts: openReceiptForReceiving,
                    loadPage: _fetchReceiptPage,
                    onSelected: (receipt) {
                      _onSelecteReceipt(true, receipt);
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop();
        showErrorDialog(context, error.toString());
      }
    } finally {
      _isChoosingReceipt = false;
    }
  }

  Future<List<Receipt>> _getOpenReceipts() {
    final loadedAt = _openReceiptsLoadedAt;
    final cacheIsFresh = loadedAt != null &&
        DateTime.now().difference(loadedAt) < _openReceiptsCacheDuration;

    if (_openReceiptsFuture != null && (loadedAt == null || cacheIsFresh)) {
      return _openReceiptsFuture!;
    }

    _openReceiptsFuture = _fetchOpenReceipts();
    return _openReceiptsFuture!;
  }

  Future<List<Receipt>> _fetchOpenReceipts() async {
    try {
      final receipts = await _fetchReceiptPage(0);
      _openReceiptsLoadedAt = DateTime.now();
      return receipts;
    } catch (_) {
      _invalidateOpenReceiptsCache();
      rethrow;
    }
  }

  Future<List<Receipt>> _fetchReceiptPage(int pageIndex) async {
    final receipts = await ReceiptService.getOpenReceipts(
      pageIndex: pageIndex,
      pageSize: _recentReceiptLimit,
    );
    _setupTotalQuantity(receipts);
    return receipts;
  }

  void _invalidateOpenReceiptsCache() {
    _openReceiptsFuture = null;
    _openReceiptsLoadedAt = null;
  }

  void _clearReceipt() {
    setState(() {
      _currentReceipt = null;
      _clearReceiptLineInformation();
    });
    _receiptNumberController.clear();
    _receiptNumberFocusNode.requestFocus();
  }

  void _setupTotalQuantity(List<Receipt> receipts) {
    receipts.forEach((receipt) {
      _setupTotalQuantityForReceipt(receipt);
    });
  }

  void _setupTotalQuantityForReceipt(Receipt receipt) {
    int totalExpectedQuantity = 0;
    int totalReceivedQuantity = 0;
    receipt.receiptLines.forEach((receiptLine) {
      totalExpectedQuantity += receiptLine.expectedQuantity ?? 0;
      totalReceivedQuantity += receiptLine.receivedQuantity ?? 0;
    });
    receipt.totalReceivedQuantity = totalReceivedQuantity;
    receipt.totalExpectedQuantity = totalExpectedQuantity;
  }

  void _onSelecteReceipt(bool selected, Receipt receipt) {
    if (selected) {
      setState(() {
        print("set current receipt to ${receipt.number}");
        _currentReceipt = receipt;
        _currentReceiptLine = new ReceiptLine();

        _receiptNumberController.text = receipt.number ?? "";
        _clearReceiptLineInformation();
      });
      // The paginated chooser is intentionally lightweight and some server
      // versions omit the nested item on receipt lines. Hydrate the selected
      // receipt before the user opens the item picker.
      if (receipt.id != null &&
          receipt.receiptLines.any((line) => line.item == null)) {
        _hydrateSelectedReceipt(receipt.id!);
      }
    }
    _itemFocusNode.requestFocus();
  }

  Future<void> _hydrateSelectedReceipt(int receiptId) async {
    try {
      final detailedReceipt = await ReceiptService.getReceiptById(receiptId);
      // A few server builds still omit item from the receipt payload even
      // when loadDetails is requested. Hydrate only those lines individually.
      final missingLines = detailedReceipt.receiptLines
          .where((line) => line.item == null && line.id != null)
          .toList();
      if (missingLines.isNotEmpty) {
        final hydratedLines = await Future.wait(
          missingLines
              .map((line) => ReceiptService.getReceiptLineById(line.id!)),
        );
        for (var i = 0; i < missingLines.length; i++) {
          final index = detailedReceipt.receiptLines.indexOf(missingLines[i]);
          if (index >= 0)
            detailedReceipt.receiptLines[index] = hydratedLines[i];
        }
      }
      if (!mounted || _currentReceipt?.id != receiptId) return;
      setState(() {
        _currentReceipt = detailedReceipt;
        _clearReceiptLineInformation();
      });
    } on WebAPICallException catch (ex) {
      if (mounted) showErrorDialog(context, ex.errMsg());
    }
  }

  // Show all items on this receipt
  _showChoosingItemsDialog() async {
    showLoading(context);
    List<ReceiptLine> receiptLines = _currentReceipt!.receiptLines;

    // 隐藏loading框
    Navigator.of(context).pop();
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        var child = Column(
          children: <Widget>[
            Row(
              children: [
                ElevatedButton(
                  child: Text(CWMSLocalizations.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            ListTile(title: Text(CWMSLocalizations.of(context).chooseItem)),
            _buildReceiptLineList(context, receiptLines)
          ],
        );
        //使用AlertDialog会报错
        //return AlertDialog(content: child);
        return Dialog(child: child);
      },
    );
  }

  Widget _buildReceiptLineList(
      BuildContext context, List<ReceiptLine> receiptLines) {
    return Expanded(
      child: ListView.builder(
          itemCount: receiptLines.length,
          itemBuilder: (BuildContext context, int index) {
            return ReceiptLineListItem(
                index: index,
                receiptLine: receiptLines[index],
                onToggleHightlighted: (selected) {
                  // reset the selected inventory
                  _onSelecteReceiptLine(selected, receiptLines[index]);
                  // hide the dialog
                  Navigator.of(context).pop();
                });
          }),
    );
  }

  void _onSelecteReceiptLine(bool selected, ReceiptLine receiptLine) {
    if (selected && receiptLine.item != null) {
      setState(() {
        _currentReceiptLine = receiptLine;
        _resetItemPackageTypeSelection();
        _itemController.text = receiptLine.item?.name ?? "";
        _selectionErrors.clear();
      });
    }
    _quantityFocusNode.requestFocus();
  }

  void _reloadInventoryOnRF() {
    try {
      InventoryService.getInventoryOnCurrentRF().then((value) {
        if (!mounted) return;
        setState(() {
          inventoryOnRF = value;
        });
      });
    } on WebAPICallException catch (ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;
    }
  }

  void _enterOnLPNController({int tryTime = 10}) async {
    if (!_validateReceivingSelections()) {
      _readyToConfirm = true;
      return;
    }
    // we may come here when the user scan / press
    // enter in the LPN controller. In either case, we will need to make sure
    // the lpn doesn't have focus before we start confirm

    printLongLogMessage(
        "Start to confirm receiving inventory, tryTime = $tryTime}");
    if (tryTime <= 0) {
      // do nothing as we run out of try time

      setState(() {
        // enable the confirm button
        _readyToConfirm = true;
      });
      return;
    }
    if (_lpnFocusNode.hasFocus) {
      printLongLogMessage(
          "lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
          () => _enterOnLPNController(tryTime: tryTime - 1));

      return;
    }
    // if we are here, then it means we already have the full LPN
    // due to how  flutter handle the input, we will get the enter
    // action listner handler fired before the input characters are
    // full assigned to the lpnController.

    if (_formKey.currentState!.validate()) {
      if (_readyToConfirm == true) {
        // set ready to confirm to fail so other trigger point
        // won't process the receiving request
        // the issue happens when we have 2 trigger point to process
        // the receiving request
        // 1. LPN blur
        // 2. confirm button click
        // so when we blur the LPN controller by clicking the confirm button, the
        // _onRecevingConfirm function will be fired twice
        _readyToConfirm = false;
        _onRecevingConfirm(_currentReceiptLine!,
            int.parse(_quantityController.text), _lpnController.text);
      }
    }

    setState(() {
      // enable the confirm button
      _readyToConfirm = true;
    });
  }
}

class _ReceiptChooserList extends StatefulWidget {
  const _ReceiptChooserList({
    required this.initialReceipts,
    required this.loadPage,
    required this.onSelected,
  });

  final List<Receipt> initialReceipts;
  final Future<List<Receipt>> Function(int pageIndex) loadPage;
  final ValueChanged<Receipt> onSelected;

  @override
  State<_ReceiptChooserList> createState() => _ReceiptChooserListState();
}

class _ReceiptChooserListState extends State<_ReceiptChooserList> {
  static const int _pageSize = 10;
  late final ScrollController _scrollController;
  late final List<Receipt> _receipts;
  late bool _hasMore;
  bool _loadingMore = false;
  bool _loadFailed = false;
  int _nextPageIndex = 1;

  @override
  void initState() {
    super.initState();
    _receipts = [...widget.initialReceipts];
    _hasMore = _receipts.length >= _pageSize;
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasMore || _loadingMore) return;
    if (_scrollController.position.extentAfter < 160) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _loadFailed = false;
    });
    try {
      final nextReceipts = await widget.loadPage(_nextPageIndex);
      if (!mounted) return;
      setState(() {
        _receipts.addAll(nextReceipts);
        _nextPageIndex++;
        _hasMore = nextReceipts.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _loadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = _receipts.length + (_hasMore || _loadFailed ? 1 : 0);
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < _receipts.length) {
            return ReceiptListItem(
              index: index,
              receipt: _receipts[index],
              onToggleHightlighted: (selected) {
                if (selected) widget.onSelected(_receipts[index]);
              },
            );
          }

          if (_loadFailed) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: TextButton.icon(
                  onPressed: _loadNextPage,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label:
                      Text(workspaceIsChinese(context) ? '重新加载' : 'Try again'),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: _loadingMore
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      workspaceIsChinese(context)
                          ? '继续下滑加载更多'
                          : 'Scroll for more',
                      style: const TextStyle(color: Color(0xFF748297)),
                    ),
            ),
          );
        },
      ),
    );
  }
}
