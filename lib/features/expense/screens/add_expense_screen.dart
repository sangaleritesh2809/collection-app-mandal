import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_label.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _paidByController = TextEditingController();
  final _paidToController = TextEditingController();
  final _descController = TextEditingController();

  String _category = 'Decoration';
  String _paymentMode = 'cash';
  DateTime _expenseDate = DateTime.now();

  final List<String> _categories = [
    'Decoration',
    'Sound System',
    'Lighting',
    'Food',
    'Transport',
    'Electricity',
    'Event Management',
    'Pooja Sahitya',
    'Prize & Gifts',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).userProfile;
    _paidByController.text = user?.fullName ?? 'मंडळ खजिनदार';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _paidByController.dispose();
    _paidToController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final success = await ref.read(expenseProvider.notifier).addExpense(
      title: _titleController.text.trim(),
      category: _category,
      amount: amount,
      expenseDate: _expenseDate,
      paidBy: _paidByController.text.trim(),
      paidTo: _paidToController.text.trim(),
      paymentMode: _paymentMode,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('खर्च यशस्वीपणे नोंदवला गेला!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final expenseState = ref.watch(expenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('नवीन खर्च नोंदवा', 'Add Expense')),
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
                  // Title
                  const FormLabel('खर्च शीर्षक', isRequired: true),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'उदा. स्टेज व मंडप डेकोरेशन',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (val) => AppValidators.required(val, 'खर्च शीर्षक'),
                  ),
                  const SizedBox(height: 16),

                  // Category
                  const FormLabel('खर्च कॅटेगरी', isRequired: true),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _category = val ?? 'Decoration'),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  const FormLabel('खर्च रक्कम (₹)', isRequired: true),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.error),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.currency_rupee, size: 28),
                      hintText: 'उदा. ३५००',
                    ),
                    validator: (val) => AppValidators.amount(val, fieldName: 'खर्च रक्कम'),
                  ),
                  const SizedBox(height: 16),

                  // Paid To & Paid By
                  FormLabel(lang.tr('रक्कम कोणाला दिली', 'Paid To'), isRequired: true),
                  TextFormField(
                    controller: _paidToController,
                    decoration: InputDecoration(
                      hintText: lang.tr('उदा. साई डेकोरेटर्स / अमोल शिंदे', 'e.g. Sai Decorators / Amol Shinde'),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (val) => AppValidators.name(val, lang.tr('स्वीकारणाऱ्याचे नाव', 'Recipient Name')),
                  ),
                  const SizedBox(height: 16),

                  FormLabel(lang.tr('रक्कम कोणी दिली', 'Paid By'), isRequired: true),
                  TextFormField(
                    controller: _paidByController,
                    decoration: InputDecoration(
                      hintText: lang.tr('उदा. खजिनदार सुरेश कदम', 'e.g. Treasurer Suresh Kadam'),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                    validator: (val) => AppValidators.name(val, lang.tr('रक्कम देणाऱ्याचे नाव', 'Payer Name')),
                  ),
                  const SizedBox(height: 16),

                  // Payment Mode & Date
                  FormLabel(lang.tr('पेमेंट पद्धत', 'Payment Mode'), isRequired: true),
                  DropdownButtonFormField<String>(
                    value: _paymentMode,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: [
                      DropdownMenuItem(value: 'cash', child: Text(lang.tr('रोख', 'Cash'))),
                      DropdownMenuItem(value: 'upi', child: Text(lang.tr('UPI ट्रान्सफर', 'UPI Transfer'))),
                      DropdownMenuItem(value: 'bank_transfer', child: Text(lang.tr('बँक चेक / NEFT', 'Bank Cheque / NEFT'))),
                      DropdownMenuItem(value: 'other', child: Text(lang.tr('इतर', 'Other'))),
                    ],
                    onChanged: (val) => setState(() => _paymentMode = val ?? 'cash'),
                  ),
                  const SizedBox(height: 16),

                  const FormLabel('खर्च दिनांक'),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expenseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _expenseDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(AppFormatters.formatDate(_expenseDate)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const FormLabel('तपशील / बिल संदर्भ'),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'उदा. बिल क्र. ४५ / ५०% ॲडव्हान्स दिला',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit
                  ElevatedButton(
                    onPressed: expenseState.isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.error,
                    ),
                    child: expenseState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(lang.tr('खर्च जतन करा', 'Save Expense')),
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

