import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
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
  final String? utrNumber;
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
    this.utrNumber,
    required this.collectorName,
    this.notes,
  });
}

class PdfService {
  static Future<Uint8List> generateReceiptPdf(PdfReceiptData data) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();

    final brandPurple = PdfColor.fromInt(0xFF3510B8);
    final brandBlue = PdfColor.fromInt(0xFF087BF5);
    final brandLightPurple = PdfColor.fromInt(0xFFF5F4FA);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: brandPurple, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    '॥ श्री गणेशाय नमः ॥',
                    style: pw.TextStyle(font: boldFont, fontSize: 10, color: brandPurple),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    data.mandalName,
                    style: pw.TextStyle(font: boldFont, fontSize: 16, color: brandPurple),
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
                pw.Divider(color: brandBlue, thickness: 1),
                pw.SizedBox(height: 6),

                // Receipt Title & Numbers
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: brandLightPurple,
                        border: pw.Border.all(color: brandPurple),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'पावती क्र. / Receipt No: ${data.receiptNumber}',
                        style: pw.TextStyle(font: boldFont, fontSize: 9, color: brandPurple),
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
                      _buildRow(font, boldFont, 'वर्गणीदाराचे नाव / Contributor:', data.familyHead.isNotEmpty ? data.familyHead : data.familyName),
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
                    pw.Text('पद्धत: ${data.paymentMode == "upi" ? "ऑनलाइन (UPI)" : data.paymentMode.toUpperCase()}${data.utrNumber != null && data.utrNumber!.isNotEmpty ? " (UTR: ${data.utrNumber})" : ""}', style: pw.TextStyle(font: font, fontSize: 8)),
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

  static Future<Uint8List> generateBalanceSheetPdf(PdfBalanceSheetData data) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();

