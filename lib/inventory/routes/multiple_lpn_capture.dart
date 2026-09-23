import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/inventory/services/lpn_ocr_service.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

enum _LpnOperation { move, updateStatus }

class MultipleLpnCapturePage extends StatefulWidget {
  const MultipleLpnCapturePage({Key? key}) : super(key: key);

  @override
  State<MultipleLpnCapturePage> createState() => _MultipleLpnCapturePageState();
}

class _MultipleLpnCapturePageState extends State<MultipleLpnCapturePage> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _lpns = [];
  final Set<String> _selectedLpns = {};
  final TextEditingController _locationController = TextEditingController();
  bool _processing = false;
  bool _executing = false;
  bool _statusesLoading = true;
  String? _message;
  _LpnOperation? _operation;
  WarehouseLocation? _destinationLocation;
  List<InventoryStatus> _statuses = [];
  InventoryStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await InventoryStatusService.getAllInventoryStatus();
      if (!mounted) return;
      setState(() {
        _statuses = statuses;
        _statusesLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _statusesLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 95,
      maxWidth: 2400,
    );
    if (image == null) return;
    setState(() {
      _processing = true;
      _message = null;
      _lpns.clear();
      _selectedLpns.clear();
    });
    try {
      final candidates = await LpnOcrService.recognizeLpnCandidates(image.path);
      if (!mounted) return;
      setState(() {
        _lpns.addAll(candidates);
        _message = candidates.isEmpty
            ? 'No LPN detected. You can add one manually.'
            : '${candidates.length} LPN(s) detected. Select the ones to process.';
      });
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _message = 'OCR failed: ${error.message ?? error.code}');
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _addManual() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add LPN'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'Enter LPN'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final normalized = LpnOcrService.normalizeCandidate(value ?? '');
    if (normalized == null) {
      if (value != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'LPN must start with L or R and contain at least 6 characters.'),
          ),
        );
      }
      return;
    }
    if (!_lpns.contains(normalized)) setState(() => _lpns.add(normalized));
  }

  Future<void> _editLpn(int index) async {
    final controller = TextEditingController(text: _lpns[index]);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit LPN'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'LPN'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final normalized = LpnOcrService.normalizeCandidate(value ?? '');
    if (normalized == null ||
        (_lpns.contains(normalized) && normalized != _lpns[index])) {
      if (value != null && mounted) _showMessage('Invalid or duplicate LPN.');
      return;
    }
    final oldValue = _lpns[index];
    final wasSelected = _selectedLpns.remove(oldValue);
    setState(() {
      _lpns[index] = normalized;
      if (wasSelected) _selectedLpns.add(normalized);
    });
  }

  void _toggleAll(bool select) {
    setState(() {
      if (select) {
        _selectedLpns
          ..clear()
          ..addAll(_lpns);
      } else {
        _selectedLpns.clear();
      }
    });
  }

  void _selectOperation(_LpnOperation? operation) {
    setState(() {
      _operation = operation;
      _destinationLocation = null;
      _locationController.clear();
    });
  }

  Future<void> _execute() async {
    if (_selectedLpns.isEmpty || _operation == null) return;
    if (_operation == _LpnOperation.move &&
        _locationController.text.trim().isEmpty) {
      _showMessage('Please enter a destination location.');
      return;
    }
    if (_operation == _LpnOperation.updateStatus && _selectedStatus == null) {
      _showMessage('Please select an inventory status.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Operation'),
        content: Text(_operation == _LpnOperation.move
            ? 'Move ${_selectedLpns.length} LPN(s) to ${_locationController.text.trim()}?'
            : 'Update ${_selectedLpns.length} LPN(s) to ${_selectedStatus!.description ?? _selectedStatus!.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Execute')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (_operation == _LpnOperation.move) {
      try {
        _destinationLocation =
            await WarehouseLocationService.getWarehouseLocationByName(
          _locationController.text.trim(),
        );
      } catch (error) {
        _showMessage('Location not found: $error');
        return;
      }
    }

    setState(() => _executing = true);
    final results = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LpnExecutionDialog(
        lpns: List<String>.from(_selectedLpns),
        operationLabel: _operation == _LpnOperation.move
            ? 'Move to ${_locationController.text.trim()}'
            : 'Update to ${_selectedStatus!.description ?? _selectedStatus!.name}',
        executeLpn: _executeSingleLpn,
      ),
    );
    if (!mounted) return;
    setState(() => _executing = false);
    if (results != null) {
      final failed =
          results.where((result) => result.contains('Failed')).length;
      _resetAfterOperation();
      _showMessage(failed == 0
          ? 'All ${results.length} LPN(s) completed successfully.'
          : '${results.length - failed} succeeded, $failed failed.');
    }
  }

  void _resetAfterOperation() {
    if (!mounted) return;
    setState(() {
      _lpns.clear();
      _selectedLpns.clear();
      _operation = null;
      _selectedStatus = null;
      _destinationLocation = null;
      _locationController.clear();
      _message = null;
    });
  }

  Future<String> _executeSingleLpn(String lpn) async {
    try {
      if (_operation == _LpnOperation.move) {
        await InventoryService.moveInventory(
          lpn: lpn,
          destinationLocation: _destinationLocation,
        );
        return '$lpn: Success';
      }

      final inventories = await InventoryService.findInventory(lpn: lpn);
      if (inventories.isEmpty) throw Exception('No inventory record found');
      for (final inventory in inventories) {
        inventory.inventoryStatus = _selectedStatus;
        await InventoryService.changeInventory(inventory);
      }
      return '$lpn: Success (${inventories.length} record(s))';
    } catch (error) {
      return '$lpn: Failed - $error';
    }
  }

  void _showMessage(String message) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple LPN Capture'),
        actions: [
          IconButton(
            tooltip: 'Add LPN manually',
            onPressed: _executing ? null : _addManual,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section(
              title: '1. Capture LPNs',
              child: Row(
                children: [
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: _processing || _executing
                              ? null
                              : () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Take Photo'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: _processing || _executing
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Choose Photo'))),
                ],
              ),
            ),
            if (_processing || _executing) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(_processing
                  ? 'Reading LPNs from photo...'
                  : 'Executing operation...'),
            ],
            if (_message != null && !_processing) ...[
              const SizedBox(height: 8),
              Text(_message!),
            ],
            const SizedBox(height: 12),
            _section(
              title: '2. Select LPNs (${_selectedLpns.length}/${_lpns.length})',
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                TextButton(
                    onPressed: _lpns.isEmpty ? null : () => _toggleAll(true),
                    child: const Text('All')),
                TextButton(
                    onPressed:
                        _selectedLpns.isEmpty ? null : () => _toggleAll(false),
                    child: const Text('Clear')),
                IconButton(
                    tooltip: 'Add LPN',
                    onPressed: _executing ? null : _addManual,
                    icon: const Icon(Icons.add)),
              ]),
              child: _lpns.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                          child: Text(
                              'No LPNs yet. Capture a photo or add one manually.')))
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _lpns.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final lpn = _lpns[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Checkbox(
                                value: _selectedLpns.contains(lpn),
                                onChanged: _executing
                                    ? null
                                    : (value) => setState(() => value == true
                                        ? _selectedLpns.add(lpn)
                                        : _selectedLpns.remove(lpn))),
                            title: Text(lpn,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text('LPN ${index + 1}'),
                            trailing: Wrap(children: [
                              IconButton(
                                  tooltip: 'Edit LPN',
                                  onPressed:
                                      _executing ? null : () => _editLpn(index),
                                  icon: const Icon(Icons.edit_outlined)),
                              IconButton(
                                  tooltip: 'Remove LPN',
                                  onPressed: _executing
                                      ? null
                                      : () => setState(() {
                                            _selectedLpns.remove(lpn);
                                            _lpns.removeAt(index);
                                          }),
                                  icon: const Icon(Icons.delete_outline)),
                            ]),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            _section(
              title: '3. Choose Operation',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<_LpnOperation>(
                      segments: const [
                        ButtonSegment(
                            value: _LpnOperation.move,
                            label: Text('Move'),
                            icon: Icon(Icons.drive_file_move_outlined)),
                        ButtonSegment(
                            value: _LpnOperation.updateStatus,
                            label: Text('Update Status'),
                            icon: Icon(Icons.sync_alt)),
                      ],
                      selected: _operation == null
                          ? <_LpnOperation>{}
                          : <_LpnOperation>{_operation!},
                      onSelectionChanged: _executing
                          ? null
                          : (values) => _selectOperation(
                              values.isEmpty ? null : values.first),
                      emptySelectionAllowed: true,
                    ),
                    if (_operation == _LpnOperation.move) ...[
                      const SizedBox(height: 12),
                      TextField(
                          controller: _locationController,
                          enabled: !_executing,
                          decoration: const InputDecoration(
                              labelText: 'Destination Location',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.place_outlined),
                              hintText: 'Enter location name')),
                    ],
                    if (_operation == _LpnOperation.updateStatus) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<InventoryStatus>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                            labelText: 'Inventory Status',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory_2_outlined)),
                        hint: Text(_statusesLoading
                            ? 'Loading statuses...'
                            : 'Select status'),
                        items: _statuses
                            .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                    status.description ?? status.name ?? '')))
                            .toList(),
                        onChanged: _executing || _statusesLoading
                            ? null
                            : (value) =>
                                setState(() => _selectedStatus = value),
                      ),
                    ],
                  ]),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed:
                    _executing || _selectedLpns.isEmpty || _operation == null
                        ? null
                        : _execute,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Execute Selected LPNs')),
          ],
        ),
      ),
    );
  }

  Widget _section(
      {required String title, Widget? trailing, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (trailing != null) trailing,
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

class _LpnExecutionDialog extends StatefulWidget {
  const _LpnExecutionDialog({
    required this.lpns,
    required this.operationLabel,
    required this.executeLpn,
  });

  final List<String> lpns;
  final String operationLabel;
  final Future<String> Function(String lpn) executeLpn;

  @override
  State<_LpnExecutionDialog> createState() => _LpnExecutionDialogState();
}

class _LpnExecutionDialogState extends State<_LpnExecutionDialog> {
  final List<String> _results = [];
  int _completed = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (final lpn in widget.lpns) {
      final result = await widget.executeLpn(lpn);
      if (!mounted) return;
      setState(() {
        _results.add(result);
        _completed++;
      });
    }
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final failed = _results.where((result) => result.contains('Failed')).length;
    return AlertDialog(
      title: Text(_done ? 'Operation Complete' : 'Executing Operation'),
      content: SizedBox(
        width: 460,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.operationLabel),
            const SizedBox(height: 14),
            LinearProgressIndicator(
                value:
                    widget.lpns.isEmpty ? 0 : _completed / widget.lpns.length),
            const SizedBox(height: 8),
            Text('Processed $_completed / ${widget.lpns.length}'),
            const SizedBox(height: 12),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('Starting...'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final result = _results[index];
                        final isFailed = result.contains('Failed');
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                              isFailed
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              color: isFailed ? Colors.red : Colors.green),
                          title: Text(result),
                        );
                      },
                    ),
            ),
            if (_done) ...[
              const SizedBox(height: 8),
              Text('$failed failed, ${_results.length - failed} succeeded.'),
            ],
          ],
        ),
      ),
      actions: [
        if (_done)
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, List<String>.from(_results)),
            child: const Text('Close'),
          ),
      ],
    );
  }
}
