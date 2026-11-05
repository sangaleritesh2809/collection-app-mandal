import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/formatters.dart';
import 'pdf_service.dart';

class ShareService {
  static Future<void> shareReceiptOnWhatsApp({
    required String? mobileNumber,
    required PdfReceiptData data,
  }) async {
    final message = '''
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
    } catch (e) {
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
