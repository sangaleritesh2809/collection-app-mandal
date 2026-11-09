import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_label.dart';
import '../../../core/widgets/responsive_container.dart';
import '../providers/mandal_provider.dart';

class CreateMandalScreen extends ConsumerStatefulWidget {
  const CreateMandalScreen({super.key});

  @override
  ConsumerState<CreateMandalScreen> createState() => _CreateMandalScreenState();
}

class _CreateMandalScreenState extends ConsumerState<CreateMandalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _villageController = TextEditingController();
  final _talukaController = TextEditingController();
  final _districtController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _villageController.dispose();
    _talukaController.dispose();
    _districtController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final lang = ref.read(languageProvider);
    setState(() => _isSubmitting = true);
    try {
      final success = await ref.read(mandalProvider.notifier).createMandal(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        village: _villageController.text.trim(),
        taluka: _talukaController.text.trim(),
        district: _districtController.text.trim(),
        contactNumber: _contactController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.tr('मंडळ यशस्वीपणे नोंदणीकृत झाले!', 'Mandal registered successfully!'))),
        );
        context.go('/dashboard');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final mandalState = ref.watch(mandalProvider);
    final isBusy = _isSubmitting || mandalState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr(BuildContextKey.createMandal, lang)),
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
                  Text(
                    lang.tr('मंडळाची माहिती भरा', 'Enter Mandal Details'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lang.tr('मंडळ तयार केल्यानंतर तुम्हाला एक अद्वितीय आमंत्रण कोड मिळेल.', 'After creating mandal you will get a unique invite code.'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Mandal Name
                  FormLabel(lang.tr('मंडळाचे नाव', 'Mandal Name'), isRequired: true),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: lang.tr('मंडळाचे नाव टाका', 'Enter mandal name'),
                      prefixIcon: const Icon(Icons.temple_hindu),
                    ),
                    validator: (val) => AppValidators.name(
                      val,
                      lang.tr('मंडळाचे नाव', 'Mandal Name'),
                      minLength: 3,
                      isEnglish: lang.isEnglish,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description
                  FormLabel(lang.tr('वर्णन / ब्रीदवाक्य', 'Description / Slogan')),
                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      hintText: lang.tr('मंडळाचे वर्णन किंवा ब्रीदवाक्य टाका', 'Enter description or slogan'),
                      prefixIcon: const Icon(Icons.info_outline),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Address & Village (Row with top alignment so errors don't misalign fields)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FormLabel(lang.tr('गाव / शहर', 'Village / City'), isRequired: true),
                            TextFormField(
                              controller: _villageController,
                              decoration: InputDecoration(
                                hintText: lang.tr('गाव किंवा शहर टाका', 'Enter village or city'),
                                prefixIcon: const Icon(Icons.location_city),
                              ),
                              validator: (val) => AppValidators.required(
                                val,
                                lang.tr('गाव / शहर', 'Village / City'),
                                isEnglish: lang.isEnglish,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FormLabel(lang.tr('तालुका', 'Taluka')),
                            TextFormField(
                              controller: _talukaController,
                              decoration: InputDecoration(
                                hintText: lang.tr('तालुका टाका', 'Enter taluka'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // District
                  FormLabel(lang.tr('जिल्हा', 'District'), isRequired: true),
                  TextFormField(
                    controller: _districtController,
                    decoration: InputDecoration(
                      hintText: lang.tr('जिल्हा टाका', 'Enter district'),
                      prefixIcon: const Icon(Icons.map),
                    ),
                    validator: (val) => AppValidators.required(
                      val,
                      lang.tr('जिल्हा', 'District'),
                      isEnglish: lang.isEnglish,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Address
                  FormLabel(lang.tr('पत्ता / मुख्य चौक', 'Address / Main Square')),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: lang.tr('पत्ता किंवा मुख्य चौक टाका', 'Enter address or landmark'),
                      prefixIcon: const Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Contact Number
                  FormLabel(lang.tr('मंडळ संपर्क मोबाईल नंबर', 'Mandal Contact Mobile Number')),
                  TextFormField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: lang.tr('मोबाईल नंबर टाका', 'Enter mobile number'),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    validator: (val) => AppValidators.mobile(
                      val,
                      isRequired: false,
                      isEnglish: lang.isEnglish,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Email
                  FormLabel(lang.tr('मंडळ ईमेल पत्ता', 'Mandal Email Address')),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: lang.tr('ईमेल पत्ता टाका', 'Enter email address'),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (val) => AppValidators.email(
                      val,
                      isRequired: false,
                      isEnglish: lang.isEnglish,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit
                  ElevatedButton(
                    onPressed: isBusy ? null : _handleCreate,
                    child: isBusy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(lang.tr('मंडळ नोंदणी पूर्ण करा', 'Complete Mandal Registration')),
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
