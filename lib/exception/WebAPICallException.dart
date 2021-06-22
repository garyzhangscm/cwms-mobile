class WebAPICallException implements Exception {
  String _errorMessage;
  WebAPICallException(String errorMessage) {
    _errorMessage = errorMessage;
  }
  String errMsg() => _errorMessage;
}