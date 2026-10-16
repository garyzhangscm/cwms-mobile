import 'package:cwms_mobile/i18n/spanish_ui.dart';import 'package:cwms_mobile/inventory/services/qc_failure_review.dart';
import 'package:cwms_mobile/inventory/widgets/qc_review_strings.dart';
import 'package:cwms_mobile/shared/updates/update_activity.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/adaptive_layout.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/inventory/services/qc_inspection.dart';
import 'package:cwms_mobile/inventory/widgets/qc_inspection_item_option_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:flutter/material.dart';

import '../models/qc_inspection_request_item.dart';
import '../models/qc_inspection_request_item_option.dart';
import '../models/qc_rule_item_type.dart';

typedef QCReviewSubmitter = Future<List<QCInspectionRequest>> Function(
  List<QCInspectionRequest> requests, {
  required bool failureAcknowledged,
});
typedef QCReviewPreparer = Future<QCInspectionRequest> Function(
  QCInspectionRequest request,
);

class QCInspectionPage extends StatefulWidget {
  QCInspectionPage({Key? key, this.submit, this.prepare, this.checkStatus})
      : super(key: key);
  final QCReviewSubmitter? submit;
  final QCReviewPreparer? prepare;
  final Future<QCInspectionRequest> Function(int)? checkStatus;

  @override
  State<StatefulWidget> createState() => _QCInspectionPageState();
}

