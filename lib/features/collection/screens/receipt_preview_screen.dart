import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/share_service.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final PdfReceiptData receiptData;

  const ReceiptPreviewScreen({super.key, required this.receiptData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('पावती पाहा (Receipt)'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/collections'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Alert Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'वर्गणी पावती यशस्वीपणे तयार झाली!',
                        style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Digital Receipt Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                  border: Border.all(color: Colors.deepOrange.shade100, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text(
                        '॥ श्री गणेशाय नमः ॥',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        receiptData.mandalName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (receiptData.mandalAddress != null)
                      Center(
                        child: Text(
                          receiptData.mandalAddress!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ),
                    const Divider(height: 24, thickness: 1),

                    // Receipt No & Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.deepOrange.shade200),
                          ),
                          child: Text(
                            receiptData.receiptNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 12),
                          ),
                        ),
                        Text(
                          AppFormatters.formatDate(receiptData.date),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Family Information
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _receiptRow('कुटुंबाचे नाव:', receiptData.familyName),
                          const SizedBox(height: 4),
                          _receiptRow('कुटुंब प्रमुख:', receiptData.familyHead),
                          const SizedBox(height: 4),
                          _receiptRow('घर नंबर:', receiptData.houseNumber ?? '-'),
                          const SizedBox(height: 4),
                          _receiptRow('सदस्य संख्या:', '${receiptData.totalMembers} व्यक्ती'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Financial Summary Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          _receiptRow('ठरलेली वर्गणी:', AppFormatters.formatCurrency(receiptData.totalVargani)),
                          const SizedBox(height: 6),
                          _receiptRow(
                            'जमा रक्कम:',
                            AppFormatters.formatCurrency(receiptData.amountPaid),
                            valueColor: AppColors.success,
                            isBold: true,
                          ),
                          const SizedBox(height: 6),
                          _receiptRow(
                            'शिल्लक बाकी:',
                            AppFormatters.formatCurrency(receiptData.pendingAmount),
                            valueColor: receiptData.pendingAmount > 0 ? AppColors.error : AppColors.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mode & Collector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('पद्धत: ${receiptData.paymentMode.toUpperCase()}', style: const TextStyle(fontSize: 12)),
                        Text('कार्यकर्ता: ${receiptData.collectorName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (receiptData.notes != null) ...[
                      const SizedBox(height: 6),
                      Text('नोंद: ${receiptData.notes!}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions: WhatsApp, PDF, Print
              ElevatedButton.icon(
                onPressed: () {
                  ShareService.shareReceiptOnWhatsApp(
                    mobileNumber: receiptData.mobile,
                    data: receiptData,
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('WhatsApp वर पावती पाठवा'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ShareService.sharePdfFile(receiptData),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF शेअर'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ShareService.printReceipt(receiptData),
                      icon: const Icon(Icons.print),
                      label: const Text('प्रिंट पावती'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('डॅशबोर्डवर परत जा'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String val, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

