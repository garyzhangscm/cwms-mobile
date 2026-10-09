import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/shared/models/factory_profile.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage(
      {Key? key, this.enableDebugAutoConnect = true, this.connector})
      : super(key: key);
  final bool enableDebugAutoConnect;
  final Future<CWMSSiteInformation> Function(FactoryProfile)? connector;
  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  String? _lastFactoryId;
  String? _connectingId;
  String? _error;
  bool get _chinese => Localizations.localeOf(context).languageCode == 'zh';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final factory = FactoryProfile.byId(prefs.getString('selected_factory'));
    if (!mounted) return;
    setState(() => _lastFactoryId = factory?.id);
    if (factory != null && widget.enableDebugAutoConnect) {
      await _connect(factory);
    }
  }

  Future<void> _connect(FactoryProfile factory) async {
    if (_connectingId != null) return;
    setState(() {
      _connectingId = factory.id;
      _error = null;
    });
    try {
      CWMSSiteInformation server;
      if (widget.connector != null) {
        server = await widget.connector!(factory);
      } else {
        final response = await Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )).get('${factory.url}resource/mobile');
        final body = response.data;
        if (body is! Map || body['result'] != 0 || body['data'] is! Map) {
          throw StateError('Invalid server response');
        }
        server = CWMSSiteInformation.fromJson(
            Map<String, dynamic>.from(body['data'] as Map));
      }
      if (!mounted) return;
      server.url = factory.url;
      server.autoConnectFlag = false;
      await Global.selectFactory(factory, server);
      if (!mounted) return;
      setState(() {
        _lastFactoryId = factory.id;
        _connectingId = null;
      });
      await Navigator.pushNamed(context, 'login_page');
    } catch (_) {
      if (mounted) {
        setState(() => _error = _chinese
            ? '无法连接到 ${factory.name}，请检查工厂网络或 VPN 后重试。'
            : 'Cannot connect to ${factory.name}. Check your factory network or VPN and try again.');
      }
    } finally {
      if (mounted) setState(() => _connectingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF142D4E);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
          title: const Text('Claytech One'),
          backgroundColor: const Color(0xFFF3F5F9),
          foregroundColor: navy,
          elevation: 0,
          scrolledUnderElevation: 0),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 12),
            Text(_chinese ? '选择工厂' : 'Choose your factory',
                style: const TextStyle(
                    fontSize: 25, fontWeight: FontWeight.w700, color: navy)),
            const SizedBox(height: 8),
            Text(
                _chinese ? '点选工作地点，即可登录。' : 'Select your workplace to sign in.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF718096))),
            const SizedBox(height: 26),
            for (var i = 0; i < FactoryProfile.values.length; i++)
              _factoryCard(FactoryProfile.values[i], i),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Color(0xFFB42318), fontSize: 14))),
            const SizedBox(height: 16),
            Text(
                _chinese
                    ? '系统会记住您上次选择的工厂。'
                    : 'Your last selected factory will be remembered.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
          ]),
        )),
      )),
    );
  }

  Widget _factoryCard(FactoryProfile factory, int index) {
    final selected = factory.id == _lastFactoryId;
    final busy = factory.id == _connectingId;
    const colors = [
      Color(0xFF2865D9),
      Color(0xFF168579),
      Color(0xFF8A6737),
      Color(0xFF7956B6)
    ];
    const symbols = [
      Icons.precision_manufacturing_outlined,
      Icons.precision_manufacturing_outlined,
      Icons.refresh_rounded,
      Icons.inventory_2_outlined
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: selected ? colors[index] : const Color(0xFFE0E6EF))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey(factory.id),
          onTap: _connectingId == null ? () => _connect(factory) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: colors[index].withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(symbols[index], color: colors[index], size: 25)),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(factory.name,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF142D4E))),
                    if (selected)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_chinese ? '上次选择' : 'Last selected',
                              style: TextStyle(
                                  fontSize: 12, color: colors[index]))),
                  ])),
              if (busy)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
          ),
        ),
      ),
    );
  }
}
