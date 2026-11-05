import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/form_label.dart';
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
        const SnackBar(content: Text('मंडळ यशस्वीपणे नोंदणीकृत झाले!')),
      );
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final mandalState = ref.watch(mandalProvider);

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
                  const Text(
                    'मंडळाची माहिती भरा',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'मंडळ तयार केल्यानंतर तुम्हाला एक अद्वितीय आमंत्रण कोड (Invite Code) मिळेल.',
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Mandal Name
                  const FormLabel('मंडळाचे नाव', isRequired: true),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'उदा. श्री गणेश मित्र मंडळ',
                      prefixIcon: Icon(Icons.temple_hindu),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'मंडळाचे नाव आवश्यक आहे';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Description
                  const FormLabel('वर्णन / ब्रीदवाक्य'),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'उदा. स्थापना वर्ष २०१० • सामाजिक ऐक्य आणि उत्सव',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Address & Village
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FormLabel('गाव / शहर', isRequired: true),
                            TextFormField(
                              controller: _villageController,
                              decoration: const InputDecoration(
                                hintText: 'उदा. वडगाव',
                                prefixIcon: Icon(Icons.location_city),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'गाव आवश्यक आहे' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FormLabel('तालुका'),
                            TextFormField(
                              controller: _talukaController,
                              decoration: const InputDecoration(
                                hintText: 'उदा. हवेली',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // District
                  const FormLabel('जिल्हा', isRequired: true),
                  TextFormField(
                    controller: _districtController,
                    decoration: const InputDecoration(
                      hintText: 'उदा. पुणे',
                      prefixIcon: Icon(Icons.map),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'जिल्हा आवश्यक आहे' : null,
                  ),
                  const SizedBox(height: 14),

                  // Address
                  const FormLabel('पत्ता / मुख्य चौक'),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      hintText: 'उदा. शिवाजी चौक, मारुती मंदिरासमोर',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Contact Number
                  const FormLabel('मंडळ संपर्क मोबाईल नंबर'),
                  TextFormField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '९८७६५४३२१०',
                      prefixIcon: Icon(Icons.phone),
                      prefixText: '+91 ',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Email
                  const FormLabel('मंडळ ईमेल पत्ता'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'mandal@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit
                  ElevatedButton(
                    onPressed: mandalState.isLoading ? null : _handleCreate,
                    child: mandalState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('मंडळ नोंदणी पूर्ण करा (Create Mandal)'),
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

