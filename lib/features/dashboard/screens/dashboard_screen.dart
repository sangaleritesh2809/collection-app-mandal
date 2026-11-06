import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
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
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authProvider);
    final user = authState.userProfile;
    final mandalState = ref.watch(mandalProvider);
    final summary = ref.watch(dashboardProvider);
    final collectionState = ref.watch(collectionProvider);
    final expenseState = ref.watch(expenseProvider);
    final configState = ref.watch(varganiConfigProvider);
    final activeMandal = mandalState.selectedMandal;

    final userName = user?.fullName.split(' ').first ?? (lang.isMarathi ? 'मित्र' : 'Friend');

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
                  _buildHeader(context, userName, activeMandal, user, lang),
                  const SizedBox(height: 16),

                  // 2. SUPER ADMIN OR PENDING NOTICES
                  if (user?.isSuperAdmin == true) ...[
                    _buildSuperAdminNotice(context, lang),
                    const SizedBox(height: 12),
                  ],
                  if (summary.pendingDepositRequestsCount > 0) ...[
                    _buildPendingApprovalBanner(context, summary.pendingDepositRequestsCount, lang),
                    const SizedBox(height: 12),
                  ],

                  // 3. HERO BALANCE CARD (FINANCIAL FORMULA: Confirmed Deposits - Approved Expenses)
                  _buildHeroBalanceCard(context, summary, lang),
                  const SizedBox(height: 14),

                  // 4. FINANCIAL SUMMARY CARDS GRID (4 METRICS)
                  _buildFinancialMetricsGrid(summary, lang),
                  const SizedBox(height: 16),

                  // 5. COLLECTION VS EXPENSE PROGRESS & BREAKDOWN
                  _buildFinancialProgressCard(summary, lang),
                  const SizedBox(height: 16),

                  // 6. QUICK ACTIONS GRID
                  _buildQuickActions(context, lang),
                  const SizedBox(height: 16),

                  // 7. MANDAL INVITE CODE STRIP
                  if (activeMandal != null) ...[
                    _buildInviteCodeStrip(context, activeMandal, lang),
                    const SizedBox(height: 16),
                  ],

                  // 8. MANDAL RATE SUMMARY STRIP
                  _buildVarganiRateStrip(context, configState, lang),
                  const SizedBox(height: 20),

                  // 9. RECENT TRANSACTIONS (COLLECTIONS & EXPENSES)
                  _buildRecentTransactionsSection(context, collectionState, expenseState, lang),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName, dynamic activeMandal, dynamic user, AppLanguage lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // User Greeting & Mandal Badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.tr('नमस्ते, $userName 👋', 'Hello, $userName 👋'),
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
                          activeMandal?.name ?? lang.tr('मंडळ निवडा', 'Select Mandal'),
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
              tooltip: lang.tr('मदत व समस्या नोंदवा', 'Support & Help'),
              onPressed: () => context.push('/report-issue'),
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
              tooltip: lang.tr('वर्गणी दर', 'Vargani Rate'),
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

  Widget _buildSuperAdminNotice(BuildContext context, AppLanguage lang) {
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
          Expanded(
            child: Text(
              lang.tr('सुपर ॲडमिन पॅनेल: मंडळांचे मेसेज व समस्या तपासा.', 'Super Admin: View mandal tickets & messages.'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/super-admin-tickets'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(lang.tr('मेसेज उघडा', 'Open Messages'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalBanner(BuildContext context, int count, AppLanguage lang) {
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
              lang.tr('$count नवीन ठेव विनंत्या मंजुरीसाठी प्रलंबित आहेत.', '$count deposit requests pending approval.'),
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
            child: Text(lang.tr('तपासा', 'Review'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBalanceCard(BuildContext context, dynamic summary, AppLanguage lang) {
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
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lang.tr('उपलब्ध शिल्लक', 'Available Balance'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF4ADE80)),
                    const SizedBox(width: 4),
                    Text(
                      lang.tr('लाईव्ह हिशोब', 'Live Account'),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
            children: [
              Expanded(child: _buildSubStat(lang.tr('खजिनदाराकडे', 'In Treasury'), AppFormatters.formatCurrency(summary.totalDeposited))),
              Expanded(child: _buildSubStat(lang.tr('मंजूर खर्च', 'Approved Exp.'), AppFormatters.formatCurrency(summary.totalApprovedExpenses))),
              Expanded(child: _buildSubStat(lang.tr('संकलक बाकी', 'With Collectors'), AppFormatters.formatCurrency(summary.awaitingDeposit), isWarning: summary.awaitingDeposit > 0)),
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

  Widget _buildFinancialMetricsGrid(dynamic summary, AppLanguage lang) {
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
              title: lang.tr('एकूण वर्गणी जमा', 'Total Collected'),
              amount: AppFormatters.formatCurrency(summary.totalCollected),
              subtitle: '${lang.tr("एकूण अपेक्षित:", "Expected:")} ${AppFormatters.formatCurrency(summary.totalExpectedVargani)}',
              icon: Icons.payments_rounded,
              color: AppColors.royalBlue,
              bgLight: AppColors.infoLight,
            ),
            _buildMetricTile(
              title: lang.tr('एकूण खर्च', 'Total Expenses'),
              amount: AppFormatters.formatCurrency(summary.totalApprovedExpenses),
              subtitle: '${lang.tr("प्रलंबित:", "Pending:")} ${AppFormatters.formatCurrency(summary.totalPendingExpenses)}',
              icon: Icons.money_off_rounded,
              color: AppColors.error,
              bgLight: AppColors.errorLight,
            ),
            _buildMetricTile(
              title: lang.tr('बाकी वर्गणी', 'Pending Vargani'),
              amount: AppFormatters.formatCurrency(summary.totalPendingVargani),
              subtitle: '${summary.totalFamilies} ${lang.tr("नोंदणीकृत कुटुंबे", "families")}',
              icon: Icons.hourglass_top_rounded,
              color: AppColors.accentOrange,
              bgLight: AppColors.warningLight,
            ),
            _buildMetricTile(
              title: lang.tr('खजिनदाराकडे जमा', 'In Treasury'),
              amount: AppFormatters.formatCurrency(summary.totalDeposited),
              subtitle: lang.tr('स्वीकारलेली प्रत्यक्ष ठेव', 'Verified deposits'),
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

  Widget _buildFinancialProgressCard(dynamic summary, AppLanguage lang) {
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
            children: [
              const Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lang.tr('वर्गणी संकलन प्रगती', 'Collection Progress'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percent% ${lang.tr("पूर्ण", "Done")}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryPurple),
                ),
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
              Text('${lang.tr("गोळा:", "Collected:")} ${AppFormatters.formatCurrency(summary.totalCollected)}', style: const TextStyle(fontSize: 11, color: AppColors.royalBlue, fontWeight: FontWeight.w600)),
              Text('${lang.tr("बाकी:", "Pending:")} ${AppFormatters.formatCurrency(summary.totalPendingVargani)}', style: const TextStyle(fontSize: 11, color: AppColors.accentOrange, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLanguage lang) {
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
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                lang.tr('थेट वर्गणी जमा करा (फास्ट पावती)', 'Record Vargani (Instant Receipt)'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            const Icon(Icons.dashboard_customize_rounded, size: 18, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            Text(
              lang.tr('जलद सेवा', 'Quick Actions'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            return GridView.count(
              crossAxisCount: isWide ? 6 : 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildQuickActionItem(
                  icon: Icons.money_off_rounded,
                  label: lang.tr('खर्च नोंदवा', 'Add Expense'),
                  color: AppColors.error,
                  onTap: () => context.push('/add-expense'),
                ),
                _buildQuickActionItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: lang.tr('ठेव विनंती', 'Deposit Req.'),
                  color: AppColors.accentOrange,
                  onTap: () => context.push('/create-deposit'),
                ),
                _buildQuickActionItem(
                  icon: Icons.analytics_rounded,
                  label: lang.tr('अहवाल पहा', 'Reports'),
                  color: AppColors.success,
                  onTap: () => context.push('/reports'),
                ),
                _buildQuickActionItem(
                  icon: Icons.group_add_rounded,
                  label: lang.tr('सदस्य व पदे', 'Members & Roles'),
                  color: AppColors.primaryPurple,
                  onTap: () => context.push('/manage-members'),
                ),
                _buildQuickActionItem(
                  icon: Icons.tune_rounded,
                  label: lang.tr('दर सेटिंग्ज', 'Vargani Settings'),
                  color: AppColors.royalBlue,
                  onTap: () => context.push('/vargani-config'),
                ),
                _buildQuickActionItem(
                  icon: Icons.qr_code_2_rounded,
                  label: lang.tr('पेमेंट QR', 'Payment QR'),
                  color: const Color(0xFF0D9488),
                  onTap: () => context.push('/mandal-payment-settings'),
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

  Widget _buildInviteCodeStrip(BuildContext context, dynamic activeMandal, AppLanguage lang) {
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
                Text(lang.tr('मंडळ आमंत्रण कोड:', 'Mandal Invite Code:'), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                '🚩 *${activeMandal.name}* 🚩\n${lang.tr("मंडळात सहभागी होण्यासाठी आमंत्रण कोड:", "Invite code to join mandal:")} *${activeMandal.invitationCode}*\n\nVargani Collection App.',
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
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.group_rounded, color: AppColors.primaryPurple, size: 22),
            tooltip: lang.tr('सदस्य व रोल्स व्यवस्थापन', 'Manage Members & Roles'),
            onPressed: () => context.push('/manage-members'),
          ),
        ],
      ),
    );
  }

  Widget _buildVarganiRateStrip(BuildContext context, dynamic configState, AppLanguage lang) {
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
                    ? '${lang.tr("मंडळाचा दर:", "Mandal Rate:")} ${configState.activeConfig!.calculationType == "per_member" ? "${AppFormatters.formatCurrency(configState.activeConfig!.perMemberAmount)} ${lang.tr('प्रति सदस्य', 'per member')}" : "${AppFormatters.formatCurrency(configState.activeConfig!.fixedAmount)} ${lang.tr('प्रति कुटुंब', 'per family')}"}'
                    : lang.tr('मंडळाचे वर्गणी दर निश्चित करा', 'Set Mandal Vargani Rate'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryPurple),
              ),
            ),
            Text(
              lang.tr('बदला ⚙️', 'Edit ⚙️'),
              style: const TextStyle(color: AppColors.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context, dynamic collectionState, dynamic expenseState, AppLanguage lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                lang.tr('अलीकडील व्यवहार', 'Recent Transactions'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
            TextButton(
              onPressed: () => context.push(_transactionTab == 0 ? '/collections' : '/expenses'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lang.tr('सर्व पहा', 'View All'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryPurple)),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primaryPurple),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Tab Switcher (वर्गणी संकलन vs खर्च)
        Row(
          children: [
            _buildTabChip(lang.tr('वर्गणी संकलन', 'Collections'), 0),
            const SizedBox(width: 8),
            _buildTabChip(lang.tr('खर्च', 'Expenses'), 1),
          ],
        ),
        const SizedBox(height: 12),

        if (_transactionTab == 0) ...[
          if (collectionState.collections.isEmpty)
            _buildEmptyState(lang.tr('अद्याप कोणतीही वर्गणी नोंदवलेली नाही.', 'No collections recorded yet.'))
          else
            ...collectionState.collections.take(5).map((c) => _buildCollectionItem(context, c)),
        ] else ...[
          if (expenseState.expenses.isEmpty)
            _buildEmptyState(lang.tr('अद्याप कोणताही खर्च नोंदवलेला नाही.', 'No expenses recorded yet.'))
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
