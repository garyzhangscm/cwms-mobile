import 'package:flutter/material.dart';

import '../models/qc_inspection_request_item_option.dart';
import '../models/qc_inspection_result.dart';
import '../models/qc_rule_item_type.dart';
import '../services/qc_failure_review.dart';
import 'qc_review_strings.dart';

class QCInspectionItemOptionListItem extends StatefulWidget {
  QCInspectionItemOptionListItem({
    required this.qcInspectionRequestItemOption,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.reviewEnabled = true,
  }) : super(
          key: ValueKey(
            qcInspectionRequestItemOption.id ??
                'new-check-${qcInspectionRequestItemOption.qcRuleItem?.id}',
          ),
        );
  final QCInspectionRequestItemOption qcInspectionRequestItemOption;
  final Object? value;
  final VoidCallback? onChanged;
  final bool enabled;
  final bool reviewEnabled;
  @override
  State<QCInspectionItemOptionListItem> createState() =>
      _QCInspectionItemOptionListItemState();
}

class _QCInspectionItemOptionListItemState
    extends State<QCInspectionItemOptionListItem> {
  late final TextEditingController _value;
  late final TextEditingController _notes;
  bool? _answer;
  @override
  void initState() {
    super.initState();
    final option = widget.qcInspectionRequestItemOption;
    _answer = widget.value is bool ? widget.value as bool : option.booleanValue;
    final raw = widget.value ??
        (option.qcRuleItem?.qcRuleItemType == QCRuleItemType.NUMBER
            ? option.doubleValue
            : option.stringValue);
    _value = TextEditingController(text: raw?.toString() ?? '');
    _notes = TextEditingController(text: option.exceptionNotes ?? '');
  }

  @override
  void dispose() {
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _changed() {
    final option = widget.qcInspectionRequestItemOption;
    setState(
      () => option.qcInspectionResult = QCFailureReview.evaluate(option),
    );
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final option = widget.qcInspectionRequestItemOption;
    final kind = option.qcRuleItem?.qcRuleItemType;
    final labels = QCReviewStrings(context);
    final failed = widget.reviewEnabled &&
        QCFailureReview.evaluate(option) == QCInspectionResult.FAIL;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: failed ? const Color(0xFFD48806) : const Color(0xFFE2E7EF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.qcRuleItem?.displayCheckPoint(
                        Localizations.localeOf(context).languageCode) ??
                    '',
                style: const TextStyle(
                  height: 1.3,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              if (kind == QCRuleItemType.YESNO)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      key: ValueKey('qc-yes-${option.id}'),
                      label: Text(labels.yes),
                      showCheckmark: false,
                      selected: _answer == true,
                      onSelected: !widget.enabled
                          ? null
                          : (_) {
                              _answer = true;
                              option.booleanValue = true;
                              _changed();
                            },
                    ),
                    ChoiceChip(
                      key: ValueKey('qc-no-${option.id}'),
                      label: Text(labels.no),
                      showCheckmark: false,
                      selected: _answer == false,
                      onSelected: !widget.enabled
                          ? null
                          : (_) {
                              _answer = false;
                              option.booleanValue = false;
                              _changed();
                            },
                    ),
                  ],
                )
              else if (kind == QCRuleItemType.NUMBER ||
                  kind == QCRuleItemType.STRING)
                TextFormField(
                  controller: _value,
                  enabled: widget.enabled,
                  key: ValueKey('qc-value-${option.id}'),
                  keyboardType: kind == QCRuleItemType.NUMBER
                      ? const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        )
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: labels.actual,
                    border: const OutlineInputBorder(),
                  ),
                  validator: kind != QCRuleItemType.NUMBER
                      ? null
                      : (text) {
                          if ((text ?? '').isEmpty) return null;
                          final parsed = double.tryParse(text!);
                          return parsed == null || !parsed.isFinite
                              ? labels.validNumber
                              : null;
                        },
                  onChanged: (text) {
                    if (kind == QCRuleItemType.NUMBER)
                      option.doubleValue = double.tryParse(text);
                    else
                      option.stringValue = text;
                    _changed();
                  },
                ),
              if (failed && widget.reviewEnabled) ...[
                const SizedBox(height: 14),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      labels.warning,
                      style: const TextStyle(
                        color: Color(0xFF795200),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey('qc-notes-${option.id}'),
                  controller: _notes,
                  enabled: widget.enabled,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: QCFailureReview.maxNotesLength,
                  decoration: InputDecoration(
                    labelText: '${labels.notes} *',
                    hintText: labels.notesHelp,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (_) => QCFailureReview.validNotes(option)
                      ? null
                      : labels.notesRequired,
                  onChanged: (text) {
                    option.exceptionNotes = text;
                    widget.onChanged?.call();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
