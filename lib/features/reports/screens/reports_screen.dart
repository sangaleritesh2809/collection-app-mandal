import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/excel_service.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../collection/providers/collection_provider.dart';
import '../../expense/providers/expense_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final summary = ref.watch(dashboardProvider);
    final mandal = ref.watch(mandalProvider).selectedMandal;
    final collectionState = ref.watch(collectionProvider);
    final expenseState = ref.watch(expenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr(BuildContextKey.reports, lang)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.saffronGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mandal?.name ?? 'मंडळ आर्थिक ताळेबंद',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'वार्षिक जमा-खर्च व ताळेबंद अहवाल (Financial Statement)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _headStat('निव्वळ शिल्लक', AppFormatters.formatCurrency(summary.availableBalance)),
                        _headStat('गोळा वर्गणी', AppFormatters.formatCurrency(summary.totalCollected)),
                        _headStat('एकूण खर्च', AppFormatters.formatCurrency(summary.totalApprovedExpenses)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Export Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (collectionState.collections.isEmpty) return;
                        await ExcelService.exportCollectionsExcel(
                          mandalName: mandal?.name ?? 'Mandal',
                          collections: collectionState.collections.map((c) => {
                            'receipt_number': c.receiptNumber,
                            'collection_date': AppFormatters.formatDate(c.collectionDate),
                            'family_name': c.familyName,
                            'family_head_name': c.familyHeadName,
                            'amount': c.amount,
                            'payment_mode': c.paymentMode,
                            'collector_name': c.collectorName,
                            'notes': c.notes,
                          }).toList(),
                        );
                      },
                      icon: const Icon(Icons.table_view, color: AppColors.success),
                      label: const Text('वर्गणी Excel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (expenseState.expenses.isEmpty) return;
                        await ExcelService.exportExpensesExcel(
                          mandalName: mandal?.name ?? 'Mandal',
                          expenses: expenseState.expenses.map((e) => {
                            'title': e.title,
                            'category': e.category,
                            'amount': e.amount,
                            'expense_date': AppFormatters.formatDate(e.expenseDate),
                            'paid_to': e.paidTo,
                            'payment_mode': e.paymentMode,
                            'approval_status': e.approvalStatus,
                            'description': e.description,
                          }).toList(),
                        );
                      },
                      icon: const Icon(Icons.table_view, color: AppColors.error),
                      label: const Text('खर्च Excel'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Detailed Income Statement Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_circle_down, color: AppColors.success),
                          SizedBox(width: 8),
                          Text(
                            '१. जमा बाजू (Income & Collections)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _statementRow('नोंदणीकृत कुटुंबे संख्या', '${summary.totalFamilies} कुटुंबे'),
                      _statementRow('अपेक्षित एकूण वर्गणी', AppFormatters.formatCurrency(summary.totalExpectedVargani)),
                      _statementRow('प्रत्यक्षात गोळा झालेली वर्गणी', AppFormatters.formatCurrency(summary.totalCollected), isHighlight: true, color: AppColors.success),
                      _statementRow('खजिनदाराकडे मंजूर जमा रक्कम', AppFormatters.formatCurrency(summary.totalDeposited)),
                      _statementRow('कार्यकर्त्यांकडे जमा बाकी रक्कम', AppFormatters.formatCurrency(summary.awaitingDeposit), color: Colors.orange),
                      _statementRow('येणे बाकी वर्गणी (Pending)', AppFormatters.formatCurrency(summary.totalPendingVargani), color: AppColors.error),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Detailed Expense Statement Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_circle_up, color: AppColors.error),
                          SizedBox(width: 8),
                          Text(
                            '२. खर्च बाजू (Expenses)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _statementRow('एकूण मंजूर झालेला खर्च', AppFormatters.formatCurrency(summary.totalApprovedExpenses), isHighlight: true, color: AppColors.error),
                      _statementRow('प्रलंबित खर्च (Approval Pending)', AppFormatters.formatCurrency(summary.totalPendingExpenses)),
                      const SizedBox(height: 10),
                      const Text(
                        'कॅटेगरीनुसार खर्च विभागणी:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 6),
                      if (summary.expensesByCategory.isEmpty)
                        const Text('कोणत्याही खर्चाची नोंद नाही', style: TextStyle(fontSize: 12))
                      else
                        ...summary.expensesByCategory.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('• ${entry.key}', style: const TextStyle(fontSize: 12)),
                                Text(AppFormatters.formatCurrency(entry.value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Net Available Balance Final Summary
              Card(
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.green.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('३. अंतिम शिल्लक सूत्र (Financial Formula)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      const Text('शिल्लक रक्कम = खजिनदाराकडे जमा रक्कम - एकूण मंजूर खर्च', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('मंडळाची अंतिम शिल्लक रक्कम:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            AppFormatters.formatCurrency(summary.availableBalance),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.success),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _statementRow(String title, String val, {bool isHighlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
          Text(
            val,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

