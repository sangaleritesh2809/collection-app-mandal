import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/share_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/widgets/form_label.dart';
import '../../collection/providers/collection_provider.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../models/family.dart';
import '../models/family_member.dart';
import '../providers/family_provider.dart';

class FamilyDetailsScreen extends ConsumerStatefulWidget {
  final String familyId;
  final Family? initialFamily;

  const FamilyDetailsScreen({
    super.key,
    required this.familyId,
    this.initialFamily,
  });

  @override
  ConsumerState<FamilyDetailsScreen> createState() => _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends ConsumerState<FamilyDetailsScreen> {
  List<FamilyMember> _members = [];
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    final members = await ref.read(familyProvider.notifier).loadMembersForFamily(widget.familyId);
    if (mounted) {
      setState(() {
        _members = members;
        _isLoadingMembers = false;
      });
    }
  }

  void _showAddMemberDialog(BuildContext context, AppLanguage lang) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String gender = 'Male';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(lang.tr('नवीन कुटुंब सदस्य जोडा', 'Add Family Member')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormLabel(lang.tr('सदस्याचे नाव', 'Member Name'), isRequired: true),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: lang.tr('सदस्याचे पूर्ण नाव टाका', 'Enter full name'),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                FormLabel(lang.tr('मोबाईल नंबर', 'Mobile Number')),
                TextField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: lang.tr('१० अंकी मोबाईल नंबर टाका', 'Enter 10-digit mobile number'),
                    prefixIcon: const Icon(Icons.phone),
                    prefixText: '+91 ',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FormLabel(lang.tr('वय', 'Age')),
                          TextField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: lang.tr('वय', 'Age'),
                              prefixIcon: const Icon(Icons.calendar_today),
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
                          FormLabel(lang.tr('लिंग', 'Gender')),
                          DropdownButtonFormField<String>(
                            value: gender,
                            items: [
                              DropdownMenuItem(value: 'Male', child: Text(lang.tr('पुरुष', 'Male'))),
                              DropdownMenuItem(value: 'Female', child: Text(lang.tr('स्त्री', 'Female'))),
                              DropdownMenuItem(value: 'Other', child: Text(lang.tr('इतर', 'Other'))),
                            ],
                            onChanged: (val) => setDialogState(() => gender = val ?? 'Male'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.tr('रद्द करा', 'Cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await ref.read(familyProvider.notifier).addMemberToFamily(
                  familyId: widget.familyId,
                  memberName: nameCtrl.text.trim(),
                  mobileNumber: mobileCtrl.text.trim().isNotEmpty ? mobileCtrl.text.trim() : null,
                  age: int.tryParse(ageCtrl.text.trim()),
                  gender: gender,
                );
                _fetchMembers();
              },
              child: Text(lang.tr('जोडा', 'Add')),
            ),
          ],
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

    // Find latest family data
    final family = familyState.families.firstWhere(
      (f) => f.id == widget.familyId,
      orElse: () => widget.initialFamily ?? Family(
        id: widget.familyId,
        mandalId: '',
        familyCode: 'FAM',
        familyName: 'कुटुंब माहिती',
        familyHeadName: '',
        createdAt: DateTime.now(),
      ),
    );

    // Filter collections of this family
    final familyCollections = collectionState.collections.where((c) => c.familyId == widget.familyId).toList();

