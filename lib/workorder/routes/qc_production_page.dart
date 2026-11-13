import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/global.dart';
import '../../shared/models/factory_profile.dart';
import '../../shared/http_client.dart';
import '../../shared/workspace_ui.dart';
import '../../shared/widgets/qc_scan_header.dart';
import '../../shared/scanning/scan_app_bar.dart';
import '../../shared/scanning/scan_feedback.dart';

// The preview API returns this business response for pre-cutoff production.
const _historicalResponse =
    'This LPN has only production from before QC confirmation was enabled; '
    'historical totals remain unchanged';
class QcProductionApi {
  QcProductionApi()
      : _http = CWMSHttpClient.getDio(),
        _warehouse = Global.currentWarehouse!.id.toString();

  final Dio _http;
  final String _warehouse;

  static bool get factorySupported {
    final server = Uri.tryParse(Global.currentServer?.url ?? '');
    final supportedServer = [
      FactoryProfile.qcPreviewUrl,
      FactoryProfile.fayQcPreviewUrl,
      const String.fromEnvironment('COLTON_API_URL'),
      const String.fromEnvironment('FAY_API_URL'),
    ].any((url) => url.isNotEmpty && server == Uri.tryParse(url));
    final mobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return mobile && supportedServer &&
        Global.currentWarehouse?.id == 1;
  }

