/// Fixed operator destinations. Company codes are not database company IDs.
class FactoryProfile {
  const FactoryProfile(this.id, this.name, this.url, this.companyCode);
  final String id;
  final String name;
  final String url;
  final String companyCode;

  static const qcPreviewUrl = String.fromEnvironment('QC_PREVIEW_API_URL');
  static const fayQcPreviewUrl = String.fromEnvironment('FAY_QC_PREVIEW_API_URL');
  static const _fayApiUrl = fayQcPreviewUrl != ''
      ? fayQcPreviewUrl
      : String.fromEnvironment('FAY_API_URL');

  static const _useQcPreview = qcPreviewUrl != '';

  static const values = [
    FactoryProfile(
      'colton-injection',
      'Colton Injection',
      _useQcPreview ? qcPreviewUrl : String.fromEnvironment('COLTON_API_URL'),
      _useQcPreview
          ? String.fromEnvironment('QC_PREVIEW_COMPANY_CODE',
              defaultValue: String.fromEnvironment('INJECTION_COMPANY_CODE'))
          : String.fromEnvironment('INJECTION_COMPANY_CODE'),
    ),
    FactoryProfile(
      'fay-injection',
      'Fay Injection',
      _fayApiUrl,
      const String.fromEnvironment('INJECTION_COMPANY_CODE'),
    ),
    FactoryProfile(
      'fay-recycle',
      'Fay Recycle',
      _fayApiUrl,
      const String.fromEnvironment('INJECTION_COMPANY_CODE'),
    ),
    FactoryProfile(
      'mira-loma-luggage',
      'Mira Loma Luggage',
      const String.fromEnvironment('LUGGAGE_API_URL'),
      const String.fromEnvironment('LUGGAGE_COMPANY_CODE'),
    ),
  ];

  static FactoryProfile? byId(String? id) {
    if (_useQcPreview && id == 'qc-preview') return values.first;

    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}
