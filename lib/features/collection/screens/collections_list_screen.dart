import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../../core/services/excel_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../family/providers/family_provider.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../providers/collection_provider.dart';

class CollectionsListScreen extends ConsumerStatefulWidget {
  const CollectionsListScreen({super.key});

  @override
  ConsumerState<CollectionsListScreen> createState() => _CollectionsListScreenState();
}

class _CollectionsListScreenState extends ConsumerState<CollectionsListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final collectionState = ref.watch(collectionProvider);
    final familyState = ref.watch(familyProvider);
    final mandal = ref.watch(mandalProvider).selectedMandal;

    final filtered = collectionState.collections.where((c) {
      if (_search.isEmpty) return true;
      final q = _search.trim().toLowerCase();

      // Check family record for fallback mobile if not directly on collection
      final fam = familyState.families.where((f) => f.id == c.familyId).firstOrNull;
      final mobile = (c.mobileNumber ?? fam?.mobileNumber ?? '').toLowerCase();
      final familyName = (c.familyName ?? fam?.familyName ?? '').toLowerCase();
      final headName = (c.familyHeadName ?? fam?.familyHeadName ?? '').toLowerCase();

      return familyName.contains(q) ||
             headName.contains(q) ||
             mobile.contains(q) ||
             c.receiptNumber.toLowerCase().contains(q) ||
             c.transactionNumber.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(lang.tr('वर्गणी संकलन', 'Collections')),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: lang.tr('Excel अहवाल डाउनलोड करा', 'Download Excel Report'),
            onPressed: () async {
              if (collectionState.collections.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(lang.tr('कोणतीही वर्गणी नोंद उपलब्ध नाही.', 'No collection records found.'))),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.tr('Excel तयार करत आहे...', 'Generating Excel...'))),
              );
              await ExcelService.exportCollectionsExcel(
                mandalName: mandal?.name ?? 'Mandal',
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
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: lang.tr('रिफ्रेश करा', 'Refresh'),
            onPressed: () => ref.read(collectionProvider.notifier).loadCollections(),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-collection'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: Text(lang.tr('वर्गणी पावती फाडा', 'Collect Vargani'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          Text(lang.tr('एकूण संकलित वर्गणी', 'Total Collections'), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 3),
                          Text(
                            AppFormatters.formatCurrency(collectionState.totalCollected),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.primaryPurple),
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
                          Text(lang.tr('जमा करायची बाकी ठेव', 'Awaiting Deposit'), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 3),
                          Text(
                            AppFormatters.formatCurrency(collectionState.undepositedAmount),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.accentOrange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search Box (Name & Number Search)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  onChanged: (val) => setState(() => _search = val),
                  decoration: InputDecoration(
                    hintText: lang.tr('नाव, मोबाईल नंबर किंवा पावती क्र. शोधा...', 'Search name, mobile, or receipt no...'),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryPurple),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() => _search = ''))
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Receipts List
              Expanded(
                child: collectionState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 60, color: AppColors.textMuted.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                Text(lang.tr('कोणतीही वर्गणी नोंद सापडली नाही', 'No records found'), style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.primaryPurple,
                            onRefresh: () => ref.read(collectionProvider.notifier).loadCollections(),
                            child: ListView.builder(
                              itemCount: filtered.length,
                              padding: const EdgeInsets.only(bottom: 90, top: 4, left: 16, right: 16),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final fam = familyState.families.where((f) => f.id == item.familyId).firstOrNull;
                                final mobile = item.mobileNumber ?? fam?.mobileNumber;
                                final displayName = item.familyHeadName ?? item.familyName ?? lang.tr('वर्गणीदार', 'Contributor');

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.cardBorder),
                                    boxShadow: AppShadows.soft,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.successLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.currency_rupee_rounded, color: AppColors.success, size: 22),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            displayName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                          ),
                                        ),
                                        Text(
                                          AppFormatters.formatCurrency(item.amount),
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.success),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 3),
                                        Text(
                                          '${mobile != null && mobile.isNotEmpty ? "+91 $mobile • " : ""}${AppFormatters.formatDate(item.collectionDate)}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.lightLavender,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppColors.cardBorder),
                                              ),
                                              child: Text(item.receiptNumber, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              item.paymentMode.toUpperCase(),
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.royalBlue),
                                            ),
                                            const Spacer(),
                                            if (item.isDeposited)
                                              Row(
                                                children: [
                                                  const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
                                                  const SizedBox(width: 3),
                                                  Text(lang.tr('ठेव जमा', 'Deposited'), style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                                                ],
                                              )
                                            else
                                              Row(
                                                children: [
                                                  const Icon(Icons.access_time_rounded, size: 13, color: AppColors.accentOrange),
                                                  const SizedBox(width: 3),
                                                  Text(lang.tr('ठेव बाकी', 'Pending Deposit'), style: const TextStyle(fontSize: 11, color: AppColors.accentOrange, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      final receiptData = PdfReceiptData(
                                        mandalName: mandal?.name ?? 'वर्गणी मंडळ',
                                        mandalAddress: mandal?.address,
                                        mandalContact: mandal?.contactNumber,
                                        receiptNumber: item.receiptNumber,
                                        transactionNumber: item.transactionNumber,
                                        date: item.collectionDate,
                                        familyName: displayName,
                                        familyHead: displayName,
                                        houseNumber: fam?.houseNumber,
                                        mobile: mobile,
                                        totalMembers: fam?.totalMembers ?? 1,
                                        amountPaid: item.amount,
                                        totalVargani: item.amount,
                                        pendingAmount: 0.0,
                                        paymentMode: item.paymentMode,
                                        collectorName: item.collectorName ?? lang.tr('कार्यकर्ता', 'Worker'),
                                        notes: item.notes,
                                      );
                                      context.push('/receipt-preview', extra: receiptData);
                                    },
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
}
