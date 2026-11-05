import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/form_label.dart';
import '../../../core/services/excel_service.dart';
import '../../../core/services/pdf_service.dart';
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
    final mandal = ref.watch(mandalProvider).selectedMandal;

    final filtered = collectionState.collections.where((c) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return (c.familyName?.toLowerCase().contains(q) ?? false) ||
             (c.familyHeadName?.toLowerCase().contains(q) ?? false) ||
             c.receiptNumber.toLowerCase().contains(q) ||
             c.transactionNumber.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr(BuildContextKey.collection, lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Excel अहवाल डाउनलोड करा',
            onPressed: () async {
              if (collectionState.collections.isEmpty) return;
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
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(collectionProvider.notifier).loadCollections(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-collection'),
        icon: const Icon(Icons.add),
        label: const Text('वर्गणी पावती फाडा'),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 760,
          padding: EdgeInsets.zero,
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
                        const Text('एकूण संकलित वर्गणी', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.formatCurrency(collectionState.totalCollected),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
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
                        const Text('जमा करायची बाकी रक्कम', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.formatCurrency(collectionState.undepositedAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search Box
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (val) => setState(() => _search = val),
                decoration: InputDecoration(
                  hintText: 'पावती क्रमांक किंवा कुटुंबाचे नाव शोधा...',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _search = ''))
                      : null,
                ),
              ),
            ),

            // Receipts List
            Expanded(
              child: collectionState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(AppStrings.tr(BuildContextKey.emptyList, lang)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(collectionProvider.notifier).loadCollections(),
                          child: ListView.builder(
                            itemCount: filtered.length,
                            padding: const EdgeInsets.only(bottom: 80, top: 4),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.success.withOpacity(0.15),
                                    child: const Icon(Icons.currency_rupee, color: AppColors.success),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.familyName ?? 'कुटुंब',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      Text(
                                        AppFormatters.formatCurrency(item.amount),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('${item.familyHeadName ?? ''} • ${AppFormatters.formatDate(item.collectionDate)}'),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Text(item.receiptNumber, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item.paymentMode.toUpperCase(),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.info),
                                          ),
                                          const Spacer(),
                                          if (item.isDeposited)
                                            const Row(
                                              children: [
                                                Icon(Icons.check_circle, size: 12, color: AppColors.success),
                                                SizedBox(width: 3),
                                                Text('ठेव जमा', style: TextStyle(fontSize: 11, color: AppColors.success)),
                                              ],
                                            )
                                          else
                                            const Row(
                                              children: [
                                                Icon(Icons.access_time, size: 12, color: Colors.orange),
                                                SizedBox(width: 3),
                                                Text('ठेव बाकी', style: TextStyle(fontSize: 11, color: Colors.orange)),
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
                                      familyName: item.familyName ?? 'कुटुंब',
                                      familyHead: item.familyHeadName ?? '',
                                      totalMembers: 4,
                                      amountPaid: item.amount,
                                      totalVargani: item.amount,
                                      pendingAmount: 0.0,
                                      paymentMode: item.paymentMode,
                                      collectorName: item.collectorName ?? 'कार्यकर्ता',
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