class _QCInspectionPageState extends State<QCInspectionPage> {
  int? _qcInspectionRequestItemIndex;
  QCInspectionRequest? _qcInspectionRequest;
  TextEditingController _qcQuantityController = new TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _busy = false, _loading = false, _uncertain = false;
  bool _reviewEnabled = true;
  String? _prepareError;
  String? _serverUrl;
  int? _warehouseId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_qcInspectionRequest != null) return;
    _qcInspectionRequest =
        ModalRoute.of(context)?.settings.arguments as QCInspectionRequest;
    _reviewEnabled = Global.currentFactory?.id != 'mira-loma-luggage';
    _serverUrl = Global.currentServer?.url;
    _warehouseId = Global.currentWarehouse?.id;
    _qcQuantityController.text =
        _qcInspectionRequest!.qcQuantity?.toString() ?? '';
    if (_reviewEnabled &&
        (widget.prepare != null || _qcInspectionRequest!.id != null)) {
      _loading = true;
      Future.microtask(_prepareRequest);
    }
  }

  Future<void> _prepareRequest() async {
    try {
      final record =
          await (widget.prepare ?? QCInspectionService.prepareForReview)(
        _qcInspectionRequest!,
      );
      if (!mounted) return;
      setState(() {
        _qcInspectionRequest = record;
        _loading = false;
        _prepareError = null;
        _qcQuantityController.text = record.qcQuantity?.toString() ?? '';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _prepareError = error is WebAPICallException
            ? error.errMsg()
            : 'Could not prepare this inspection. Please reload the task.';
      });
    }
  }

  @override
  void dispose() {
    _qcQuantityController.dispose();
    super.dispose();
  }

  bool get _sameFactory =>
      _serverUrl == Global.currentServer?.url &&
      _warehouseId == Global.currentWarehouse?.id;

  // map to store the value for each option
  // so that when we refresh the screen, we can still keep the value
  Map valueMap = new Map();

  @override
  void initState() {
    super.initState();
    _qcInspectionRequestItemIndex = 0;
    _qcQuantityController.clear();

    valueMap.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title:  Text(uiText(context,"Claytech One - QC")),
          backgroundColor: const Color(0xFFF6F7FB),
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _prepareError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(uiErrorText(context,_prepareError!), textAlign: TextAlign.center),
                    ),
                  )
                : _qcInspectionRequest!.qcInspectionRequestItems.isEmpty
                    ?  Center(
                        child: Text(
                          uiText(context,
                              "No inspection checks are available. Review the QC configuration."),
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                            child: TabletContent(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 900)
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildQCHeader(context, theme),
                                        if (_qcInspectionRequest!
                                                .workOrderQCSampleId !=
                                            null) ...[
                                          const SizedBox(height: 12),
                                          _buildQCQuantity(context),
                                        ],
                                        const SizedBox(height: 14),
                                        _buildQCItemOptionList(context),
                                        const SizedBox(height: 8),
                                        _buildQCResultButtons(context),
                                      ],
                                    );
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        width: 320,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _buildQCHeader(context, theme),
                                              if (_qcInspectionRequest!
                                                      .workOrderQCSampleId !=
                                                  null) ...[
                                                const SizedBox(height: 12),
                                                _buildQCQuantity(context),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildQCItemOptionList(context),
                                            const SizedBox(height: 12),
                                            _buildQCResultButtons(context),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
        endDrawer: _busy ? null : MyDrawer(),
      ),
    );
  }

  Widget _buildQCHeader(BuildContext context, ThemeData theme) {
    final item = _qcInspectionRequest!
        .qcInspectionRequestItems[_qcInspectionRequestItemIndex!];
    final total = _qcInspectionRequest!.qcInspectionRequestItems.length;
    final step = _qcInspectionRequestItemIndex! + 1;
    final enabled = getEnabledQCItemOptions(item);
    final completed = enabled
        .where(
          (option) =>
              option.qcInspectionResult != null &&
              option.qcInspectionResult != QCInspectionResult.PENDING,
        )
        .length;

    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFF182F52),
              borderRadius: BorderRadius.circular(14)),
          child: Text('${item.qcRule?.name ?? ''} · $step / $total',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF182F52), Color(0xFF284B78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24182F52),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFFBFD5FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                QCReviewStrings(context)
                    .choose('QUALITY CHECK', '质量检查', '品質檢查'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFFBFD5FF),
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              )),
              const SizedBox(width: 8),
              Text(
                '$step / $total',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.qcRule?.name ?? '',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            Localizations.localeOf(context).languageCode == 'es'
                ? '$completed de ${enabled.length} puntos completados'
                : '$completed of ${enabled.length} checks completed',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFD8E4F7),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: enabled.isEmpty ? 0 : completed / enabled.length,
              backgroundColor: Colors.white.withValues(alpha: .18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFBFD5FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQCQuantity(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: TextFormField(
        controller: _qcQuantityController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: CWMSLocalizations.of(context).qcQuantity,
          border: InputBorder.none,
        ),
        enabled: !_busy,
        validator: (text) =>
            int.tryParse(text ?? '') == null || int.parse(text!) < 0
                ? 'Enter a valid QC quantity.'
                : null,
        onChanged: (text) {
          _qcInspectionRequest!.qcQuantity = int.tryParse(text);
        },
      ),
    );
  }

  Widget _buildQCItemOptionList(BuildContext context) {
    List<QCInspectionRequestItemOption> enabledQCInspectionRequestItemOptions =
        getEnabledQCItemOptions(
      _qcInspectionRequest!
          .qcInspectionRequestItems[_qcInspectionRequestItemIndex!],
    );

    if (enabledQCInspectionRequestItemOptions.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            QCReviewStrings(context).choose(
                'No enabled inspection checks are available for this rule. Ask an administrator to review the QC configuration.',
                '此规则没有已启用的检查项，请联系管理员检查质检配置。'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: enabledQCInspectionRequestItemOptions.length,
        itemBuilder: (context, index) => QCInspectionItemOptionListItem(
          qcInspectionRequestItemOption:
              enabledQCInspectionRequestItemOptions[index],
          value: _getOptionValue(enabledQCInspectionRequestItemOptions[index]),
          enabled: !_busy,
          reviewEnabled: _reviewEnabled,
          onChanged: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  Object? _getOptionValue(QCInspectionRequestItemOption option) {
    switch (option.qcRuleItem?.qcRuleItemType) {
      case QCRuleItemType.NUMBER:
        return option.doubleValue;
      case QCRuleItemType.STRING:
        return option.stringValue;

      default:
        return option.booleanValue;
    }
  }

  List<QCInspectionRequestItemOption> getEnabledQCItemOptions(
    QCInspectionRequestItem qcItem,
  ) {
    return qcItem.qcInspectionRequestItemOptions
        .where((option) => option.qcRuleItem?.enabled == true)
        .toList();
  }

  Widget _buildQCResultButtons(BuildContext context) {
    final isLast = _qcInspectionRequestItemIndex! >=
        _qcInspectionRequest!.qcInspectionRequestItems.length - 1;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _busy ? null : _onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(CWMSLocalizations.of(context).cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: !_busy && _hasEnabledChecks
                ? (_uncertain
                    ? _checkSubmissionStatus
                    : isLast
                        ? _onConfirm
                        : _onNextQCInspectionRequestItem)
                : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: const Color(0xFF6950B5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _uncertain
                        ? QCReviewStrings(context).checkStatus
                        : isLast
                            ? CWMSLocalizations.of(context).confirm
                            : CWMSLocalizations.of(context).nextQCRule,
                  ),
          ),
        ),
      ],
    );
  }

  bool get _hasEnabledChecks => _qcInspectionRequest!.qcInspectionRequestItems
      .any((item) => getEnabledQCItemOptions(item).isNotEmpty);

  Future<void> _message(String text) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child:  Text(uiText(context, "OK")),
          ),
        ],
      ),
    );
  }

  String _actual(QCInspectionRequestItemOption option) {
    final labels = QCReviewStrings(context);
    if (option.qcRuleItem?.qcRuleItemType == QCRuleItemType.YESNO)
      return option.booleanValue == true ? labels.yes : labels.no;
    return option.qcRuleItem?.qcRuleItemType == QCRuleItemType.NUMBER
        ? '${option.doubleValue}'
        : option.stringValue ?? '';
  }

  String _standard(QCInspectionRequestItemOption option) {
    final rule = option.qcRuleItem!, labels = QCReviewStrings(context);
    final expected = rule.expectedValue ?? '';
    const symbols = {
      'EQUAL': '=',
      'GREAT_THAN': '>',
      'LESS_THAN': '<',
      'GREAT_OR_EQUAL': '≥',
      'LESS_OR_EQUAL': '≤',
      'LIKE': 'Matches',
    };
    final value = rule.qcRuleItemType == QCRuleItemType.YESNO
        ? expected.toLowerCase() == 'true'
            ? labels.yes
            : labels.no
        : expected;
    return '${symbols[rule.qcRuleItemComparator?.name] ?? ''} $value';
  }

  Future<bool> _confirmFailures(
    List<QCInspectionRequestItemOption> failures,
  ) async {
    final labels = QCReviewStrings(context);
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (c) => AlertDialog(
            title: Text(labels.title),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uiTemplate(context, "{0} · {1} Fail", [_qcInspectionRequest!.number ?? '',failures.length]),
                    ),
                    const SizedBox(height: 12),
                    Text(labels.explanation),
                    for (final option in failures)
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.qcRuleItem?.displayCheckPoint(
                                      Localizations.localeOf(context)
                                          .languageCode) ??
                                  '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${labels.standard}: ${_standard(option)}'),
                            Text('${labels.actual}: ${_actual(option)}'),
                            const SizedBox(height: 6),
                            Text(
                              '${labels.notes}: ${option.exceptionNotes?.trim()}',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: Text(labels.back),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFAD3434),
                ),
                onPressed: () => Navigator.of(c).pop(true),
                child: Text(labels.submitFail),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _onConfirm() async {
    if (_busy || _uncertain || !_hasEnabledChecks) return;
    setState(() => _busy = true);
    await UpdateActivity.instance.run(() async {
      try {
        final request = _qcInspectionRequest!,
            labels = QCReviewStrings(context);
        if (!_sameFactory) {
          await _message(
            'The factory changed. Reopen this inspection in the correct factory.',
          );
          return;
        }
        final options = QCFailureReview.enabledOptions(request);
        final bad = options
            .where(
              (o) =>
                  QCFailureReview.evaluate(o) == QCInspectionResult.PENDING ||
                  _reviewEnabled &&
                      QCFailureReview.evaluate(o) == QCInspectionResult.FAIL &&
                      !QCFailureReview.validNotes(o),
            )
            .toList();
        if (bad.isNotEmpty) {
          final index = request.qcInspectionRequestItems.indexWhere(
            (g) => g.qcInspectionRequestItemOptions.contains(bad.first),
          );
          setState(() => _qcInspectionRequestItemIndex = index < 0 ? 0 : index);
          await _message(
            QCFailureReview.evaluate(bad.first) == QCInspectionResult.PENDING
                ? labels.incomplete
                : labels.notesRequired,
          );
          return;
        }
        if (!(_formKey.currentState?.validate() ?? false)) return;
        FocusScope.of(context).unfocus();
        final failures = _reviewEnabled
            ? QCFailureReview.failures(request)
            : <QCInspectionRequestItemOption>[];
        final acknowledged =
            failures.isNotEmpty && await _confirmFailures(failures);
        if (!mounted || failures.isNotEmpty && !acknowledged) return;
        if (!_sameFactory) {
          await _message('The factory changed. Reopen this inspection.');
          return;
        }
        await (widget.submit ??
            (_reviewEnabled
                ? QCInspectionService.saveQCInspectionRequest
                : QCInspectionService.saveLegacyQCInspectionRequest))([
          QCFailureReview.submission(request),
        ], failureAcknowledged: acknowledged);
        if (!mounted || !_sameFactory) return;
        Navigator.of(context).pop(true);
      } catch (error) {
        if (mounted) {
          if (error is QCSubmissionException && error.outcomeUnknown)
            _uncertain = true;
          await _message(
            error is WebAPICallException
                ? error.errMsg()
                : 'The QC result could not be confirmed. Answers are retained; check submission status before retrying.',
          );
          if (error is! WebAPICallException) _uncertain = true;
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    });
  }

  Future<void> _checkSubmissionStatus() async {
    if (_busy || !_sameFactory || _qcInspectionRequest?.id == null) return;
    setState(() => _busy = true);
    await UpdateActivity.instance.run(() async {
      try {
        final stored = await (widget.checkStatus ??
            QCInspectionService.getQCInspectionRequest)(
          _qcInspectionRequest!.id!,
        );
        if (!mounted || !_sameFactory) return;
        if (stored.qcInspectionResult == QCInspectionResult.PASS ||
            stored.qcInspectionResult == QCInspectionResult.FAIL) {
          await _message(
            'QC result recorded: ${stored.qcInspectionResult!.name}',
          );
          if (mounted) Navigator.of(context).pop(true);
        } else {
          setState(() => _uncertain = false);
          await _message(QCReviewStrings(context).retry);
        }
      } catch (_) {
        await _message(
          'Could not check the result yet. Your answers are retained. Try checking again when connected.',
        );
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    });
  }

  void _onNextQCInspectionRequestItem() {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _qcInspectionRequestItemIndex = _qcInspectionRequestItemIndex! + 1;
    });
  }

  void _onCancel() {
    // return to the previous page
    Navigator.of(context).pop();
  }
}
