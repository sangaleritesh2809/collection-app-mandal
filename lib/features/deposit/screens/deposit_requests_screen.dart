import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/deposit_request.dart';
import '../providers/deposit_provider.dart';

class DepositRequestsScreen extends ConsumerStatefulWidget {
  const DepositRequestsScreen({super.key});

  @override
  ConsumerState<DepositRequestsScreen> createState() => _DepositRequestsScreenState();
}

class _DepositRequestsScreenState extends ConsumerState<DepositRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showApproveDialog(BuildContext context, DepositRequest req) {
    final lang = ref.read(languageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 26),
            const SizedBox(width: 10),
            Text(lang.tr('ठेव विनंती मंजूर करा', 'Approve Deposit Request'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'कार्यकर्ता ${req.collectorName ?? 'कार्यकर्ता'} यांच्याकडून आलेली ${AppFormatters.formatCurrency(req.amount)} ची ठेव खजिन्यात जमा म्हणून निश्चित करण्यात येईल.',
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.tr('रद्द करा', 'Cancel'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(lang.tr('मंजूर करा', 'Approve'), style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(depositProvider.notifier).processRequest(
                requestId: req.id,
                action: 'approved',
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(lang.tr('ठेव विनंती यशस्वीपणे मंजूर झाली!', 'Deposit request approved successfully!'))),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, DepositRequest req) {
    final lang = ref.read(languageProvider);
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: AppColors.error, size: 26),
            const SizedBox(width: 10),
            Text(lang.tr('ठेव विनंती नाकारा', 'Reject Deposit Request'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${lang.tr("कार्यकर्ता:", "Collector:")} ${req.collectorName ?? ''} • ${lang.tr("रक्कम:", "Amount:")} ${AppFormatters.formatCurrency(req.amount)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: lang.tr('नाकारण्याचे कारण (अनिवार्य) *', 'Rejection Reason (Required) *'),
                hintText: lang.tr('नाकारण्याचे कारण टाका', 'Enter reason for rejection'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.tr('रद्द करा', 'Cancel'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(lang.tr('नाकारा', 'Reject'), style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final success = await ref.read(depositProvider.notifier).processRequest(
                requestId: req.id,
                action: 'rejected',
                rejectionReason: reasonCtrl.text.trim(),
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(lang.tr('ठेव विनंती नाकारली गेली.', 'Deposit request rejected.'))),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final depositState = ref.watch(depositProvider);
    final currentUserId = ref.watch(authProvider).userProfile?.id;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(lang.tr('ठेव मंजुरी', 'Deposit Approvals')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: '${lang.tr("प्रलंबित", "Pending")} (${depositState.pendingRequests.length})'),
            Tab(text: '${lang.tr("मंजूर", "Approved")} (${depositState.approvedRequests.length})'),
            Tab(text: '${lang.tr("नाकारलेले", "Rejected")} (${depositState.rejectedRequests.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: lang.tr('रिफ्रेश करा', 'Refresh'),
            onPressed: () => ref.read(depositProvider.notifier).loadDepositRequests(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-deposit'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('नवीन ठेव विनंती', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 760,
          padding: EdgeInsets.zero,
          child: depositState.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsList(depositState.pendingRequests, currentUserId),
                    _buildRequestsList(depositState.approvedRequests, currentUserId),
                    _buildRequestsList(depositState.rejectedRequests, currentUserId),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  Widget _buildRequestsList(List<DepositRequest> list, String? currentUserId) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text('कोणत्याही ठेव विनंत्या नाहीत', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryPurple,
      onRefresh: () => ref.read(depositProvider.notifier).loadDepositRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 90, top: 12, left: 16, right: 16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final req = list[index];
          final isPending = req.isPending;
          final isOwnRequest = currentUserId == req.collectorId && currentUserId != 'demo-user-id';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightLavender,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tag_rounded, size: 12, color: AppColors.primaryPurple),
                          Text(req.requestNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryPurple)),
                        ],
                      ),
                    ),
                    _statusChip(req.status),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('जमा करायची रक्कम', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.formatCurrency(req.amount),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryPurple),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('विनंती दिनांक', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(AppFormatters.formatDate(req.requestDate), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),

                Row(
                  children: [
                    const Icon(Icons.person_pin_rounded, size: 16, color: AppColors.primaryPurple),
                    const SizedBox(width: 6),
                    Text('गोळा करणारा: ${req.collectorName ?? 'कार्यकर्ता'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, size: 16, color: AppColors.royalBlue),
                    const SizedBox(width: 6),
                    Text('खजिनदार: ${req.treasurerName ?? 'खजिनदार'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                if (req.description != null && req.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('तपशील: ${req.description!}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
                if (req.rejectionReason != null && req.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text('नाकारण्याचे कारण: ${req.rejectionReason}', style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
                  ),
                ],

                // Approval Actions for Designated Treasurer
                if (isPending) ...[
                  const SizedBox(height: 14),
                  if (isOwnRequest)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ℹ️ तुम्ही स्वतः तयार केलेली विनंती तुम्ही स्वतः मंजूर करू शकत नाही.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => _showRejectDialog(context, req),
                            label: Text(ref.watch(languageProvider).tr('नाकारा', 'Reject'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            onPressed: () => _showApproveDialog(context, req),
                            label: Text(ref.watch(languageProvider).tr('मंजूर करा', 'Approve'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusChip(String status) {
    final lang = ref.watch(languageProvider);
    Color bg;
    Color text;
    String label;

    if (status == 'approved') {
      bg = AppColors.successLight;
      text = AppColors.success;
      label = lang.tr('मंजूर', 'Approved');
    } else if (status == 'rejected') {
      bg = AppColors.errorLight;
      text = AppColors.error;
      label = lang.tr('नाकारले', 'Rejected');
    } else {
      bg = AppColors.warningLight;
      text = const Color(0xFFB45309);
      label = lang.tr('प्रलंबित', 'Pending');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: text.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
