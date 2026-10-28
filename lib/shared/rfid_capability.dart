import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum RfidHardware { checking, available, unavailable, unsupported, unknown }

class RfidCapability {
  static final state = ValueNotifier<RfidHardware>(RfidHardware.checking);
  static Future<void>? _pending;
  static bool _checked = false;
  static bool get visible =>
      state.value == RfidHardware.available ||
      state.value == RfidHardware.unavailable;
  static bool isRfid(String? route) =>
      route == 'work_order_rfid_check' || route == 'work_order_rfid_pallet';
  static Future<void> check({bool retry = false}) {
    if (_pending != null) return _pending!;
    if (_checked && !retry) return Future.value();
    _pending = _detect().whenComplete(() {
      _pending = null;
      _checked = true;
    });
    return _pending!;
  }

  static Future<void> _detect() async {
    final wasVerified = visible;
    state.value = RfidHardware.checking;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      state.value = RfidHardware.unsupported;
      return;
    }
    try {
      final result = await const MethodChannel('cwms_mobile/rfid')
          .invokeMethod<String>('capabilities')
          .timeout(const Duration(seconds: 12));
      state.value = switch (result) {
        'available' => RfidHardware.available,
        'unavailable' => RfidHardware.unavailable,
        'unsupported' => RfidHardware.unsupported,
        _ => wasVerified ? RfidHardware.unavailable : RfidHardware.unknown,
      };
    } on MissingPluginException {
      state.value = RfidHardware.unsupported;
    } catch (_) {
      state.value =
          wasVerified ? RfidHardware.unavailable : RfidHardware.unknown;
    }
  }
}

/// All menu surfaces rebuild together when the asynchronous probe finishes.
class RfidMenuGate extends StatefulWidget {
  const RfidMenuGate({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  State<RfidMenuGate> createState() => _RfidMenuGateState();
}

class _RfidMenuGateState extends State<RfidMenuGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => RfidCapability.check());
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<RfidHardware>(
      valueListenable: RfidCapability.state,
      builder: (context, state, _) => widget.builder(context));
}

class RfidHardwareNotice extends StatelessWidget {
  const RfidHardwareNotice({super.key});
  @override
  Widget build(BuildContext context) {
    final status = RfidCapability.state.value;
    if (status == RfidHardware.available || status == RfidHardware.unsupported)
      return const SizedBox.shrink();
    final es = Localizations.localeOf(context).languageCode == 'es';
    final message = status == RfidHardware.checking
        ? (es ? 'Comprobando lector RFID…' : 'Checking RFID reader…')
        : status == RfidHardware.unavailable
            ? (es
                ? 'Lector RFID temporalmente no disponible. Cierre otras aplicaciones RFID y reintente.'
                : 'RFID reader temporarily unavailable. Close other RFID apps and retry.')
            : (es
                ? 'No se pudo confirmar un lector RFID compatible. Reintente para mostrar las funciones RFID.'
                : 'Could not confirm a compatible RFID reader. Retry to show RFID functions.');
    return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message),
          if (status != RfidHardware.checking)
            TextButton(
                onPressed: () => RfidCapability.check(retry: true),
                child: Text(es ? 'Reintentar RFID' : 'Retry RFID detection')),
        ]));
  }
}
