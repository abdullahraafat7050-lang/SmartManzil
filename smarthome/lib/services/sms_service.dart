import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:smarthome/config.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  String _generateCode() => (100000 + Random().nextInt(900000)).toString();

  Future<Map<String, dynamic>> sendCode(String toNumber) async {
    final code = _generateCode();
    final uri = Uri.parse(
      'https://api.twilio.com/2010-04-01/Accounts/${AppConfig.twilioAccountSid}/Messages.json',
    );

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${AppConfig.twilioAccountSid}:${AppConfig.twilioAuthToken}'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': AppConfig.twilioFromNumber,
          'To': toNumber,
          'Body': 'SmartManzil Security Code: $code',
        },
      );

      if (response.statusCode == 201) {
        return {'success': true, 'code': code, 'message': 'Code sent to $toNumber'};
      }
      return {'success': false, 'message': 'SMS failed (${response.statusCode})'};
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }
}
