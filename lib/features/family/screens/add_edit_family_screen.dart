import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_label.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../vargani_config/models/vargani_config.dart';
import '../../vargani_config/providers/vargani_config_provider.dart';
import '../models/family.dart';
import '../providers/family_provider.dart';

class AddEditFamilyScreen extends ConsumerStatefulWidget {
  final Family? family;

  const AddEditFamilyScreen({super.key, this.family});

  @override
  ConsumerState<AddEditFamilyScreen> createState() => _AddEditFamilyScreenState();
}

class _AddEditFamilyScreenState extends ConsumerState<AddEditFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _headNameController;
  late final TextEditingController _houseNumberController;
  late final TextEditingController _addressController;
  late final TextEditingController _villageController;
  late final TextEditingController _mobileController;
  late final TextEditingController _membersCountController;
  late final TextEditingController _customVarganiController;
  bool _useCustomVargani = false;

  bool get isEditing => widget.family != null;

  @override
  void initState() {
    super.initState();
    final f = widget.family;
    _headNameController = TextEditingController(text: f?.familyHeadName ?? '');
    _houseNumberController = TextEditingController(text: f?.houseNumber ?? '');
    _addressController = TextEditingController(text: f?.address ?? '');
    _villageController = TextEditingController(text: f?.village ?? '');
    _mobileController = TextEditingController(text: f?.mobileNumber ?? '');
    _membersCountController = TextEditingController(text: (f?.totalMembers ?? 1).toString());
    _useCustomVargani = f?.isCustomVargani ?? false;
    _customVarganiController = TextEditingController(
      text: f != null && f.isCustomVargani ? f.totalVargani.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
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
    final membersText = _membersCountController.text.trim();
    if (membersText.isEmpty) return 0.0;
    final members = int.tryParse(membersText) ?? 0;
    if (config != null) {
      return config.calculateTotalForFamily(members);
    }
    return members * 500.0;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final lang = ref.read(languageProvider);
    final members = int.tryParse(_membersCountController.text.trim()) ?? 1;
    final customAmount = _useCustomVargani ? double.tryParse(_customVarganiController.text.trim()) : null;
    final headName = _headNameController.text.trim();

    if (isEditing) {
      final success = await ref.read(familyProvider.notifier).updateFamily(
        familyId: widget.family!.id,
        familyName: headName,
        familyHeadName: headName,
        houseNumber: _houseNumberController.text.trim(),
        address: _addressController.text.trim(),
        village: _villageController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        totalMembers: members,
        customTotalVargani: customAmount,
        isCustomVargani: _useCustomVargani,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(lang.tr('कुटुंब माहिती यशस्वीपणे बदलली!', 'Family details updated successfully!')),
          ),
        );
        context.pop();
      } else if (mounted) {
        final err = ref.read(familyProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(err != null ? 'त्रुटी: $err' : 'माहिती बदलताना अडचण आली.'),
          ),
        );
      }
    } else {
      final success = await ref.read(familyProvider.notifier).addFamily(
        familyName: headName,
        familyHeadName: headName,
        houseNumber: _houseNumberController.text.trim(),
        address: _addressController.text.trim(),
        village: _villageController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        initialMembersCount: members,
        customTotalVargani: customAmount,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(lang.tr('कुटुंब यशस्वीपणे जोडले गेले!', 'Family added successfully!')),
          ),
        );
        context.pop();
      } else if (mounted) {
        final err = ref.read(familyProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(err != null ? 'त्रुटी: $err' : 'कुटुंब जोडताना अडचण आली. कृपया पुन्हा प्रयत्न करा.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final configState = ref.watch(varganiConfigProvider);
    final activeConfig = configState.activeConfig;
    final calculatedVargani = _getCalculatedVargani(activeConfig);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? lang.tr('कुटुंब माहिती बदला', 'Edit Family') : lang.tr('नवीन कुटुंब जोडा', 'Add Family')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            maxWidth: 720,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Family Head Name (Primary Name of the Family)
                  FormLabel(lang.tr('कुटुंब प्रमुखाचे नाव', 'Head of Family Name'), isRequired: true),
                  TextFormField(
                    controller: _headNameController,
                    decoration: InputDecoration(
                      hintText: lang.tr('उदा. श्री. रविंद्र गणपत पाटील', 'e.g. Shri. Ravindra Ganpat Patil'),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (val) => AppValidators.name(val, lang.tr('कुटुंब प्रमुखाचे नाव', 'Head of Family Name')),
                  ),
                  const SizedBox(height: 14),

                  // Mobile Number (Mandatory 10 digits)
                  FormLabel(lang.tr('मोबाईल नंबर', 'Mobile Number'), isRequired: true),
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      hintText: '9876543210',
                      prefixIcon: Icon(Icons.phone),
                      prefixText: '+91 ',
                    ),
                    validator: (val) => AppValidators.mobile(val, isRequired: true),
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
                            FormLabel(lang.tr('घर नंबर', 'House No.')),
                            TextFormField(
                              controller: _houseNumberController,
                              decoration: InputDecoration(
                                hintText: lang.tr('उदा. १२/अ', 'e.g. 12/A'),
                                prefixIcon: const Icon(Icons.home),
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
                            FormLabel(lang.tr('गाव / वस्ती', 'Village / Area')),
                            TextFormField(
                              controller: _villageController,
                              decoration: InputDecoration(
                                hintText: lang.tr('उदा. वडगाव', 'e.g. Wadgaon'),
                                prefixIcon: const Icon(Icons.location_city),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Address
                  FormLabel(lang.tr('संपूर्ण पत्ता / गल्ली', 'Full Address / Street')),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: lang.tr('उदा. मुख्य रस्ता, मारुती मंदिराजवळ', 'e.g. Main Road, near temple'),
                      prefixIcon: const Icon(Icons.place_outlined),
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
                          Text(
                            lang.tr('वर्गणी आकारणी गणित', 'Vargani Calculation'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryPurple),
                          ),
                          const SizedBox(height: 12),
                          FormLabel(lang.tr('एकूण सदस्य संख्या', 'Total Members'), isRequired: !_useCustomVargani),
                          TextFormField(
                            controller: _membersCountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: InputDecoration(
                              hintText: _useCustomVargani
                                  ? lang.tr('उदा. १ (पर्यायी)', 'e.g. 1 (Optional)')
                                  : lang.tr('उदा. ४', 'e.g. 4'),
                              prefixIcon: const Icon(Icons.people_alt_outlined),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (val) {
                              if (_useCustomVargani) {
                                if (val != null && val.trim().isNotEmpty) {
                                  return AppValidators.memberCount(val);
                                }
                                return null;
                              }
                              return AppValidators.memberCount(val);
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            activeConfig?.calculationType == 'per_member'
                                ? '${lang.tr("मंडळाचा दर:", "Rate:")} ${AppFormatters.formatCurrency(activeConfig?.perMemberAmount ?? 500.0)} ${lang.tr("प्रति व्यक्ती", "per person")}'
                                : '${lang.tr("मंडळाचा दर:", "Rate:")} ${AppFormatters.formatCurrency(activeConfig?.fixedAmount ?? 2000.0)} ${lang.tr("प्रति कुटुंब (ठराविक)", "per family (fixed)")}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lang.tr('एकूण ठरलेली वर्गणी:', 'Total Expected Vargani:'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(
                                AppFormatters.formatCurrency(calculatedVargani),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryPurple),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(lang.tr('स्वतंत्र / सवलतीची वर्गणी रक्कम ठरवा', 'Set custom / discounted vargani amount'), style: const TextStyle(fontSize: 13)),
                            value: _useCustomVargani,
                            activeColor: AppColors.primaryPurple,
                            onChanged: (val) => setState(() => _useCustomVargani = val ?? false),
                          ),
                          if (_useCustomVargani) ...[
                            const SizedBox(height: 6),
                            FormLabel(lang.tr('निश्चित केलेली वर्गणी रक्कम (₹)', 'Custom Vargani Amount (₹)')),
                            TextFormField(
                              controller: _customVarganiController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                hintText: lang.tr('उदा. १५००', 'e.g. 1500'),
                                prefixIcon: const Icon(Icons.currency_rupee),
                              ),
                              validator: (val) => _useCustomVargani ? AppValidators.amount(val, fieldName: lang.tr('निश्चित केलेली वर्गणी रक्कम', 'Custom Amount')) : null,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isEditing ? lang.tr('बदल जतन करा', 'Save Changes') : lang.tr('कुटुंब जतन करा', 'Save Family'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
