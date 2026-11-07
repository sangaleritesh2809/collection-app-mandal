import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/share_service.dart';
import '../../../core/widgets/responsive_container.dart';

class ReceiptPreviewScreen extends ConsumerStatefulWidget {
  final PdfReceiptData receiptData;

  const ReceiptPreviewScreen({super.key, required this.receiptData});

  @override
  ConsumerState<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends ConsumerState<ReceiptPreviewScreen> {
  bool _isSharingWhatsApp = false;

  PdfReceiptData get receiptData => widget.receiptData;

  Future<void> _handleWhatsAppShare() async {
    if (_isSharingWhatsApp) return;
    setState(() => _isSharingWhatsApp = true);
    try {
      await ShareService.shareReceiptOnWhatsApp(
        mobileNumber: receiptData.mobile,
        data: receiptData,
      );
    } finally {
      if (mounted) setState(() => _isSharingWhatsApp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(lang.tr('पावती पाहा', 'View Receipt')),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/collections'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            maxWidth: 600,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success Alert Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 26),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'वर्गणी पावती यशस्वीपणे तयार झाली!',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Digital Receipt Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppShadows.card,
                    border: Border.all(color: AppColors.cardBorder, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/vargani_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.temple_hindu, color: AppColors.primaryPurple),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '॥ श्री गणेशाय नमः ॥',
                            style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          receiptData.mandalName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryPurple),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (receiptData.mandalAddress != null)
                        Center(
                          child: Text(
                            receiptData.mandalAddress!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      const Divider(height: 24, thickness: 1),

                      // Receipt No & Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.lightLavender,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Text(
                              'पावती क्र: ${receiptData.receiptNumber}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                            ),
                          ),
                          Text(
                            AppFormatters.formatDate(receiptData.date),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Contributor details
                      _receiptRow('वर्गणीदाराचे नाव:', receiptData.familyHead.isNotEmpty ? receiptData.familyHead : receiptData.familyName, isBold: true),
                      if (receiptData.houseNumber != null) ...[
                        const SizedBox(height: 8),
                        _receiptRow('घर क्र:', receiptData.houseNumber!),
                      ],
                      if (receiptData.mobile != null) ...[
                        const SizedBox(height: 8),
                        _receiptRow('मोबाईल:', '+91 ${receiptData.mobile!}'),
                      ],
                      const SizedBox(height: 8),
                      _receiptRow('सदस्य संख्या:', '${receiptData.totalMembers} व्यक्ती'),
                      const Divider(height: 24, thickness: 1),

                      // Financial Details
                      _receiptRow('एकूण ठरलेली वर्गणी:', AppFormatters.formatCurrency(receiptData.totalVargani)),
                      const SizedBox(height: 12),

                      // Large Highlight Amount Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryPurple.withOpacity(0.06),
                              AppColors.royalBlue.withOpacity(0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'जमा केलेली रक्कम:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                            ),
                            Text(
                              AppFormatters.formatCurrency(receiptData.amountPaid),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      _receiptRow('पेमेंट पद्धत:', receiptData.paymentMode.toUpperCase(), isBold: true, valueColor: AppColors.royalBlue),
                      if (receiptData.utrNumber != null && receiptData.utrNumber!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _receiptRow('UTR / ट्रान्झॅक्शन क्र:', receiptData.utrNumber!),
                      ],
                      const SizedBox(height: 8),
                      _receiptRow(
                        'उर्वरित बाकी रक्कम:',
                        AppFormatters.formatCurrency(receiptData.pendingAmount),
                        valueColor: receiptData.pendingAmount > 0 ? AppColors.error : AppColors.success,
                        isBold: true,
                      ),
                      if (receiptData.notes != null && receiptData.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _receiptRow('विशेष नोंद:', receiptData.notes!),
                      ],
                      const Divider(height: 24, thickness: 1),

                      // Signature & Collector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('वर्गणी स्वीकारणारा:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(receiptData.collectorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('अधिकृत स्वाक्षरी', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              SizedBox(height: 2),
                              Text('✓ डिजिटल शिक्का', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.royalBlue)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions: WhatsApp, PDF, Print
                ElevatedButton.icon(
                  onPressed: _isSharingWhatsApp ? null : _handleWhatsAppShare,
                  icon: _isSharingWhatsApp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    _isSharingWhatsApp
                        ? lang.tr('PDF तयार करून WhatsApp उघडत आहे...', 'Opening WhatsApp with PDF...')
                        : lang.tr('WhatsApp वर PDF पावती पाठवा', 'Send PDF Receipt on WhatsApp'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ShareService.sharePdfFile(receiptData),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: const Text('PDF शेअर', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryPurple,
                          side: const BorderSide(color: AppColors.primaryPurple),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ShareService.printReceipt(receiptData),
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('प्रिंट पावती', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.royalBlue,
                          side: const BorderSide(color: AppColors.royalBlue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('डॅशबोर्डवर परत जा', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String val, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
