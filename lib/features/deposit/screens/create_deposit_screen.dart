import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_label.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../collection/providers/collection_provider.dart';
import '../providers/deposit_provider.dart';

class CreateDepositScreen extends ConsumerStatefulWidget {
  const CreateDepositScreen({super.key});

  @override
  ConsumerState<CreateDepositScreen> createState() => _CreateDepositScreenState();
}

class _CreateDepositScreenState extends ConsumerState<CreateDepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedTreasurerId;
  String _paymentMode = 'cash';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(collectionProvider.notifier).loadCollections();
      ref.read(depositProvider.notifier).loadDepositRequests();
      ref.read(depositProvider.notifier).loadTreasurers();

      final undeposited = ref.read(collectionProvider).undepositedAmount;
      if (undeposited > 0) {
        _amountController.text = undeposited.toInt().toString();
      }
      final treasurers = ref.read(depositProvider).treasurers;
      if (treasurers.isNotEmpty) {
        setState(() => _selectedTreasurerId = treasurers.first['id'] as String?);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(double maxAllowed) async {
    final lang = ref.read(languageProvider);

    if (!_formKey.currentState!.validate()) return;
    if (_selectedTreasurerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(lang.tr('कृपया खजिनदार निवडा', 'Please select a treasurer')),
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (maxAllowed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(lang.tr('सध्या जमा करण्यासाठी कोणतीही वर्गणी रक्कम शिल्लक नाही.', 'No collection balance available to deposit.')),
        ),
      );
      return;
    }

    if (amount > maxAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(lang.tr(
            'जमा रक्कम उपलब्ध बाकीपेक्षा (${AppFormatters.formatCurrency(maxAllowed)}) जास्त असू शकत नाही.',
            'Deposit amount cannot exceed available balance (${AppFormatters.formatCurrency(maxAllowed)}).',
          )),
        ),
      );
      return;
    }

    final success = await ref.read(depositProvider.notifier).createDepositRequest(
      designatedTreasurerId: _selectedTreasurerId!,
      amount: amount,
      paymentMode: _paymentMode,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(lang.tr('ठेव विनंती यशस्वीपणे पाठवली गेली! खजिनदाराला सूचना पाठवली आहे.', 'Deposit request submitted successfully! Notification sent to treasurer.')),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final depositState = ref.watch(depositProvider);
    final collectionState = ref.watch(collectionProvider);

    final maxDepositAllowed = collectionState.undepositedAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('ठेव विनंती करा', 'Deposit Request')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lang.tr(
                              'तुम्ही गोळा केलेली रक्कम खजिनदाराकडे जमा करण्यासाठी येथे विनंती नोंदवा. खजिनदाराने मंजूर केल्यानंतरच हिशेब पूर्ण होईल.',
                              'Submit a request to deposit collected funds with the treasurer. Accounts will update once approved.',
                            ),
                            style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Undeposited Balance quick reminder
                  if (maxDepositAllowed > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.tr('तुमच्याकडील जमा बाकी रक्कम:', 'Your Undeposited Balance:'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          Text(
                            AppFormatters.formatCurrency(maxDepositAllowed),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryPurple),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lang.tr(
                                'सध्या जमा करण्यासाठी कोणतीही वर्गणी रक्कम शिल्लक नाही (उपलब्ध: ₹0).',
                                'No collection balance available to deposit (Available: ₹0).',
                              ),
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Select Treasurer
                  FormLabel(lang.tr('खजिनदार / रक्कम स्वीकारणारा', 'Treasurer / Recipient'), isRequired: true),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedTreasurerId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    items: depositState.treasurers.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['id'] as String,
                        child: Text(
                          t['full_name'] as String? ?? lang.tr('खजिनदार', 'Treasurer'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTreasurerId = val),
                    validator: (val) => val == null ? lang.tr('खजिनदार निवडणे आवश्यक आहे', 'Please select a treasurer') : null,
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  FormLabel(lang.tr('जमा करायची रक्कम (₹)', 'Deposit Amount (₹)'), isRequired: true),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee, size: 28),
                      hintText: lang.tr('रक्कम टाका', 'Enter amount'),
                    ),
                    validator: (val) {
                      final basicCheck = AppValidators.amount(val, fieldName: lang.tr('जमा रक्कम', 'Deposit amount'), min: 1);
                      if (basicCheck != null) return basicCheck;
                      final num = double.tryParse(val!.trim()) ?? 0.0;
                      if (maxDepositAllowed > 0 && num > maxDepositAllowed) {
                        return lang.tr(
                          'जमा रक्कम शिल्लक रकमेपेक्षा (${AppFormatters.formatCurrency(maxDepositAllowed)}) जास्त असू शकत नाही.',
                          'Amount cannot exceed available balance (${AppFormatters.formatCurrency(maxDepositAllowed)}).',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Payment Mode
                  FormLabel(lang.tr('पेमेंट पद्धत', 'Payment Mode'), isRequired: true),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _paymentMode,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: [
                      DropdownMenuItem(value: 'cash', child: Text(lang.tr('रोख', 'Cash'))),
                      DropdownMenuItem(value: 'upi', child: Text(lang.tr('UPI ट्रान्सफर', 'UPI Transfer'))),
                      DropdownMenuItem(value: 'bank_transfer', child: Text(lang.tr('बँक खात्यात थेट जमा', 'Direct Bank Deposit'))),
                      DropdownMenuItem(value: 'other', child: Text(lang.tr('इतर', 'Other'))),
                    ],
                    onChanged: (val) => setState(() => _paymentMode = val ?? 'cash'),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  FormLabel(lang.tr('तपशील / वर्णन', 'Description / Details')),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: lang.tr('तपशील किंवा वर्णन टाका', 'Enter details or description'),
                      prefixIcon: const Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit
                  ElevatedButton(
                    onPressed: (depositState.isLoading || maxDepositAllowed <= 0) ? null : () => _handleSubmit(maxDepositAllowed),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: depositState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(lang.tr('ठेव विनंती पाठवा', 'Submit Request')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
