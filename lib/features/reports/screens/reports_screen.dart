import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../../core/services/excel_service.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../collection/providers/collection_provider.dart';
import '../../expense/providers/expense_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedYear = '२०२६-२०२७';

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final summary = ref.watch(dashboardProvider);
    final mandal = ref.watch(mandalProvider).selectedMandal;
    final collectionState = ref.watch(collectionProvider);
    final expenseState = ref.watch(expenseProvider);

    final expected = summary.totalExpectedVargani > 0 ? summary.totalExpectedVargani : 1.0;
    final collectionPercent = ((summary.totalCollected / expected) * 100).clamp(0, 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('आर्थिक अहवाल व ताळेबंद (Reports)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'वर्गणी Excel डाउनलोड',
            onPressed: () => _exportCollectionsExcel(mandal?.name, collectionState),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'खर्च Excel डाउनलोड',
            onPressed: () => _exportExpensesExcel(mandal?.name, expenseState),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            maxWidth: 780,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. FINANCIAL YEAR FILTER BAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'आर्थिक वर्ष निवडा:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedYear,
                          isDense: true,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPurple, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: '२०२६-२०२७', child: Text('२०२६ - २०२७ (चालू)')),
                            DropdownMenuItem(value: '२०२५-२०२६', child: Text('२०२५ - २०२६')),
                            DropdownMenuItem(value: 'all', child: Text('सर्व कालावधी')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedYear = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. HERO SUMMARY BANNER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroCardGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppShadows.floating,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              mandal?.name ?? 'मंडळ आर्थिक ताळेबंद',
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'दर $collectionPercent% पूर्ण',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'वार्षिक जमा-खर्च व ताळेबंद अहवाल (Financial Statement)',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _headStat('उपलब्ध शिल्लक', AppFormatters.formatCurrency(summary.availableBalance)),
                          _headStat('गोळा वर्गणी', AppFormatters.formatCurrency(summary.totalCollected)),
                          _headStat('मंजूर खर्च', AppFormatters.formatCurrency(summary.totalApprovedExpenses)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. EXCEL EXPORT BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: AppShadows.soft,
                        ),
                        child: TextButton.icon(
                          onPressed: () => _exportCollectionsExcel(mandal?.name, collectionState),
                          icon: const Icon(Icons.table_chart_rounded, color: AppColors.success, size: 20),
                          label: const Text('वर्गणी Excel', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: AppShadows.soft,
                        ),
                        child: TextButton.icon(
                          onPressed: () => _exportExpensesExcel(mandal?.name, expenseState),
                          icon: const Icon(Icons.table_chart_rounded, color: AppColors.error, size: 20),
                          label: const Text('खर्च Excel', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 4. COMPARATIVE BAR CHART (COLLECTION VS EXPENSE)
                _buildComparisonBarChart(summary),
                const SizedBox(height: 16),

                // 5. INCOME / COLLECTION STATEMENT CARD
                _buildIncomeStatementCard(summary),
                const SizedBox(height: 16),

                // 6. EXPENSE DISTRIBUTION CARD
                _buildExpenseDistributionCard(summary),
                const SizedBox(height: 16),

                // 7. PAYMENT MODE BREAKDOWN CARD
                _buildPaymentModeBreakdownCard(summary),
                const SizedBox(height: 16),

                // 8. FINAL BALANCE SHEET FORMULA
                _buildBalanceFormulaCard(summary),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonBarChart(dynamic summary) {
    final collected = summary.totalCollected;
    final expenses = summary.totalApprovedExpenses;
    final maxVal = collected > expenses ? collected : (expenses > 0 ? expenses : 1.0);

    final collectedRatio = (collected / maxVal).clamp(0.05, 1.0);
    final expensesRatio = (expenses / maxVal).clamp(0.05, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'जमा विरूद्ध खर्च तुलना (Bar Chart)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              Icon(Icons.bar_chart_rounded, color: AppColors.primaryPurple, size: 22),
            ],
          ),
          const SizedBox(height: 18),

          // Bar 1: Collections
          Row(
            children: [
              const SizedBox(
                width: 90,
                child: Text('गोळा वर्गणी', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 20, decoration: BoxDecoration(color: AppColors.lightLavender, borderRadius: BorderRadius.circular(6))),
                    FractionallySizedBox(
                      widthFactor: collectedRatio,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primaryPurple, AppColors.royalBlue]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Text(
                  AppFormatters.formatCurrency(collected),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.royalBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bar 2: Expenses
          Row(
            children: [
              const SizedBox(
                width: 90,
                child: Text('मंजूर खर्च', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 20, decoration: BoxDecoration(color: AppColors.lightLavender, borderRadius: BorderRadius.circular(6))),
                    FractionallySizedBox(
                      widthFactor: expensesRatio,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFDC2626), AppColors.error]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Text(
                  AppFormatters.formatCurrency(expenses),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeStatementCard(dynamic summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.arrow_circle_down_rounded, color: AppColors.success, size: 22),
              SizedBox(width: 8),
              Text(
                '१. जमा बाजू (Income & Collections)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Divider(height: 22),
          _statementRow('नोंदणीकृत कुटुंबे संख्या', '${summary.totalFamilies} कुटुंबे'),
          _statementRow('अपेक्षित एकूण वर्गणी', AppFormatters.formatCurrency(summary.totalExpectedVargani)),
          _statementRow('प्रत्यक्षात गोळा झालेली वर्गणी', AppFormatters.formatCurrency(summary.totalCollected), isHighlight: true, color: AppColors.royalBlue),
          _statementRow('खजिनदाराकडे मंजूर जमा रक्कम', AppFormatters.formatCurrency(summary.totalDeposited)),
          _statementRow('कार्यकर्त्यांकडे जमा बाकी रक्कम', AppFormatters.formatCurrency(summary.awaitingDeposit), color: AppColors.accentOrange),
          _statementRow('येणे बाकी वर्गणी (Pending)', AppFormatters.formatCurrency(summary.totalPendingVargani), color: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildExpenseDistributionCard(dynamic summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.arrow_circle_up_rounded, color: AppColors.error, size: 22),
              SizedBox(width: 8),
              Text(
                '२. खर्च बाजू व कॅटेगरी विभागणी (Expenses)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Divider(height: 22),
          _statementRow('एकूण मंजूर झालेला खर्च', AppFormatters.formatCurrency(summary.totalApprovedExpenses), isHighlight: true, color: AppColors.error),
          _statementRow('प्रलंबित खर्च (Approval Pending)', AppFormatters.formatCurrency(summary.totalPendingExpenses)),
          const SizedBox(height: 12),
          const Text(
            'कॅटेगरीनुसार खर्च विभागणी:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),

          if (summary.expensesByCategory.isEmpty)
            const Text('अद्याप कोणत्याही खर्चाची नोंद नाही.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
          else
            ...summary.expensesByCategory.entries.map((entry) {
              final catTotal = summary.totalApprovedExpenses > 0 ? summary.totalApprovedExpenses : 1.0;
              final catPercent = ((entry.value / catTotal) * 100).toInt();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('• ${entry.key}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('${AppFormatters.formatCurrency(entry.value)} ($catPercent%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (entry.value / catTotal).clamp(0.02, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.lightLavender,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPaymentModeBreakdownCard(dynamic summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: AppColors.primaryPurple, size: 22),
              SizedBox(width: 8),
              Text(
                '३. पेमेंट पद्धतीनुसार विभागणी (Payment Modes)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Divider(height: 22),
          if (summary.collectionsByMode.isEmpty)
            const Text('अद्याप वर्गणी उपलब्ध नाही.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
          else
            ...summary.collectionsByMode.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getModeLabel(entry.key), style: const TextStyle(fontSize: 13)),
                    Text(
                      AppFormatters.formatCurrency(entry.value),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.royalBlue),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBalanceFormulaCard(dynamic summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.successLight,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('४. अंतिम शिल्लक सूत्र (Financial Formula)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('उपलब्ध शिल्लक = खजिनदाराकडे जमा रक्कम - एकूण मंजूर खर्च', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('मंडळाची अंतिम शिल्लक रक्कम:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                AppFormatters.formatCurrency(summary.availableBalance),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _getModeLabel(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return '💵 रोख (Cash)';
      case 'upi':
        return '📱 ऑनलाइन / UPI QR';
      case 'bank_transfer':
        return '🏦 बँक ट्रान्सफर';
      case 'cheque':
        return '📝 चेक (Cheque)';
      default:
        return 'इतर (Other)';
    }
  }

  Future<void> _exportCollectionsExcel(String? mandalName, dynamic collectionState) async {
    if (collectionState.collections.isEmpty) return;
    await ExcelService.exportCollectionsExcel(
      mandalName: mandalName ?? 'Mandal',
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
  }

  Future<void> _exportExpensesExcel(String? mandalName, dynamic expenseState) async {
    if (expenseState.expenses.isEmpty) return;
    await ExcelService.exportExpensesExcel(
      mandalName: mandalName ?? 'Mandal',
      expenses: expenseState.expenses.map((e) => {
        'title': e.title,
        'category': e.category,
        'amount': e.amount,
        'expense_date': AppFormatters.formatDate(e.expenseDate),
        'paid_to': e.paidTo,
        'paid_by': e.paidBy,
        'payment_mode': e.paymentMode,
        'approval_status': e.approvalStatus,
        'description': e.description,
      }).toList(),
    );
  }
}
