import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/excel_service.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../providers/expense_provider.dart';

class ExpensesListScreen extends ConsumerWidget {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final expenseState = ref.watch(expenseProvider);
    final mandal = ref.watch(mandalProvider).selectedMandal;

    final categories = [
      'All',
      'Decoration',
      'Sound System',
      'Lighting',
      'Food',
      'Transport',
      'Electricity',
      'Event Management',
      'Pooja Sahitya',
      'Prize & Gifts',
      'Other',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr(BuildContextKey.expenses, lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'खर्च Excel अहवाल डाउनलोड करा',
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
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(expenseProvider.notifier).loadExpenses(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-expense'),
        icon: const Icon(Icons.add),
        label: const Text('खर्च नोंदवा'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // KPI Summary Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('एकूण मंजूर खर्च', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.formatCurrency(expenseState.totalApprovedExpenses),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: Colors.grey.shade300),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('प्रलंबित खर्च (Pending)', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.formatCurrency(expenseState.totalPendingExpenses),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = expenseState.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat == 'All' ? 'सर्व खर्च' : cat),
                      selected: isSelected,
                      onSelected: (_) => ref.read(expenseProvider.notifier).filterCategory(cat),
                      selectedColor: AppColors.primary.withOpacity(0.18),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Expenses List
            Expanded(
              child: expenseState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : expenseState.filteredExpenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.money_off, size: 56, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(AppStrings.tr(BuildContextKey.emptyList, lang)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(expenseProvider.notifier).loadExpenses(),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80, top: 4),
                            itemCount: expenseState.filteredExpenses.length,
                            itemBuilder: (context, index) {
                              final item = expenseState.filteredExpenses[index];
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.category,
                                              style: TextStyle(color: Colors.blue.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Text(
                                            '- ${AppFormatters.formatCurrency(item.amount)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.error),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('दिले: ${item.paidTo}', style: const TextStyle(fontSize: 12)),
                                          Text(AppFormatters.formatDate(item.expenseDate), style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                                        ],
                                      ),
                                      if (item.description != null && item.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('वर्णन: ${item.description!}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                      ],
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text('देणारा: ${item.paidBy}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                          const Spacer(),
                                          Text(item.paymentMode.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.info)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

