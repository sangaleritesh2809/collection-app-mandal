import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../../collection/providers/collection_provider.dart';
import '../../deposit/providers/deposit_provider.dart';
import '../../expense/providers/expense_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final mandalState = ref.watch(mandalProvider);
    final summary = ref.watch(dashboardProvider);
    final collectionState = ref.watch(collectionProvider);
    final expenseState = ref.watch(expenseProvider);
    final activeMandal = mandalState.selectedMandal;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeMandal?.name ?? AppStrings.tr(BuildContextKey.appName, lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (activeMandal != null)
              Text(
                '${activeMandal.village ?? ''} • ${activeMandal.userRole ?? 'सदस्य'}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'मंडळ बदला',
            onPressed: () => context.push('/mandal-selection'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'सेटिंग्ज',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (idx) {
          if (idx == 0) return;
          if (idx == 1) context.push('/families');
          if (idx == 2) context.push('/collections');
          if (idx == 3) context.push('/deposits');
          if (idx == 4) context.push('/expenses');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'डॅशबोर्ड'),
          NavigationDestination(icon: Icon(Icons.people), label: 'कुटुंबे'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'वर्गणी'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'ठेव'),
          NavigationDestination(icon: Icon(Icons.payment), label: 'खर्च'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(mandalProvider.notifier).loadUserMandals();
          await ref.read(collectionProvider.notifier).loadCollections();
          await ref.read(depositProvider.notifier).loadDepositRequests();
          await ref.read(expenseProvider.notifier).loadExpenses();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pending Deposit Request Alert Banner (for Treasurers)
              if (summary.pendingDepositRequestsCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notification_important, color: Colors.orange, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${summary.pendingDepositRequestsCount} नवीन ठेव विनंत्या मंजुरीसाठी प्रलंबित आहेत.',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/deposits'),
                        child: const Text('तपासा'),
                      ),
                    ],
                  ),
                ),

              // Main Available Balance Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.saffronGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'मंडळाची शिल्लक रक्कम (Balance)',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'लाइव्ह हिशेब',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppFormatters.formatCurrency(summary.availableBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSubStat('जमा रक्कम', AppFormatters.formatCurrency(summary.totalDeposited)),
                        _buildSubStat('मंजूर खर्च', AppFormatters.formatCurrency(summary.totalApprovedExpenses)),
                        _buildSubStat('जमा बाकी', AppFormatters.formatCurrency(summary.awaitingDeposit)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Action Buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.add_circle,
                      color: AppColors.success,
                      label: 'वर्गणी जमा करा',
                      route: '/add-collection',
                    ),
                    const SizedBox(width: 10),
                    _buildActionButton(
                      context,
                      icon: Icons.account_balance_wallet,
                      color: Colors.blue,
                      label: 'ठेव विनंती करा',
                      route: '/create-deposit',
                    ),
                    const SizedBox(width: 10),
                    _buildActionButton(
                      context,
                      icon: Icons.money_off,
                      color: Colors.red,
                      label: 'खर्च नोंदवा',
                      route: '/add-expense',
                    ),
                    const SizedBox(width: 10),
                    _buildActionButton(
                      context,
                      icon: Icons.group_add,
                      color: Colors.deepPurple,
                      label: 'कुटुंब जोडा',
                      route: '/add-family',
                    ),
                    const SizedBox(width: 10),
                    _buildActionButton(
                      context,
                      icon: Icons.assessment,
                      color: Colors.teal,
                      label: 'अहवाल',
                      route: '/reports',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Grid KPI Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'अपेक्षित वर्गणी',
                      value: AppFormatters.formatCurrency(summary.totalExpectedVargani),
                      icon: Icons.trending_up,
                      color: Colors.indigo,
                      subtitle: '${summary.totalFamilies} कुटुंबे नोंदणीकृत',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'गोळा वर्गणी',
                      value: AppFormatters.formatCurrency(summary.totalCollected),
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                      subtitle: 'बाकी: ${AppFormatters.formatCurrency(summary.totalPendingVargani)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'एकूण खर्च',
                      value: AppFormatters.formatCurrency(summary.totalApprovedExpenses),
                      icon: Icons.payment,
                      color: AppColors.error,
                      subtitle: 'प्रलंबित: ${AppFormatters.formatCurrency(summary.totalPendingExpenses)}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'खजिनदाराकडे जमा',
                      value: AppFormatters.formatCurrency(summary.totalDeposited),
                      icon: Icons.verified,
                      color: Colors.teal,
                      subtitle: 'मंजूर ठेवी',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Collections Header & List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ताजी वर्गणी संकलने (Recent Collections)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.push('/collections'),
                    child: const Text('सर्व पहा'),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              if (collectionState.collections.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long, size: 40, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text('अद्याप कोणतीही वर्गणी नोंदवलेली नाही'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.push('/add-collection'),
                            child: const Text('पहिली वर्गणी जमा करा'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...collectionState.collections.take(3).map((c) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.success.withOpacity(0.15),
                        child: const Icon(Icons.currency_rupee, color: AppColors.success),
                      ),
                      title: Text(
                        c.familyName ?? 'कुटुंब',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${c.familyHeadName ?? ''} • ${AppFormatters.formatDate(c.collectionDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.formatCurrency(c.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            c.receiptNumber,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                      onTap: () => context.push('/collections'),
                    ),
                  );
                }),
              const SizedBox(height: 20),

              // Recent Expenses Header & List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ताजे खर्च (Recent Expenses)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.push('/expenses'),
                    child: const Text('सर्व पहा'),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              if (expenseState.expenses.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () => context.push('/add-expense'),
                        icon: const Icon(Icons.add),
                        label: const Text('खर्च नोंदवा'),
                      ),
                    ),
                  ),
                )
              else
                ...expenseState.expenses.take(3).map((e) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.error.withOpacity(0.12),
                        child: const Icon(Icons.shopping_bag_outlined, color: AppColors.error),
                      ),
                      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${e.category} • ${e.paidTo}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '- ${AppFormatters.formatCurrency(e.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 14),
                      ),
                      onTap: () => context.push('/expenses'),
                    ),
                  );
                }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                Icon(icon, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }
}
