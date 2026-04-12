import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class MoMoService {
  static const String _partnerCode = 'MOMO';
  static const String _accessKey = '***MOMO_ACCESS_KEY_REMOVED***';
  static const String _secretKey = '***MOMO_SECRET_REMOVED***';
  static const String _redirectUrl = 'yourapp://payment-result';
  static const String _ipnUrl = 'https://test-payment.momo.vn/notify';
  static const String _endpoint =
      'https://test-payment.momo.vn/v2/gateway/api/create';

  /// Creates a MoMo payment request and returns the payUrl.
  /// Throws [Exception] on network or MoMo API errors.
  static Future<String> createMoMoPayment({
    required String orderId,
    required int amount,
    required String orderInfo,
  }) async {
    final requestId = orderId;
    const extraData = '';
    const requestType = 'payWithMethod';

    // Build raw signature string exactly as required by MoMo
    final rawSignature = 'accessKey=$_accessKey'
        '&amount=$amount'
        '&extraData=$extraData'
        '&ipnUrl=$_ipnUrl'
        '&orderId=$orderId'
        '&orderInfo=$orderInfo'
        '&partnerCode=$_partnerCode'
        '&redirectUrl=$_redirectUrl'
        '&requestId=$requestId'
        '&requestType=$requestType';

    final keyBytes = utf8.encode(_secretKey);
    final msgBytes = utf8.encode(rawSignature);
    final signature = Hmac(sha256, keyBytes).convert(msgBytes).toString();

    final payload = {
      'partnerCode': _partnerCode,
      'accessKey': _accessKey,
      'requestId': requestId,
      'amount': amount,
      'orderId': orderId,
      'orderInfo': orderInfo,
      'redirectUrl': _redirectUrl,
      'ipnUrl': _ipnUrl,
      'extraData': extraData,
      'requestType': requestType,
      'signature': signature,
      'lang': 'vi',
    };

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('MoMo request failed (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final payUrl = data['payUrl'] as String?;
    if (payUrl == null || payUrl.isEmpty) {
      final msg = data['message'] ?? 'Lỗi không xác định từ MoMo';
      throw Exception(msg.toString());
    }

    return payUrl;
  }
}
