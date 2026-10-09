/// Fixed operator destinations. Company codes are not database company IDs.
class FactoryProfile {
  const FactoryProfile(this.id, this.name, this.url, this.companyCode);
  final String id;
  final String name;
  final String url;
  final String companyCode;

  static const values = [
    FactoryProfile(
        'colton-injection',
        'Colton Injection',
        const String.fromEnvironment('COLTON_API_URL'),
        const String.fromEnvironment('INJECTION_COMPANY_CODE')),
    FactoryProfile(
        'fay-injection',
        'Fay Injection',
        const String.fromEnvironment('FAY_API_URL'),
        const String.fromEnvironment('INJECTION_COMPANY_CODE')),
    FactoryProfile(
        'fay-recycle',
        'Fay Recycle',
        const String.fromEnvironment('FAY_API_URL'),
        const String.fromEnvironment('INJECTION_COMPANY_CODE')),
    FactoryProfile(
        'mira-loma-luggage',
        'Mira Loma Luggage',
        const String.fromEnvironment('LUGGAGE_API_URL'),
        const String.fromEnvironment('LUGGAGE_COMPANY_CODE')),
  ];

  static FactoryProfile? byId(String? id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}
