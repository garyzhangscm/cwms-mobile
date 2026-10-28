import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/global.dart';
import '../../shared/models/factory_profile.dart';
import '../../shared/models/cwms_site_information.dart';

const lineClearanceTestEnabled = bool.fromEnvironment('LINE_CLEARANCE_TEST');

/// Isolated test endpoint: never falls back to the selected production gateway.
class LineClearanceTestPage extends StatefulWidget {
  const LineClearanceTestPage({super.key, this.testClient});
  final Dio? testClient;
  @override
  State<LineClearanceTestPage> createState() => _LineClearanceTestPageState();
}

class _LineClearanceTestPageState extends State<LineClearanceTestPage> {
  final _machine = TextEditingController(),
      _wo = TextEditingController(),
      _previous = TextEditingController(),
      _reason = TextEditingController(),
      _reference = TextEditingController();
  late final Dio _dio;
  Dio _defaultClient() => Dio(BaseOptions(
      baseUrl: 'http://10.0.202.70:4200/api/line-clearance/',
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 30)));
  final Map<String, TextEditingController> _inputs = {};
  final Map<String, dynamic> _values = {};
  late final String _scope;
  Map<String, dynamic>? _session, _record;
  List<dynamic> _records = [];
  String _error = '', _notice = '', _nonce = '';
  bool _busy = false, _spanish = false;
  int _page = 0;
  final _scroll = ScrollController();
  List<Map> get _stageQuestions =>
      (_record?['template']['items'] as List? ?? [])
          .where((q) =>
              ['completed', 'cancelled'].contains(_record?['stage']) ||
              q['phase'] == _record?['stage'])
          .map((q) => q as Map)
          .toList();
  bool _unusedAllowed(Map q) =>
      ['old_carton', 'old_labels', 'old_rfid', 'old_gtin', 'old_resin']
          .contains(q['key']) &&
      q['phase'] == 'clearance';
  void _top() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
  String get _currentScope =>
      '${Global.currentFactory?.id}:${Global.currentWarehouse?.id}:${Global.lastLoginCompanyId}:${Global.currentUser?.username}';
  String _newNonce() => List.generate(24,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'))
      .join();
  bool _cap(String cap) =>
      (_session?['actor']?['caps'] as List? ?? []).contains(cap);
  String _t(String en, String es) => _spanish ? es : en;
  String _operation(String? oldOrder, String? newOrder) =>
      oldOrder?.trim().isNotEmpty == true
          ? (newOrder?.trim().isNotEmpty == true ? 'changeover' : 'closing')
          : (newOrder?.trim().isNotEmpty == true ? 'opening' : '');
  String _modeLabel(String? mode) =>
      {
        'changeover': _t('Changeover', 'Cambio de orden'),
        'opening': _t('Opening only', 'Apertura de línea'),
        'closing': _t('Closing only', 'Cierre de línea')
      }[mode] ??
      '—';
  String _label(Map f) => '${f[_spanish ? 'es' : 'en'] ?? ''}';
  @override
  void initState() {
    super.initState();
    _dio = widget.testClient ?? _defaultClient();
    _scope = _currentScope;
    _nonce = _newNonce();
    _run(() async {
      _session = await _request('session');
      await _search();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _machine,
      _wo,
      _previous,
      _reason,
      _reference,
      ..._inputs.values
    ]) {
      c.dispose();
    }
    _scroll.dispose();
    _dio.close(force: true);
    super.dispose();
  }

  Future<dynamic> _request(String path, [Map<String, dynamic>? data]) async {
    if (!lineClearanceTestEnabled || _scope != _currentScope)
      throw StateError('Test session changed; leave and reopen this page');
    final scope = {
      'companyId': Global.currentWarehouse?.companyId,
      'warehouseId': Global.currentWarehouse?.id
    };
    final opts = Options(headers: {
      'Authorization': 'Bearer ${Global.currentUser?.token}',
      'Accept': 'application/json'
    });
    final r = data == null
        ? await _dio.get(path, queryParameters: scope, options: opts)
        : await _dio.post(path, data: {...scope, ...data}, options: opts);
    if (_scope != _currentScope)
      throw StateError('Account / warehouse changed; reopen the page');
    if (r.data is! Map || r.data['result'] != 0)
      throw StateError('Test service request failed');
    return r.data['data'];
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = '';
      _notice = '';
    });
    try {
      await action();
    } on DioException catch (e) {
      final body = e.response?.data;
      _error = body is Map
          ? '${body['message'] ?? 'Request failed'}'
          : 'Connection interrupted. Reload saved records before retrying; do not start another changeover.';
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _search() async {
    _records = await _request('records') as List;
  }

  void _open(Map<String, dynamic> r, {int? page}) {
    for (final c in _inputs.values) {
      c.dispose();
    }
    _inputs.clear();
    _values.clear();
    _record = r;
    for (final q in r['template']['items'] as List) {
      final k = q['key'] as String;
      _values[k] = Map<String, dynamic>.from(r['answers'][k]?['values'] ?? {});
    }
    final items = _stageQuestions;
    final first = items.indexWhere((q) =>
        r['answers'][q['key']]?['complete'] != true &&
        r['na'][q['key']] == null);
    _page = page?.clamp(0, items.length) ?? (first < 0 ? items.length : first);
    _top();
  }

  void _act(String action,
      {Map? question, Map<String, dynamic> extra = const {}}) {
    _run(() async {
      final unsaved = _values.keys
          .where((k) =>
              jsonEncode(_values[k]) !=
              jsonEncode(_record!['answers'][k]?['values'] ?? {}))
          .toList();
      if (['verify', 'advance', 'sign', 'link'].contains(action) &&
          unsaved.isNotEmpty)
        throw StateError('Save or reload unsaved answers before approval.');
      final keep = jsonDecode(jsonEncode(_values)) as Map;
      final previousPage = _page, previousStage = _record!['stage'];
      final r = await _request('records/${_record!['id']}/$action', {
        'revision': _record!['revision'],
        'question': question?['key'],
        ...extra,
        if (action == 'issue' && question != null)
          'values': _values[question['key']]
      });
      _open(Map<String, dynamic>.from(r),
          page: r['stage'] == previousStage
              ? previousPage +
                  (action == 'answer' && extra['complete'] == true ? 1 : 0)
              : null);
      for (final key in unsaved) {
        if (key != question?['key']) _values[key] = keep[key];
      }
      _reason.clear();
      _reference.clear();
      _notice = _t('Saved.', 'Guardado.');
    });
  }

  TextEditingController _controller(String q, String f) {
    return _inputs.putIfAbsent('$q:$f',
        () => TextEditingController(text: _values[q][f]?.toString() ?? ''));
  }

  Future<void> _photo(Map q, Map f, ImageSource source) async {
    await _run(() async {
      final photo = await ImagePicker().pickImage(
          source: source, maxWidth: 1800, maxHeight: 1800, imageQuality: 82);
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (bytes.length > 6 * 1024 * 1024)
        throw StateError('Photo must be smaller than 6 MB');
      final isPng = bytes.length > 8 && bytes[0] == 137 && bytes[1] == 80;
      final r = await _request('records/${_record!['id']}/photo', {
        'base64': base64Encode(bytes),
        'mime': isPng ? 'image/png' : 'image/jpeg'
      });
      _values[q['key']][f['key']] = r['id'];
      _notice = _t('Photo uploaded. Save this question to attach it.',
          'Foto cargada. Guarde esta pregunta para adjuntarla.');
    });
  }

  Widget _input(Map q, Map f, bool editable) {
    final qk = q['key'] as String, fk = f['key'] as String;
    final label = '${_label(f)}${f['required'] == true ? ' *' : ''}';
    if (f['type'] == 'choice')
      return DropdownButtonFormField<String>(
          key: ValueKey('${_record!['id']}:${_record!['revision']}:$qk:$fk'),
          initialValue: _values[qk][fk] as String?,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final v in f['options'] as List)
              DropdownMenuItem(
                  value: '$v',
                  child: Text(v == 'Confirmed'
                      ? _t('Confirmed', 'Confirmado')
                      : v == 'Problem'
                          ? _t('Problem', 'Problema')
                          : '$v'))
          ],
          onChanged:
              editable ? (v) => setState(() => _values[qk][fk] = v) : null);
    if (f['type'] == 'photo')
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label),
        if (editable)
          TextButton(
              onPressed: () async {
                final evidence = <String, String>{};
                for (final item in _record!['template']['items'] as List) {
                  for (final field in item['fields'] as List) {
                    final value = _values[item['key']][field['key']];
                    if (field['type'] == 'photo' && value is String)
                      evidence[value] = _label(item as Map);
                  }
                }
                if (evidence.isEmpty) {
                  setState(() => _notice = 'Upload a photo first.');
                  return;
                }
                final picked = await showDialog<String>(
                    context: context,
                    builder: (c) => SimpleDialog(
                            title: const Text(
                                'Reuse only if the photo covers this item'),
                            children: [
                              for (final e in evidence.entries)
                                SimpleDialogOption(
                                    onPressed: () => Navigator.pop(c, e.key),
                                    child: Text(e.value))
                            ]));
                if (picked != null && mounted)
                  setState(() => _values[qk][fk] = picked);
              },
              child:
                  Text(_t('Reuse existing evidence', 'Reutilizar evidencia'))),
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(
              onPressed:
                  editable ? () => _photo(q, f, ImageSource.camera) : null,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(_t('Take photo', 'Tomar foto'))),
          OutlinedButton(
              onPressed:
                  editable ? () => _photo(q, f, ImageSource.gallery) : null,
              child: Text(_t('Choose photo', 'Elegir foto'))),
          if (_values[qk][fk] != null)
            TextButton(
                onPressed: () => _viewPhoto('${_values[qk][fk]}'),
                child: Text(_t('View evidence', 'Ver evidencia')))
        ]),
        Text(_values[qk][fk] == null
            ? _t('Required evidence not yet attached',
                'Falta adjuntar evidencia requerida')
            : _t('Evidence attached', 'Evidencia adjunta'))
      ]);
    return TextField(
        controller: _controller(qk, fk),
        enabled: editable,
        keyboardType: f['type'] == 'number'
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        decoration: InputDecoration(
            labelText: label,
            helperText: f['matchRequired'] == true
                ? 'Expected: ${f['expectedByProduct']?[q['appliesToProduct'] ?? _record!['context']['product']] ?? 'NOT CONFIGURED'}'
                : f['type'] == 'scan'
                    ? _t('Scan barcode or enter the identifier',
                        'Escanear código o ingresar identificador')
                    : null),
        onChanged: (v) {
          _values[qk][fk] = f['type'] == 'number'
              ? (v.isEmpty
                  ? null
                  : (num.tryParse(v)?.isFinite == true ? num.parse(v) : v))
              : v;
        });
  }

  void _viewPhoto(String id) {
    _run(() async {
      if (_scope != _currentScope) throw StateError('Session changed');
      final r = await _dio.get<List<int>>('photos/$id',
          queryParameters: {
            'companyId': Global.currentWarehouse?.companyId,
            'warehouseId': Global.currentWarehouse?.id
          },
          options: Options(responseType: ResponseType.bytes, headers: {
            'Authorization': 'Bearer ${Global.currentUser?.token}'
          }));
      if (!mounted || _scope != _currentScope) return;
      await showDialog<void>(
          context: context,
          builder: (c) => Dialog(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Flexible(child: Image.memory(Uint8List.fromList(r.data!))),
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Close'))
              ])));
    });
  }

  Widget _usage(Map q, bool editable) {
    final key = q['key'];
    return DropdownButtonFormField<String>(
        key: ValueKey(
            'usage:${_record!['revision']}:$key:${_values[key]['usage']}'),
        initialValue: _values[key]['usage'] as String?,
        decoration: InputDecoration(
            labelText: _t('Was this material used for the old order? *',
                '¿Se utilizó este material en la orden anterior? *')),
        items: [
          DropdownMenuItem(value: 'Used', child: Text(_t('Used', 'Utilizado'))),
          DropdownMenuItem(
              value: 'Not used', child: Text(_t('Not used', 'No utilizado')))
        ],
        onChanged: editable
            ? (v) => setState(() {
                  _values[key] = <String, dynamic>{'usage': v};
                  if (v == 'Not used')
                    for (final f in q['fields'] as List)
                      if (f['type'] == 'number') _values[key][f['key']] = 0;
                  for (final entry in _inputs.entries)
                    if (entry.key.startsWith('$key:')) entry.value.clear();
                })
            : null);
  }

  void _navigate(int target) {
    _run(() async {
      final items = _stageQuestions;
      if (_page < items.length) {
        final q = items[_page], key = q['key'];
        if (jsonEncode(_values[key]) !=
            jsonEncode(_record!['answers'][key]?['values'] ?? {})) {
          final r = await _request('records/${_record!['id']}/answer', {
            'revision': _record!['revision'],
            'question': key,
            'values': _values[key],
            'complete': false
          });
          _open(Map<String, dynamic>.from(r), page: target);
          return;
        }
      }
      _page = target.clamp(0, items.length);
      _top();
    });
  }

  Widget _questionPages() {
    final items = _stageQuestions;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (items.isNotEmpty) ...[
        Text(_page < items.length
            ? _t('Question ${_page + 1} of ${items.length} — current stage',
                'Pregunta ${_page + 1} de ${items.length} — etapa actual')
            : _t('Stage summary', 'Resumen de etapa')),
        LinearProgressIndicator(
            value: items
                    .where((q) =>
                        _record!['answers'][q['key']]?['complete'] == true ||
                        _record!['na'][q['key']] != null)
                    .length /
                items.length),
        if (_page > 0)
          TextButton(
              onPressed: _busy ? null : () => _navigate(_page - 1),
              child: Text(_t('Previous item', 'Anterior'))),
        const SizedBox(height: 12),
      ],
      if (_page < items.length)
        _question(items[_page])
      else ...[
        for (var i = 0; i < items.length; i++)
          ListTile(
              title: Text(_label(items[i])),
              subtitle: Text(
                  _record!['answers'][items[i]['key']]?['complete'] == true
                      ? 'Complete'
                      : 'Pending'),
              trailing: TextButton(
                  onPressed: _busy ? null : () => _navigate(i),
                  child: Text(_t('Review', 'Revisar')))),
        if (items.isEmpty)
          Text(_t(
              'No questions in this stage. Continue with the required approval.',
              'Esta etapa no tiene preguntas. Continúe con la aprobación requerida.')),
      ]
    ]);
  }

  Widget _question(Map q) {
    final r = _record!, key = q['key'], answer = r['answers'][key] as Map?;
    final current = q['phase'] == r['stage'];
    final editable = current && _cap('qc') && !_busy;
    return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_label(q),
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                      'QC · ${q['phase']} · ${r['na'][key] != null ? 'N/A' : answer?['complete'] == true ? 'Complete' : 'Pending'}'),
                  if (answer?['actor'] != null)
                    Text('Entered: ${answer!['actor']['name']}'),
                  if (answer?['verified'] != null &&
                      answer?['completionMode'] != 'qc-single-submit')
                    Text(
                        'QC verified: ${answer!['verified']['actor']['name']}'),
                  if (r['issues'][key] != null)
                    Text(
                        'Observed: ${r['issues'][key]['reason']}\n${r['issues'][key]['resolved'] == true ? 'Correction: ${r['issues'][key]['remedy']}' : 'OPEN — blocks completion'}',
                        style: const TextStyle(color: Colors.red)),
                  if (r['na'][key] != null)
                    Text(
                        'N/A: ${r['na'][key]['reason']} — ${r['na'][key]['actor']['name']}'),
                  if (q['key'] == 'last_shot')
                    Text(_t(
                        'Reference — Machine: ${r['context']['machine']} · Old product: ${r['context']['previousProduct'] ?? 'Not recorded'}',
                        'Referencia — Máquina: ${r['context']['machine']} · Producto anterior: ${r['context']['previousProduct'] ?? 'Sin registrar'}')),
                  if (_unusedAllowed(q)) _usage(q, editable),
                  if (_values[key]['usage'] == 'Not used')
                    Text(_t('Not used for the old order',
                        'No utilizado en la orden anterior')),
                  for (final f in q['fields'] as List)
                    if (f['key'] != 'usage' &&
                        _values[key]['usage'] != 'Not used')
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _input(q, f as Map, editable)),
                  if (current)
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      if (editable) ...[
                        OutlinedButton(
                            onPressed: () => _act('answer',
                                    question: q,
                                    extra: {
                                      'values': _values[key],
                                      'complete': false
                                    }),
                            child: Text(_t('Save draft', 'Guardar borrador'))),
                        FilledButton(
                            onPressed: () => _act('answer',
                                    question: q,
                                    extra: {
                                      'values': _values[key],
                                      'complete': true
                                    }),
                            child: Text(_t(
                                'Complete & next', 'Completar y siguiente'))),
                        OutlinedButton(
                            onPressed: () => _reasonDialog('issue', q),
                            child:
                                Text(_t('Report issue', 'Reportar problema')))
                      ],
                      if (_cap('qc') &&
                          r['issues'][key] != null &&
                          r['issues'][key]['resolved'] != true)
                        OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _reasonDialog('resolve', q),
                            child: Text(
                                _t('Correct & recheck', 'Corregir y revisar'))),
                    ])
                ])));
  }

  Future<void> _reasonDialog(String action, Map q) async {
    _reason.clear();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(action == 'issue'
                    ? 'Observed problem'
                    : action == 'resolve'
                        ? 'Corrective action and physical recheck'
                        : action == 'cancel'
                            ? 'Reason to void this test record'
                            : 'Temporary N/A justification'),
                content: TextField(
                    controller: _reason,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 2000),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Save'))
                ]));
    if (confirmed == true && _reason.text.trim().isNotEmpty)
      _act(action, question: q, extra: {'reason': _reason.text.trim()});
  }

  Widget _workflow() {
    final r = _record!, stage = r['stage'];
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Current stage: $stage',
                      style: Theme.of(context).textTheme.titleLarge),
                  if (stage == 'sample' || stage == 'pallet') ...[
                    TextField(
                        controller: _reference,
                        enabled: !_busy,
                        decoration: InputDecoration(
                            labelText: stage == 'sample'
                                ? 'MES first sample number'
                                : 'First completed pallet LPN'),
                        textInputAction: TextInputAction.done,
                        autocorrect: false),
                    if (_cap('qc'))
                      OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _act('link',
                                  extra: {'reference': _reference.text}),
                          child: const Text(
                              'Verify existing MES PASS inspection')),
                    Text(
                        'Linked: ${r['links'][stage]?['inspection'] ?? 'Not verified'}')
                  ],
                  if (stage == 'sample') ...[
                    Text(
                        'QC and technician must sign using different authenticated accounts.\nQC: ${r['signatures']['qc']?['actor']?['name'] ?? 'Pending'}\nTechnician: ${r['signatures']['technician']?['actor']?['name'] ?? 'Pending'}'),
                    for (final cap in ['qc', 'technician'])
                      if (_cap(cap))
                        FilledButton(
                            onPressed: _busy
                                ? null
                                : () => _act('sign', extra: {'as': cap}),
                            child: Text(
                                'Sign as $cap — ${_session!['actor']['identity']['name']}'))
                  ],
                  if (['clearance', 'pallet', 'final'].contains(stage) &&
                      _cap('qc'))
                    FilledButton(
                        onPressed: _busy ? null : () => _act('advance'),
                        child: Text(stage == 'final'
                            ? 'Final QC approval & complete'
                            : 'Complete stage & continue')),
                  if (stage == 'supervisor' && _cap('supervisor'))
                    FilledButton(
                        onPressed: _busy ? null : () => _act('sign'),
                        child: const Text('Supervisor approval')),
                  if (!['completed', 'cancelled'].contains(stage) &&
                      _cap('supervisor'))
                    TextButton(
                        onPressed:
                            _busy ? null : () => _reasonDialog('cancel', {}),
                        child: const Text('Void test record with reason')),
                  if (['completed', 'cancelled'].contains(stage))
                    const Text('Completed. Record is read-only.')
                ])));
  }

  @override
  Widget build(BuildContext context) {
    if (!lineClearanceTestEnabled)
      return const Scaffold(
          body: Center(child: Text('Test feature unavailable')));
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
            appBar:
                AppBar(title: const Text('Line Clearance · TEST'), actions: [
              IconButton(
                  tooltip: 'Switch MES account',
                  onPressed: _busy
                      ? null
                      : () {
                          Global.logout();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              'login_page', (_) => false);
                        },
                  icon: const Icon(Icons.logout)),
              IconButton(
                  onPressed:
                      _busy ? null : () => setState(() => _spanish = !_spanish),
                  icon: const Icon(Icons.language)),
              IconButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            if (_record != null) {
                              _open(Map<String, dynamic>.from(
                                  await _request('records/${_record!['id']}')));
                            } else {
                              await _search();
                            }
                          }),
                  icon: const Icon(Icons.refresh))
            ]),
            body: SafeArea(
                child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    children: [
                  const Text(
                      'TEST ENVIRONMENT · Records and photos are stored separately. No production data is changed.'),
                  if (_session != null)
                    Text(
                        '${_session!['actor']['identity']['name']} · ${_session!['shifts']['timezone']}'),
                  if (_busy) const LinearProgressIndicator(),
                  if (_error.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_error,
                            style: const TextStyle(color: Colors.red))),
                  if (_notice.isNotEmpty) Text(_notice),
                  if (_record == null) ...[
                    if (_cap('qc')) ...[
                      TextField(
                          controller: _machine,
                          enabled: !_busy,
                          decoration: InputDecoration(
                              labelText:
                                  _t('Machine scan', 'Escanear máquina')),
                          autocorrect: false,
                          textInputAction: TextInputAction.next),
                      TextField(
                          controller: _wo,
                          enabled: !_busy,
                          decoration: InputDecoration(
                              labelText: _t('New work order (optional)',
                                  'Orden nueva (opcional)')),
                          autocorrect: false,
                          textInputAction: TextInputAction.next),
                      TextField(
                          controller: _previous,
                          enabled: !_busy,
                          decoration: InputDecoration(
                              labelText: _t('Old work order (optional)',
                                  'Orden anterior (opcional)')),
                          autocorrect: false),
                      Text(_t(
                          'Enter at least one old or new work order. Both orders cannot be empty.',
                          'Ingrese al menos una orden anterior o nueva. No pueden estar vacías las dos.')),
                      FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                    if (_operation(_previous.text, _wo.text)
                                        .isEmpty)
                                      throw StateError(_t(
                                          'Enter at least one old or new work order.',
                                          'Ingrese al menos una orden anterior o nueva.'));
                                    final r = await _request('records', {
                                      'machine': _machine.text.trim(),
                                      'workOrder': _wo.text.trim(),
                                      'previousWorkOrder':
                                          _previous.text.trim(),
                                      'nonce': _nonce
                                    });
                                    _open(Map<String, dynamic>.from(r));
                                    _nonce = _newNonce();
                                  }),
                          child: Text(_t('Start Line Clearance',
                              'Iniciar despeje de línea'))),
                    ],
                    const SizedBox(height: 16),
                    Text(
                        _t('Existing test records — tap to resume',
                            'Registros de prueba — tocar para continuar'),
                        style: Theme.of(context).textTheme.titleMedium),
                    for (final r in _records)
                      Card(
                          child: ListTile(
                              title: Text(
                                  '${r['machine']} · ${r['workOrder']?.isNotEmpty == true ? r['workOrder'] : r['previousWorkOrder']}'),
                              subtitle: Text(
                                  '${_modeLabel(r['operation'])} · ${r['date']} · ${r['status']} · ${r['operator']}'),
                              onTap: _busy
                                  ? null
                                  : () => _run(() async {
                                        _open(Map<String, dynamic>.from(
                                            await _request(
                                                'records/${r['id']}')));
                                      })))
                  ] else ...[
                    Text(
                        '${_record!['context']['machine']} · ${_modeLabel(_record!['context']['operation'] ?? _operation(_record!['context']['previousWorkOrder'], _record!['context']['workOrder']))}\nOld order: ${_record!['context']['previousWorkOrder']?.isNotEmpty == true ? _record!['context']['previousWorkOrder'] : '—'}\nNew order: ${_record!['context']['workOrder']?.isNotEmpty == true ? _record!['context']['workOrder'] : '—'}\n${_record!['context']['product']}\n${_record!['context']['shiftDate']} · ${_record!['context']['shift']['start']}–${_record!['context']['shift']['end']} · Template v${_record!['version']}',
                        style: Theme.of(context).textTheme.titleMedium),
                    TextButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                  _record = null;
                                  await _search();
                                }),
                        child: const Text('Back to records')),
                    if (_page >= _stageQuestions.length) _workflow(),
                    if ((_record!['template']['omittedItems'] as List? ?? [])
                        .isNotEmpty)
                      ExpansionTile(
                          title: Text(_t('Not applicable to this operation',
                              'No aplica a esta operación')),
                          children: [
                            for (final q
                                in _record!['template']['omittedItems'] as List)
                              ListTile(
                                  title: Text(_label(q as Map)),
                                  subtitle: Text('${q['reason']}'))
                          ]),
                    _questionPages()
                  ]
                ]))));
  }
}

