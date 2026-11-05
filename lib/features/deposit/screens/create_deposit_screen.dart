import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/form_label.dart';
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
    // Prefill with collector's current undeposited amount
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTreasurerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया खजिनदार निवडा')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final success = await ref.read(depositProvider.notifier).createDepositRequest(
      designatedTreasurerId: _selectedTreasurerId!,
      amount: amount,
      paymentMode: _paymentMode,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ठेव विनंती यशस्वीपणे पाठवली गेली! खजिनदाराला सूचना पाठवली आहे.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final depositState = ref.watch(depositProvider);
    final collectionState = ref.watch(collectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ठेव विनंती करा (Deposit Request)'),
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
                            'तुम्ही गोळा केलेली रक्कम खजिनदाराकडे जमा करण्यासाठी येथे विनंती नोंदवा. खजिनदाराने मंजूर केल्यानंतरच हिशेब पूर्ण होईल.',
                            style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Undeposited Balance quick reminder
                  if (collectionState.undepositedAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('तुमच्याकडील जमा बाकी रक्कम:', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                          Text(
                            AppFormatters.formatCurrency(collectionState.undepositedAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                          ),
                        ],
                      ),
                    ),

                  // Select Treasurer
                  const FormLabel('खजिनदार / रक्कम स्वीकारणारा', isRequired: true),
                  DropdownButtonFormField<String>(
                    value: _selectedTreasurerId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    items: depositState.treasurers.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['id'] as String,
                        child: Text(t['full_name'] as String? ?? 'Treasurer'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTreasurerId = val),
                    validator: (val) => val == null ? 'खजिनदार निवडणे आवश्यक आहे' : null,
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  const FormLabel('जमा करायची रक्कम (₹)', isRequired: true),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.currency_rupee, size: 28),
                      hintText: 'उदा. ५०००',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'रक्कम आवश्यक आहे';
                      final n = double.tryParse(val.trim());
                      if (n == null || n <= 0) return 'वैध रक्कम टाका';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Payment Mode
                  const FormLabel('पेमेंट पद्धत', isRequired: true),
                  DropdownButtonFormField<String>(
                    value: _paymentMode,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('रोख (Cash)')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI ट्रान्सफर')),
                      DropdownMenuItem(value: 'bank_transfer', child: Text('बँक खात्यात थेट जमा')),
                      DropdownMenuItem(value: 'other', child: Text('इतर')),
                    ],
                    onChanged: (val) => setState(() => _paymentMode = val ?? 'cash'),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const FormLabel('तपशील / वर्णन'),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'उदा. आज शिवाजी चौकातील १० कुटुंबांकडून गोळा केलेली रोख वर्गणी.',
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit
                  ElevatedButton(
                    onPressed: depositState.isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: depositState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('ठेव विनंती पाठवा (Submit Request)'),
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

