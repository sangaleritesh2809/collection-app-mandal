import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
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

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot(ImageSource source, AppLanguage lang) async {
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
          SnackBar(content: Text('${lang.tr("स्क्रीनशॉट निवडताना त्रुटी", "Error picking image")}: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit(AppLanguage lang) async {
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
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(lang.tr(
            '🚩 तुमची अडचण सुपर ॲडमिनकडे यशस्वीपणे नोंदवली गेली आहे!',
            '🚩 Your issue has been successfully submitted to Super Admin!',
          )),
        ),
      );
      context.pushReplacement('/my-tickets');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final user = ref.watch(authProvider).userProfile;
    final mandal = ref.watch(mandalProvider).selectedMandal;
    final supportState = ref.watch(supportProvider);

    final categories = [
      {'value': 'payment_qr', 'label': lang.tr('💳 पेमेंट / UPI / QR कोड समस्या', '💳 Payment / UPI / QR Code')},
      {'value': 'receipt_vargani', 'label': lang.tr('🧾 पावती / वर्गणी संकलन समस्या', '🧾 Receipt / Collection Issue')},
      {'value': 'report_calc', 'label': lang.tr('📊 हिशेब / अहवाल त्रुटी', '📊 Accounts / Report Error')},
      {'value': 'technical', 'label': lang.tr('⚙️ तांत्रिक अडचण / बग (Bug / Crash)', '⚙️ Technical / Bug / Crash')},
      {'value': 'feature_request', 'label': lang.tr('💡 नवीन फिचर विनंती', '💡 New Feature Request')},
      {'value': 'other', 'label': lang.tr('📝 इतर समस्या', '📝 Other Issue')},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('समस्या नोंदवा', 'Report Issue')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: lang.tr('माझ्या तक्रारी', 'My Tickets'),
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
                            Expanded(
                              child: Text(
                                lang.tr('थेट सुपर ॲडमिनला मेसेज / सपोर्ट', 'Direct Support to Super Admin'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(lang.tr('🚩 मंडळ: ', '🚩 Mandal: '), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                mandal != null ? mandal.name : lang.tr('मंडळ निवडलेले नाही', 'No Mandal Selected'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                              ),
                            ),
                          ],
                        ),
                        if (mandal != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(lang.tr('📍 ठिकाण: ', '📍 Location: '), style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                              Expanded(
                                child: Text(
                                  '${mandal.village ?? ''} ${mandal.district != null ? "• ${mandal.district}" : ""} (${lang.tr("कोड", "Code")}: ${mandal.invitationCode})',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(lang.tr('👤 पाठवणारा: ', '👤 Sender: '), style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            Expanded(
                              child: Text(
                                '${user?.fullName ?? lang.tr("सदस्य", "Member")} (${mandal?.userRole ?? lang.tr("सदस्य", "Member")} • ${user?.mobileNumber ?? user?.email ?? ""})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lang.tr(
                            '💡 हा मेसेज कोणत्या मंडळाकडून व कोणी पाठवला आहे हे सुपर ॲडमिनला स्पष्ट दिसेल.',
                            '💡 Super Admin will clearly see who sent this message and from which mandal.',
                          ),
                          style: const TextStyle(fontSize: 11, color: Colors.brown),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Category
                  FormLabel(lang.tr('समस्येचा प्रकार / कॅटेगरी', 'Issue Category'), isRequired: true),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['value'],
                        child: Text(c['label']!, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _category = val ?? 'technical'),
                  ),
                  const SizedBox(height: 16),

                  // Subject
                  FormLabel(lang.tr('समस्येचा विषय', 'Issue Subject'), isRequired: true),
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      hintText: lang.tr('समस्येचा विषय टाका', 'Enter issue subject'),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return lang.tr('कृपया समस्येचा विषय लिहा', 'Please enter issue subject');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description (Compact & vertically centered)
                  FormLabel(lang.tr('सविस्तर अडचण / मेसेज', 'Detailed Message'), isRequired: true),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: lang.tr('काय समस्या आली आहे ते लिहा...', 'Describe what issue you faced...'),
                      prefixIcon: const Icon(Icons.notes),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return lang.tr('कृपया सविस्तर अडचण लिहा', 'Please enter detailed message');
                      }
                      if (val.trim().length < 5) {
                        return lang.tr('किमान ५ अक्षरे लिहा', 'Please write at least 5 characters');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Priority
                  FormLabel(lang.tr('प्राधान्य', 'Priority')),
                  Row(
                    children: [
                      _buildPriorityChip('medium', lang.tr('साधारण', 'Normal'), Colors.blue),
                      const SizedBox(width: 8),
                      _buildPriorityChip('high', lang.tr('उच्च (High)', 'High'), Colors.orange),
                      const SizedBox(width: 8),
                      _buildPriorityChip('urgent', lang.tr('तात्काळ (Urgent)', 'Urgent'), Colors.red),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Screenshot / Attachment (Optional)
                  FormLabel(
                    lang.tr('स्क्रीनशॉट किंवा फोटो (पर्यायी)', 'Screenshot / Photo (Optional)'),
                    subtitle: lang.tr('समस्येचा स्क्रीनशॉट असल्यास सुपर ॲडमिनला लवकर समजेल', 'Attaching a screenshot helps resolve faster'),
                  ),
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
                            label: Text(
                              lang.tr('स्क्रीनशॉट काढा', 'Remove Screenshot'),
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickScreenshot(ImageSource.gallery, lang),
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: Text(lang.tr('गॅलरीतून निवडा', 'From Gallery')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickScreenshot(ImageSource.camera, lang),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: Text(lang.tr('कॅमेऱ्याने काढा', 'Take Photo')),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 26),

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: supportState.isSubmitting ? null : () => _handleSubmit(lang),
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
                      supportState.isSubmitting
                          ? lang.tr('मेसेज पाठवत आहे...', 'Submitting...')
                          : lang.tr('सुपर ॲडमिनला मेसेज पाठवा', 'Submit to Super Admin'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Link to view My Tickets
                  OutlinedButton.icon(
                    onPressed: () => context.push('/my-tickets'),
                    icon: const Icon(Icons.history),
                    label: Text(lang.tr('माझ्या पाठवलेल्या तक्रारी व उत्तरे पहा', 'View My Submitted Tickets')),
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
