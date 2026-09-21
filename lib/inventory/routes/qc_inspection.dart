import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/inventory/services/qc_inspection.dart';
import 'package:cwms_mobile/inventory/widgets/qc_inspection_item_option_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/material.dart';

import '../models/qc_inspection_request_item.dart';
import '../models/qc_inspection_request_item_option.dart';
import '../models/qc_rule_item_type.dart';

class QCInspectionPage extends StatefulWidget {
  QCInspectionPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QCInspectionPageState();
}

class _QCInspectionPageState extends State<QCInspectionPage> {
  int? _qcInspectionRequestItemIndex;
  QCInspectionRequest? _qcInspectionRequest;
  TextEditingController _qcQuantityController = new TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
    _qcInspectionRequest =
        ModalRoute.of(context)?.settings.arguments as QCInspectionRequest;
    _qcQuantityController.text = _qcInspectionRequest!.qcQuantity.toString();

    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Claytech One - QC"),
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQCHeader(context, theme),
              if (_qcInspectionRequest!.workOrderQCSampleId != null) ...[
                const SizedBox(height: 12),
                _buildQCQuantity(context),
              ],
              const SizedBox(height: 14),
              _buildQCItemOptionList(context),
              const SizedBox(height: 8),
              _buildQCResultButtons(context),
            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildQCHeader(BuildContext context, ThemeData theme) {
    final item = _qcInspectionRequest!
        .qcInspectionRequestItems[_qcInspectionRequestItemIndex!];
    final total = _qcInspectionRequest!.qcInspectionRequestItems.length;
    final step = _qcInspectionRequestItemIndex! + 1;
    final enabled = getEnabledQCItemOptions(item);
    final completed = enabled
        .where((option) =>
            option.qcInspectionResult != null &&
            option.qcInspectionResult != QCInspectionResult.PENDING)
        .length;

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
              color: Color(0x24182F52), blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: Color(0xFFBFD5FF), size: 20),
              const SizedBox(width: 8),
              Text('QUALITY CHECK',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFBFD5FF),
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$step / $total',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.qcRule?.name ?? '',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('$completed of ${enabled.length} checks completed',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFFD8E4F7))),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: enabled.isEmpty ? 0 : completed / enabled.length,
              backgroundColor: Colors.white.withOpacity(.18),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFBFD5FF)),
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
          border: Border.all(color: const Color(0xFFE2E7EF))),
      child: TextFormField(
        controller: _qcQuantityController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
            labelText: CWMSLocalizations.of(context).qcQuantity,
            border: InputBorder.none),
        onChanged: (text) {
          _qcInspectionRequest!.qcQuantity = int.tryParse(text);
        },
      ),
    );
  }

  Widget _buildQCItemOptionList(BuildContext context) {
    List<QCInspectionRequestItemOption> enabledQCInspectionRequestItemOptions =
        getEnabledQCItemOptions(_qcInspectionRequest!
            .qcInspectionRequestItems[_qcInspectionRequestItemIndex!]);

    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: enabledQCInspectionRequestItemOptions.length,
        itemBuilder: (context, index) => QCInspectionItemOptionListItem(
          qcInspectionRequestItemOption:
              enabledQCInspectionRequestItemOptions[index],
          value: _getOptionValue(enabledQCInspectionRequestItemOptions[index]),
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
      QCInspectionRequestItem qcItem) {
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
          onPressed: _onCancel,
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child: Text(CWMSLocalizations.of(context).cancel),
        )),
        const SizedBox(width: 12),
        Expanded(
            child: ElevatedButton(
          onPressed: isLast ? _onConfirm : _onNextQCInspectionRequestItem,
          style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: const Color(0xFF6950B5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child: Text(isLast
              ? CWMSLocalizations.of(context).confirm
              : CWMSLocalizations.of(context).nextQCRule),
        )),
      ],
    );
  }

  Widget _buildNextQCInspectionRequestItemButton(BuildContext context) {
    return ElevatedButton(
        onPressed: _onNextQCInspectionRequestItem,
        child: Text(CWMSLocalizations.of(context).nextQCRule));
  }

  Widget _buildComfirmButton(BuildContext context) {
    return ElevatedButton(
        onPressed: _onConfirm,
        child: Text(CWMSLocalizations.of(context).confirm));
  }

  Future<void> _onConfirm() async {
    showLoading(context);
    try {
      await QCInspectionService.saveQCInspectionRequest(
          [_getQCInspectionResult(_qcInspectionRequest!)]);

      // flow to the previous page after we saved the result

      Navigator.of(context).pop();
      showToast(CWMSLocalizations.of(context).qcCompleted);
      Navigator.of(context).pop();
    } on WebAPICallException catch (ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;
    }
  }

  /// Calculate the result based on the user's input
  QCInspectionRequest _getQCInspectionResult(
      QCInspectionRequest qcInspectionRequest) {
    int passedQCInspectionRequestItem = 0;
    int failedQCInspectionRequestItem = 0;
    int pendingQCInspectionRequestItem = 0;

    qcInspectionRequest.qcInspectionRequestItems
        .forEach((qcInspectionRequestItem) {
      int passedQCInspectionRequestItemOption = 0;
      int failedQCInspectionRequestItemOption = 0;
      int pendingQCInspectionRequestItemOption = 0;
      qcInspectionRequestItem.qcInspectionRequestItemOptions
          .forEach((qcInspectionRequestItemOption) {
        if (qcInspectionRequestItemOption.qcRuleItem?.enabled == false) {
          // if the item is disabled, then the user won't need to do QC on the item
          // it is a pass by default
          qcInspectionRequestItemOption.qcInspectionResult =
              QCInspectionResult.PASS;
          passedQCInspectionRequestItemOption++;
        }
        if (qcInspectionRequestItemOption.qcInspectionResult ==
            QCInspectionResult.PENDING) {
          pendingQCInspectionRequestItemOption++;
        } else if (qcInspectionRequestItemOption.qcInspectionResult ==
            QCInspectionResult.FAIL) {
          failedQCInspectionRequestItemOption++;
        } else if (qcInspectionRequestItemOption.qcInspectionResult ==
            QCInspectionResult.PASS) {
          passedQCInspectionRequestItemOption++;
        }
      });
      if (failedQCInspectionRequestItemOption > 0) {
        // we have at least one failed inspection, then the whole item is fail
        qcInspectionRequestItem.qcInspectionResult = QCInspectionResult.FAIL;
        failedQCInspectionRequestItem++;
      } else if (passedQCInspectionRequestItemOption == 0) {
        // the user hasn't changed anything, then this request item is still PENDING
        qcInspectionRequestItem.qcInspectionResult = QCInspectionResult.PENDING;
        pendingQCInspectionRequestItem++;
      } else if (pendingQCInspectionRequestItemOption > 0) {
        // in here, we know we have the pending and passed qc items
        // but no fail inspection , the overall result is still fail
        qcInspectionRequestItem.qcInspectionResult = QCInspectionResult.FAIL;
        failedQCInspectionRequestItem++;
      } else {
        // in here, we know we don't have pending or failed items
        // it is a pass
        qcInspectionRequestItem.qcInspectionResult = QCInspectionResult.PASS;
        passedQCInspectionRequestItem++;
      }
    });

    if (failedQCInspectionRequestItem > 0) {
      // we have at least one failed inspection, then the whole item is fail
      qcInspectionRequest.qcInspectionResult = QCInspectionResult.FAIL;
    } else if (passedQCInspectionRequestItem == 0) {
      // the user hasn't changed anything, then this request item is still PENDING
      qcInspectionRequest.qcInspectionResult = QCInspectionResult.PENDING;
    } else if (pendingQCInspectionRequestItem > 0) {
      // in here, we know we have the pending and passed qc items
      // but no fail inspection , the overall result is still fail
      qcInspectionRequest.qcInspectionResult = QCInspectionResult.FAIL;
    } else {
      // in here, we know we don't have pending or failed items
      // it is a pass
      qcInspectionRequest.qcInspectionResult = QCInspectionResult.PASS;
    }
    return qcInspectionRequest;
  }

  void _onNextQCInspectionRequestItem() {
    setState(() {
      _qcInspectionRequestItemIndex = _qcInspectionRequestItemIndex! + 1;
    });
  }

  void _onCancel() {
    // return to the previous page
    Navigator.of(context).pop();
  }
}
