import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../auth/providers/auth_provider.dart';
import '../../collection/providers/collection_provider.dart';
import '../../deposit/providers/deposit_provider.dart';
import '../../expense/providers/expense_provider.dart';
import '../../family/providers/family_provider.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../../vargani_config/providers/vargani_config_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _transactionTab = 0; // 0 = Collections, 1 = Expenses

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.userProfile;
    final mandalState = ref.watch(mandalProvider);
    final summary = ref.watch(dashboardProvider);
    final collectionState = ref.watch(collectionProvider);
    final expenseState = ref.watch(expenseProvider);
    final configState = ref.watch(varganiConfigProvider);
    final activeMandal = mandalState.selectedMandal;

    final userName = user?.fullName.split(' ').first ?? 'मित्र';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryPurple,
          onRefresh: () async {
            await ref.read(mandalProvider.notifier).loadUserMandals();
            await ref.read(collectionProvider.notifier).loadCollections();
            await ref.read(depositProvider.notifier).loadDepositRequests();
            await ref.read(expenseProvider.notifier).loadExpenses();
            await ref.read(familyProvider.notifier).loadFamilies();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsiveContainer(
              maxWidth: 820,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TOP HEADER WITH GREETING & MANDAL SWITCHER
                  _buildHeader(context, userName, activeMandal, user),
                  const SizedBox(height: 16),

                  // 2. SUPER ADMIN OR PENDING NOTICES
                  if (user?.isSuperAdmin == true) ...[
                    _buildSuperAdminNotice(context),
                    const SizedBox(height: 12),
                  ],
                  if (summary.pendingDepositRequestsCount > 0) ...[
                    _buildPendingApprovalBanner(context, summary.pendingDepositRequestsCount),
                    const SizedBox(height: 12),
                  ],

                  // 3. HERO BALANCE CARD (FINANCIAL FORMULA: Confirmed Deposits - Approved Expenses)
                  _buildHeroBalanceCard(context, summary),
                  const SizedBox(height: 14),

                  // 4. FINANCIAL SUMMARY CARDS GRID (4 METRICS)
                  _buildFinancialMetricsGrid(summary),
                  const SizedBox(height: 16),

                  // 5. COLLECTION VS EXPENSE PROGRESS & BREAKDOWN
                  _buildFinancialProgressCard(summary),
                  const SizedBox(height: 16),

                  // 6. QUICK ACTIONS GRID
                  _buildQuickActions(context),
                  const SizedBox(height: 16),

                  // 7. MANDAL INVITE CODE STRIP
                  if (activeMandal != null) ...[
                    _buildInviteCodeStrip(context, activeMandal),
                    const SizedBox(height: 16),
                  ],

                  // 8. MANDAL RATE SUMMARY STRIP
                  _buildVarganiRateStrip(context, configState),
                  const SizedBox(height: 20),

                  // 9. RECENT TRANSACTIONS (COLLECTIONS & EXPENSES)
                  _buildRecentTransactionsSection(context, collectionState, expenseState),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName, dynamic activeMandal, dynamic user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // User Greeting & Mandal Badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'नमस्ते, $userName 👋',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => context.push('/mandal-selection'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryPurple.withOpacity(0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.temple_hindu_rounded, size: 14, color: AppColors.primaryPurple),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          activeMandal?.name ?? 'मंडळ निवडा',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.unfold_more_rounded, size: 14, color: AppColors.primaryPurple),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Actions: Support/Notification & Avatar
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.support_agent_rounded, color: AppColors.primaryPurple),
              tooltip: 'मदत व समस्या नोंदवा',
              onPressed: () => context.push('/report-issue'),
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
              tooltip: 'वर्गणी दर',
              onPressed: () => context.push('/vargani-config'),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => context.push('/settings'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.soft,
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuperAdminNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'सुपर ॲडमिन पॅनेल: मंडळांचे मेसेज व समस्या तपासा.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/super-admin-tickets'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('मेसेज उघडा', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalBanner(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notification_important_rounded, color: AppColors.warning, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count नवीन ठेव विनंत्या मंजुरीसाठी प्रलंबित आहेत.',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF92400E)),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/deposits'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
            ),
            child: const Text('तपासा', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBalanceCard(BuildContext context, dynamic summary) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroCardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.floating,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'उपलब्ध शिल्लक रक्कम (Balance)',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, size: 10, color: Color(0xFF4ADE80)),
                    SizedBox(width: 4),
                    Text(
                      'लाईव्ह हिशोब',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppFormatters.formatCurrency(summary.availableBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSubStat('खजिनदाराकडे जमा', AppFormatters.formatCurrency(summary.totalDeposited)),
              _buildSubStat('एकूण मंजूर खर्च', AppFormatters.formatCurrency(summary.totalApprovedExpenses)),
              _buildSubStat('संकलकांकडे बाकी', AppFormatters.formatCurrency(summary.awaitingDeposit), isWarning: summary.awaitingDeposit > 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String val, {bool isWarning = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 3),
        Text(
          val,
          style: TextStyle(
            color: isWarning ? const Color(0xFFFDE047) : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialMetricsGrid(dynamic summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: isWide ? 1.6 : 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMetricTile(
              title: 'एकूण वर्गणी जमा',
              amount: AppFormatters.formatCurrency(summary.totalCollected),
              subtitle: 'एकूण अपेक्षित: ${AppFormatters.formatCurrency(summary.totalExpectedVargani)}',
              icon: Icons.payments_rounded,
              color: AppColors.royalBlue,
              bgLight: AppColors.infoLight,
            ),
            _buildMetricTile(
              title: 'एकूण खर्च',
              amount: AppFormatters.formatCurrency(summary.totalApprovedExpenses),
              subtitle: 'प्रलंबित: ${AppFormatters.formatCurrency(summary.totalPendingExpenses)}',
              icon: Icons.money_off_rounded,
              color: AppColors.error,
              bgLight: AppColors.errorLight,
            ),
            _buildMetricTile(
              title: 'बाकी वर्गणी',
              amount: AppFormatters.formatCurrency(summary.totalPendingVargani),
              subtitle: '${summary.totalFamilies} नोंदणीकृत कुटुंबे',
              icon: Icons.hourglass_top_rounded,
              color: AppColors.accentOrange,
              bgLight: AppColors.warningLight,
            ),
            _buildMetricTile(
              title: 'खजिनदाराकडे जमा',
              amount: AppFormatters.formatCurrency(summary.totalDeposited),
              subtitle: 'स्वीकारलेली प्रत्यक्ष ठेव',
              icon: Icons.verified_rounded,
              color: AppColors.success,
              bgLight: AppColors.successLight,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgLight,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialProgressCard(dynamic summary) {
    final expected = summary.totalExpectedVargani > 0 ? summary.totalExpectedVargani : 1.0;
    final collectionRatio = (summary.totalCollected / expected).clamp(0.0, 1.0);
    final percent = (collectionRatio * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppColors.primaryPurple),
                  SizedBox(width: 8),
                  Text(
                    'वर्गणी संकलन प्रगती (Collection Progress)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Text(
                '$percent% पूर्ण',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryPurple),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: collectionRatio,
              minHeight: 10,
              backgroundColor: AppColors.lightLavender,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('गोळा: ${AppFormatters.formatCurrency(summary.totalCollected)}', style: const TextStyle(fontSize: 11, color: AppColors.royalBlue, fontWeight: FontWeight.w600)),
              Text('बाकी: ${AppFormatters.formatCurrency(summary.totalPendingVargani)}', style: const TextStyle(fontSize: 11, color: AppColors.accentOrange, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Fast Collection Hero Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.floating,
          ),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/add-collection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.flash_on_rounded, size: 24, color: AppColors.accentOrange),
            label: const Text(
              '⚡ थेट वर्गणी जमा करा (फास्ट पावती)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 14),

        const Row(
          children: [
            Icon(Icons.dashboard_customize_rounded, size: 18, color: AppColors.primaryPurple),
            SizedBox(width: 8),
            Text(
              'जलद सेवा (Quick Actions)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            return GridView.count(
              crossAxisCount: isWide ? 5 : 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildQuickActionItem(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'कुटुंब जोडा',
                  color: AppColors.primaryPurple,
                  onTap: () => context.push('/add-family'),
                ),
                _buildQuickActionItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'वर्गणी नोंद',
                  color: AppColors.royalBlue,
                  onTap: () => context.push('/add-collection'),
                ),
                _buildQuickActionItem(
                  icon: Icons.money_off_rounded,
                  label: 'खर्च नोंदवा',
                  color: AppColors.error,
                  onTap: () => context.push('/add-expense'),
                ),
                _buildQuickActionItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'ठेव विनंती',
                  color: AppColors.accentOrange,
                  onTap: () => context.push('/create-deposit'),
                ),
                _buildQuickActionItem(
                  icon: Icons.analytics_rounded,
                  label: 'अहवाल पहा',
                  color: AppColors.success,
                  onTap: () => context.push('/reports'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCodeStrip(BuildContext context, dynamic activeMandal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.vpn_key_rounded, size: 20, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('मंडळ आमंत्रण कोड (Invite Code):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(
                  activeMandal.invitationCode,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.5, color: AppColors.primaryPurple),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Share.share(
                '🚩 *${activeMandal.name}* 🚩\nमंडळात सहभागी होण्यासाठी आमंत्रण कोड: *${activeMandal.invitationCode}*\n\nVargani Collection ॲप डाउनलोड करा.',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
            ),
            icon: const Icon(Icons.share, size: 14),
            label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildVarganiRateStrip(BuildContext context, dynamic configState) {
    return InkWell(
      onTap: () => context.push('/vargani-config'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.lightLavender,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, color: AppColors.primaryPurple, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                configState.activeConfig != null
                    ? 'मंडळाचा दर: ${configState.activeConfig!.calculationType == "per_member" ? "${AppFormatters.formatCurrency(configState.activeConfig!.perMemberAmount)} प्रति सदस्य" : "${AppFormatters.formatCurrency(configState.activeConfig!.fixedAmount)} प्रति कुटुंब"}'
                    : 'मंडळाचे वर्गणी दर निश्चित करा (Set Vargani Rate)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryPurple),
              ),
            ),
            const Text(
              'बदला ⚙️',
              style: TextStyle(color: AppColors.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context, dynamic collectionState, dynamic expenseState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'अलीकडील व्यवहार (Recent Transactions)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: () => context.push(_transactionTab == 0 ? '/collections' : '/expenses'),
              child: const Text('सर्व पहा', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Tab Switcher (वर्गणी संकलन vs खर्च)
        Row(
          children: [
            _buildTabChip('वर्गणी संकलन (Collections)', 0),
            const SizedBox(width: 8),
            _buildTabChip('खर्च (Expenses)', 1),
          ],
        ),
        const SizedBox(height: 12),

        if (_transactionTab == 0) ...[
          if (collectionState.collections.isEmpty)
            _buildEmptyState('अद्याप कोणतीही वर्गणी नोंदवलेली नाही.')
          else
            ...collectionState.collections.take(5).map((c) => _buildCollectionItem(context, c)),
        ] else ...[
          if (expenseState.expenses.isEmpty)
            _buildEmptyState('अद्याप कोणताही खर्च नोंदवलेला नाही.')
          else
            ...expenseState.expenses.take(5).map((e) => _buildExpenseItem(e)),
        ],
      ],
    );
  }

  Widget _buildTabChip(String label, int index) {
    final isSelected = _transactionTab == index;
    return InkWell(
      onTap: () => setState(() => _transactionTab = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primaryPurple : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionItem(BuildContext context, dynamic c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_downward_rounded, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.familyName ?? 'कुटुंब',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppFormatters.formatDate(c.collectionDate)} • ${c.paymentMode.toUpperCase()}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+ ${AppFormatters.formatCurrency(c.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.success),
              ),
              const SizedBox(height: 2),
              Text(
                'पावती: ${c.receiptNumber}',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(dynamic e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_upward_rounded, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppFormatters.formatDate(e.expenseDate)} • ${e.category}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '- ${AppFormatters.formatCurrency(e.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.error),
              ),
              const SizedBox(height: 2),
              Text(
                e.isApproved ? 'मंजूर' : 'प्रलंबित',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: e.isApproved ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ),
    );
  }
}
