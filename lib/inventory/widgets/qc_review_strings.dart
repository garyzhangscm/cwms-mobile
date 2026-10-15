import 'package:flutter/widgets.dart';

class QCReviewStrings {
  QCReviewStrings(BuildContext context)
      : zh = Localizations.localeOf(context).languageCode == 'zh',
        traditional = Localizations.localeOf(context).countryCode == 'TW';
  final bool zh, traditional;
  String choose(String en, String cn, [String? tw]) => !zh
      ? en
      : traditional
          ? tw ?? cn
          : cn;
  String get yes => choose('Yes', '是');
  String get no => choose('No', '否');
  String get warning => choose(
        'This answer does not meet the acceptance standard. Verify the observation and record the exception.',
        '此答案不符合验收标准。请核实实际情况，并记录异常。',
        '此答案不符合驗收標準。請核實實際情況，並記錄異常。',
      );
  String get notes => choose('Exception notes', '异常说明', '異常說明');
  String get notesHelp =>
      choose('Describe the observed issue.', '请描述实际观察到的问题。', '請描述實際觀察到的問題。');
  String get notesRequired => choose(
        'Enter exception notes for every failed check (1–2000 characters).',
        '请为每个不合格项填写异常说明（1–2000 字）。',
        '請為每個不合格項填寫異常說明（1–2000 字）。',
      );
  String get incomplete => choose(
        'Complete all required checks before submitting. A missing answer is pending, not a Fail.',
        '请先完成所有必检项。未填写的答案是待检，不应判定为不合格。',
        '請先完成所有必檢項。未填寫的答案是待檢，不應判定為不合格。',
      );
  String get title =>
      choose('Confirm nonconforming results', '确认不合格检验结果', '確認不合格檢驗結果');
  String get explanation => choose(
        'These checks failed. Confirm the answers and notes reflect actual observations. Submitting retains a Fail result.',
        '以下检查项不合格。请确认答案和说明符合实际观察情况；提交后仍保留 Fail 结果。',
        '以下檢查項不合格。請確認答案和說明符合實際觀察情況；提交後仍保留 Fail 結果。',
      );
  String get back => choose('Return to inspection', '返回检查', '返回檢查');
  String get submitFail =>
      choose('Confirm and submit Fail', '确认提交不合格结果', '確認提交不合格結果');
  String get standard => choose('Acceptance standard', '验收标准', '驗收標準');
  String get actual => choose('Actual answer', '实际答案', '實際答案');
  String get validNumber =>
      choose('Enter a valid, finite number.', '请输入有效数值。', '請輸入有效數值。');
  String get checkStatus =>
      choose('Check submission status', '检查提交状态', '檢查提交狀態');
  String get retry => choose(
        'No completed result was found. Your answers are retained; review before submitting again.',
        '未发现已完成的结果。答案已保留，请核实后再提交。',
        '未發現已完成的結果。答案已保留，請核實後再提交。',
      );
}
