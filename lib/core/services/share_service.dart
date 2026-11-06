import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/formatters.dart';
import 'pdf_service.dart';

class ShareService {
  static const MethodChannel _channel = MethodChannel('com.vargani.vargani_collection/whatsapp_share');

  static String _buildReceiptMessage(PdfReceiptData data) {
    return '''
🚩 *${data.mandalName}* 🚩
पावती क्रमांक: *${data.receiptNumber}*
तारीख: *${AppFormatters.formatDate(data.date)}*

प्रिय *${data.familyName}* (${data.familyHead}),
आपली वर्गणी खालीलप्रमाणे यशस्वीपणे जमा झाली आहे:

• एकूण ठरलेली वर्गणी: *${AppFormatters.formatCurrency(data.totalVargani)}*
• जमा केलेली रक्कम: *${AppFormatters.formatCurrency(data.amountPaid)}*
• शिल्लक बाकी: *${AppFormatters.formatCurrency(data.pendingAmount)}*
• पद्धत: *${data.paymentMode.toUpperCase()}*
• जमा करणारा कार्यकर्ता: *${data.collectorName}*

मंडळाच्या कार्यात आपले बहुमूल्य सहकार्य लाभल्याबद्दल मनःपूर्वक आभार! 🙏
''';
  }

  static Future<void> shareReceiptOnWhatsApp({
    required String? mobileNumber,
    required PdfReceiptData data,
  }) async {
    final message = _buildReceiptMessage(data);

    try {
      // 1. Generate the receipt PDF bytes
      final pdfBytes = await PdfService.generateReceiptPdf(data);

      // 2. Save PDF file to system temporary cache directory
      final safeRctNo = data.receiptNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/Receipt_$safeRctNo.pdf');
      await file.writeAsBytes(pdfBytes, flush: true);

      // 3. Invoke native Android WhatsApp share with direct contact targeting (JID)
      bool sent = false;
      try {
        final result = await _channel.invokeMethod<bool>('sharePdfToWhatsApp', {
          'filePath': file.path,
          'phoneNumber': mobileNumber,
          'message': message,
        });
        sent = result == true;
      } catch (nativeErr) {
        debugPrint('Native WhatsApp share failed or not on Android: $nativeErr');
      }

      // 4. Fallback to share_plus with the generated PDF file if native intent didn't launch
      if (!sent) {
        final xFile = XFile(file.path, name: 'Receipt_$safeRctNo.pdf', mimeType: 'application/pdf');
        await Share.shareXFiles([xFile], text: message);
      }
    } catch (err) {
      debugPrint('Error generating or sharing PDF: $err');
      await _fallbackTextShare(mobileNumber: mobileNumber, data: data, message: message);
    }
  }

  static Future<void> _fallbackTextShare({
    required String? mobileNumber,
    required PdfReceiptData data,
    required String message,
  }) async {
    final encoded = Uri.encodeComponent(message);
    Uri whatsappUri;

    if (mobileNumber != null && mobileNumber.replaceAll(RegExp(r'\D'), '').length >= 10) {
      final cleanNumber = mobileNumber.replaceAll(RegExp(r'\D'), '');
      final formattedNumber = cleanNumber.length == 10 ? '91$cleanNumber' : cleanNumber;
      whatsappUri = Uri.parse('https://wa.me/$formattedNumber?text=$encoded');
    } else {
      whatsappUri = Uri.parse('https://wa.me/?text=$encoded');
    }

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        await Share.share(message, subject: '${data.mandalName} - वर्गणी पावती');
      }
    } catch (_) {
      await Share.share(message, subject: '${data.mandalName} - वर्गणी पावती');
    }
  }

  static Future<void> printReceipt(PdfReceiptData data) async {
    final pdfBytes = await PdfService.generateReceiptPdf(data);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Receipt_${data.receiptNumber}.pdf',
    );
  }

  static Future<void> sharePdfFile(PdfReceiptData data) async {
    final pdfBytes = await PdfService.generateReceiptPdf(data);
    final xFile = XFile.fromData(
      pdfBytes,
      name: 'Receipt_${data.receiptNumber}.pdf',
      mimeType: 'application/pdf',
    );
    await Share.shareXFiles([xFile], text: '${data.mandalName} - वर्गणी पावती (${data.receiptNumber})');
  }
}
