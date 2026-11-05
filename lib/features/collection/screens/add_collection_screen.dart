import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../family/models/family.dart';
import '../../family/providers/family_provider.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../providers/collection_provider.dart';

class AddCollectionScreen extends ConsumerStatefulWidget {
  final Family? initialFamily;

  const AddCollectionScreen({super.key, this.initialFamily});

  @override
  ConsumerState<AddCollectionScreen> createState() => _AddCollectionScreenState();
}

class _AddCollectionScreenState extends ConsumerState<AddCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  Family? _selectedFamily;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _utrController = TextEditingController();
  String _paymentMode = 'cash';
  DateTime _collectionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedFamily = widget.initialFamily;
    if (_selectedFamily != null && _selectedFamily!.pendingAmount > 0) {
      _amountController.text = _selectedFamily!.pendingAmount.toInt().toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFamily == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया कुटुंब निवडा')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final receipt = await ref.read(collectionProvider.notifier).submitCollection(
      familyId: _selectedFamily!.id,
      amount: amount,
      paymentMode: _paymentMode,
      utrNumber: _utrController.text.trim().isNotEmpty ? _utrController.text.trim() : null,
      collectionDate: _collectionDate,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      familyName: _selectedFamily!.familyName,
      familyHeadName: _selectedFamily!.familyHeadName,
      houseNumber: _selectedFamily!.houseNumber,
      mobileNumber: _selectedFamily!.mobileNumber,
      totalMembers: _selectedFamily!.totalMembers,
      totalVargani: _selectedFamily!.totalVargani,
      previousPaid: _selectedFamily!.paidAmount,
    );

    if (receipt != null && mounted) {
      context.pushReplacement('/receipt-preview', extra: receipt);
    }
  }

  void _showEnlargedQrImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('मंडळाचा QR कोड', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  CloseButton(),
                ],
              ),
              const SizedBox(height: 12),
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 100),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('स्कॅन करून पेमेंट करा', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);
    final collectionState = ref.watch(collectionProvider);
    final mandal = ref.watch(mandalProvider).selectedMandal;
    final amountVal = double.tryParse(_amountController.text.trim()) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('वर्गणी जमा करा (Collect Vargani)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Family Selector Dropdown
                DropdownButtonFormField<Family>(
                  value: _selectedFamily != null
                      ? familyState.families.firstWhere(
                          (f) => f.id == _selectedFamily!.id,
                          orElse: () => _selectedFamily!,
                        )
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'कुटुंब निवडा *',
                    prefixIcon: Icon(Icons.people),
                  ),
                  items: familyState.families.map((f) {
                    return DropdownMenuItem<Family>(
                      value: f,
                      child: Text('${f.familyName} (${f.familyHeadName})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedFamily = val;
                      if (val != null && val.pendingAmount > 0) {
                        _amountController.text = val.pendingAmount.toInt().toString();
                      }
                    });
                  },
                  validator: (val) => val == null ? 'कुटुंब निवडणे आवश्यक आहे' : null,
                ),
                const SizedBox(height: 16),

                // Selected Family Summary Card
                if (_selectedFamily != null) ...[
                  Card(
                    color: Colors.orange.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.orange.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedFamily!.familyName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                '${_selectedFamily!.totalMembers} व्यक्ती',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _infoSub('एकूण ठरलेली वर्गणी', AppFormatters.formatCurrency(_selectedFamily!.totalVargani)),
                              _infoSub('आधी जमा रक्कम', AppFormatters.formatCurrency(_selectedFamily!.paidAmount), color: AppColors.success),
                              _infoSub('बाकी रक्कम', AppFormatters.formatCurrency(_selectedFamily!.pendingAmount), color: AppColors.error),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.success),
                  decoration: const InputDecoration(
                    labelText: 'वर्गणी रक्कम (₹) *',
                    prefixIcon: Icon(Icons.currency_rupee, size: 28),
                    hintText: 'उदा. ५००',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'रक्कम आवश्यक आहे';
                    final n = double.tryParse(val.trim());
                    if (n == null || n <= 0) return 'वैध रक्कम टाका';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Payment Mode Dropdown
                DropdownButtonFormField<String>(
                  value: _paymentMode,
                  decoration: const InputDecoration(
                    labelText: 'पेमेंट पद्धत *',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('रोख (Cash)')),
                    DropdownMenuItem(value: 'upi', child: Text('📱 ऑनलाइन / UPI QR (Scan & Pay)')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('बँक ट्रान्सफर (NEFT/RTGS)')),
                    DropdownMenuItem(value: 'cheque', child: Text('धनादेश (Cheque)')),
                    DropdownMenuItem(value: 'other', child: Text('इतर (Other)')),
                  ],
                  onChanged: (val) => setState(() => _paymentMode = val ?? 'cash'),
                ),
                const SizedBox(height: 16),

                // ONLINE UPI QR PAYMENT CARD (Displays when 'upi' selected)
                if (_paymentMode == 'upi') ...[
                  _buildOnlineQrCard(context, mandal, amountVal),
                  const SizedBox(height: 16),
                ],

                // Collection Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _collectionDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _collectionDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'संकलन दिनांक',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(AppFormatters.formatDate(_collectionDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'काही विशेष नोंद (Notes)',
                    hintText: 'उदा. विशेष देणगी / उर्वरित रक्कम नंतर देतील',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton.icon(
                  onPressed: collectionState.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _paymentMode == 'upi' ? Colors.green.shade700 : AppColors.primary,
                  ),
                  icon: collectionState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(_paymentMode == 'upi' ? Icons.check_circle : Icons.receipt_long),
                  label: Text(
                    _paymentMode == 'upi'
                        ? '✅ पेमेंट पूर्ण झाले - पावती तयार करा'
                        : 'पावती तयार करा व जतन करा (Generate Receipt)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineQrCard(BuildContext context, dynamic mandal, double amountVal) {
    final hasQrPhoto = mandal?.qrCodeUrl != null && mandal!.qrCodeUrl!.isNotEmpty;
    final hasUpiId = mandal?.upiId != null && mandal!.upiId!.isNotEmpty;
    final upiId = mandal?.upiId ?? '';
    final payeeName = mandal?.upiPayeeName ?? mandal?.name ?? 'Mandal';

    final upiUri = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payeeName)}${amountVal > 0 ? '&am=${amountVal.toStringAsFixed(2)}' : ''}&cu=INR&tn=Vargani_${_selectedFamily?.familyCode ?? "Collection"}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                amountVal > 0 ? 'स्कॅन करून ₹${amountVal.toInt()} भरा' : 'स्कॅन करून वर्गणी भरा',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. If Official QR Image is uploaded
          if (hasQrPhoto) ...[
            InkWell(
              onTap: () => _showEnlargedQrImage(context, mandal!.qrCodeUrl!),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        mandal!.qrCodeUrl!,
                        height: 180,
                        width: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 100),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text('मोठा पाहण्यासाठी टॅप करा', style: TextStyle(fontSize: 11, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ]
          // 2. Or if UPI ID is provided, show dynamic generated QR
          else if (hasUpiId) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: QrImageView(
                data: upiUri,
                version: QrVersions.auto,
                size: 180.0,
              ),
            ),
            const SizedBox(height: 12),
          ]
          // 3. If neither is set, prompt Mandal Admin to set it
          else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
                  const SizedBox(height: 6),
                  const Text(
                    'या मंडळासाठी अद्याप QR कोड किंवा UPI ID जोडलेला नाही.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'मंडळ ॲडमिन सेटिंग्जमधून अधिकृत QR कोडचा फोटो किंवा UPI ID जोडू शकतात.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                    onPressed: () => context.push('/mandal-payment-settings'),
                    icon: const Icon(Icons.add_photo_alternate, size: 18),
                    label: const Text('QR कोड / UPI ID जोडा'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // UPI ID Row and Direct Pay Button
          if (hasUpiId) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('मंडळाचा UPI ID:', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                        Text(upiId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.green),
                    tooltip: 'UPI ID कॉपी करा',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: upiId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UPI ID कॉपी झाला!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Open in UPI Apps button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade800,
                side: BorderSide(color: Colors.green.shade600),
              ),
              onPressed: () async {
                try {
                  if (await canLaunchUrlString(upiUri)) {
                    await launchUrlString(upiUri);
                  } else {
                    Clipboard.setData(ClipboardData(text: upiId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UPI ॲप उघडता आले नाही. UPI ID कॉपी केला आहे.')),
                      );
                    }
                  }
                } catch (_) {
                  Clipboard.setData(ClipboardData(text: upiId));
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('GPay / PhonePe / Paytm मध्ये उघडा'),
            ),
            const SizedBox(height: 12),
          ],

          // UTR / Transaction Reference Number Input
          TextFormField(
            controller: _utrController,
            decoration: const InputDecoration(
              labelText: 'UTR / ऑनलाइन ट्रान्झॅक्शन नंबर (ऐच्छिक)',
              hintText: 'उदा. 324156789012',
              prefixIcon: Icon(Icons.receipt_outlined),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSub(String label, String val, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}
