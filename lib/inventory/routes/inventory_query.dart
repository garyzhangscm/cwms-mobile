import 'package:cwms_mobile/shared/adaptive_layout.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/inventory_delete_policy.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/material.dart';

import '../../shared/models/barcode.dart';
import '../../shared/services/barcode_service.dart';

class InventoryQueryPage extends StatefulWidget {
  InventoryQueryPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InventoryQueryPageState();
}

class _InventoryQueryPageState extends State<InventoryQueryPage> {
  // show LPN and Item
  // allow the user to choose LPN or Item if there're
  // multiple LPN to deposit, or multiple Item on the same LPN to deposit
  TextEditingController _locationController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();
  FocusNode _lpnFocusNode = FocusNode();
  TextEditingController _itemController = new TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _deletingLpn = false;

  @override
  void initState() {
    super.initState();

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
      }
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _lpnController.dispose();
    _lpnFocusNode.dispose();
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Claytech One - Inventory"),
        actions: [
          IconButton(
            tooltip: 'Multiple LPN Capture',
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: () async {
              final lpns =
                  await Navigator.of(context).pushNamed('multiple_lpn_capture');
              if (!mounted || lpns is! List<String> || lpns.isEmpty) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        '${lpns.length} LPN(s) captured for the next operation.')),
              );
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TabletContent(
            maxWidth: 720,
            child: SingleChildScrollView(
                child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.always, //开启自动校验
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final lpns = await Navigator.of(context)
                                .pushNamed('multiple_lpn_capture');
                            if (!mounted ||
                                lpns is! List<String> ||
                                lpns.isEmpty) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${lpns.length} LPN(s) captured for the next operation.')),
                            );
                          },
                          icon: const Icon(Icons.document_scanner_outlined),
                          label: const Text('Multiple LPN Capture'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _deletingLpn ? null : _openDeleteLpn,
                          icon: _deletingLpn
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_outline),
                          label: const Text('Delete LPN'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildLocationScanner(context),
                  _buildLPNScanner(context),
                  _buildItemScanner(context),
                  Padding(
                    padding: const EdgeInsets.only(top: 25),
                    child: ConstrainedBox(
                      constraints: BoxConstraints.expand(height: 55.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            print("form validation passed");
                            _onInventoryQuery();
                          }
                        },
                        child: Text(CWMSLocalizations.of(context).query),
                      ),
                    ),
                  ),
                ],
              ),
            ))),
      ),
      endDrawer: MyDrawer(),
    );
  }

  // scan in barcode to add a order into current batch
  Widget _buildLPNScanner(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(children: <Widget>[
          TextFormField(
            controller: _lpnController,
            focusNode: _lpnFocusNode,
            decoration: InputDecoration(
              labelText: CWMSLocalizations.of(context).lpn,
              hintText: CWMSLocalizations.of(context).inputLPNHint,
              suffixIcon: IconButton(
                onPressed: () => _clearLpnField(),
                icon: Icon(Icons.close),
              ),
            ),
          ),
        ]));
  }

  // scan in location barcode to confirm
  Widget _buildLocationScanner(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(children: <Widget>[
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: CWMSLocalizations.of(context).location,
              hintText: CWMSLocalizations.of(context).inputLocationHint,
              suffixIcon: IconButton(
                onPressed: () => _clearLocationField(),
                icon: Icon(Icons.close),
              ),
            ),
          ),
        ]));
  }

  // scan in location barcode to confirm
  Widget _buildItemScanner(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(children: <Widget>[
          TextFormField(
            controller: _itemController,
            decoration: InputDecoration(
              labelText: CWMSLocalizations.of(context).item,
              hintText: CWMSLocalizations.of(context).inputItemHint,
              suffixIcon: IconButton(
                onPressed: () => _clearItemField(),
                icon: Icon(Icons.close),
              ),
            ),
          ),
        ]));
  }

  _onInventoryQuery() async {
    showLoading(context);
    List<Inventory> inventories = await InventoryService.findInventory(
      locationName: _locationController.text,
      itemName: _itemController.text,
      lpn: _lpnController.text,
    );

    Navigator.of(context).pop();

    if (inventories.length == 0) {
      showToast(CWMSLocalizations.of(context).noInventoryFound);
    } else {
      // load the location for each inventory
      for (var inventory in inventories) {
        if (inventory.location == null && inventory.locationId != null) {
          inventory.location =
              await WarehouseLocationService.getWarehouseLocationById(
                  inventory.locationId!);
        }

        printLongLogMessage(
            "INVENTORY ${inventory.lpn} 's location is setup to ${inventory.location?.name}");
      }

      printLongLogMessage(
          "will flow to invenory with ${inventories.length} inventory records");
      Navigator.of(context)
          .pushNamed("inventory_display", arguments: inventories);
    }
  }

  Future<void> _openDeleteLpn() async {
    String enteredLpn = _lpnController.text.trim();
    final scannedLpn = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Delete LPN'),
          content: TextFormField(
            initialValue: enteredLpn,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'LPN'),
            onChanged: (value) => setDialogState(() => enteredLpn = value),
            onFieldSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: enteredLpn.trim().isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(enteredLpn.trim()),
              child: const Text('Find'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || scannedLpn == null) return;

    String lpn = scannedLpn;
    try {
      final barcode = BarcodeService.parseBarcode(lpn);
      if (barcode.is_2d == true) {
        lpn = BarcodeService.getLPN(barcode);
      }
    } catch (_) {
      _showDeleteMessage('Unable to read this barcode.');
      return;
    }
    lpn = lpn.trim();
    if (lpn.isEmpty) {
      _showDeleteMessage('No LPN found in the scanned barcode.');
      return;
    }

    setState(() => _deletingLpn = true);
    Inventory inventory;
    try {
      final inventories = await InventoryService.findInventory(lpn: lpn);
      if (inventories.length == 1 &&
          inventories.single.location == null &&
          inventories.single.locationId != null) {
        inventories.single.location =
            await WarehouseLocationService.getWarehouseLocationById(
                inventories.single.locationId!);
      }
      inventory = requireSingleOutInventory(inventories, lpn);
    } catch (error) {
      if (mounted) _showDeleteMessage(_deleteErrorMessage(error));
      return;
    } finally {
      if (mounted) setState(() => _deletingLpn = false);
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete LPN?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LPN: ${inventory.lpn}'),
            Text('Item: ${inventory.item?.name ?? '-'}'),
            Text('Location: ${inventory.location?.name}'),
            Text('Quantity: ${inventory.quantity ?? '-'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() => _deletingLpn = true);
    var deleteAccepted = false;
    try {
      await InventoryService.removeInventory(inventory.id!);
      deleteAccepted = true;
      final remaining = await InventoryService.findInventory(lpn: lpn);
      if (remaining.isNotEmpty) {
        throw StateError(
            'Delete returned success, but the LPN is still found.');
      }
      if (mounted) {
        _lpnController.clear();
        _showDeleteMessage('$lpn deleted and verified.');
      }
    } catch (error) {
      if (mounted) {
        _showDeleteMessage(deleteAccepted
            ? 'Deletion was accepted, but verification failed: $error'
            : _deleteErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _deletingLpn = false);
    }
  }

  String _deleteErrorMessage(Object error) =>
      error is StateError ? error.message.toString() : 'Delete failed: $error';

  void _showDeleteMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  _clearLpnField() {
    _lpnController.clear();
  }

  _clearItemField() {
    _itemController.clear();
  }

  _clearLocationField() {
    _locationController.clear();
  }
}
