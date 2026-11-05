import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/excel_service.dart';
import '../../../core/widgets/responsive_container.dart';
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('मंडळ खर्च हिशोब (Expenses)'),
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
                  'paid_by': e.paidBy,
                  'payment_mode': e.paymentMode,
                  'approval_status': e.approvalStatus,
                  'description': e.description,
                }).toList(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'रिफ्रेश करा',
            onPressed: () => ref.read(expenseProvider.notifier).loadExpenses(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-expense'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('नवीन खर्च नोंदवा', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 760,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // KPI Summary Header
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('एकूण मंजूर खर्च', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 3),
                          Text(
                            AppFormatters.formatCurrency(expenseState.totalApprovedExpenses),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 36, width: 1, color: AppColors.cardBorder),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('प्रलंबित खर्च (Pending)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 3),
                          Text(
                            AppFormatters.formatCurrency(expenseState.totalPendingExpenses),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.accentOrange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = expenseState.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat == 'All' ? 'सर्व खर्च' : cat),
                        selected: isSelected,
                        onSelected: (_) => ref.read(expenseProvider.notifier).filterCategory(cat),
                        selectedColor: AppColors.primaryPurple.withOpacity(0.14),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: isSelected ? AppColors.primaryPurple : AppColors.cardBorder),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),

              // Expenses List
              Expanded(
                child: expenseState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                    : expenseState.filteredExpenses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.money_off_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                Text(AppStrings.tr(BuildContextKey.emptyList, lang), style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.primaryPurple,
                            onRefresh: () => ref.read(expenseProvider.notifier).loadExpenses(),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 90, top: 4, left: 16, right: 16),
                              itemCount: expenseState.filteredExpenses.length,
                              itemBuilder: (context, index) {
                                final item = expenseState.filteredExpenses[index];
                                final categoryIcon = _getCategoryIcon(item.category);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.cardBorder),
                                    boxShadow: AppShadows.soft,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.lightLavender,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.cardBorder),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(categoryIcon, size: 14, color: AppColors.royalBlue),
                                                const SizedBox(width: 4),
                                                Text(
                                                  item.category,
                                                  style: const TextStyle(color: AppColors.royalBlue, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '- ${AppFormatters.formatCurrency(item.amount)}',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.error),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      Text(
                                        item.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 6),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('स्वीकारणारा: ${item.paidTo}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                          Text(AppFormatters.formatDate(item.expenseDate), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                      if (item.description != null && item.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('नोंद: ${item.description!}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                      const Divider(height: 16),

                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text('खर्च देणारा: ${item.paidBy}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: item.isApproved ? AppColors.successLight : AppColors.warningLight,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.isApproved ? 'मंजूर (Approved)' : 'प्रलंबित (Pending)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: item.isApproved ? AppColors.success : const Color(0xFFB45309),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'decoration':
        return Icons.celebration_rounded;
      case 'sound system':
        return Icons.volume_up_rounded;
      case 'lighting':
        return Icons.lightbulb_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.local_shipping_rounded;
      case 'electricity':
        return Icons.electric_bolt_rounded;
      case 'event management':
        return Icons.event_seat_rounded;
      case 'pooja sahitya':
        return Icons.temple_hindu_rounded;
      case 'prize & gifts':
        return Icons.emoji_events_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
