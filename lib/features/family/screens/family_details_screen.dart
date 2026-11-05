import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/share_service.dart';
import '../../../core/services/pdf_service.dart';
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

  void _showAddMemberDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String gender = 'Male';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('नवीन कुटुंब सदस्य जोडा'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'सदस्याचे नाव *', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'मोबाईल नंबर', prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'वय (Age)', prefixIcon: Icon(Icons.calendar_today)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: gender,
                        decoration: const InputDecoration(labelText: 'लिंग'),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('पुरुष')),
                          DropdownMenuItem(value: 'Female', child: Text('स्त्री')),
                          DropdownMenuItem(value: 'Other', child: Text('इतर')),
                        ],
                        onChanged: (val) => setDialogState(() => gender = val ?? 'Male'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करा')),
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
              child: const Text('जोडा (Add)'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/add-collection', extra: family),
            icon: const Icon(Icons.add_card),
            label: const Text('वर्गणी पावती फाडा (Collect Vargani)'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
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
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: Text(
                            family.familyName.isNotEmpty ? family.familyName[0] : 'फ',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(family.familyName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('प्रमुख: ${family.familyHeadName}', style: const TextStyle(color: AppColors.textSecondaryLight)),
                              Text('कोड: ${family.familyCode} • घर क्र.: ${family.houseNumber ?? '-'}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (family.mobileNumber != null)
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 6),
                          Text(family.mobileNumber!, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    if (family.address != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place, size: 16, color: AppColors.textSecondaryLight),
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
                    const Text('वर्गणी स्थिती (Payment Status)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                        _summaryCol('एकूण वर्गणी', AppFormatters.formatCurrency(family.totalVargani)),
                        _summaryCol('जमा झालेली', AppFormatters.formatCurrency(family.paidAmount), color: AppColors.success),
                        _summaryCol('बाकी रक्कम', AppFormatters.formatCurrency(family.pendingAmount), color: family.pendingAmount > 0 ? AppColors.error : AppColors.success),
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
                  'कुटुंब सदस्य (${_members.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showAddMemberDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('सदस्य जोडा'),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (_isLoadingMembers)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_members.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('कोणताही सदस्य नोंदवलेला नाही')),
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
                      '${m.gender == 'Female' ? 'स्त्री' : 'पुरुष'}${m.age != null ? ' • वय: ${m.age}' : ''}${m.mobileNumber != null ? ' • ${m.mobileNumber}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      tooltip: 'दप्तरबंद करा',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('सदस्य हटवायचा आहे का?'),
                            content: Text('${m.memberName} या सदस्याला सुरक्षितपणे दप्तरबंद करण्यात येईल.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('रद्द करा')),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('हटवा')),
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
            const Text(
              'वर्गणी पावती इतिहास (Payment Receipts)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}
