import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/formatters.dart';

class PdfReceiptData {
  final String mandalName;
  final String? mandalAddress;
  final String? mandalContact;
  final String receiptNumber;
  final String transactionNumber;
  final DateTime date;
  final String familyName;
  final String familyHead;
  final String? houseNumber;
  final String? mobile;
  final int totalMembers;
  final double amountPaid;
  final double totalVargani;
  final double pendingAmount;
  final String paymentMode;
  final String collectorName;
  final String? notes;

  PdfReceiptData({
    required this.mandalName,
    this.mandalAddress,
    this.mandalContact,
    required this.receiptNumber,
    required this.transactionNumber,
    required this.date,
    required this.familyName,
    required this.familyHead,
    this.houseNumber,
    this.mobile,
    required this.totalMembers,
    required this.amountPaid,
    required this.totalVargani,
    required this.pendingAmount,
    required this.paymentMode,
    required this.collectorName,
    this.notes,
  });
}

class PdfService {
  static Future<Uint8List> generateReceiptPdf(PdfReceiptData data) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.deepOrange800, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    '॥ श्री गणेशाय नमः ॥',
                    style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.deepOrange900),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    data.mandalName,
                    style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.deepOrange900),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                if (data.mandalAddress != null)
                  pw.Center(
                    child: pw.Text(
                      data.mandalAddress!,
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
                    ),
                  ),
                if (data.mandalContact != null)
                  pw.Center(
                    child: pw.Text(
                      'संपर्क: ${data.mandalContact}',
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
                    ),
                  ),
                pw.Divider(color: PdfColors.deepOrange300, thickness: 1),
                pw.SizedBox(height: 6),

                // Receipt Title & Numbers
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.deepOrange50,
                        border: pw.Border.all(color: PdfColors.deepOrange200),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'पावती क्र. / Receipt No: ${data.receiptNumber}',
                        style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.deepOrange900),
                      ),
                    ),
                    pw.Text(
                      'दिनांक: ${AppFormatters.formatDate(data.date)}',
                      style: pw.TextStyle(font: font, fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Family & Member Info Table
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      _buildRow(font, boldFont, 'कुटुंबाचे नाव / Family:', data.familyName),
                      pw.SizedBox(height: 4),
                      _buildRow(font, boldFont, 'कुटुंब प्रमुख / Head:', data.familyHead),
                      pw.SizedBox(height: 4),
                      _buildRow(font, boldFont, 'घर नंबर / House No:', data.houseNumber ?? '-'),
                      pw.SizedBox(height: 4),
                      _buildRow(font, boldFont, 'एकूण सदस्य संख्या:', '${data.totalMembers} व्यक्ती'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Financial Summary
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _tableCell(boldFont, 'तपशील / Description', isHeader: true),
                        _tableCell(boldFont, 'रक्कम / Amount', isHeader: true, alignRight: true),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _tableCell(font, 'एकूण ठरलेली वर्गणी (Total Vargani)'),
                        _tableCell(boldFont, AppFormatters.formatCurrency(data.totalVargani), alignRight: true),
                      ],
                    ),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.green50),
                      children: [
                        _tableCell(boldFont, 'आता जमा केलेली रक्कम (Paid Amount)'),
                        _tableCell(boldFont, AppFormatters.formatCurrency(data.amountPaid), alignRight: true, color: PdfColors.green800),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _tableCell(font, 'शिल्लक बाकी रक्कम (Remaining Balance)'),
                        _tableCell(boldFont, AppFormatters.formatCurrency(data.pendingAmount), alignRight: true, color: PdfColors.red800),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Payment Mode & Collector
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('पद्धत: ${data.paymentMode.toUpperCase()}', style: pw.TextStyle(font: font, fontSize: 8)),
                    pw.Text('व्यवहार क्र: ${data.transactionNumber}', style: pw.TextStyle(font: font, fontSize: 8)),
                  ],
                ),
                if (data.notes != null && data.notes!.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text('नोंद: ${data.notes!}', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700)),
                  ),

                pw.Spacer(),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('जमा करणारा कार्यकर्ता:', style: pw.TextStyle(font: font, fontSize: 8)),
                        pw.SizedBox(height: 2),
                        pw.Text(data.collectorName, style: pw.TextStyle(font: boldFont, fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 80,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 1)),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('अध्यक्ष / खजिनदार स्वाक्षरी', style: pw.TextStyle(font: font, fontSize: 8)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text(
                    'मंडळातर्फे आपल्या सहकार्याबद्दल मनःपूर्वक धन्यवाद!',
                    style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.deepOrange800),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildRow(pw.Font font, pw.Font boldFont, String title, String val) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(title, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
        pw.Text(val, style: pw.TextStyle(font: boldFont, fontSize: 9)),
      ],
    );
  }

  static pw.Widget _tableCell(pw.Font font, String text, {bool isHeader = false, bool alignRight = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 9 : 8.5,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