    final brandPurple = PdfColor.fromInt(0xFF3510B8);
    final brandBlue = PdfColor.fromInt(0xFF087BF5);
    final brandLightPurple = PdfColor.fromInt(0xFFF5F4FA);
    final brandGreen = PdfColor.fromInt(0xFF16A34A);
    final brandRed = PdfColor.fromInt(0xFFDC2626);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: brandPurple, width: 2),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Top Header
                pw.Center(
                  child: pw.Text(
                    '॥ श्री गणेशाय नमः ॥',
                    style: pw.TextStyle(font: boldFont, fontSize: 11, color: brandPurple),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text(
                    data.mandalName,
                    style: pw.TextStyle(font: boldFont, fontSize: 22, color: brandPurple),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                if (data.mandalAddress != null && data.mandalAddress!.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      data.mandalAddress!,
                      style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700),
                    ),
                  ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'वार्षिक जमा-खर्च व ताळेबंद अहवाल (Financial & Balance Sheet Statement)',
                    style: pw.TextStyle(font: boldFont, fontSize: 13, color: brandBlue),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(color: brandPurple, thickness: 1.5),
                pw.SizedBox(height: 8),

                // Meta Bar
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: brandLightPurple,
                        border: pw.Border.all(color: brandPurple),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        'आर्थिक वर्ष: ${data.selectedYear}',
                        style: pw.TextStyle(font: boldFont, fontSize: 11, color: brandPurple),
                      ),
                    ),
                    pw.Text(
                      'दिनांक: ${AppFormatters.formatDate(DateTime.now())}',
                      style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),

                // 1. Income & Collection Section
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: brandLightPurple,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    '१. जमा व वर्गणी संकलन तपशील (Income & Collection Details)',
                    style: pw.TextStyle(font: boldFont, fontSize: 12, color: brandPurple),
                  ),
                ),
                pw.SizedBox(height: 8),
                _balanceSheetRow(font, boldFont, 'नोंदणीकृत एकूण कुटुंबे:', '${data.totalFamilies} कुटुंबे'),
                _balanceSheetRow(font, boldFont, 'अपेक्षित एकूण वर्गणी:', AppFormatters.formatCurrency(data.expectedVargani)),
                _balanceSheetRow(font, boldFont, 'प्रत्यक्ष गोळा झालेली वर्गणी:', AppFormatters.formatCurrency(data.collectedVargani), valColor: brandBlue),
                _balanceSheetRow(font, boldFont, 'खजिनदाराकडे जमा झालेली रक्कम:', AppFormatters.formatCurrency(data.depositedWithTreasurer), valColor: brandGreen),
                _balanceSheetRow(font, boldFont, 'कार्यकर्त्यांकडे जमा बाकी (शिल्लक):', AppFormatters.formatCurrency(data.pendingWithCollectors), valColor: PdfColors.orange800),
                _balanceSheetRow(font, boldFont, 'उर्वरित बाकी वर्गणी:', AppFormatters.formatCurrency(data.pendingVargani), valColor: brandRed),

                pw.SizedBox(height: 14),
                // 2. Expense Section
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: brandLightPurple,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    '२. खर्च तपशील (Expenditure Statement)',
                    style: pw.TextStyle(font: boldFont, fontSize: 12, color: brandPurple),
                  ),
                ),
                pw.SizedBox(height: 8),
                _balanceSheetRow(font, boldFont, 'एकूण मंजूर झालेला खर्च:', AppFormatters.formatCurrency(data.totalApprovedExpenses), valColor: brandRed),
                _balanceSheetRow(font, boldFont, 'मंजुरीसाठी प्रलंबित खर्च:', AppFormatters.formatCurrency(data.totalPendingExpenses), valColor: PdfColors.orange800),

                pw.SizedBox(height: 16),
                // 3. Final Balance Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: brandGreen, width: 2),
                    borderRadius: pw.BorderRadius.circular(8),
                    color: PdfColor.fromInt(0xFFF0FDF4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '३. अंतिम शिल्लक सूत्र व मंडळ ताळेबंद',
                        style: pw.TextStyle(font: boldFont, fontSize: 11, color: brandGreen),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'उपलब्ध शिल्लक = खजिनदाराकडे जमा रक्कम - एकूण मंजूर खर्च',
                        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'मंडळाची अंतिम शिल्लक रक्कम (Net Balance):',
                            style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.black),
                          ),
                          pw.Text(
                            AppFormatters.formatCurrency(data.availableBalance),
                            style: pw.TextStyle(font: boldFont, fontSize: 18, color: brandGreen),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(width: 100, height: 1, color: PdfColors.grey500),
                        pw.SizedBox(height: 4),
                        pw.Text('अध्यक्ष स्वाक्षरी', style: pw.TextStyle(font: boldFont, fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 100, height: 1, color: PdfColors.grey500),
                        pw.SizedBox(height: 4),
                        pw.Text('खजिनदार स्वाक्षरी', style: pw.TextStyle(font: boldFont, fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 100, height: 1, color: PdfColors.grey500),
                        pw.SizedBox(height: 4),
                        pw.Text('कार्यवाह स्वाक्षरी', style: pw.TextStyle(font: boldFont, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'वर्गणी कलेक्शन ॲपद्वारे प्रमाणित व तयार केलेला अधिकृत अहवाल',
                    style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
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

  static pw.Widget _balanceSheetRow(pw.Font font, pw.Font boldFont, String title, String val, {PdfColor? valColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800)),
          pw.Text(val, style: pw.TextStyle(font: boldFont, fontSize: 11, color: valColor ?? PdfColors.black)),
        ],
      ),
    );
  }

  static Future<void> shareBalanceSheetPdf(PdfBalanceSheetData data) async {
    final pdfBytes = await generateBalanceSheetPdf(data);
    final safeMandal = data.mandalName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\u0900-\u097F]'), '_');
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/${safeMandal}_BalanceSheet.pdf');
    await file.writeAsBytes(pdfBytes, flush: true);

    final xFile = XFile(file.path, name: '${safeMandal}_BalanceSheet.pdf', mimeType: 'application/pdf');
    await Share.shareXFiles([xFile], text: '${data.mandalName} - ताळेबंद अहवाल (${data.selectedYear})');
  }

  static Future<void> printBalanceSheetPdf(PdfBalanceSheetData data) async {
    final pdfBytes = await generateBalanceSheetPdf(data);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: '${data.mandalName}_BalanceSheet.pdf',
    );
  }
}

class PdfBalanceSheetData {
  final String mandalName;
  final String? mandalAddress;
  final String selectedYear;
  final double expectedVargani;
  final double collectedVargani;
  final double depositedWithTreasurer;
  final double pendingWithCollectors;
  final double pendingVargani;
  final double totalApprovedExpenses;
  final double totalPendingExpenses;
  final double availableBalance;
  final int totalFamilies;

  PdfBalanceSheetData({
    required this.mandalName,
    this.mandalAddress,
    required this.selectedYear,
    required this.expectedVargani,
    required this.collectedVargani,
    required this.depositedWithTreasurer,
    required this.pendingWithCollectors,
    required this.pendingVargani,
    required this.totalApprovedExpenses,
    required this.totalPendingExpenses,
    required this.availableBalance,
    required this.totalFamilies,
  });
}