/// Test APK has its own login destination and never opens production menus.
class LineClearanceTestLaunchPage extends StatefulWidget {
  const LineClearanceTestLaunchPage({super.key});
  @override
  State<LineClearanceTestLaunchPage> createState() =>
      _LineClearanceTestLaunchPageState();
}

class _LineClearanceTestLaunchPageState
    extends State<LineClearanceTestLaunchPage> {
  bool _busy = false;
  String _error = '';
  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20)));
    try {
      const target = 'http://10.0.202.70:4200/api/';
      final response = await dio.get('${target}resource/mobile');
      final body = response.data;
      if (body is! Map || body['result'] != 0 || body['data'] is! Map)
        throw StateError('Test login service unavailable');
      final server = CWMSSiteInformation.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
      server.url = target;
      server.autoConnectFlag = false;
      await Global.selectFactory(
          const FactoryProfile(
              'line-clearance-test', 'Line Clearance Test', target, '20901'),
          server);
      if (mounted) await Navigator.of(context).pushNamed('login_page');
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'Cannot reach the test server. Connect to the factory network / VPN and retry.');
    } finally {
      dio.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Line Clearance Test')),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Line Clearance',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 12),
                            const Text(
                                'Test environment: 10.0.202.70\nSign in with your Colton MES account.\nLine Clearance records and photos are stored separately. This test app does not open production operation menus.'),
                            const SizedBox(height: 24),
                            if (_error.isNotEmpty)
                              Text(_error,
                                  style: const TextStyle(color: Colors.red)),
                            if (_busy) const LinearProgressIndicator(),
                            FilledButton(
                                onPressed: _busy ? null : _connect,
                                child:
                                    const Text('Connect to test environment'))
                          ]))))));
}
