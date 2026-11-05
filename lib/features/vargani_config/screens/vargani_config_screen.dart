import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_label.dart';
import '../../../core/widgets/responsive_container.dart';
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
  String? _editingSection; // null, 'campaign', 'calculation', 'discount'

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
        _calculationType = (active.calculationType == 'per_family') ? 'fixed' : active.calculationType;
        _perMemberAmountController.text = active.perMemberAmount.toStringAsFixed(0);
        _fixedAmountController.text = active.fixedAmount.toStringAsFixed(0);
        _discountController.text = active.discount.toStringAsFixed(0);
        _specialContributionController.text = active.specialContribution.toStringAsFixed(0);
        _dueDate = active.dueDate;
        _editingSection = null;
      } else {
        final mandalName = ref.read(mandalProvider).selectedMandal?.name ?? 'मंडळ';
        _nameController.text = '$mandalName वर्गणी ${DateTime.now().year}';
        _editingSection = 'calculation';
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

  void _resetValuesFromConfig() {
    final active = ref.read(varganiConfigProvider).activeConfig;
    if (active != null) {
      _nameController.text = active.name;
      _financialYearController.text = active.financialYear;
      _calculationType = (active.calculationType == 'per_family') ? 'fixed' : active.calculationType;
      _perMemberAmountController.text = active.perMemberAmount.toStringAsFixed(0);
      _fixedAmountController.text = active.fixedAmount.toStringAsFixed(0);
      _discountController.text = active.discount.toStringAsFixed(0);
      _specialContributionController.text = active.specialContribution.toStringAsFixed(0);
      _dueDate = active.dueDate;
    }
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

    final lang = ref.read(languageProvider);
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
      ref.read(familyProvider.notifier).loadFamilies();

      final mandalName = ref.read(mandalProvider).selectedMandal?.name ?? 'मंडळ';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(lang.tr(
            '🚩 $mandalName चे वर्गणी दर यशस्वीपणे सेव्ह झाले!',
            '🚩 Vargani rates for $mandalName saved successfully!',
          )),
        ),
      );
      setState(() => _editingSection = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final mandalState = ref.watch(mandalProvider);
    final configState = ref.watch(varganiConfigProvider);
    final activeMandal = mandalState.selectedMandal;
    final hasExistingConfig = configState.activeConfig != null;

    final isCampaignEditing = _editingSection == 'campaign' || !hasExistingConfig;
    final isCalculationEditing = _editingSection == 'calculation' || !hasExistingConfig;
    final isDiscountEditing = _editingSection == 'discount' || !hasExistingConfig;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('वर्गणी दर व नियम', 'Vargani Settings')),
      ),
      body: SafeArea(
        child: configState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: ResponsiveContainer(
                  maxWidth: 720,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Active Mandal Banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: AppColors.primaryPurple, size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activeMandal != null ? '🚩 ${activeMandal.name}' : lang.tr('सक्रिय मंडळ', 'Active Mandal'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryPurple),
                                ),
                              ),
                              if (hasExistingConfig && _editingSection == null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    lang.tr('सक्रिय', 'Active'),
                                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 1: Campaign Details Card
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isCampaignEditing ? AppColors.primaryPurple : Colors.grey.shade300,
                              width: isCampaignEditing ? 1.5 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      lang.tr('वर्गणी मोहीम तपशील', 'Vargani Campaign Details'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    if (hasExistingConfig) ...[
                                      if (!isCampaignEditing)
                                        TextButton.icon(
                                          onPressed: () {
                                            _resetValuesFromConfig();
                                            setState(() => _editingSection = 'campaign');
                                          },
                                          icon: const Icon(Icons.edit, size: 15, color: AppColors.primaryPurple),
                                          label: Text(
                                            lang.tr('बदला', 'Edit'),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryPurple),
                                          ),
                                        )
                                      else
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                _resetValuesFromConfig();
                                                setState(() => _editingSection = null);
                                              },
                                              child: Text(lang.tr('रद्द करा', 'Cancel'), style: const TextStyle(color: AppColors.textSecondary)),
                                            ),
                                            ElevatedButton(
                                              onPressed: _handleSave,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primaryPurple,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              ),
                                              child: Text(lang.tr('जतन करा', 'Save')),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                FormLabel(lang.tr('वर्गणीचे नाव', 'Vargani Campaign Name'), isRequired: true),
                                TextFormField(
                                  controller: _nameController,
                                  enabled: isCampaignEditing,
                                  decoration: InputDecoration(
                                    hintText: lang.tr('उदा. श्री गणेशोत्सव वर्गणी २०२६', 'e.g. Ganeshotsav Vargani 2026'),
                                    prefixIcon: const Icon(Icons.event_note),
                                    suffixIcon: isCampaignEditing && _nameController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 18),
                                            tooltip: lang.tr('साफ करा', 'Clear'),
                                            onPressed: () => setState(() => _nameController.clear()),
                                          )
                                        : null,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (val) => AppValidators.required(val, lang.tr('वर्गणीचे नाव', 'Vargani Name')),
                                ),
                                const SizedBox(height: 12),
                                FormLabel(lang.tr('आर्थिक वर्ष', 'Financial Year'), isRequired: true),
                                TextFormField(
                                  controller: _financialYearController,
                                  enabled: isCampaignEditing,
                                  decoration: const InputDecoration(
                                    hintText: '2026-2027',
                                    prefixIcon: Icon(Icons.calendar_month),
                                  ),
                                  validator: (val) => AppValidators.required(val, lang.tr('आर्थिक वर्ष', 'Financial Year')),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Calculation Method Selection Card
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isCalculationEditing ? AppColors.primaryPurple : Colors.grey.shade300,
                              width: isCalculationEditing ? 1.5 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      lang.tr('वर्गणी आकारणी पद्धत', 'Calculation Type'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    if (hasExistingConfig) ...[
                                      if (!isCalculationEditing)
                                        TextButton.icon(
                                          onPressed: () {
                                            _resetValuesFromConfig();
                                            setState(() => _editingSection = 'calculation');
                                          },
                                          icon: const Icon(Icons.edit, size: 15, color: AppColors.primaryPurple),
                                          label: Text(
                                            lang.tr('बदला', 'Edit'),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryPurple),
                                          ),
                                        )
                                      else
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                _resetValuesFromConfig();
                                                setState(() => _editingSection = null);
                                              },
                                              child: Text(lang.tr('रद्द करा', 'Cancel'), style: const TextStyle(color: AppColors.textSecondary)),
                                            ),
                                            ElevatedButton(
                                              onPressed: _handleSave,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primaryPurple,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              ),
                                              child: Text(lang.tr('जतन करा', 'Save')),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Option 1: Per Member
                                _buildCalculationOption(
                                  type: 'per_member',
                                  title: lang.tr('प्रत्येक सदस्यानुसार', 'Per Member'),
                                  subtitle: lang.tr('कुटुंबातील व्यक्तींच्या संख्येनुसार वर्गणी (उदा. ४ व्यक्ती × दर)', 'Based on family members count (e.g. 4 members × rate)'),
                                  icon: Icons.people_outline,
                                  enabled: isCalculationEditing,
                                ),
                                const SizedBox(height: 10),

                                // Option 2: Per Family / Fixed Flat Rate (Duplicate removed!)
                                _buildCalculationOption(
                                  type: 'fixed',
                                  title: lang.tr('प्रत्येक कुटुंबास ठराविक (निश्चित रक्कम)', 'Per Family (Fixed Amount)'),
                                  subtitle: lang.tr('कुटुंबातील व्यक्तींची संख्या कितीही असली तरी समान निश्चित रक्कम', 'Fixed flat rate regardless of family size'),
                                  icon: Icons.home_outlined,
                                  enabled: isCalculationEditing,
                                ),
                                const SizedBox(height: 16),

                                // Amount Inputs based on selection
                                if (_calculationType == 'per_member') ...[
                                  FormLabel(
                                    lang.tr('प्रति सदस्य वर्गणी दर (₹)', 'Per Member Vargani Rate (₹)'),
                                    isRequired: true,
                                    subtitle: lang.tr('उदा. ५०० टाकल्यास ४ सदस्यांच्या कुटुंबाची वर्गणी ₹२,००० होईल.', 'e.g. ₹500 means 4 member family will pay ₹2,000.'),
                                  ),
                                  TextFormField(
                                    controller: _perMemberAmountController,
                                    enabled: isCalculationEditing,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: '500',
                                      prefixIcon: Icon(Icons.currency_rupee),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (val) => AppValidators.amount(val, fieldName: lang.tr('प्रति सदस्य वर्गणी दर', 'Per Member Rate')),
                                  ),
                                ] else ...[
                                  FormLabel(
                                    lang.tr('कुटुंबास निश्चित वर्गणी दर (₹)', 'Fixed Family Vargani Rate (₹)'),
                                    isRequired: true,
                                    subtitle: lang.tr('कुटुंबात कितीही सदस्य असले तरी हीच रक्कम आकारली जाईल.', 'Same amount charged regardless of member count.'),
                                  ),
                                  TextFormField(
                                    controller: _fixedAmountController,
                                    enabled: isCalculationEditing,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: '2000',
                                      prefixIcon: Icon(Icons.currency_rupee),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (val) => AppValidators.amount(val, fieldName: lang.tr('कुटुंबास निश्चित वर्गणी दर', 'Fixed Family Rate')),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 3: Optional Discount & Contribution Card
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDiscountEditing ? AppColors.primaryPurple : Colors.grey.shade300,
                              width: isDiscountEditing ? 1.5 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      lang.tr('सवलत किंवा देणगी (ऐच्छिक)', 'Discount or Donation (Optional)'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    if (hasExistingConfig) ...[
                                      if (!isDiscountEditing)
                                        TextButton.icon(
                                          onPressed: () {
                                            _resetValuesFromConfig();
                                            setState(() => _editingSection = 'discount');
                                          },
                                          icon: const Icon(Icons.edit, size: 15, color: AppColors.primaryPurple),
                                          label: Text(
                                            lang.tr('बदला', 'Edit'),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryPurple),
                                          ),
                                        )
                                      else
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                _resetValuesFromConfig();
                                                setState(() => _editingSection = null);
                                              },
                                              child: Text(lang.tr('रद्द करा', 'Cancel'), style: const TextStyle(color: AppColors.textSecondary)),
                                            ),
                                            ElevatedButton(
                                              onPressed: _handleSave,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primaryPurple,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              ),
                                              child: Text(lang.tr('जतन करा', 'Save')),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          FormLabel(lang.tr('सवलत (₹)', 'Discount (₹)')),
                                          TextFormField(
                                            controller: _discountController,
                                            enabled: isDiscountEditing,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              hintText: '0',
                                              prefixIcon: Icon(Icons.discount_outlined),
                                            ),
                                            validator: (val) {
                                              if (val != null && val.trim().isNotEmpty) {
                                                return AppValidators.amount(val, min: 0, fieldName: lang.tr('सवलत', 'Discount'));
                                              }
                                              return null;
                                            },
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          FormLabel(lang.tr('विशेष देणगी (₹)', 'Special Contribution (₹)')),
                                          TextFormField(
                                            controller: _specialContributionController,
                                            enabled: isDiscountEditing,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              hintText: '0',
                                              prefixIcon: Icon(Icons.add_circle_outline),
                                            ),
                                            validator: (val) {
                                              if (val != null && val.trim().isNotEmpty) {
                                                return AppValidators.amount(val, min: 0, fieldName: lang.tr('विशेष देणगी', 'Special Contribution'));
                                              }
                                              return null;
                                            },
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Live Calculation Preview Card
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
                              Row(
                                children: [
                                  const Icon(Icons.calculate_outlined, color: AppColors.primaryPurple, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    lang.tr('थेट हिशोब पडताळणी', 'Live Calculation Preview'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryPurple),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lang.tr('उदा. ४ सदस्यांच्या कुटुंबाची वर्गणी:', 'e.g. Family with 4 members:'),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    AppFormatters.formatCurrency(_getCalculatedSample(4)),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryPurple),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lang.tr('उदा. १ सदस्याच्या कुटुंबाची वर्गणी:', 'e.g. Family with 1 member:'),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    AppFormatters.formatCurrency(_getCalculatedSample(1)),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Initial setup submit button (only shown when setting up for the first time)
                        if (!hasExistingConfig) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _handleSave,
                            icon: const Icon(Icons.check_circle, color: Colors.white),
                            label: Text(lang.tr('दर व नियम लागू करा', 'Save & Apply')),
                          ),
                        ],
                        const SizedBox(height: 30),
                      ],
                    ),
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
    bool enabled = true,
  }) {
    final isSelected = _calculationType == type;
    return InkWell(
      onTap: enabled ? () => setState(() => _calculationType = type) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryPurple : Colors.grey.shade600, size: 24),
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
                      color: isSelected ? AppColors.primaryPurple : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: type,
              groupValue: _calculationType,
              activeColor: AppColors.primaryPurple,
              onChanged: enabled
                  ? (val) {
                      if (val != null) setState(() => _calculationType = val);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
