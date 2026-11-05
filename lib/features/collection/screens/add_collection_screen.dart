import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../family/models/family.dart';
import '../../family/providers/family_provider.dart';
import '../providers/collection_provider.dart';

class AddCollectionScreen extends ConsumerStatefulWidget {
  final Family? initialFamily;

  const AddCollectionScreen({super.key, this.initialFamily});

  @override
  ConsumerState<AddCollectionScreen> createState() => _AddCollectionScreenState();
}

class _AddCollectionScreenState extends ConsumerState<AddCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  Family? _selectedFamily;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMode = 'cash';
  DateTime _collectionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedFamily = widget.initialFamily;
    if (_selectedFamily != null && _selectedFamily!.pendingAmount > 0) {
      _amountController.text = _selectedFamily!.pendingAmount.toInt().toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFamily == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया कुटुंब निवडा')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final receipt = await ref.read(collectionProvider.notifier).submitCollection(
      familyId: _selectedFamily!.id,
      amount: amount,
      paymentMode: _paymentMode,
      collectionDate: _collectionDate,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      familyName: _selectedFamily!.familyName,
      familyHeadName: _selectedFamily!.familyHeadName,
      houseNumber: _selectedFamily!.houseNumber,
      mobileNumber: _selectedFamily!.mobileNumber,
      totalMembers: _selectedFamily!.totalMembers,
      totalVargani: _selectedFamily!.totalVargani,
      previousPaid: _selectedFamily!.paidAmount,
    );

    if (receipt != null && mounted) {
      context.pushReplacement('/receipt-preview', extra: receipt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);
    final collectionState = ref.watch(collectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('वर्गणी जमा करा (Collect Vargani)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Family Selector Dropdown
                DropdownButtonFormField<Family>(
                  value: _selectedFamily != null
                      ? familyState.families.firstWhere(
                          (f) => f.id == _selectedFamily!.id,
                          orElse: () => _selectedFamily!,
                        )
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'कुटुंब निवडा *',
                    prefixIcon: Icon(Icons.people),
                  ),
                  items: familyState.families.map((f) {
                    return DropdownMenuItem<Family>(
                      value: f,
                      child: Text('${f.familyName} (${f.familyHeadName})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedFamily = val;
                      if (val != null && val.pendingAmount > 0) {
                        _amountController.text = val.pendingAmount.toInt().toString();
                      }
                    });
                  },
                  validator: (val) => val == null ? 'कुटुंब निवडणे आवश्यक आहे' : null,
                ),
                const SizedBox(height: 16),

                // Selected Family Summary Card
                if (_selectedFamily != null) ...[
                  Card(
                    color: Colors.orange.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.orange.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedFamily!.familyName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                '${_selectedFamily!.totalMembers} व्यक्ती',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _infoSub('एकूण ठरलेली वर्गणी', AppFormatters.formatCurrency(_selectedFamily!.totalVargani)),
                              _infoSub('आधी जमा रक्कम', AppFormatters.formatCurrency(_selectedFamily!.paidAmount), color: AppColors.success),
                              _infoSub('बाकी रक्कम', AppFormatters.formatCurrency(_selectedFamily!.pendingAmount), color: AppColors.error),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.success),
                  decoration: const InputDecoration(
                    labelText: 'वर्गणी रक्कम (₹) *',
                    prefixIcon: Icon(Icons.currency_rupee, size: 28),
                    hintText: 'उदा. ५००',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'रक्कम आवश्यक आहे';
                    final n = double.tryParse(val.trim());
                    if (n == null || n <= 0) return 'वैध रक्कम टाका';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Payment Mode Dropdown
                DropdownButtonFormField<String>(
                  value: _paymentMode,
                  decoration: const InputDecoration(
                    labelText: 'पेमेंट पद्धत *',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('रोख (Cash)')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI (GPay / PhonePe / Paytm)')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('बँक ट्रान्सफर (NEFT/RTGS)')),
                    DropdownMenuItem(value: 'cheque', child: Text('धनादेश (Cheque)')),
                    DropdownMenuItem(value: 'other', child: Text('इतर (Other)')),
                  ],
                  onChanged: (val) => setState(() => _paymentMode = val ?? 'cash'),
                ),
                const SizedBox(height: 16),

                // Collection Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _collectionDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _collectionDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'संकलन दिनांक',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(AppFormatters.formatDate(_collectionDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'काही विशेष नोंद (Notes)',
                    hintText: 'उदा. विशेष देणगी / उर्वरित रक्कम नंतर देतील',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: collectionState.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: collectionState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('पावती तयार करा व जतन करा (Generate Receipt)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoSub(String label, String val, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}