    final progress = family.totalVargani > 0
        ? (family.paidAmount / family.totalVargani).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(family.familyName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: lang.tr('संपादित करा', 'Edit'),
            onPressed: () => context.push('/add-family', extra: family),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: lang.tr('डिलीट करा', 'Delete'),
            onPressed: () => _showDeleteFamilyDialog(context, ref, family, lang),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/add-collection', extra: family),
            icon: const Icon(Icons.add_card),
            label: Text(lang.tr('वर्गणी पावती फाडा', 'Collect Vargani')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Family Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryPurple.withOpacity(0.15),
                          child: Text(
                            family.familyName.isNotEmpty ? family.familyName[0] : 'फ',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(family.familyName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('${lang.tr("प्रमुख:", "Head:")} ${family.familyHeadName}', style: const TextStyle(color: AppColors.textSecondary)),
                              Text('${lang.tr("कोड:", "Code:")} ${family.familyCode} • ${lang.tr("घर क्र.:", "House No.:")} ${family.houseNumber ?? '-'}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (family.mobileNumber != null)
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(family.mobileNumber!, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    if (family.address != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(child: Text('${family.address!}, ${family.village ?? ''}', style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Financial Status Card
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
                    Text(lang.tr('वर्गणी स्थिती', 'Payment Status'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? AppColors.success : (progress > 0 ? AppColors.warning : AppColors.error),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _summaryCol(lang.tr('एकूण वर्गणी', 'Total Vargani'), AppFormatters.formatCurrency(family.totalVargani)),
                        _summaryCol(lang.tr('जमा झालेली', 'Paid Amount'), AppFormatters.formatCurrency(family.paidAmount), color: AppColors.success),
                        _summaryCol(lang.tr('बाकी रक्कम', 'Balance Due'), AppFormatters.formatCurrency(family.pendingAmount), color: family.pendingAmount > 0 ? AppColors.error : AppColors.success),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Members Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${lang.tr("कुटुंब सदस्य", "Family Members")} (${_members.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showAddMemberDialog(context, lang),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(lang.tr('सदस्य जोडा', 'Add Member')),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (_isLoadingMembers)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_members.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text(lang.tr('कोणताही सदस्य नोंदवलेला नाही', 'No members recorded yet'))),
                ),
              )
            else
              ..._members.map((m) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(m.gender == 'Female' ? Icons.woman : Icons.man, color: Colors.blue),
                    ),
                    title: Text(m.memberName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${m.gender == 'Female' ? lang.tr('स्त्री', 'Female') : lang.tr('पुरुष', 'Male')}${m.age != null ? ' • ${lang.tr("वय:", "Age:")} ${m.age}' : ''}${m.mobileNumber != null ? ' • ${m.mobileNumber}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      tooltip: lang.tr('दप्तरबंद करा', 'Archive'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(lang.tr('सदस्य हटवायचा आहे का?', 'Delete member?')),
                            content: Text(lang.tr('${m.memberName} या सदस्याला सुरक्षितपणे दप्तरबंद करण्यात येईल.', '${m.memberName} will be archived safely.')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(lang.tr('रद्द करा', 'Cancel'))),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(lang.tr('हटवा', 'Delete'))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(familyProvider.notifier).archiveMember(
                            familyId: widget.familyId,
                            memberId: m.id,
                          );
                          _fetchMembers();
                        }
                      },
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),

            // Payment History Section
            Text(
              lang.tr('वर्गणी पावती इतिहास', 'Payment Receipts History'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (familyCollections.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('या कुटुंबाची कोणतीही वर्गणी पावती अजून झालेली नाही.'),
                  ),
                ),
              )
            else
              ...familyCollections.map((c) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.success.withOpacity(0.15),
                      child: const Icon(Icons.receipt, color: AppColors.success),
                    ),
                    title: Text(
                      AppFormatters.formatCurrency(c.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 16),
                    ),
                    subtitle: Text(
                      'पावती: ${c.receiptNumber}\nदिनांक: ${AppFormatters.formatDate(c.collectionDate)} • पद्धत: ${c.paymentMode.toUpperCase()}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.share, color: Colors.green),
                      tooltip: 'WhatsApp वर पावती पाठवा',
                      onPressed: () {
                        final receiptData = PdfReceiptData(
                          mandalName: mandal?.name ?? 'वर्गणी मंडळ',
                          mandalAddress: mandal?.address,
                          mandalContact: mandal?.contactNumber,
                          receiptNumber: c.receiptNumber,
                          transactionNumber: c.transactionNumber,
                          date: c.collectionDate,
                          familyName: family.familyName,
                          familyHead: family.familyHeadName,
                          houseNumber: family.houseNumber,
                          mobile: family.mobileNumber,
                          totalMembers: family.totalMembers,
                          amountPaid: c.amount,
                          totalVargani: family.totalVargani,
                          pendingAmount: family.pendingAmount,
                          paymentMode: c.paymentMode,
                          collectorName: c.collectorName ?? 'कार्यकर्ता',
                          notes: c.notes,
                        );
                        ShareService.shareReceiptOnWhatsApp(
                          mobileNumber: family.mobileNumber,
                          data: receiptData,
                        );
                      },
                    ),
                  ),
                );
              }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _summaryCol(String label, String val, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _showDeleteFamilyDialog(BuildContext context, WidgetRef ref, dynamic family, AppLanguage lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(lang.tr('कुटुंब डिलीट करा', 'Delete Family')),
          ],
        ),
        content: Text(
          lang.tr(
            'तुम्हाला "${family.familyName}" हे कुटुंब आणि त्यांच्या नोंदी यादीतून डिलीट करायच्या आहेत का?',
            'Are you sure you want to delete "${family.familyName}" and remove from active list?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(lang.tr('रद्द करा', 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref.read(familyProvider.notifier).deleteFamily(family.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? AppColors.success : AppColors.error,
                    content: Text(
                      success
                          ? lang.tr('कुटुंब यशस्वीपणे डिलीट केले!', 'Family deleted successfully!')
                          : lang.tr('कुटुंब डिलीट करताना त्रुटी आली.', 'Failed to delete family.'),
                    ),
                  ),
                );
                if (success) {
                  context.pop();
                }
              }
            },
            child: Text(lang.tr('होय, डिलीट करा', 'Yes, Delete')),
          ),
        ],
      ),
    );
  }
}
