import 'package:cwms_mobile/shared/workspace_ui.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

const appPrivacyUrl = 'https://www.olivetintl.com/claytech-one/privacy.html';
const appSupportUrl = 'https://www.olivetintl.com/claytech-one/support.html';

void openAppPrivacy(BuildContext context) => _openPublicPage(context,
    workspaceIsChinese(context) ? '隐私政策' : 'Privacy Policy', appPrivacyUrl);

void _openPublicPage(BuildContext context, String title, String url) {
  Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PublicInformationPage(title: title, url: url)));
}

class AppInformationPage extends StatefulWidget {
  const AppInformationPage({super.key});

  @override
  State<AppInformationPage> createState() => _AppInformationPageState();
}

class _AppInformationPageState extends State<AppInformationPage> {
  final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final zh = workspaceIsChinese(context);
    return Scaffold(
      backgroundColor: workspaceBackground,
      appBar:
          AppBar(title: Text(zh ? '关于 Claytech One' : 'About Claytech One')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const Icon(Icons.layers_rounded, size: 48, color: workspaceNavy),
              const SizedBox(height: 12),
              const Center(
                  child: Text('Claytech One',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: workspaceNavy))),
              const SizedBox(height: 6),
              const Center(child: Text('olivet international inc.')),
              FutureBuilder<PackageInfo>(
                future: _packageInfo,
                builder: (_, snapshot) => Center(
                    child: Text(
                        snapshot.hasData
                            ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                            : '',
                        style: const TextStyle(color: Colors.grey))),
              ),
              const SizedBox(height: 24),
              Card(
                  child: Column(children: [
                ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(zh ? '隐私政策' : 'Privacy Policy'),
                    onTap: () => openAppPrivacy(context)),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.support_agent_outlined),
                    title: Text(zh ? '技术支持' : 'Technical Support'),
                    onTap: () => _openPublicPage(context,
                        zh ? '技术支持' : 'Technical Support', appSupportUrl)),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(zh ? '开源许可' : 'Open-source Licenses'),
                    onTap: () => showLicensePage(
                        context: context,
                        applicationName: 'Claytech One',
                        applicationVersion: '1.62.3')),
              ])),
              const SizedBox(height: 20),
              Text(zh ? '联系我们' : 'Contact',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const SelectableText(
                  'Brian Wang\nbrianwang@olivetintl.com\n+1 951 681 8888'),
            ]),
          ),
        ),
      ),
    );
  }
}

class PublicInformationPage extends StatefulWidget {
  const PublicInformationPage(
      {super.key, required this.title, required this.url});
  final String title;
  final String url;

  @override
  State<PublicInformationPage> createState() => _PublicInformationPageState();
}

class _PublicInformationPageState extends State<PublicInformationPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
        onWebResourceError: (error) {
          if (mounted && error.isForMainFrame == true) {
            setState(() => _failed = true);
          }
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          return uri?.scheme == 'https' && uri?.host == 'www.olivetintl.com'
              ? NavigationDecision.navigate
              : NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  void _retry() {
    setState(() {
      _failed = false;
      _progress = 0;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final zh = workspaceIsChinese(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
          child: _failed
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(zh
                            ? '页面加载失败，请检查网络后重试。'
                            : 'Could not load this page. Check your connection and retry.'),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _retry,
                            child: Text(zh ? '重试' : 'Retry')),
                        const SizedBox(height: 12),
                        SelectableText(widget.url),
                      ])))
              : Column(children: [
                  if (_progress < 100)
                    LinearProgressIndicator(value: _progress / 100),
                  Expanded(child: WebViewWidget(controller: _controller)),
                ])),
    );
  }
}
