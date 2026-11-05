import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

class ExcelService {
  static Future<void> exportCollectionsExcel({
    required String mandalName,
    required List<Map<String, dynamic>> collections,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['वर्गणी नोंदी'];
    excel.setDefaultSheet('वर्गणी नोंदी');

    // Header Title
    sheet.appendRow([
      TextCellValue('मंडळ: $mandalName'),
    ]);
    sheet.appendRow([
      TextCellValue('वर्गणी संकलन अहवाल (Vargani Collection Report)'),
    ]);
    sheet.appendRow([
      TextCellValue(''),
    ]);

    // Table Columns
    sheet.appendRow([
      TextCellValue('पावती क्र. (Receipt No)'),
      TextCellValue('दिनांक (Date)'),
      TextCellValue('कुटुंबाचे नाव (Family)'),
      TextCellValue('कुटुंब प्रमुख (Head)'),
      TextCellValue('रक्कम (Amount ₹)'),
      TextCellValue('पेमेंट पद्धत (Mode)'),
      TextCellValue('जमा करणारा (Collector)'),
      TextCellValue('नोंद (Notes)'),
    ]);

    for (final c in collections) {
      sheet.appendRow([
        TextCellValue(c['receipt_number']?.toString() ?? '-'),
        TextCellValue(c['collection_date']?.toString() ?? '-'),
        TextCellValue(c['family_name']?.toString() ?? '-'),
        TextCellValue(c['family_head_name']?.toString() ?? '-'),
        DoubleCellValue((c['amount'] as num?)?.toDouble() ?? 0.0),
        TextCellValue(c['payment_mode']?.toString().toUpperCase() ?? '-'),
        TextCellValue(c['collector_name']?.toString() ?? '-'),
        TextCellValue(c['notes']?.toString() ?? '-'),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final xFile = XFile.fromData(
        Uint8List.fromList(fileBytes),
        name: '${mandalName}_Collections.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      await Share.shareXFiles([xFile], text: '$mandalName - वर्गणी संकलन अहवाल (Excel)');
    }
  }

  static Future<void> exportExpensesExcel({
    required String mandalName,
    required List<Map<String, dynamic>> expenses,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['खर्च नोंदी'];
    excel.setDefaultSheet('खर्च नोंदी');

    // Header Title
    sheet.appendRow([
      TextCellValue('मंडळ: $mandalName'),
    ]);
    sheet.appendRow([
      TextCellValue('मंडळ खर्च अहवाल (Mandal Expense Report)'),
    ]);
    sheet.appendRow([
      TextCellValue(''),
    ]);

    // Table Columns
    sheet.appendRow([
      TextCellValue('खर्च शीर्षक (Title)'),
      TextCellValue('वर्ग / कॅटेगरी (Category)'),
      TextCellValue('रक्कम (Amount ₹)'),
      TextCellValue('दिनांक (Date)'),
      TextCellValue('कोणाला दिले (Paid To)'),
      TextCellValue('पद्धत (Mode)'),
      TextCellValue('स्थिती (Status)'),
      TextCellValue('तपशील (Description)'),
    ]);

    for (final e in expenses) {
      sheet.appendRow([
        TextCellValue(e['title']?.toString() ?? '-'),
        TextCellValue(e['category']?.toString() ?? '-'),
        DoubleCellValue((e['amount'] as num?)?.toDouble() ?? 0.0),
        TextCellValue(e['expense_date']?.toString() ?? '-'),
        TextCellValue(e['paid_to']?.toString() ?? '-'),
        TextCellValue(e['payment_mode']?.toString().toUpperCase() ?? '-'),
        TextCellValue(e['approval_status']?.toString().toUpperCase() ?? '-'),
        TextCellValue(e['description']?.toString() ?? '-'),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final xFile = XFile.fromData(
        Uint8List.fromList(fileBytes),
        name: '${mandalName}_Expenses.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      await Share.shareXFiles([xFile], text: '$mandalName - मंडळ खर्च अहवाल (Excel)');
    }
  }
}

