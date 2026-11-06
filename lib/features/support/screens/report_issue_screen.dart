import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/form_label.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../providers/support_provider.dart';

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _category = 'technical';
  String _priority = 'medium';
  Uint8List? _screenshotBytes;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _categories = [
    {'value': 'payment_qr', 'label': '💳 पेमेंट / UPI / QR कोड समस्या'},
    {'value': 'receipt_vargani', 'label': '🧾 पावती / वर्गणी संकलन समस्या'},
    {'value': 'report_calc', 'label': '📊 हिशेब / अहवाल त्रुटी'},
    {'value': 'technical', 'label': '⚙️ तांत्रिक अडचण / बग (Bug / Crash)'},
    {'value': 'feature_request', 'label': '💡 नवीन फिचर विनंती'},
    {'value': 'other', 'label': '📝 इतर समस्या'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() => _screenshotBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('स्क्रीनशॉट निवडताना त्रुटी: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(supportProvider.notifier).createTicket(
      category: _category,
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      screenshotBytes: _screenshotBytes,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('🚩 तुमची अडचण सुपर ॲडमिनकडे यशस्वीपणे नोंदवली गेली आहे!'),
        ),
      );
      context.pushReplacement('/my-tickets');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).userProfile;
    final mandal = ref.watch(mandalProvider).selectedMandal;
    final supportState = ref.watch(supportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('समस्या नोंदवा (Report Issue)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'माझ्या तक्रारी',
            onPressed: () => context.push('/my-tickets'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mandal & Sender Identification Header Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.support_agent, color: AppColors.primary, size: 26),
                            const SizedBox(width: 8),
                            const Text(
                              'थेट सुपर ॲडमिनला मेसेज / सपोर्ट',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('🚩 मंडळ: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                mandal != null ? mandal.name : 'मंडळ निवडलेले नाही',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                              ),
                            ),
                          ],
                        ),
                        if (mandal != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('📍 ठिकाण: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                              Expanded(
                                child: Text(
                                  '${mandal.village ?? ''} ${mandal.district != null ? "• ${mandal.district}" : ""} (कोड: ${mandal.invitationCode})',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('👤 पाठवणारा: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            Expanded(
                              child: Text(
                                '${user?.fullName ?? "सदस्य"} (${mandal?.userRole ?? "सदस्य"} • ${user?.mobileNumber ?? user?.email ?? ""})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '💡 हा मेसेज कोणत्या मंडळाकडून व कोणी पाठवला आहे हे सुपर ॲडमिनला स्पष्ट दिसेल.',
                          style: TextStyle(fontSize: 11, color: Colors.brown),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Category
                  const FormLabel('समस्येचा प्रकार / कॅटेगरी', isRequired: true),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['value'],
                        child: Text(c['label']!, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _category = val ?? 'technical'),
                  ),
                  const SizedBox(height: 16),

                  // Subject
                  const FormLabel('समस्येचा विषय (Subject)', isRequired: true),
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      hintText: 'समस्येचा विषय टाका',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'कृपया समस्येचा विषय लिहा';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const FormLabel('सविस्तर अडचण / मेसेज (Detailed Message)', isRequired: true),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'काय समस्या आली आहे ते सविस्तर लिहा...',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'कृपया सविस्तर अडचण लिहा';
                      if (val.trim().length < 10) return 'किमान १० अक्षरे लिहा';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Priority
                  const FormLabel('प्राधान्य (Priority)'),
                  Row(
                    children: [
                      _buildPriorityChip('medium', 'साधारण', Colors.blue),
                      const SizedBox(width: 8),
                      _buildPriorityChip('high', 'उच्च (High)', Colors.orange),
                      const SizedBox(width: 8),
                      _buildPriorityChip('urgent', 'तात्काळ (Urgent)', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Screenshot / Attachment (Optional)
                  const FormLabel('स्क्रीनशॉट किंवा फोटो (पर्यायी)', subtitle: 'समस्येचा स्क्रीनशॉट असल्यास सुपर ॲडमिनला लवकर समजेल'),
                  if (_screenshotBytes != null)
                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _screenshotBytes!,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => _screenshotBytes = null),
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            label: const Text('स्क्रीनशॉट काढा', style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickScreenshot(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: const Text('गॅलरीतून निवडा'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickScreenshot(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text('कॅमेऱ्याने काढा'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 26),

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: supportState.isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: supportState.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      supportState.isSubmitting ? 'मेसेज पाठवत आहे...' : 'सुपर ॲडमिनला मेसेज पाठवा',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Link to view My Tickets
                  OutlinedButton.icon(
                    onPressed: () => context.push('/my-tickets'),
                    icon: const Icon(Icons.history),
                    label: const Text('माझ्या पाठवलेल्या तक्रारी व उत्तरे पहा'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label, Color color) {
    final isSelected = _priority == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.08),
      side: BorderSide(color: color.withOpacity(0.3)),
      onSelected: (_) => setState(() => _priority = value),
    );
  }
}

