import 'ota_update_scope.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../global.dart';
import 'ota_update_controller.dart';
import 'update_activity.dart';

/// Dart-only: compatible with the existing Android Shorebird baseline.
/// Closing is explicit, with a warning about unsaved input; there is no timer
/// that kills the process while a production transaction is running.
class OtaUpdateGate extends StatefulWidget {
  const OtaUpdateGate(
      {super.key,
      required this.child,
      required this.navigatorKey,
      this.updateController,
      this.androidEnabled,
      this.closeApp,
      this.releaseVersion});
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final OtaUpdateController? updateController;
  final bool? androidEnabled;
  final VoidCallback? closeApp;
  final String? releaseVersion;
  @override
  State<OtaUpdateGate> createState() => _OtaUpdateGateState();
}

class _OtaUpdateGateState extends State<OtaUpdateGate>
    with WidgetsBindingObserver {
  late final OtaUpdateController controller;
  Timer? timer;
  String release = '';
  String? lastScope;
  String? policyServer;
  DateTime lastCheck = DateTime.fromMillisecondsSinceEpoch(0);
  bool closing = false;
  bool enforcing = false;
  bool get enabled => widget.androidEnabled ?? Platform.isAndroid;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = widget.updateController ??
        OtaUpdateController(
            gateway: ShorebirdGateway(), loadPolicy: _loadPolicy);
    controller.addListener(_changed);
    UpdateActivity.instance.addListener(_changed);
    release = widget.releaseVersion ?? '';
    if (enabled && widget.updateController == null) _start();
  }

  Future<void> _start() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    release = '${info.version}+${info.buildNumber}';
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed)
        return;
      final scope = "${Global.currentServer?.url}:${Global.currentUser?.token}";
      if (scope != lastScope ||
          DateTime.now().difference(lastCheck) >= const Duration(minutes: 15)) {
        lastScope = scope;
        lastCheck = DateTime.now();
        controller.check();
      }
    });
    await controller.check();
  }

  Future<OtaPolicy> _loadPolicy() async {
    final server = Global.currentServer?.url;
    if (server != policyServer) {
      policyServer = server;
      controller.policy = const OtaPolicy();
    }
    final token = Global.currentUser?.token;
    if (server == null || server.isEmpty || token == null || token.isEmpty)
      return const OtaPolicy();
    final client = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5)));
    try {
      final response = await client.get(
          '${server.replaceAll(RegExp(r'/+$'), '')}/resource/rf-app-version/ota-policy',
          queryParameters: {
            'releaseVersion': release,
            'companyId': Global.getLastLoginCompanyId()
          },
          options: Options(headers: {
            'Cache-Control': 'no-cache',
            'Authorization': 'Bearer $token'
          }));
      if (Global.currentServer?.url != server) return const OtaPolicy();
      final body = response.data as Map<String, dynamic>;
      final data = body.containsKey('data')
          ? body['data'] as Map<String, dynamic>
          : body;
      return OtaPolicy.fromJson(data, release);
    } finally {
      client.close();
    }
  }

  void _changed() {
    if (!mounted) return;
    if (!controller.mandatory) enforcing = false;
    if (controller.mandatory && !UpdateActivity.instance.busy) enforcing = true;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && release.isNotEmpty && enabled)
      controller.check();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    UpdateActivity.instance.removeListener(_changed);
    controller.removeListener(_changed);
    // In-flight checks may finish after dispose; their notifier is still valid.
    super.dispose();
  }

  Future<void> _close(BuildContext context) async {
    if (UpdateActivity.instance.busy || closing) return;
    setState(() => closing = true);
    final dialogContext = widget.navigatorKey.currentContext;
    if (dialogContext == null) {
      setState(() => closing = false);
      return;
    }
    final confirmed = await showDialog<bool>(
        context: dialogContext,
        builder: (context) => AlertDialog(
              title: const Text('Close app to apply update?'),
              content: const Text(
                  'Check that your last operation completed successfully. Unsaved entries will be lost. After closing, tap the app icon to reopen it.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Close app'))
              ],
            ));
    if (!mounted) return;
    setState(() => closing = false);
    if (confirmed == true &&
        !UpdateActivity.instance.busy &&
        controller.ready &&
        enabled) {
      if (widget.closeApp != null) {
        widget.closeApp!();
      } else {
        exit(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final show = enabled &&
        controller.visible &&
        !closing &&
        (!UpdateActivity.instance.busy || enforcing);
    return OtaUpdateScope(
        controller: controller,
        child: Stack(children: [
          widget.child,
          if (show)
            Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: controller.mandatory ? 0 : null,
                child: Material(
                  color: controller.mandatory
                      ? Colors.black54
                      : Colors.transparent,
                  child: Align(
                    alignment: controller.mandatory
                        ? Alignment.center
                        : Alignment.bottomCenter,
                    child: SafeArea(
                        child: Builder(
                            builder: (innerContext) => Card(
                                  margin: const EdgeInsets.all(16),
                                  child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                controller.mandatory
                                                    ? 'Required update ready'
                                                    : 'App update ready',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge),
                                            const SizedBox(height: 8),
                                            Text(
                                                '$release · Patch ${controller.current} -> ${controller.next}'),
                                            const SizedBox(height: 8),
                                            Text(controller
                                                    .policy.message.isEmpty
                                                ? 'Close and reopen the app to apply the update.'
                                                : controller.policy.message),
                                            if (controller.mandatory)
                                              const Text(
                                                  'Update before starting another operation.'),
                                            const SizedBox(height: 12),
                                            Wrap(spacing: 12, children: [
                                              if (!controller.mandatory)
                                                TextButton(
                                                    onPressed: controller.defer,
                                                    child: const Text('Later')),
                                              FilledButton(
                                                  onPressed: closing ||
                                                          UpdateActivity
                                                              .instance.busy
                                                      ? null
                                                      : () =>
                                                          _close(innerContext),
                                                  child: const Text(
                                                      'Close and reopen')),
                                            ]),
                                          ])),
                                ))),
                  ),
                )),
        ]));
  }
}
