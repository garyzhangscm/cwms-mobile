import 'package:flutter/widgets.dart';

class QCReviewStrings {
  QCReviewStrings(BuildContext context)
      : zh = Localizations.localeOf(context).languageCode == 'zh',
        traditional = Localizations.localeOf(context).countryCode == 'TW',
        es = Localizations.localeOf(context).languageCode == 'es';
  final bool zh, traditional, es;
  String choose(String en, String cn, [String? tw]) => es
      ? (_spanish[en] ?? en)
      : !zh
          ? en
          : traditional
              ? tw ?? cn
              : cn;
  static const _spanish = <String, String>{
    "QCR Number": "Número QCR",
    "Not available": "No disponible",
    "Yes": "Sí",
    "No": "No",
    "This answer does not meet the acceptance standard. Verify the observation and record the exception.":
        "Esta respuesta no cumple con el criterio de aceptación. Verifique lo observado y registre la incidencia.",
    "Exception notes": "Notas de la incidencia",
    "Describe the observed issue.": "Describa el problema observado.",
    "Enter exception notes for every failed check (1–2000 characters).":
        "Escriba una nota para cada punto que no cumpla (de 1 a 2000 caracteres).",
    "Complete all required checks before submitting. A missing answer is pending, not a Fail.":
        "Complete todos los puntos obligatorios antes de enviar. Una respuesta en blanco queda pendiente; no es un resultado no conforme.",
    "Confirm nonconforming results": "Confirmar resultados no conformes",
    "These checks failed. Confirm the answers and notes reflect actual observations. Submitting retains a Fail result.":
        "Estos puntos no cumplen. Confirme que las respuestas y las notas reflejan lo observado. Al enviar, se conservará el resultado no conforme.",
    "Return to inspection": "Volver a la inspección",
    "Confirm and submit Fail": "Confirmar y enviar como no conforme",
    "Acceptance standard": "Criterio de aceptación",
    "Actual answer": "Respuesta registrada",
    "Enter a valid, finite number.": "Ingrese un número válido y finito.",
    "Check submission status": "Verificar el estado del envío",
    "No completed result was found. Your answers are retained; review before submitting again.":
        "No se encontró un resultado completado. Sus respuestas se conservaron; revíselas antes de volver a enviar.",
    "QUALITY CHECK": "INSPECCIÓN DE CALIDAD",
    "No enabled inspection checks are available for this rule. Ask an administrator to review the QC configuration.":
        "Esta regla no tiene puntos de inspección habilitados. Pida al administrador que revise la configuración de calidad."
  };
  String get qcrNumber => choose('QCR Number', 'QCR 编号', 'QCR 編號');
  String get qcrNumberUnavailable => choose('Not available', '暂无编号', '暫無編號');
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
