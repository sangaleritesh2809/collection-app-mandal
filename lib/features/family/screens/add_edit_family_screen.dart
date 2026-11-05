import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_label.dart';
import '../../vargani_config/models/vargani_config.dart';
import '../../vargani_config/providers/vargani_config_provider.dart';
import '../providers/family_provider.dart';

class AddEditFamilyScreen extends ConsumerStatefulWidget {
  const AddEditFamilyScreen({super.key});

  @override
  ConsumerState<AddEditFamilyScreen> createState() => _AddEditFamilyScreenState();
}

class _AddEditFamilyScreenState extends ConsumerState<AddEditFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _headNameController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _villageController = TextEditingController();
  final _mobileController = TextEditingController();
  final _membersCountController = TextEditingController(text: '4');
  final _customVarganiController = TextEditingController();
  bool _useCustomVargani = false;

  @override
  void dispose() {
    _familyNameController.dispose();
    _headNameController.dispose();
    _houseNumberController.dispose();
    _addressController.dispose();
    _villageController.dispose();
    _mobileController.dispose();
    _membersCountController.dispose();
    _customVarganiController.dispose();
    super.dispose();
  }

  double _getCalculatedVargani(VarganiConfig? config) {
    if (_useCustomVargani) {
      return double.tryParse(_customVarganiController.text.trim()) ?? 0.0;
    }
    final members = int.tryParse(_membersCountController.text.trim()) ?? 1;
    if (config != null) {
      return config.calculateTotalForFamily(members);
    }
    return members * 500.0;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final members = int.tryParse(_membersCountController.text.trim()) ?? 1;
    final customAmount = _useCustomVargani ? double.tryParse(_customVarganiController.text.trim()) : null;

    final success = await ref.read(familyProvider.notifier).addFamily(
      familyName: _familyNameController.text.trim(),
      familyHeadName: _headNameController.text.trim(),
      houseNumber: _houseNumberController.text.trim(),
      address: _addressController.text.trim(),
      village: _villageController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      initialMembersCount: members,
      customTotalVargani: customAmount,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कुटुंब यशस्वीपणे जोडले गेले!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(varganiConfigProvider);
    final activeConfig = configState.activeConfig;
    final calculatedVargani = _getCalculatedVargani(activeConfig);

    return Scaffold(
      appBar: AppBar(
        title: const Text('नवीन कुटुंब जोडा (Add Family)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Family Name
                  const FormLabel('कुटुंबाचे आडनाव / नाव', isRequired: true),
                  TextFormField(
                    controller: _familyNameController,
                    decoration: const InputDecoration(
                      hintText: 'उदा. पाटील परिवार / देशमुख',
                      prefixIcon: Icon(Icons.people),
                    ),
                    validator: (val) => AppValidators.name(val, 'कुटुंबाचे नाव'),
                  ),
                  const SizedBox(height: 14),

                  // Family Head Name
                  const FormLabel('कुटुंब प्रमुखाचे नाव', isRequired: true),
                  TextFormField(
                    controller: _headNameController,
                    decoration: const InputDecoration(
                      hintText: 'उदा. श्री. रविंद्र गणपत पाटील',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (val) => AppValidators.name(val, 'कुटुंब प्रमुखाचे नाव'),
                  ),
                  const SizedBox(height: 14),

                  // Mobile Number
                  const FormLabel('मोबाईल नंबर'),
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '9876543210',
                      prefixIcon: Icon(Icons.phone),
                      prefixText: '+91 ',
                    ),
                    validator: (val) => AppValidators.mobile(val, isRequired: false),
                  ),
                  const SizedBox(height: 14),

                  // House Number & Village
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FormLabel('घर नंबर'),
                            TextFormField(
                              controller: _houseNumberController,
                              decoration: const InputDecoration(
                                hintText: 'उदा. १२/अ',
                                prefixIcon: Icon(Icons.home),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FormLabel('गाव / वस्ती'),
                            TextFormField(
                              controller: _villageController,
                              decoration: const InputDecoration(
                                hintText: 'उदा. वडगाव',
                                prefixIcon: Icon(Icons.location_city),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Address
                  const FormLabel('संपूर्ण पत्ता / गल्ली'),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      hintText: 'उदा. मुख्य रस्ता, मारुती मंदिराजवळ',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Members & Calculation Card
                  Card(
                    color: Colors.orange.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.orange.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'वर्गणी आकारणी गणित (Vargani Calculation)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                          ),
                          const SizedBox(height: 12),
                          const FormLabel('एकूण सदस्य संख्या', isRequired: true),
                          TextFormField(
                            controller: _membersCountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '४',
                              prefixIcon: Icon(Icons.people_alt_outlined),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: AppValidators.memberCount,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  activeConfig?.calculationType == 'per_member'
                                      ? 'मंडळाचा दर: ${AppFormatters.formatCurrency(activeConfig?.perMemberAmount ?? 500.0)} प्रति व्यक्ती'
                                      : 'मंडळाचा दर: ${AppFormatters.formatCurrency(activeConfig?.fixedAmount ?? 2000.0)} प्रति कुटुंब (ठराविक)',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                ),
                              ),
                              InkWell(
                                onTap: () => context.push('/vargani-config'),
                                child: const Text(
                                  'दर बदला ⚙️',
                                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('एकूण ठरलेली वर्गणी:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(
                                AppFormatters.formatCurrency(calculatedVargani),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('स्वतंत्र / सवलतीची वर्गणी रक्कम ठरवा', style: TextStyle(fontSize: 13)),
                            value: _useCustomVargani,
                            onChanged: (val) => setState(() => _useCustomVargani = val ?? false),
                          ),
                          if (_useCustomVargani) ...[
                            const SizedBox(height: 6),
                            const FormLabel('निश्चित केलेली वर्गणी रक्कम (₹)'),
                            TextFormField(
                              controller: _customVarganiController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'उदा. १५००',
                                prefixIcon: Icon(Icons.currency_rupee),
                              ),
                              validator: (val) => _useCustomVargani ? AppValidators.amount(val, fieldName: 'निश्चित केलेली वर्गणी रक्कम') : null,
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('कुटुंब जतन करा (Save Family)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
