import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../../family/providers/family_provider.dart';
import '../providers/vargani_config_provider.dart';

class VarganiConfigScreen extends ConsumerStatefulWidget {
  const VarganiConfigScreen({super.key});

  @override
  ConsumerState<VarganiConfigScreen> createState() => _VarganiConfigScreenState();
}

class _VarganiConfigScreenState extends ConsumerState<VarganiConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _financialYearController;
  late TextEditingController _perMemberAmountController;
  late TextEditingController _fixedAmountController;
  late TextEditingController _discountController;
  late TextEditingController _specialContributionController;
  String _calculationType = 'per_member';
  DateTime? _dueDate;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _financialYearController = TextEditingController(text: '${DateTime.now().year}-${DateTime.now().year + 1}');
    _perMemberAmountController = TextEditingController(text: '500');
    _fixedAmountController = TextEditingController(text: '2000');
    _discountController = TextEditingController(text: '0');
    _specialContributionController = TextEditingController(text: '0');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final configState = ref.read(varganiConfigProvider);
      final active = configState.activeConfig;
      if (active != null) {
        _nameController.text = active.name;
        _financialYearController.text = active.financialYear;
        _calculationType = active.calculationType;
        _perMemberAmountController.text = active.perMemberAmount.toStringAsFixed(0);
        _fixedAmountController.text = active.fixedAmount.toStringAsFixed(0);
        _discountController.text = active.discount.toStringAsFixed(0);
        _specialContributionController.text = active.specialContribution.toStringAsFixed(0);
        _dueDate = active.dueDate;
      } else {
        final mandalName = ref.read(mandalProvider).selectedMandal?.name ?? 'मंडळ';
        _nameController.text = '$mandalName वर्गणी ${DateTime.now().year}';
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _financialYearController.dispose();
    _perMemberAmountController.dispose();
    _fixedAmountController.dispose();
    _discountController.dispose();
    _specialContributionController.dispose();
    super.dispose();
  }

  double _getCalculatedSample(int members) {
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final special = double.tryParse(_specialContributionController.text) ?? 0.0;

    if (_calculationType == 'per_member') {
      final rate = double.tryParse(_perMemberAmountController.text) ?? 0.0;
      return (members * rate - discount + special).clamp(0.0, double.infinity);
    } else {
      final fixed = double.tryParse(_fixedAmountController.text) ?? 0.0;
      return (fixed - discount + special).clamp(0.0, double.infinity);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final configState = ref.read(varganiConfigProvider);
    final activeId = configState.activeConfig?.id;

    final perMember = double.tryParse(_perMemberAmountController.text.trim()) ?? 0.0;
    final fixed = double.tryParse(_fixedAmountController.text.trim()) ?? 0.0;
    final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;
    final special = double.tryParse(_specialContributionController.text.trim()) ?? 0.0;

    final success = await ref.read(varganiConfigProvider.notifier).saveConfig(
      id: activeId,
      name: _nameController.text.trim(),
      financialYear: _financialYearController.text.trim(),
      calculationType: _calculationType,
      perMemberAmount: perMember,
      fixedAmount: fixed,
      discount: discount,
      specialContribution: special,
      dueDate: _dueDate,
    );

    if (success && mounted) {
      // Reload families so updated totals reflect immediately on screens
      ref.read(familyProvider.notifier).loadFamilies();

      final mandalName = ref.read(mandalProvider).selectedMandal?.name ?? 'मंडळ';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('🚩 $mandalName चे वर्गणी दर यशस्वीपणे सेव्ह झाले आणि कुटुंबांना लागू झाले!'),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mandalState = ref.watch(mandalProvider);
    final configState = ref.watch(varganiConfigProvider);
    final activeMandal = mandalState.selectedMandal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('वर्गणी दर व नियम (Vargani Settings)'),
      ),
      body: SafeArea(
        child: configState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Active Mandal Multi-Tenant Security Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activeMandal != null ? '🚩 ${activeMandal.name}' : 'सक्रिय मंडळ',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'बहु-मंडळ सुरक्षितता (Mandal Isolation):',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primaryDark),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'तुम्ही येथे निश्चित केलेले वर्गणीचे दर फक्त आणि फक्त या मंडळाच्या कुटुंबांसाठीच लागू होतील. इतर कोणत्याही मंडळावर याचा परिणाम होणार नाही.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Basic Details Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('वर्गणी मोहीम तपशील', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'वर्गणीचे नाव *',
                                  hintText: 'उदा. श्री गणेशोत्सव वर्गणी २०२६',
                                  prefixIcon: Icon(Icons.event_note),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'नाव आवश्यक आहे' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _financialYearController,
                                decoration: const InputDecoration(
                                  labelText: 'आर्थिक वर्ष *',
                                  hintText: 'उदा. 2026-2027',
                                  prefixIcon: Icon(Icons.calendar_month),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'वर्ष आवश्यक आहे' : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Calculation Method Selection Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('वर्गणी आकारणी पद्धत (Calculation Type)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 12),

                              // Option 1: Per Member
                              _buildCalculationOption(
                                type: 'per_member',
                                title: 'प्रत्येक सदस्यानुसार (Per Member)',
                                subtitle: 'कुटुंबातील व्यक्तींच्या संख्येनुसार वर्गणी (उदा. ४ व्यक्ती × दर)',
                                icon: Icons.people_outline,
                              ),
                              const SizedBox(height: 8),

                              // Option 2: Per Family
                              _buildCalculationOption(
                                type: 'per_family',
                                title: 'प्रत्येक कुटुंबास ठराविक (Per Family)',
                                subtitle: 'कुटुंबातील व्यक्तींची संख्या कितीही असली तरी समान निश्चित रक्कम',
                                icon: Icons.home_outlined,
                              ),
                              const SizedBox(height: 8),

                              // Option 3: Fixed
                              _buildCalculationOption(
                                type: 'fixed',
                                title: 'समान निश्चित वर्गणी (Fixed Amount)',
                                subtitle: 'सर्व कुटुंबांसाठी एकसमान निश्चित दर',
                                icon: Icons.payments_outlined,
                              ),
                              const SizedBox(height: 16),

                              // Amount Inputs based on selection
                              if (_calculationType == 'per_member')
                                TextFormField(
                                  controller: _perMemberAmountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'प्रति सदस्य वर्गणी दर (₹) *',
                                    hintText: '500',
                                    prefixIcon: Icon(Icons.currency_rupee),
                                    helperText: 'उदा. ५०० टाकल्यास ४ सदस्यांच्या कुटुंबाची वर्गणी ₹२,००० होईल.',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (val) {
                                    if (val == null || double.tryParse(val.trim()) == null || double.parse(val.trim()) <= 0) {
                                      return 'वैध दर टाका';
                                    }
                                    return null;
                                  },
                                )
                              else
                                TextFormField(
                                  controller: _fixedAmountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'कुटुंबास निश्चित वर्गणी दर (₹) *',
                                    hintText: '2000',
                                    prefixIcon: Icon(Icons.currency_rupee),
                                    helperText: 'कुटुंबात कितीही सदस्य असले तरी हीच रक्कम आकारली जाईल.',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (val) {
                                    if (val == null || double.tryParse(val.trim()) == null || double.parse(val.trim()) <= 0) {
                                      return 'वैध रक्कम टाका';
                                    }
                                    return null;
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Optional Discount & Contribution
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('सवलत किंवा देणगी (ऐच्छिक)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _discountController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'सवलत (₹)',
                                        hintText: '0',
                                        prefixIcon: Icon(Icons.discount_outlined),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _specialContributionController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'विशेष देणगी (₹)',
                                        hintText: '0',
                                        prefixIcon: Icon(Icons.add_circle_outline),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Live Calculation Preview Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calculate_outlined, color: AppColors.primary, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'थेट हिशोब पडताळणी (Live Preview)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('उदा. ४ सदस्यांच्या कुटुंबाची वर्गणी:', style: TextStyle(fontSize: 13)),
                                Text(
                                  AppFormatters.formatCurrency(_getCalculatedSample(4)),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('उदा. १ सदस्याच्या कुटुंबाची वर्गणी:', style: TextStyle(fontSize: 13)),
                                Text(
                                  AppFormatters.formatCurrency(_getCalculatedSample(1)),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _handleSave,
                        icon: const Icon(Icons.save),
                        label: const Text('दर सेव्ह करा व या मंडळाला लागू करा', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCalculationOption({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _calculationType == type;
    return InkWell(
      onTap: () => setState(() => _calculationType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade600, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: type,
              groupValue: _calculationType,
              onChanged: (val) {
                if (val != null) setState(() => _calculationType = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
