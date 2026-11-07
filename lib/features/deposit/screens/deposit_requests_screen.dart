import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mandal/providers/mandal_provider.dart';
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
          lang.tr(
            'कार्यकर्ता ${req.collectorName ?? "कार्यकर्ता"} यांच्याकडून आलेली ${AppFormatters.formatCurrency(req.amount)} ची ठेव खजिन्यात जमा म्हणून निश्चित करण्यात येईल.',
            'Deposit of ${AppFormatters.formatCurrency(req.amount)} from worker ${req.collectorName ?? "worker"} will be marked as deposited into treasury.',
          ),
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
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text(lang.tr('ठेव विनंती यशस्वीपणे मंजूर झाली!', 'Deposit request approved successfully!')),
                    ),
                  );
                } else {
                  final err = ref.read(depositProvider).error ?? lang.tr('मंजूर करताना अडचण आली.', 'Failed to approve request.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text(err),
                    ),
                  );
                }
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
                labelText: lang.tr('नाकारण्याचे कारण *', 'Rejection Reason *'),
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
              Navigator.pop(ctx);
              final success = await ref.read(depositProvider.notifier).processRequest(
                requestId: req.id,
                action: 'rejected',
                rejectionReason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
              );
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.warning,
                      content: Text(lang.tr('ठेव विनंती नाकारली गेली.', 'Deposit request rejected.')),
                    ),
                  );
                } else {
                  final err = ref.read(depositProvider).error ?? lang.tr('नाकारताना अडचण आली.', 'Failed to reject request.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text(err),
                    ),
                  );
                }
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
    final mandalState = ref.watch(mandalProvider);

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
        label: Text(lang.tr('नवीन ठेव विनंती', 'New Deposit Request'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    _buildRequestsList(depositState.pendingRequests, currentUserId, mandalState),
                    _buildRequestsList(depositState.approvedRequests, currentUserId, mandalState),
                    _buildRequestsList(depositState.rejectedRequests, currentUserId, mandalState),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildRequestsList(List<DepositRequest> list, String? currentUserId, MandalState mandalState) {
    final lang = ref.watch(languageProvider);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(lang.tr('कोणत्याही ठेव विनंत्या नाहीत', 'No deposit requests found'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    final currentRole = mandalState.selectedMandal?.userRole ?? '';

    return RefreshIndicator(
      color: AppColors.primaryPurple,
      onRefresh: () => ref.read(depositProvider.notifier).loadDepositRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 90, top: 12, left: 16, right: 16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final req = list[index];
          final isPending = req.isPending;
          final isOwnRequest = currentUserId != null && currentUserId == req.collectorId;

          // Check if this user is authorized to approve/reject
          final canDecide = currentRole == 'Mandal Admin' ||
              currentRole == 'Super Admin' ||
              currentRole == 'Treasurer' ||
              (currentUserId != null && currentUserId == req.designatedTreasurerId) ||
              mandalState.hasPermission('approve_deposit_request');

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
                        Text(lang.tr('जमा करायची रक्कम', 'Deposit Amount'), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                        Text(lang.tr('विनंती दिनांक', 'Request Date'), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                    Text('${lang.tr("गोळा करणारा:", "Collector:")} ${req.collectorName ?? lang.tr("कार्यकर्ता", "Worker")}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, size: 16, color: AppColors.royalBlue),
                    const SizedBox(width: 6),
                    Text('${lang.tr("खजिनदार:", "Treasurer:")} ${req.treasurerName ?? lang.tr("खजिनदार", "Treasurer")}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                if (req.description != null && req.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('${lang.tr("तपशील:", "Details:")} ${req.description!}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],

                // Approved status card (Shows WHO approved it & date)
                if (req.isApproved) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${lang.tr("मंजूर करणारा:", "Approved by:")} ${req.deciderName ?? req.treasurerName ?? lang.tr("खजिनदार", "Treasurer")}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success),
                              ),
                              if (req.decisionDate != null)
                                Text(
                                  '${lang.tr("मंजूर दिनांक:", "Approval Date:")} ${AppFormatters.formatDate(req.decisionDate!)}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rejected status card (Shows WHO rejected it, reason & date)
                if (req.isRejected) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_rounded, size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${lang.tr("नाकारणारा:", "Rejected by:")} ${req.deciderName ?? req.treasurerName ?? lang.tr("खजिनदार", "Treasurer")}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error),
                              ),
                              if (req.rejectionReason != null && req.rejectionReason!.isNotEmpty)
                                Text(
                                  '${lang.tr("कारण:", "Reason:")} ${req.rejectionReason}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                                ),
                              if (req.decisionDate != null)
                                Text(
                                  '${lang.tr("नाकारल्याचा दिनांक:", "Rejection Date:")} ${AppFormatters.formatDate(req.decisionDate!)}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Approval Actions for Designated Treasurer / Admins / Collector
                if (isPending) ...[
                  const SizedBox(height: 14),
                  if (canDecide) ...[
                    // Authorized Admin / Treasurer can approve or reject
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
                            label: Text(lang.tr('नाकारा', 'Reject'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            label: Text(lang.tr('मंजूर करा', 'Approve'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ] else if (isOwnRequest) ...[
                    // Collector sees status reminder and has option to cancel their pending request
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFFB45309)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lang.tr(
                                'तुमच्या या ठेव विनंतीवर खजिनदाराची (${req.treasurerName ?? "खजिनदार"}) मंजुरी प्रलंबित आहे.',
                                'Waiting for treasurer (${req.treasurerName ?? "Treasurer"}) approval.',
                              ),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () => _showRejectDialog(context, req),
                            child: Text(
                              lang.tr('रद्द करा', 'Cancel'),
                              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
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
      label = lang.tr('नाकारलेले', 'Rejected');
    } else {
      bg = AppColors.warningLight;
      text = const Color(0xFFB45309);
      label = lang.tr('प्रलंबित', 'Pending');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
