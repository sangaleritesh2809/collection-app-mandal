import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

class EmailJsService {
  static const String _serviceId = 'service_69dft2t';
  static const String _templateId = 'template_76ncbnr';
  static const String _publicKey = 'B9PSehHs9ZjnvguEc';
  static const String _accessToken = 'K0s5R16ZJbNfhRRYDmpxx';
  static const String _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Generates a secure 6-digit numeric OTP
  static String generate6DigitOtp() {
    final random = Random.secure();
    final otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }

  /// Sends an email with OTP using EmailJS REST API
  static Future<bool> sendOtp({
    required String toEmail,
    required String otp,
    required String purpose,
    String userName = 'User',
  }) async {
    final payload = {
      'service_id': _serviceId,
      'template_id': _templateId,
      'user_id': _publicKey,
      'accessToken': _accessToken,
      'template_params': {
        'to_email': toEmail.trim(),
        'otp': otp.trim(),
        'purpose': purpose,
        'user_name': userName.trim().isNotEmpty ? userName.trim() : 'User',
        'to_name': userName.trim().isNotEmpty ? userName.trim() : 'User',
      },
    };

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(Uri.parse(_endpoint));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set('origin', 'http://localhost');
      
      final jsonBody = jsonEncode(payload);
      request.add(utf8.encode(jsonBody));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('EmailJS OTP sent successfully to $toEmail: $responseBody');
        return true;
      } else {
        debugPrint('EmailJS error (HTTP ${response.statusCode}): $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to send EmailJS OTP: $e');
      return false;
    } finally {
      client?.close();
    }
  }
}

