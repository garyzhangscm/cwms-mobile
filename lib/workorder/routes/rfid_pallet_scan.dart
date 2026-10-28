import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/rfid_pallet.dart';
import '../services/rfid_catalog.dart';

class RfidPalletScanPage extends StatefulWidget {
  const RfidPalletScanPage(
      {super.key, this.loadCatalog, this.loadBatch, this.scopeKey});
  final Future<RfidCatalog> Function()? loadCatalog;
  final Future<RfidCatalog> Function(Set<String>)? loadBatch;
  final String Function()? scopeKey;
  @override
  State<RfidPalletScanPage> createState() => _RfidPalletScanPageState();
}

class _RfidPalletScanPageState extends State<RfidPalletScanPage>
    with WidgetsBindingObserver {
  static const channel = MethodChannel('cwms_mobile/rfid');
  RfidPallet pallet = RfidPallet();
  RfidCatalog? catalog;
  bool loading = false,
      catalogError = false,
      scanning = false,
      stopping = false;
  bool canLeave = false, leaving = false;
  String? scanError;
  int? readerPower;
  bool changingPower = false;
  int runId = 0, catalogGeneration = 0, lastAdded = 0;
  DateTime? lastNewTag;
  Timer? ticker, lookupTimer;
  final Set<String> attemptedUpcs = {};
  String scope = '';
  String tr(String en, String es) =>
      Localizations.localeOf(context).languageCode == 'es' ? es : en;
  String currentScope() => (widget.scopeKey ?? RfidCatalogService.scope)();
  void invoke(String method, [Object? args]) {
    channel.invokeMethod<void>(method, args).catchError((Object _) {});
  }

  @override
  void initState() {
    super.initState();
    scope = currentScope();
    WidgetsBinding.instance.addObserver(this);
    channel.setMethodCallHandler((call) async {
      if (!mounted) return;
      if (call.method == 'readerPower' && call.arguments is Map) {
        final value = (call.arguments as Map)['dbm'];
        if (value is int && currentScope() == scope) {
          setState(() {
            readerPower = value;
          });
        }
        return;
      }
      if (call.method == 'trigger') {
        toggle();
        return;
      }
      if (call.method == 'palletTags' && call.arguments is Map) {
        final data = call.arguments as Map;
        if (scanning && data['session'] == runId && currentScope() == scope) {
          final values = data['epcs'];
          if (values is List) accept(values.whereType<String>());
        }
      }
    });
    invoke('activate', {'palletMode': true});
    invoke('arm', true);
    if (widget.loadCatalog != null) reloadCatalog();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (currentScope() != scope) {
        invoke('deactivate');
        setState(() {
          scanning = false;
          stopping = false;
          runId++;
          pallet = RfidPallet();
          attemptedUpcs.clear();
          catalog = null;
          catalogGeneration++;
          loading = false;
          catalogError = true;
        });
        return;
      }
      if (scanning) setState(() {});
    });
  }

  Future<void> reloadCatalog({bool forceRefresh = false}) async {
    if (loading) return;
    final requested = pallet.counts.keys.toSet();
    if (widget.loadCatalog == null && requested.isEmpty) return;
    attemptedUpcs.addAll(requested);
    final token = ++catalogGeneration;
    setState(() {
      loading = true;
      catalogError = false;
    });
    try {
      final result = await (widget.loadCatalog != null
          ? widget.loadCatalog!()
          : widget.loadBatch != null
              ? widget.loadBatch!(requested)
              : RfidCatalogService.load(requested, forceRefresh: forceRefresh));
      if (mounted && token == catalogGeneration && currentScope() == scope)
        setState(() {
          catalog = result;
        });
    } catch (_) {
      if (mounted && token == catalogGeneration)
        setState(() {
          catalogError = true;
        });
    } finally {
      if (mounted && token == catalogGeneration)
        setState(() {
          loading = false;
        });
      scheduleLookup();
    }
  }

  void scheduleLookup() {
    if (!mounted ||
        loading ||
        currentScope() != scope ||
        widget.loadCatalog != null) return;
    if (!pallet.counts.keys.any((code) => !attemptedUpcs.contains(code)))
      return;
    lookupTimer ??= Timer(const Duration(milliseconds: 350), () {
      lookupTimer = null;
      if (mounted) reloadCatalog();
    });
  }

  void accept(Iterable<String> values) {
    final added = pallet.add(values);
    setState(() {
      if (added > 0) {
        lastAdded = added;
        lastNewTag = DateTime.now();
      }
    });
    scheduleLookup();
    if (pallet.atCapacity) stop();
  }

  void toggle() {
    if (stopping || changingPower || leaving) return;
    if (scanning) {
      stop();
    } else {
      unawaited(start());
    }
  }

  Future<void> start() async {
    if (scanning ||
        changingPower ||
        currentScope() != scope ||
        pallet.atCapacity) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      setState(() {
        scanError = tr('Use a supported Chainway Android handheld.',
            'Use un terminal Android Chainway compatible.');
      });
      return;
    }
    final token = ++runId;
    setState(() {
      scanning = true;
      stopping = false;
      scanError = null;
      lastAdded = 0;
      lastNewTag = DateTime.now();
    });
    try {
      final result = await channel
          .invokeMapMethod<String, dynamic>('scanPallet', {'session': token});
      if (!mounted || token != runId || currentScope() != scope) return;
      final tail = result?['epcs'];
      if (tail is List) accept(tail.whereType<String>());
      final reason = result?['reason'];
      if (reason == 'limit')
        setState(() {
          scanError = tr(
              'Scan batch limit reached. Continue scanning to collect more tags.',
              'Se alcanzó el límite de lectura. Continúe escaneando para leer más etiquetas.');
        });
    } catch (_) {
      if (mounted && token == runId)
        setState(() {
          scanError = tr(
              'Reader interrupted or unavailable. Counts are retained; close the UHF demo and try again.',
              'Lector interrumpido o no disponible. Se conservan los recuentos; cierre la demostración UHF e inténtelo de nuevo.');
        });
    } finally {
      if (mounted && token == runId)
        setState(() {
          scanning = false;
          stopping = false;
        });
    }
  }

  void stop() {
    if (!scanning || stopping) return;
    setState(() {
      stopping = true;
    });
    invoke('stopPallet');
  }

  Future<bool> confirm(String message) async =>
      await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(content: Text(message), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(tr('Cancel', 'Cancelar'))),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(tr('Confirm', 'Confirmar'))),
              ])) ??
      false;
  Future<void> changePower(int? value) async {
    if (value == null ||
        value == readerPower ||
        scanning ||
        changingPower ||
        currentScope() != scope) return;
    setState(() {
      changingPower = true;
    });
    try {
      if (pallet.uniqueTags > 0 &&
          !await confirm(tr(
              'Changing power clears this count so earlier stray reads are removed. Continue?',
              'Cambiar la potencia borra este recuento para eliminar lecturas anteriores. ¿Continuar?')))
        return;
      if (!mounted || currentScope() != scope) return;
      final actual =
          await channel.invokeMethod<int>('setPalletPower', {'dbm': value});
      if (!mounted || currentScope() != scope) return;
      if (actual != value) throw StateError('Power not verified');
      setState(() {
        readerPower = actual;
        pallet = RfidPallet();
        attemptedUpcs.clear();
        runId++;
        lastAdded = 0;
        lastNewTag = null;
        scanError = null;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          readerPower = null;
          scanError = tr('Power change failed. Try again before scanning.',
              'No se pudo cambiar la potencia. Inténtelo de nuevo antes de escanear.');
        });
    } finally {
      if (mounted)
        setState(() {
          changingPower = false;
        });
    }
  }

  Future<void> newPallet() async {
    if (scanning) return;
    if (pallet.uniqueTags > 0 &&
        !await confirm(tr('Clear this count and start a new pallet?',
            '¿Borrar este recuento y comenzar un palé nuevo?'))) return;
    if (!mounted) return;
    setState(() {
      runId++;
      pallet = RfidPallet();
      attemptedUpcs.clear();
      lastAdded = 0;
      lastNewTag = null;
      scanError = null;
    });
  }

  Future<void> leave() async {
    if (leaving || changingPower) return;
    leaving = true;
    stop();
    if (pallet.uniqueTags > 0 || scanning) {
      if (!await confirm(tr('Leave this page? This pallet count is not saved.',
          '¿Salir de esta página? El recuento de este palé no se guarda.'))) {
        leaving = false;
        return;
      }
    }
    if (!mounted) return;
    invoke('deactivate');
    setState(() {
      canLeave = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && currentScope() == scope) {
      invoke('activate', {'palletMode': true});
      invoke('arm', true);
    } else {
      readerPower = null;
      invoke('cancel');
      if (mounted)
        setState(() {
          runId++;
          scanning = false;
          stopping = false;
        });
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    lookupTimer?.cancel();
    runId++;
    catalogGeneration++;
    invoke('deactivate');
    channel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = pallet.counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final stale = scanning &&
        lastNewTag != null &&
        DateTime.now().difference(lastNewTag!).inSeconds >= 3;
    return PopScope(
        canPop: canLeave,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) leave();
        },
        child: Scaffold(
          appBar: AppBar(
              title: Text(tr('RFID Pallet Scan', 'Escaneo RFID de palé'))),
          body: SafeArea(
              child: ListView(padding: const EdgeInsets.all(16), children: [
            Text(tr('Scan one pallet. Keep nearby tagged products away.',
                'Escanee un solo palé. Aleje los productos etiquetados cercanos.')),
            const SizedBox(height: 8),
            Text(readerPower == null
                ? tr('Whole pallet mode · Checking reader power…',
                    'Modo palé completo · Comprobando potencia…')
                : tr('Whole pallet mode · $readerPower dBm',
                    'Modo palé completo · $readerPower dBm')),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
                initialValue: readerPower != null &&
                        readerPower! >= 5 &&
                        readerPower! <= 30
                    ? readerPower
                    : null,
                key: ValueKey('power-$readerPower'),
                decoration: InputDecoration(
                    labelText: tr('Scan power', 'Potencia de lectura'),
                    helperText: changingPower
                        ? tr('Applying and verifying…',
                            'Aplicando y comprobando…')
                        : tr('Stop scanning to adjust · Saved on this device',
                            'Detenga la lectura para ajustar · Guardado en este dispositivo')),
                items: List.generate(
                    26,
                    (i) => DropdownMenuItem(
                        value: i + 5, child: Text('${i + 5} dBm'))),
                onChanged: scanning ||
                        stopping ||
                        changingPower ||
                        currentScope() != scope
                    ? null
                    : changePower),
            const SizedBox(height: 16),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Text(tr('Items read', 'Unidades leídas')),
                      Text('${pallet.itemsRead}',
                          style: const TextStyle(
                              fontSize: 64, fontWeight: FontWeight.bold)),
                      Text(tr('Unique RFID tags — not confirmed inventory',
                          'Etiquetas RFID únicas — inventario sin confirmar')),
                      if (scanning)
                        Text(tr('Latest additions: $lastAdded',
                            'Últimas añadidas: $lastAdded')),
                    ]))),
            if (scanning) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: stopping ||
                        changingPower ||
                        currentScope() != scope ||
                        pallet.atCapacity
                    ? null
                    : toggle,
                icon: Icon(scanning ? Icons.stop : Icons.sensors),
                label: Text(stopping
                    ? tr('Stopping…', 'Deteniendo…')
                    : scanning
                        ? tr('Stop scan', 'Detener escaneo')
                        : pallet.uniqueTags == 0
                            ? tr('Start scan', 'Iniciar escaneo')
                            : tr('Continue scan', 'Continuar escaneo'))),
            OutlinedButton(
                onPressed: scanning || changingPower ? null : newPallet,
                child: Text(tr('New pallet', 'Nuevo palé'))),
            if (stale)
              Text(tr(
                  'No new tags. Move around the pallet to check for missed tags.',
                  'No hay etiquetas nuevas. Muévase alrededor del palé para buscar etiquetas sin leer.')),
            if (currentScope() != scope)
              Text(tr('Login changed. Reopen this page to scan.',
                  'Cambió la sesión. Vuelva a abrir esta página para escanear.')),
            if (scanError != null)
              Text(scanError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (pallet.atCapacity)
              Text(tr('Session capacity reached. Stop and review this count.',
                  'Se alcanzó la capacidad de la sesión. Deténgase y revise el recuento.')),
            if (groups.length > 1)
              Text(
                  tr('Multiple products detected. Check for mixed goods or nearby pallets.',
                      'Se detectaron varios productos. Compruebe si hay productos mezclados o palés cercanos.'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            if (pallet.unsupported > 0)
              Text(tr(
                  'Unrecognized tags: ${pallet.unsupported} (excluded from item count)',
                  'Etiquetas no reconocidas: ${pallet.unsupported} (excluidas del recuento)')),
            const SizedBox(height: 12),
            if (loading)
              Text(catalog == null
                  ? tr('Loading item names…', 'Cargando nombres de productos…')
                  : tr('Refreshing item names in background…',
                      'Actualizando nombres en segundo plano…')),
            if (catalogError)
              Text(tr(
                  catalog == null
                      ? 'Item lookup unavailable. Counts are retained; retry loading.'
                      : 'Refresh failed. Showing previously loaded item names; retry to get latest changes.',
                  catalog == null
                      ? 'Consulta de productos no disponible. Se conservan los recuentos; vuelva a cargar.'
                      : 'No se pudo actualizar. Se muestran los nombres anteriores; vuelva a intentarlo.')),
            TextButton(
                onPressed: loading || scanning || currentScope() != scope
                    ? null
                    : () => reloadCatalog(forceRefresh: true),
                child: Text(tr(
                    'Refresh item names', 'Actualizar nombres de productos'))),
            for (final group in groups) productCard(group.key, group.value),
            const SizedBox(height: 16),
            Text(tr(
                'Counts stay only on this page. No MES inventory is changed.',
                'Los recuentos se conservan solo en esta página. No se modifica el inventario MES.')),
          ])),
        ));
  }

  Widget productCard(String gtin, int count) {
    final items = catalog?.matches(gtin) ?? <RfidItem>[];
    final title = catalog == null
        ? tr('Item name unavailable', 'Nombre no disponible')
        : items.isEmpty
            ? loading || !attemptedUpcs.contains(gtin)
                ? tr('Looking up item…', 'Buscando producto…')
                : catalogError
                    ? tr('Item name unavailable', 'Nombre no disponible')
                    : tr('Unmatched UPC', 'UPC sin coincidencia')
            : items.length > 1
                ? tr('UPC matches multiple items',
                    'El UPC coincide con varios productos')
                : items.single.name;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              if (items.length == 1) Text(items.single.description),
              if (items.length > 1) Text(items.map((i) => i.name).join(', ')),
              SelectableText('GTIN: $gtin'),
              Text(tr('$count items read', '$count unidades leídas'),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ])));
  }
}
