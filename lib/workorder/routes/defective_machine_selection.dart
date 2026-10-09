import 'package:flutter/material.dart';
import '../../shared/workspace_ui.dart';
import '../models/work_order.dart';
import '../services/defective_machines.dart';

class DefectiveMachineSelectionPage extends StatefulWidget {
  const DefectiveMachineSelectionPage({super.key, this.loader});
  final Future<List<DefectiveMachine>> Function()? loader;
  @override
  State<DefectiveMachineSelectionPage> createState() =>
      _DefectiveMachineSelectionPageState();
}

class _DefectiveMachineSelectionPageState
    extends State<DefectiveMachineSelectionPage> {
  List<DefectiveMachine> _machines = [];
  bool _loading = true;
  bool _refreshing = false;
  bool _previewOnly = false;
  String? _error;
  bool _opening = false;
  bool _preparing = false;
  bool get _zh => workspaceIsChinese(context);
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (mounted)
      setState(() {
        if (widget.loader == null && _machines.isEmpty) {
          _machines = DefectiveMachineService.preview;
          _previewOnly =
              _machines.isNotEmpty && !DefectiveMachineService.previewIsFresh;
        }
        _loading = _machines.isEmpty;
        _refreshing = true;
        _error = null;
      });
    try {
      final machines = await (widget.loader != null
          ? widget.loader!()
          : DefectiveMachineService.load(
              forceRefresh: refresh,
              onProgress: (machines) {
                if (!mounted) return;
                setState(() {
                  _machines = machines;
                  _previewOnly = false;
                  _loading = false;
                });
              }));
      if (!mounted) return;
      setState(() {
        _machines = machines;
        _previewOnly = false;
        _loading = false;
        _refreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error =
            _zh ? '机器资料加载失败，请重试。' : 'Unable to load machines. Please retry.';
      });
    }
  }

  Future<void> _open(DefectiveMachine machine) async {
    if (_opening || _previewOnly) return;
    setState(() => _opening = true);
    try {
      WorkOrder? order;
      if (machine.orders.length == 1) {
        order = machine.orders.single;
      } else {
        order = await showModalBottomSheet<WorkOrder>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => FractionallySizedBox(
                heightFactor: .65,
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                          '${machine.line.name} · ${_zh ? "选择工单" : "Choose work order"}',
                          style: Theme.of(context).textTheme.titleLarge)),
                  Expanded(
                      child: ListView.builder(
                          itemCount: machine.orders.length,
                          itemBuilder: (_, index) {
                            final value = machine.orders[index];
                            return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 10),
                                title: Text(value.item?.name ??
                                    (_zh ? '物料资料缺失' : 'Item unavailable')),
                                subtitle: Text(value.number ?? ''),
                                onTap: () => Navigator.pop(context, value));
                          })),
                ])));
      }
      if (!mounted || order == null) return;
      if (widget.loader == null) {
        setState(() => _preparing = true);
        try {
          await DefectiveMachineService.prepareOrder(order);
          if (!mounted) return;
          setState(() => _preparing = false);
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_zh
                  ? '报产资料加载失败，请重试。'
                  : 'Unable to load reporting details. Please retry.')));
          return;
        }
      }
      if (order.item == null || order.item!.itemPackageTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_zh
                ? '物料或包装资料缺失，请刷新或检查配置。'
                : 'Item or package details are missing. Refresh or check configuration.')));
        return;
      }
      await Navigator.pushNamed(context, 'work_order_defective_inventory',
          arguments: {'workOrder': order, 'productionLine': machine.line});
      if (mounted) await _load(refresh: true);
    } finally {
      if (mounted)
        setState(() {
          _opening = false;
          _preparing = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(title: Text(_zh ? '废品报产' : 'Defective'), actions: [
        IconButton(
            tooltip: _zh ? '刷新' : 'Refresh',
            onPressed:
                _refreshing || _opening ? null : () => _load(refresh: true),
            icon: const Icon(Icons.refresh_rounded)),
      ]),
      body: SafeArea(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_zh ? '选择机器' : 'Choose a machine',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                  _zh
                      ? '点击正在生产的机器，开始废品报产。'
                      : 'Select your assigned machine to report defective output.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: const Color(0xFF65748B))),
            ])),
        if (_preparing || (_refreshing && !_loading))
          const LinearProgressIndicator(minHeight: 2),
        if (_refreshing && _machines.isNotEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(_zh ? '正在更新机器资料…' : 'Updating machines…',
                  style: Theme.of(context).textTheme.bodySmall)),
        if (_error != null && _machines.isNotEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.orange))),
                TextButton(
                    onPressed: () => _load(refresh: true),
                    child: Text(_zh ? '重试' : 'Retry')),
              ])),
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _machines.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            Text(_error!),
                            TextButton(
                                onPressed: _load,
                                child: Text(_zh ? '重试' : 'Retry'))
                          ]))
                    : _machines.isEmpty
                        ? Center(
                            child: Text(_zh
                                ? '暂无已分配有效工单的机器'
                                : 'No machines with active assigned work orders'))
                        : RefreshIndicator(
                            onRefresh: () => _load(refresh: true),
                            child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                itemCount: (_machines.length / 3).ceil(),
                                itemBuilder: (_, row) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: IntrinsicHeight(
                                          child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          for (var column = 0;
                                              column < 3;
                                              column++) ...[
                                            if (column > 0)
                                              const SizedBox(width: 8),
                                            Expanded(
                                                child: row * 3 + column <
                                                        _machines.length
                                                    ? _card(_machines[
                                                        row * 3 + column])
                                                    : const SizedBox.shrink()),
                                          ],
                                        ],
                                      )),
                                    )))),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextButton.icon(
                onPressed: _opening
                    ? null
                    : () async {
                        await Navigator.pushNamed(
                            context, 'work_order_defective_manual');
                        if (mounted) _load(refresh: true);
                      },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label:
                    Text(_zh ? '扫描／输入机器编号' : 'Scan / enter machine number'))),
      ])));

  Widget _card(DefectiveMachine machine) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE1E7F0))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _opening || _previewOnly ? null : () => _open(machine),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 112),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                Text(machine.line.name ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF163150))),
                const SizedBox(height: 8),
                for (final name in machine.orders
                    .map((order) =>
                        order.item?.name ??
                        (_refreshing
                            ? '…'
                            : (_zh ? '物料资料缺失' : 'Item unavailable')))
                    .toSet())
                  Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF65748B)))),
              ]),
            ),
          ),
        ),
      );
}
