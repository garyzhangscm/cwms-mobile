import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';

class PreprintedManualPickService {
  static String get _key =>
      'manual-pick-pending:${Global.currentServer?.url}:${Global.currentWarehouse?.id}:${Global.currentUser?.username}';
  static Map<String, dynamic> _data(dynamic value) {
    final map = value is Map
        ? Map<String, dynamic>.from(value)
        : jsonDecode(value.toString()) as Map<String, dynamic>;
    if (map['result'] != 0)
      throw WebAPICallException(
          map['message']?.toString() ?? 'Unable to process manual pick');
    return Map<String, dynamic>.from(map['data'] as Map);
  }

  static Future<Map<String, dynamic>> preview(int orderId, String lpn) async =>
      _data((await CWMSHttpClient.getDio().get(
              'outbound/orders/$orderId/preprinted-manual-pick',
              queryParameters: {
            'warehouseId': Global.currentWarehouse!.id,
            'sourceLpn': lpn.trim()
          }))
          .data);
  static Future<Map<String, dynamic>?> pending() async {
    final key = _key;
    final text = (await SharedPreferences.getInstance()).getString(key);
    return text == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  static String _uuid() {
    final b = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static Future<bool> cancelUnstarted() async {
    final key = _key;
    final warehouseId = Global.currentWarehouse!.id;
    final client = CWMSHttpClient.getDio();
    final saved = await pending();
    if (saved == null) return true;
    if (_key != key)
      throw WebAPICallException(
          'Work profile changed. Return to the original warehouse.');
    final response = _data((await client.post(
            'outbound/orders/${saved['orderId']}/preprinted-manual-pick/cancel-unstarted',
            queryParameters: {
          'warehouseId': warehouseId,
          'requestId': saved['requestId']
        }))
        .data);
    if (response['cancelled'] == true || response['completed'] == true) {
      if (!await (await SharedPreferences.getInstance()).remove(key)) {
        throw WebAPICallException(
            'Could not clear the pending record. Retry this same operation.');
      }
      return true;
    }
    return false;
  }

  static Future<void>? _sending;
  static Future<void> submit(Map<String, dynamic> details) {
    if (_sending != null) return _sending!;
    final current = _submit(details);
    _sending = current.whenComplete(() => _sending = null);
    return _sending!;
  }

  static Future<void> _submit(Map<String, dynamic> details) async {
    final key = _key;
    final warehouseId = Global.currentWarehouse!.id;
    final client = CWMSHttpClient.getDio();
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(key);
    final saved = text == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(text) as Map);
    final request = saved ?? {...details, 'requestId': _uuid()};
    // Write before sending. An uncertain response always reuses this exact request.
    if (saved == null && !await prefs.setString(key, jsonEncode(request))) {
      throw WebAPICallException(
          'Could not save this pick safely. Please try again.');
    }
    if (_key != key)
      throw WebAPICallException(
          'Work profile changed. Return to the original warehouse to resume this pick.');
    final params = {...request}
      ..remove('orderId')
      ..remove('orderNumber');
    final result = _data((await client.post(
            'outbound/orders/${request['orderId']}/preprinted-manual-pick',
            queryParameters: {...params, 'warehouseId': warehouseId}))
        .data);
    if (result['completed'] != true)
      throw WebAPICallException(
          'Pick is awaiting confirmation. Retry this same pick.');
    if (!await prefs.remove(key)) {
      throw WebAPICallException(
          'Pick confirmed, but the pending record could not be cleared. Retry the same operation to recover.');
    }
  }
}
