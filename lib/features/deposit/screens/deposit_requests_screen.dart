import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ठेव विनंती मंजूर करायची आहे का?'),
        content: Text(
          'कार्यकर्ता ${req.collectorName ?? 'कार्यकर्ता'} यांच्याकडून आलेली ${AppFormatters.formatCurrency(req.amount)} ची ठेव खजिन्यात जमा म्हणून निश्चित करण्यात येईल.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करा')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(depositProvider.notifier).processRequest(
                requestId: req.id,
                action: 'approved',
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ठेव विनंती यशस्वीपणे मंजूर झाली!')),
                );
              }
            },
            child: const Text('मंजूर करा (Approve)'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, DepositRequest req) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ठेव विनंती नाकारायची आहे का?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('कार्यकर्ता: ${req.collectorName ?? ''} • रक्कम: ${AppFormatters.formatCurrency(req.amount)}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'नाकारण्याचे कारण (अनिवार्य) *',
                hintText: 'उदा. रक्कम प्रत्यक्षात कमी मिळाली / चुकीची पावती',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करा')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
                  const SnackBar(content: Text('ठेव विनंती नाकारली गेली.')),
                );
              }
            },
            child: const Text('नाकारा (Reject)'),
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
      appBar: AppBar(
        title: Text(AppStrings.tr(BuildContextKey.depositRequests, lang)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'प्रलंबित (${depositState.pendingRequests.length})'),
            Tab(text: 'मंजूर (${depositState.approvedRequests.length})'),
            Tab(text: 'नाकारलेले (${depositState.rejectedRequests.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(depositProvider.notifier).loadDepositRequests(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-deposit'),
        icon: const Icon(Icons.add),
        label: const Text('नवीन ठेव विनंती करा'),
      ),
      body: SafeArea(
        child: depositState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildRequestsList(depositState.pendingRequests, currentUserId),
                  _buildRequestsList(depositState.approvedRequests, currentUserId),
                  _buildRequestsList(depositState.rejectedRequests, currentUserId),
                ],
              ),
      ),
    );
  }

  Widget _buildRequestsList(List<DepositRequest> list, String? currentUserId) {
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('कोणत्याही ठेव विनंत्या नाहीत', style: TextStyle(color: AppColors.textSecondaryLight)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(depositProvider.notifier).loadDepositRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final req = list[index];
          final isPending = req.isPending;
          final isOwnRequest = currentUserId == req.collectorId && currentUserId != 'demo-user-id';

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
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(req.requestNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      _statusChip(req.status),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('जमा करायची रक्कम', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          Text(
                            AppFormatters.formatCurrency(req.amount),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('दिनांक', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          Text(AppFormatters.formatDate(req.requestDate), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 18),

                  Row(
                    children: [
                      const Icon(Icons.person_pin, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 6),
                      Text('गोळा करणारा: ${req.collectorName ?? 'कार्यकर्ता'}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.account_balance, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 6),
                      Text('खजिनदार: ${req.treasurerName ?? 'खजिनदार'}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  if (req.description != null && req.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('तपशील: ${req.description!}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  ],
                  if (req.rejectionReason != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('नाकारण्याचे कारण: ${req.rejectionReason}', style: const TextStyle(fontSize: 11, color: AppColors.error)),
                    ),
                  ],

                  // Approval Actions for Designated Treasurer
                  if (isPending) ...[
                    const SizedBox(height: 14),
                    if (isOwnRequest)
                      const Text(
                        'ℹ️ तुम्ही स्वतः तयार केलेली विनंती तुम्ही स्वतः मंजूर करू शकत नाही.',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                              onPressed: () => _showRejectDialog(context, req),
                              child: const Text('नाकारा (Reject)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                              onPressed: () => _showApproveDialog(context, req),
                              child: const Text('मंजूर करा (Approve)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color text;
    String label;

    if (status == 'approved') {
      bg = Colors.green.shade50;
      text = AppColors.success;
      label = 'मंजूर';
    } else if (status == 'rejected') {
      bg = Colors.red.shade50;
      text = AppColors.error;
      label = 'नाकारले';
    } else {
      bg = Colors.amber.shade50;
      text = Colors.orange.shade800;
      label = 'प्रलंबित (Pending)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