  static Future<bool> hasAccess() async {
    if (!factorySupported) return false;
    try {
      final capability = await QcProductionApi().request('capabilities');
      return capability is Map && capability['enabled'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<dynamic> request(
    String action, [
    Map<String, dynamic>? body,
    String? lpn,
  ]) async {
    final response = await _http.request<dynamic>(
      'workorder/qc-production/$action',
      data: body,
      queryParameters: {'warehouseId': _warehouse, if (lpn != null) 'lpn': lpn},
      options: Options(
        method: body == null ? 'GET' : 'POST',
        validateStatus: (status) => status != null && status < 500,
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final result = response.data;
    if (response.statusCode == 403) throw StateError('QC access is required.');
    if (response.statusCode == 401)
      throw StateError('Session expired. Sign in again.');
    if (result is! Map ||
        response.statusCode! >= 400 ||
        (result['result'] != null && result['result'] != 0)) {
      throw StateError(
        result is Map
            ? result['message']?.toString() ?? 'QC request rejected.'
            : 'QC request rejected.',
      );
    }
    return result['data'] ?? result;
  }
}

class QcProductionPage extends StatefulWidget {
  const QcProductionPage({super.key, required this.withdraw});

  final bool withdraw;

  @override
  State<QcProductionPage> createState() => _QcProductionPageState();
}

class _QcProductionPageState extends State<QcProductionPage> {
  final _input = TextEditingController();
  final _reason = TextEditingController();
  final _focus = FocusNode();
  final _queue = <Map<String, dynamic>>[];
  final _random = Random.secure();
  late final QcProductionApi _api;
  late final SharedPreferences _prefs;
  late final String _storageKey;
  Future<void> _writes = Future.value();
  bool _ready = false;
  bool _processing = false;
  bool _paused = false;
  bool _lookingUp = false;
  static const _recentLimit = 80;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      if (!QcProductionApi.factorySupported) {
        throw StateError('Production confirmation is unavailable for this warehouse.');
      }
      _api = QcProductionApi();
      final cap = await _api.request('capabilities') as Map;
      if (cap['enabled'] != true) throw StateError('QC access is required.');
      _prefs = await SharedPreferences.getInstance();
      final mode = widget.withdraw ? 'exceptions' : 'confirmation';
      _storageKey =
          'qc-scans-v1:${Global.currentServer?.url}:${Global.currentWarehouse?.id}:${cap['actor']}:$mode';
      final saved = jsonDecode(_prefs.getString(_storageKey) ?? '[]') as List;
      if (!mounted) return;
      _queue.addAll(saved.map((row) => Map<String, dynamic>.from(row as Map)));
      final unfinished = _unfinishedScans().toList();
      _queue
        ..clear()
        ..addAll(unfinished);
      _queue.removeWhere((scan) =>
          scan['status'] == 'historical' ||
          (scan['status'] == 'error' && scan['message'] == _historicalResponse));
      for (final scan in _queue.where((scan) => scan['status'] == 'sending')) {
        scan['status'] = 'unconfirmed';
        scan['message'] = 'Result pending confirmation. Retry the same scan.';
      }
      setState(() => _ready = true);
      _focus.requestFocus();
      unawaited(_process());
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    }
  }

  String _message(Object error) {
    if (error is StateError) return error.message.toString();
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Could not confirm the result. Retry the same scan.';
  }

  String _requestId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Iterable<Map<String, dynamic>> _unfinishedScans() {
    final completed = <(Object?, Object?)>{};
    final unfinished = <Map<String, dynamic>>[];
    for (final scan in _queue.reversed) {
      final key = (scan['lpn'], scan['action']);
      if (scan['status'] == 'success') {
        completed.add(key);
      } else if (!_needsAttention(scan['status']) || !completed.contains(key)) {
        unfinished.add(scan);
      }
    }
    return unfinished.reversed;
  }

  Future<void> _save() {
    final snapshot = jsonEncode(_unfinishedScans().toList());
    _writes = _writes.then(
      (_) async {
        if (!await _prefs.setString(_storageKey, snapshot)) {
          throw StateError('Could not save the scan queue.');
        }
      },
      onError: (Object _) async {
        if (!await _prefs.setString(_storageKey, snapshot)) {
          throw StateError('Could not save the scan queue.');
        }
      },
    );
    return _writes;
  }

  void _submit(String value) {
    final lpn = value.trim();
    final reason = _reason.text.trim();
    if (!_ready || _lookingUp || lpn.isEmpty) return;
    if (_paused ||
        !RegExp(r'^[A-Za-z0-9._/\-]{1,100}$').hasMatch(lpn) ||
        (widget.withdraw && reason.isEmpty)) {
      setState(
        () => _error = _paused
            ? 'Resume the scan queue first.'
            : widget.withdraw && reason.isEmpty
                ? 'Enter an exception reason.'
                : 'Scan a valid pallet LPN.',
      );
      _input.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _input.text.length,
      );
      _focus.requestFocus();
      return;
    }
    _enqueue(lpn, widget.withdraw ? 'exception' : 'confirm', reason: reason);
  }

  void _enqueue(String lpn, String action, {String reason = '', int? version}) {
    if (_queue.where((scan) => scan['status'] == 'queued').length >= 1000) {
      setState(() => _error = 'Queue is full. Wait for pending scans.');
      return;
    }
    setState(() {
      _error = null;
      _queue.add({
        'requestId': _requestId(),
        'lpn': lpn,
        'action': action,
        'reason': action == 'confirm' ? '' : reason,
        if (version != null) 'version': version,
        'status': 'queued',
      });
    });
    _input.clear();
    _focus.requestFocus();
    unawaited(_persistAndProcess());
  }

  Future<void> _resolve() async {
    final lpn = _input.text.trim();
    final reason = _reason.text.trim();
    if (_paused || _lookingUp || lpn.isEmpty || reason.isEmpty) {
      setState(() => _error = 'Enter an LPN and a resolution reason.');
      return;
    }
    setState(() => _lookingUp = true);
    try {
      final result = await _api.request('lpn', null, lpn) as Map;
      if (!mounted) return;
      if (result['state'] != 'EXCEPTION' || result['version'] is! int) {
        throw StateError('This LPN is not currently marked as an exception.');
      }
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resolve exception?'),
          content: Text('$lpn will be eligible for QC confirmation again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Resolve'),
            ),
          ],
        ),
      );
      if (mounted && proceed == true && !_paused) {
        _enqueue(
          lpn,
          'resolve',
          reason: reason,
          version: result['version'] as int,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) {
        setState(() => _lookingUp = false);
        _focus.requestFocus();
      }
    }
  }

  Future<void> _persistAndProcess() async {
    try {
      await _save();
      if (mounted) unawaited(_process());
    } catch (error) {
      if (mounted)
        setState(() {
          _paused = true;
          _error = _message(error);
        });
    }
  }

  Future<void> _process() async {
    if (_processing || _paused) return;
    _processing = true;
    try {
      while (mounted && !_paused) {
        final index = _queue.indexWhere((scan) => scan['status'] == 'queued');
        if (index < 0) break;
        final scan = _queue[index];
        scan['status'] = 'sending';
        setState(() {});
        await _save();
        try {
          final result = await _api.request(scan['action'] as String, {
            'requestId': scan['requestId'],
            'lpn': scan['lpn'],
            'reason': scan['reason'],
            if (scan.containsKey('version')) 'version': scan['version'],
          }) as Map;
          final state = result['state'];
          final outcome = result['outcome'];
          const knownStates = {
            'PENDING',
            'CONFIRMED',
            'NEW_QUANTITY_PENDING',
            'EXCEPTION',
            'HISTORICAL',
          };
          if (!knownStates.contains(state) ||
              result['requestId'] != scan['requestId']) {
            throw const FormatException('Unexpected scan result');
          }
          if (state == 'HISTORICAL') {
            _queue.removeAt(index);
          } else {
            scan['status'] = 'success';
            scan['message'] = switch (outcome) {
              'REPLAYED' => 'Previously processed · Current status: $state',
              'ALREADY_CONFIRMED' => 'Already confirmed · No duplicate count',
              'EXCEPTION' => 'Exception recorded · Confirmation withdrawn',
              'RESOLVED' => 'Exception resolved · Scan again to confirm',
              _ => state == 'NEW_QUANTITY_PENDING'
                  ? 'New production pending · Scan again to confirm'
                  : 'Production confirmed',
            };
          }
        } on StateError catch (error) {
          if (error.message == _historicalResponse) {
            _queue.removeAt(index);
          } else {
            scan['status'] = 'error';
            scan['message'] = _message(error);
            if (scan['warned'] != true) {
              scan['warned'] = true;
              unawaited(ScanFeedback.playFailure());
            }
          }
        } catch (_) {
          scan['status'] = 'unconfirmed';
          scan['message'] = 'Result pending confirmation. Retry the same scan.';
        }
        await _save();
        if (mounted) setState(() {});
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _paused = true;
          _error = _message(error);
        });
      }
    } finally {
      _processing = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _reason.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _retry(Map<String, dynamic> scan) {
    setState(() {
      scan['status'] = 'queued';
      scan.remove('message');
    });
    unawaited(_persistAndProcess());
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final latestByLpn = <String, Map<String, dynamic>>{};
    for (final scan in _queue.reversed) {
      latestByLpn.putIfAbsent(scan['lpn'] as String, () => scan);
    }
    final rows = latestByLpn.values;
    final attention = rows.where((scan) => _needsAttention(scan['status']));
    final pending = rows.where(
      (scan) => scan['status'] == 'queued' || scan['status'] == 'sending',
    );
    final visible = [
      ...attention,
      ...rows.where((scan) => !_needsAttention(scan['status'])).take(_recentLimit),
    ];
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_processing,
      child: Scaffold(
        backgroundColor: workspaceBackground,
        appBar: ScanAppBar(
          backgroundColor: workspaceBackground,
          foregroundColor: workspaceNavy,
          scrolledUnderElevation: 0,
          title: Text(
            widget.withdraw
                ? 'Production Pallet Exception'
                : 'Production Confirmation',
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QcScanHeader(
                        title: widget.withdraw
                            ? 'Flag a pallet exception'
                            : 'Confirm pallet production',
                        subtitle: widget.withdraw
                            ? 'Enter a reason and scan the pallet LPN'
                            : 'Scan a pallet LPN to confirm it',
                        icon: widget.withdraw
                            ? Icons.error_outline
                            : Icons.verified_user_outlined,
                      ),
                      const SizedBox(height: 12),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_error!,
                              style: TextStyle(color: theme.colorScheme.error)),
                        ),
                      if (_paused)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _paused = false;
                              _error = null;
                              for (final scan in _queue.where(
                                (row) => row['status'] == 'sending',
                              )) {
                                scan['status'] = 'queued';
                              }
                            });
                            unawaited(_process());
                          },
                          child: const Text('Resume queue'),
                        ),
                      if (!_ready && _error == null) const LinearProgressIndicator(),
                      if (_ready) ...[
                        _scanControls(),
                        const SizedBox(height: 20),
                        Text(
                          'Scan results',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: workspaceNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (pending.isNotEmpty || attention.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${pending.length} pending · ${attention.length} need attention',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        if (visible.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('No scans yet'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final scan = visible[index];
                    return _ScanResultCard(
                      key: ValueKey(scan['lpn']),
                      lpn: scan['lpn'] as String,
                      status: scan['status'] as String,
                      message: scan['message'] as String?,
                      onRetry: _needsAttention(scan['status'])
                          ? () => _retry(scan)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scanControls() {
    final action = widget.withdraw ? 'Flag exception' : 'Confirm';
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFDFE6F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.withdraw) ...[
              TextField(
                controller: _reason,
                maxLength: 240,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _focus.requestFocus(),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _input,
              focusNode: _focus,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onEditingComplete: () {},
              onSubmitted: _submit,
              decoration: InputDecoration(
                labelText: 'Scan pallet LPN',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                filled: true,
                fillColor: workspaceBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: workspaceBlue,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _lookingUp ? null : () => _submit(_input.text),
              icon: Icon(widget.withdraw ? Icons.error_outline : Icons.check),
              label: Text(action),
            ),
            if (widget.withdraw)
              TextButton(
                onPressed: _lookingUp ? null : _resolve,
                child: const Text('Resolve exception'),
              ),
          ],
        ),
      ),
    );
  }
}

bool _needsAttention(Object? status) => status == 'error' || status == 'unconfirmed';

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({
    super.key,
    required this.lpn,
    required this.status,
    required this.message,
    required this.onRetry,
  });

  final String lpn;
  final String status;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, tint, background, fallback) = switch (status) {
      'success' => (Icons.check_circle_outline, const Color(0xFF08754B),
          const Color(0xFFE9F6EE), 'Confirmed'),
      'error' => (Icons.error_outline, const Color(0xFFB42318),
          const Color(0xFFFFEFEE), 'Failed'),
      'unconfirmed' => (Icons.refresh_rounded, const Color(0xFF855309),
          const Color(0xFFFFF3D9), 'Pending confirmation'),
      _ => (Icons.refresh_rounded, workspaceBlue, const Color(0xFFEAF0FC),
          status == 'sending' ? 'Checking inventory…' : 'Queued'),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDFE6F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lpn, style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: workspaceNavy,
                    fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(height: 3),
                  Text(message ?? fallback, style: TextStyle(color: tint)),
                  if (onRetry != null)
                    TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
