import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_label.dart';
import '../../family/models/family.dart';
import '../../family/providers/family_provider.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../../vargani_config/models/vargani_config.dart';
import '../../vargani_config/providers/vargani_config_provider.dart';
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

  // ==============================================================================
  // नवीन कुटुंब थेट याच फॉर्ममधून जोडून वर्गणी पावती तयार करण्यासाठीचे व्हेरिएबल्स
  // (Integrated Family Registration state and controllers)
  // ==============================================================================
  bool _isNewFamily = false;
  bool _isSubmitting = false;

  final _headNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _villageController = TextEditingController();
  final _addressController = TextEditingController();
  final _membersCountController = TextEditingController(text: '1');
  bool _useCustomVargani = false;
  final _customVarganiController = TextEditingController();

  AppLanguage get lang => ref.watch(languageProvider);

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
    _headNameController.dispose();
    _mobileController.dispose();
    _houseNumberController.dispose();
    _villageController.dispose();
    _addressController.dispose();
    _membersCountController.dispose();
    _customVarganiController.dispose();
    super.dispose();
  }

  double _getCalculatedVarganiForNewFamily(VarganiConfig? config) {
    if (_useCustomVargani) {
      return double.tryParse(_customVarganiController.text.trim()) ?? 0.0;
    }
    final membersText = _membersCountController.text.trim();
    if (membersText.isEmpty) return 0.0;
    final members = int.tryParse(membersText) ?? 1;
    if (config != null) {
      return config.calculateTotalForFamily(members);
    }
    return members * 500.0;
  }

  void _recalculateForNewFamily() {
    final config = ref.read(varganiConfigProvider).activeConfig;
    final calculated = _getCalculatedVarganiForNewFamily(config);
    if (calculated > 0) {
      _amountController.text = calculated.toInt().toString();
    }
    setState(() {});
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final lang = ref.read(languageProvider);
    setState(() => _isSubmitting = true);

    Family? targetFamily = _selectedFamily;

    // ==============================================================================
    // नवीन कुटुंब थेट या फॉर्ममधून जोडून डेटाबेसमध्ये जतन करण्याचा कोड (Integrated Family Creation)
    // ==============================================================================
    if (_isNewFamily) {
      final headName = _headNameController.text.trim();
      final mobile = _mobileController.text.trim();
      final members = int.tryParse(_membersCountController.text.trim()) ?? 1;
      final customAmount = _useCustomVargani ? double.tryParse(_customVarganiController.text.trim()) : null;

      if (headName.isEmpty) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(lang.tr('कृपया कुटुंब प्रमुखाचे नाव टाका.', 'Please enter family head name.')),
          ),
        );
        return;
      }

      targetFamily = await ref.read(familyProvider.notifier).addFamilyAndReturn(
        familyName: headName,
        familyHeadName: headName,
        houseNumber: _houseNumberController.text.trim().isNotEmpty ? _houseNumberController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        village: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : null,
        mobileNumber: mobile.isNotEmpty ? mobile : null,
        initialMembersCount: members,
        customTotalVargani: customAmount,
      );

      if (targetFamily == null) {
        setState(() => _isSubmitting = false);
        final err = ref.read(familyProvider).error;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(err != null ? 'कुटुंब जोडताना त्रुटी: $err' : 'नवीन कुटुंब जतन करताना त्रुटी आली.'),
            ),
          );
        }
        return;
      }
    }

    if (targetFamily == null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(lang.tr('कृपया कुटुंब निवडा किंवा नवीन कुटुंब नोंदवा', 'Please select or add family')),
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final receipt = await ref.read(collectionProvider.notifier).submitCollection(
      familyId: targetFamily.id,
      amount: amount,
      paymentMode: _paymentMode,
      utrNumber: _utrController.text.trim().isNotEmpty ? _utrController.text.trim() : null,
      collectionDate: _collectionDate,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      familyName: targetFamily.familyName,
      familyHeadName: targetFamily.familyHeadName,
      houseNumber: targetFamily.houseNumber,
      mobileNumber: targetFamily.mobileNumber,
      totalMembers: targetFamily.totalMembers,
      totalVargani: targetFamily.totalVargani,
      previousPaid: targetFamily.paidAmount,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (receipt != null) {
      context.pushReplacement('/receipt-preview', extra: receipt);
    } else {
      final err = ref.read(collectionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(err != null ? 'त्रुटी: $err' : 'पावती तयार करताना त्रुटी आली. कृपया पुन्हा प्रयत्न करा.'),
          duration: const Duration(seconds: 4),
        ),
      );
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
    final lang = ref.watch(languageProvider);
    final familyState = ref.watch(familyProvider);
    final collectionState = ref.watch(collectionProvider);
    final mandal = ref.watch(mandalProvider).selectedMandal;
    final configState = ref.watch(varganiConfigProvider);
    final activeConfig = configState.activeConfig;
    final amountVal = double.tryParse(_amountController.text.trim()) ?? 0.0;

    // Automatically default to "Add New Family" if no families exist in the mandal
    if (familyState.families.isEmpty && widget.initialFamily == null && !_isNewFamily && _selectedFamily == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isNewFamily) {
          setState(() {
            _isNewFamily = true;
            _recalculateForNewFamily();
          });
        }
      });
    }

    final newFamilyExpectedVargani = _getCalculatedVarganiForNewFamily(activeConfig);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('वर्गणी जमा करा', 'Collect Vargani')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==============================================================================
                  // 1. मोड सिलेक्टर: 'कुटुंब निवडा' vs '➕ नवीन कुटुंब जोडा' (Segmented Toggle)
                  // ==============================================================================
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isNewFamily = false;
                                if (_selectedFamily != null && _selectedFamily!.pendingAmount > 0) {
                                  _amountController.text = _selectedFamily!.pendingAmount.toInt().toString();
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isNewFamily ? AppColors.primaryPurple : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isNewFamily
                                    ? [BoxShadow(color: AppColors.primaryPurple.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_alt_rounded,
                                      size: 16,
                                      color: !_isNewFamily ? Colors.white : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      lang.tr('कुटुंब निवडा', 'Select Family'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: !_isNewFamily ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isNewFamily = true;
                                _selectedFamily = null;
                                _recalculateForNewFamily();
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isNewFamily ? AppColors.primaryPurple : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isNewFamily
                                    ? [BoxShadow(color: AppColors.primaryPurple.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_add_alt_1_rounded,
                                      size: 16,
                                      color: _isNewFamily ? Colors.white : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      lang.tr('➕ नवीन कुटुंब जोडा', '+ Add Family'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _isNewFamily ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==============================================================================
                  // 2A. अस्तित्वात असलेले कुटुंब निवडण्याचा भाग (Select Existing Family Mode)
                  // ==============================================================================
                  if (!_isNewFamily) ...[
                    const FormLabel('कुटुंब निवडा', isRequired: true),
                    DropdownButtonFormField<Family>(
                      value: _selectedFamily != null
                          ? familyState.families.firstWhere(
                              (f) => f.id == _selectedFamily!.id,
                              orElse: () => _selectedFamily!,
                            )
                          : null,
                      decoration: InputDecoration(
                        hintText: lang.tr('कुटुंब निवडा', 'Select family'),
                        prefixIcon: const Icon(Icons.people),
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
                      validator: (val) => (!_isNewFamily && val == null) ? 'कुटुंब निवडणे आवश्यक आहे' : null,
                    ),
                    const SizedBox(height: 6),

                    // Quick switch to new family if not found
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () {
                          setState(() {
                            _isNewFamily = true;
                            _selectedFamily = null;
                            _recalculateForNewFamily();
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 14),
                        label: Text(
                          lang.tr('कुटुंब यादीत नाही? नवीन जोडा', 'Not in list? Add new'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

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
                  ],

                  // ==============================================================================
                  // 2B. नवीन कुटुंब थेट फॉर्ममध्ये भरण्याचा एकात्मिक भाग (Add New Family Integrated Form)
                  // ==============================================================================
                  if (_isNewFamily) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.home_work_rounded, color: AppColors.primaryPurple, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                lang.tr('नवीन कुटुंब तपशील', 'New Family Details'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryPurple),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Head of Family Name
                          FormLabel(lang.tr('कुटुंब प्रमुखाचे नाव', 'Family Head Name'), isRequired: true),
                          TextFormField(
                            controller: _headNameController,
                            decoration: InputDecoration(
                              hintText: lang.tr('उदा. रमेश तानाजी कदम', 'e.g. Ramesh Tanaji Kadam'),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (val) {
                              if (_isNewFamily && (val == null || val.trim().isEmpty)) {
                                return 'कुटुंब प्रमुखाचे नाव टाकणे आवश्यक आहे';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Mobile Number
                          FormLabel(lang.tr('मोबाईल नंबर', 'Mobile Number')),
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: InputDecoration(
                              hintText: lang.tr('१० अंकी मोबाईल नंबर टाका', '10-digit mobile number'),
                              prefixText: '+91 ',
                              prefixIcon: const Icon(Icons.phone),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // House Number & Village Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FormLabel(lang.tr('घर नंबर', 'House No.')),
                                    TextFormField(
                                      controller: _houseNumberController,
                                      decoration: InputDecoration(
                                        hintText: lang.tr('घर नंबर...', 'House No...'),
                                        prefixIcon: const Icon(Icons.home),
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
                                    FormLabel(lang.tr('गाव / वस्ती', 'Village / Area')),
                                    TextFormField(
                                      controller: _villageController,
                                      decoration: InputDecoration(
                                        hintText: lang.tr('गाव किंवा वस्ती...', 'Village/Area...'),
                                        prefixIcon: const Icon(Icons.location_city),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Full Address
                          FormLabel(lang.tr('संपूर्ण पत्ता / गल्ली', 'Full Address / Street')),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              hintText: lang.tr('पत्ता किंवा गल्ली टाका', 'Address or street name'),
                              prefixIcon: const Icon(Icons.location_on),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Member Count & Vargani Calculation Card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.tr('वर्गणी आकारणी गणित', 'Vargani Calculation'),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          FormLabel(lang.tr('एकूण सदस्य संख्या', 'Total Members'), isRequired: true),
                                          TextFormField(
                                            controller: _membersCountController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              prefixIcon: Icon(Icons.group),
                                            ),
                                            onChanged: (_) => _recalculateForNewFamily(),
                                            validator: (val) {
                                              if (_isNewFamily && (val == null || val.trim().isEmpty)) {
                                                return 'सदस्य संख्या टाका';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'ठरलेली वर्गणी',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            AppFormatters.formatCurrency(newFamilyExpectedVargani),
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.royalBlue),
                                          ),
                                          if (activeConfig != null)
                                            Text(
                                              'दर: ₹${activeConfig.perMemberAmount.toInt()}/व्यक्ती',
                                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  title: Text(
                                    lang.tr('स्वतंत्र / सवलतीची वर्गणी रक्कम ठरवा', 'Set custom vargani amount'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  value: _useCustomVargani,
                                  onChanged: (val) {
                                    setState(() {
                                      _useCustomVargani = val ?? false;
                                      _recalculateForNewFamily();
                                    });
                                  },
                                ),
                                if (_useCustomVargani) ...[
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _customVarganiController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.currency_rupee),
                                      hintText: lang.tr('एकूण ठरलेली सवलतीची वर्गणी टाका', 'Enter custom total vargani'),
                                    ),
                                    onChanged: (_) => _recalculateForNewFamily(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ==============================================================================
                  // 3. वर्गणी पावती भरण्याचा भाग (Vargani Amount & Receipt Fields)
                  // ==============================================================================
                  const FormLabel('वर्गणी रक्कम (₹)', isRequired: true),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.success),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee, size: 28),
                      hintText: lang.tr('रक्कम टाका', 'Enter amount'),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) => AppValidators.amount(val, fieldName: 'वर्गणी रक्कम'),
                  ),
                  const SizedBox(height: 16),

                  // Payment Mode Dropdown
                  const FormLabel('पेमेंट पद्धत', isRequired: true),
                  DropdownButtonFormField<String>(
                    value: _paymentMode,
                    decoration: const InputDecoration(
                      hintText: 'पेमेंट पद्धत निवडा',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: [
                      DropdownMenuItem(value: 'cash', child: Text(lang.tr('रोख', 'Cash'))),
                      DropdownMenuItem(value: 'upi', child: Text(lang.tr('📱 ऑनलाइन / UPI QR', '📱 Online / UPI QR'))),
                      DropdownMenuItem(value: 'bank_transfer', child: Text(lang.tr('बँक ट्रान्सफर', 'Bank Transfer (NEFT/RTGS)'))),
                      DropdownMenuItem(value: 'cheque', child: Text(lang.tr('धनादेश / चेक', 'Cheque'))),
                      DropdownMenuItem(value: 'other', child: Text(lang.tr('इतर', 'Other'))),
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
                  FormLabel(lang.tr('संकलन दिनांक', 'Collection Date')),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _collectionDate.isAfter(now) ? now : _collectionDate,
                        firstDate: DateTime(2020),
                        lastDate: now,
                      );
                      if (picked != null) setState(() => _collectionDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(AppFormatters.formatDate(_collectionDate)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  FormLabel(lang.tr('काही विशेष नोंद (ऐच्छिक)', 'Special Notes (Optional)')),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: lang.tr('काही विशेष नोंद असल्यास टाका', 'Enter special notes (optional)'),
                      prefixIcon: const Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ==============================================================================
                  // 4. सबमिट बटन: कुटुंब जोडून थेट पावती फाडणे व जतन करणे
                  // ==============================================================================
                  ElevatedButton.icon(
                    onPressed: (collectionState.isLoading || _isSubmitting) ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _paymentMode == 'upi' ? Colors.green.shade700 : AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: (collectionState.isLoading || _isSubmitting)
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(_paymentMode == 'upi' ? Icons.check_circle : Icons.receipt_long),
                    label: Text(
                      _isNewFamily
                          ? lang.tr('कुटुंब नोंदवून पावती तयार करा', 'Save Family & Generate Receipt')
                          : (_paymentMode == 'upi'
                              ? lang.tr('✅ पेमेंट पूर्ण झाले - पावती तयार करा', '✅ Payment Complete - Generate Receipt')
                              : lang.tr('पावती तयार करा व जतन करा', 'Generate & Save Receipt')),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
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
          const Align(
            alignment: Alignment.centerLeft,
            child: FormLabel('UTR / ऑनलाइन ट्रान्झॅक्शन नंबर (ऐच्छिक)', subtitle: 'GPay/PhonePe मधील १२ अंकी UTR नंबर टाका'),
          ),
          TextFormField(
            controller: _utrController,
            validator: (val) => AppValidators.utrNumber(val, isRequired: false),
            decoration: InputDecoration(
              hintText: lang.tr('UTR / ट्रान्झॅक्शन नंबर टाका', 'Enter UTR / Transaction number'),
              prefixIcon: const Icon(Icons.receipt_outlined),
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
