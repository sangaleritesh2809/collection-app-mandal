import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/form_label.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../../collection/providers/collection_provider.dart';
import '../../deposit/providers/deposit_provider.dart';
import '../../expense/providers/expense_provider.dart';
import '../../vargani_config/providers/vargani_config_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authProvider);
    final user = authState.userProfile;
    final mandalState = ref.watch(mandalProvider);
    final summary = ref.watch(dashboardProvider);
    final collectionState = ref.watch(collectionProvider);
    final expenseState = ref.watch(expenseProvider);
    final configState = ref.watch(varganiConfigProvider);
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
            icon: const Icon(Icons.support_agent),
            tooltip: 'समस्या नोंदवा / मेसेज',
            onPressed: () => context.push('/report-issue'),
          ),
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
              // Super Admin Notice Banner (if user is Super Admin)
              if (user?.isSuperAdmin == true)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.red, size: 26),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'सुपर ॲडमिन पॅनेल: मंडळांचे मेसेज व समस्या तपासा.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/super-admin-tickets'),
                        child: const Text('मेसेज उघडा', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

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
              const SizedBox(height: 14),

              // Mandal Invite Code Strip (1-tap Share)
              if (activeMandal != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('मंडळ आमंत्रण कोड (Invite Code):', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                            Text(
                              activeMandal.invitationCode,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.green, size: 20),
                        tooltip: 'WhatsApp वर कोड शेअर करा',
                        onPressed: () {
                          Share.share(
                            '🚩 *${activeMandal.name}* 🚩\nमंडळात सहभागी होण्यासाठी आमंत्रण कोड: *${activeMandal.invitationCode}*\n\nवर्गणी ॲप डाउनलोड करा.',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Quick Action Services Section Header
              const Row(
                children: [
                  Icon(Icons.widgets_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'सर्व सेवा व सुविधा (Quick Actions)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2-Column Responsive Service Grid (Everything visible at a glance!)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: isWide ? 2.0 : 2.1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildFeatureCard(
                        context,
                        icon: Icons.receipt_long,
                        color: AppColors.success,
                        title: 'वर्गणी जमा',
                        subtitle: 'पावती फाडा',
                        route: '/add-collection',
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.account_balance_wallet,
                        color: Colors.blue,
                        title: 'ठेव विनंती',
                        subtitle: 'खजिनदाराकडे द्या',
                        route: '/create-deposit',
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.money_off,
                        color: Colors.red,
                        title: 'खर्च नोंदवा',
                        subtitle: 'खर्चाचा हिशेब',
                        route: '/add-expense',
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.group,
                        color: Colors.deepPurple,
                        title: 'कुटुंबे यादी',
                        subtitle: 'सर्व कुटुंब यादी',
                        route: '/families',
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.assessment,
                        color: Colors.teal,
                        title: 'हिशेब अहवाल',
                        subtitle: 'PDF व Excel',
                        route: '/reports',
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.tune,
                        color: Colors.deepOrange,
                        title: 'वर्गणी दर',
                        subtitle: 'दर निश्चित करा',
                        route: '/vargani-config',
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.qr_code_2,
                        color: Colors.indigo,
                        title: 'पेमेंट QR',
                        subtitle: 'UPI सेटिंग्स',
                        route: '/mandal-payment-settings',
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.support_agent,
                        color: Colors.brown,
                        title: 'मदत / तक्रार',
                        subtitle: 'ॲडमिनला मेसेज',
                        route: '/report-issue',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Mandal Vargani Rate Summary Banner
              InkWell(
                onTap: () => context.push('/vargani-config'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tune, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          configState.activeConfig != null
                              ? 'मंडळाचा दर: ${configState.activeConfig!.calculationType == "per_member" ? "${AppFormatters.formatCurrency(configState.activeConfig!.perMemberAmount)} प्रति सदस्य" : "${AppFormatters.formatCurrency(configState.activeConfig!.fixedAmount)} प्रति कुटुंब"}'
                              : 'या मंडळाचे वर्गणी दर निश्चित करा',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                        ),
                      ),
                      const Text(
                        'बदला ⚙️',
                        style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Card(
      elevation: 0.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.25), width: 1.2),
      ),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
