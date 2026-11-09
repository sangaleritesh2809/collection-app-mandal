import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_label.dart';
import '../providers/mandal_provider.dart';

class MandalPaymentSettingsScreen extends ConsumerStatefulWidget {
  const MandalPaymentSettingsScreen({super.key});

  @override
  ConsumerState<MandalPaymentSettingsScreen> createState() => _MandalPaymentSettingsScreenState();
}

class _MandalPaymentSettingsScreenState extends ConsumerState<MandalPaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _upiIdController;
  late TextEditingController _payeeNameController;
  Uint8List? _selectedImageBytes;
  String? _existingQrUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final mandal = ref.read(mandalProvider).selectedMandal;
    _upiIdController = TextEditingController(text: mandal?.upiId ?? '');
    _payeeNameController = TextEditingController(text: mandal?.upiPayeeName ?? mandal?.name ?? '');
    _existingQrUrl = mandal?.qrCodeUrl;
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _payeeNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, AppLanguage lang) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${lang.tr("फोटो निवडताना त्रुटी आली", "Error picking image")}: $e')),
        );
      }
    }
  }

  Future<void> _handleSave(AppLanguage lang) async {
    if (!_formKey.currentState!.validate()) return;
    final mandal = ref.read(mandalProvider).selectedMandal;
    if (mandal == null) return;

    setState(() => _isUploading = true);

    try {
      String? finalQrUrl = _existingQrUrl;

      // 1. Upload new QR photo if selected, with seamless base64 fallback
      if (_selectedImageBytes != null) {
        final fileName = 'qr_${mandal.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        try {
          await SupabaseService.client.storage
              .from('qr_codes')
              .uploadBinary(
                fileName,
                _selectedImageBytes!,
              );

          finalQrUrl = SupabaseService.client.storage
              .from('qr_codes')
              .getPublicUrl(fileName);
        } catch (storageError) {
          debugPrint('Storage upload fallback to base64: $storageError');
          final base64String = base64Encode(_selectedImageBytes!);
          finalQrUrl = 'data:image/jpeg;base64,$base64String';
        }
      }

      // 2. Update Mandal record in database
      final success = await ref.read(mandalProvider.notifier).updateMandalPaymentQr(
        mandalId: mandal.id,
        upiId: _upiIdController.text.trim(),
        upiPayeeName: _payeeNameController.text.trim(),
        qrCodeUrl: finalQrUrl,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text(lang.tr('🚩 मंडळाचे UPI व QR कोड यशस्वीपणे जतन झाले!', '🚩 Mandal UPI & QR Code saved successfully!')),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(lang.tr('माहिती जतन करताना त्रुटी आली.', 'Error saving details.')),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('${lang.tr("त्रुटी", "Error")}: $e')),
        );
      }
    }
  }

  Widget _buildExistingQrImage(String url, AppLanguage lang) {
    if (url.startsWith('data:image') || !url.startsWith('http')) {
      try {
        final clean = url.contains(',') ? url.split(',').last : url;
        final bytes = base64Decode(clean);
        return Image.memory(bytes, width: 180, height: 180, fit: BoxFit.cover);
      } catch (_) {}
    }
    return Image.network(
      url,
      width: 180,
      height: 180,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 80, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final mandal = ref.watch(mandalProvider).selectedMandal;
    final upiId = _upiIdController.text.trim();
    final payeeName = _payeeNameController.text.trim().isNotEmpty
        ? _payeeNameController.text.trim()
        : (mandal?.name ?? 'Mandal');

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('मंडळाचा UPI व QR कोड सेटिंग्स', 'Mandal UPI & QR Settings')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2, color: AppColors.primary, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mandal != null ? '🚩 ${mandal.name}' : lang.tr('सक्रिय मंडळ', 'Active Mandal'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                            ),
                            Text(
                              lang.tr(
                                'वर्गणी गोळा करताना ऑनलाइन पेमेंट स्वीकारण्यासाठी येथे QR कोड किंवा UPI ID सेट करा.',
                                'Configure QR code or UPI ID here to accept online payments while collecting vargani.',
                              ),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 1: Official QR Photo Upload
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
                        Row(
                          children: [
                            const Icon(Icons.photo_camera_back, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lang.tr('१. मंडळाचा अधिकृत QR फोटो अपलोड करा', '1. Upload Mandal Official QR Photo'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.tr(
                            'बँकेचा किंवा PhonePe/GPay स्टँडीचा प्रत्यक्ष फोटो असल्यास तो येथे जोडा:',
                            'Attach photo of bank QR or PhonePe/GPay standee if available:',
                          ),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 12),

                        // Image Preview or Placeholder
                        if (_selectedImageBytes != null)
                          Center(
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _selectedImageBytes!,
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    _selectedImageBytes = null;
                                  }),
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                  label: Text(
                                    lang.tr('फोटो बदला', 'Change Photo'),
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_existingQrUrl != null && _existingQrUrl!.isNotEmpty)
                          Center(
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildExistingQrImage(_existingQrUrl!, lang),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lang.tr('सध्याचा सक्रिय QR फोटो', 'Current Active QR Photo'),
                                  style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.qr_code_scanner, size: 40, color: Colors.grey),
                                  const SizedBox(height: 4),
                                  Text(
                                    lang.tr('कोणताही QR फोटो जोडलेला नाही', 'No QR photo attached'),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery, lang),
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: Text(lang.tr('गॅलरीतून निवडा', 'From Gallery')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera, lang),
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: Text(lang.tr('कॅमेऱ्याने काढा', 'Take Photo')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card 2: UPI ID & Payee Name
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
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lang.tr('२. मंडळाचा UPI ID (पर्यायी किंवा थेट)', '2. Mandal UPI ID (Optional / Direct)'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.tr(
                            'UPI ID टाकल्यास ॲप आपोआप प्रत्येक पावतीसाठी थेट रकमेचा QR कोड तयार करेल:',
                            'Entering UPI ID allows the app to automatically generate amount-specific QR codes:',
                          ),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 14),

                        FormLabel(lang.tr('मंडळाचा UPI ID', 'Mandal UPI ID')),
                        TextFormField(
                          controller: _upiIdController,
                          decoration: InputDecoration(
                            hintText: lang.tr('UPI ID टाका (उदा. mandal@upi)', 'Enter UPI ID (e.g. mandal@upi)'),
                            prefixIcon: const Icon(Icons.alternate_email),
                          ),
                          validator: (val) => AppValidators.upiId(val, isRequired: false, isEnglish: lang.isEnglish),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),

                        FormLabel(lang.tr('खातेधारकाचे / मंडळाचे नाव', 'Account Holder / Mandal Name')),
                        TextFormField(
                          controller: _payeeNameController,
                          decoration: InputDecoration(
                            hintText: lang.tr('खातेधारकाचे नाव टाका', 'Enter payee name'),
                            prefixIcon: const Icon(Icons.person_pin),
                          ),
                          validator: (val) {
                            if (_upiIdController.text.trim().isNotEmpty) {
                              return AppValidators.name(
                                val,
                                lang.tr('खातेधारकाचे नाव', 'Payee Name'),
                                minLength: 3,
                                isEnglish: lang.isEnglish,
                              );
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Live Dynamic QR Preview (if UPI ID entered)
                if (upiId.isNotEmpty) ...[
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
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified, color: Colors.green, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                lang.tr('थेट UPI QR कोड पूर्वावलोकन (Preview)', 'Live UPI QR Code Preview'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: QrImageView(
                              data: 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}&cu=INR',
                              version: QrVersions.auto,
                              size: 160.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            upiId,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                          ),
                          Text(
                            lang.tr(
                              'वर्गणी जमा करताना कुटुंबाजवळ जाऊन हा QR कोड स्कॅन करता येईल.',
                              'This dynamic QR code can be scanned by members to pay vargani directly.',
                            ),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Save Button
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : () => _handleSave(lang),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isUploading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(
                    _isUploading
                        ? lang.tr('जतन होत आहे...', 'Saving...')
                        : lang.tr('पेमेंट QR सेटिंग्स जतन करा', 'Save Payment QR Settings'),
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
