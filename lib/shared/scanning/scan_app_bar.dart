import 'package:flutter/material.dart';
import 'server_connection.dart';

class ScanAppBar extends AppBar {
  ScanAppBar(
      {super.key,
      super.title,
      super.leading,
      super.automaticallyImplyLeading,
      super.backgroundColor,
      super.foregroundColor,
      super.elevation,
      super.scrolledUnderElevation,
      super.centerTitle,
      super.bottom,
      super.toolbarHeight,
      List<Widget>? actions})
      : super(actions: [
          const ServerConnectionIndicator(),
          ...?actions,
          if (actions == null) const _ScanDrawerButton()
        ]);
}

class _ScanDrawerButton extends StatelessWidget {
  const _ScanDrawerButton();
  @override
  Widget build(BuildContext context) => Scaffold.of(context).hasEndDrawer
      ? const EndDrawerButton()
      : const SizedBox.shrink();
}

class ServerConnectionIndicator extends StatefulWidget {
  const ServerConnectionIndicator({super.key, this.monitor});
  final ServerConnectionMonitor? monitor;
  @override
  State<ServerConnectionIndicator> createState() =>
      _ServerConnectionIndicatorState();
}

class _ServerConnectionIndicatorState extends State<ServerConnectionIndicator> {
  ServerConnectionMonitor get monitor =>
      widget.monitor ?? ServerConnectionMonitor.shared;
  @override
  void initState() {
    super.initState();
    monitor.attach();
  }

  @override
  void dispose() {
    monitor.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: monitor,
      builder: (context, _) {
        final es = Localizations.localeOf(context).languageCode == 'es';
        final state = monitor.visibleState;
        final label = switch (state) {
          ServerConnectionState.connected => es ? 'Conectado' : 'Connected',
          ServerConnectionState.disconnected => es ? 'Sin conexión' : 'Offline',
          ServerConnectionState.signIn => es ? 'Iniciar sesión' : 'Sign in',
          ServerConnectionState.checking => es ? 'Comprobando' : 'Checking',
        };
        final color = switch (state) {
          ServerConnectionState.connected => Colors.green,
          ServerConnectionState.disconnected => Colors.red,
          _ => Colors.orange,
        };
        return Tooltip(
            message: label,
            child: Semantics(
                label: 'Server: $label',
                liveRegion: true,
                child: InkWell(
                    onTap: monitor.check,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 60),
                              child: Text(label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      TextStyle(fontSize: 10, color: color))),
                        ])))));
      });
}
