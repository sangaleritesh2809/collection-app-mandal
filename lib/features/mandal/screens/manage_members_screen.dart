import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/form_label.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/mandal_member.dart';
import '../providers/mandal_provider.dart';

class ManageMembersScreen extends ConsumerStatefulWidget {
  const ManageMembersScreen({super.key});

  @override
  ConsumerState<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends ConsumerState<ManageMembersScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MandalMember> _members = [];
  Map<String, String> _roleNameToId = {}; // e.g. {'Mandal Admin': 'uuid', ...}
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembersAndRoles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembersAndRoles() async {
    final mandal = ref.read(mandalProvider).selectedMandal;
    if (mandal == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'मंडळ निवडलेले नाही.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch available system roles
      final rolesRes = await SupabaseService.client
          .from('roles')
          .select('id, name')
          .inFilter('name', ['Mandal Admin', 'Treasurer', 'Collector', 'Member']);

      final Map<String, String> roleMap = {};
      for (final r in (rolesRes as List)) {
        final name = r['name'] as String;
        final id = r['id'] as String;
        roleMap[name] = id;
      }
      _roleNameToId = roleMap;

      // 2. Fetch all memberships for this mandal joined with profiles and roles
      final res = await SupabaseService.client
          .from('mandal_memberships')
          .select('''
            id,
            mandal_id,
            user_id,
            role_id,
            status,
            joined_at,
            profiles (id, full_name, mobile_number, email, avatar_url),
            roles (id, name, description)
          ''')
          .eq('mandal_id', mandal.id)
          .eq('status', 'active')
          .order('joined_at', ascending: true);

      final List<MandalMember> list = [];
      for (final item in (res as List)) {
        list.add(MandalMember.fromJson(item as Map<String, dynamic>));
      }

      if (mounted) {
        setState(() {
          _members = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading mandal members: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'सदस्यांची यादी लोड करताना अडचण आली: $e';
        });
      }
    }
  }

  Future<void> _updateMemberRole(MandalMember member, String newRoleName) async {
    final roleId = _roleNameToId[newRoleName];
    if (roleId == null) return;

    final lang = ref.read(languageProvider);
    final currentUserId = SupabaseService.currentUserId;
    if (member.userId == currentUserId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(lang.tr('तुम्ही स्वतःचा रोल बदलू शकत नाही.', 'You cannot change your own role.')),
          ),
        );
      }
      return;
    }

    try {
      await SupabaseService.client
          .from('mandal_memberships')
          .update({'role_id': roleId})
          .eq('id', member.membershipId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(lang.tr(
              '✅ ${member.fullName} यांचा रोल यशस्वीपणे "${_getRoleMarathiName(newRoleName)}" करण्यात आला.',
              '✅ Role updated for ${member.fullName} to "$newRoleName".',
            )),
          ),
        );
      }

      await _loadMembersAndRoles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(lang.tr('रोल बदलताना त्रुटी आली: $e', 'Error changing role: $e')),
          ),
        );
      }
    }
  }

  Future<void> _removeMember(MandalMember member) async {
    final lang = ref.read(languageProvider);
    final currentUserId = SupabaseService.currentUserId;
    if (member.userId == currentUserId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(lang.tr('तुम्ही स्वतःचा रोल बदलू शकत नाही.', 'You cannot change your own role.')),
          ),
        );
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lang.tr('सदस्य काढून टाकायचा का?', 'Remove Member?')),
        content: Text(lang.tr(
          'तुम्हाला खात्री आहे का? ${member.fullName} यांना या मंडळातून काढून टाकले जाईल.',
          'Are you sure you want to remove ${member.fullName} from this mandal?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.tr('रद्द करा', 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.tr('काढून टाका', 'Remove')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.client
            .from('mandal_memberships')
            .delete()
            .eq('id', member.membershipId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text(lang.tr('सदस्य यशस्वीपणे काढून टाकला.', 'Member removed successfully.')),
            ),
          );
        }
        await _loadMembersAndRoles();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(lang.tr('काढताना त्रुटी आली: $e', 'Error removing: $e')),
            ),
          );
        }
      }
    }
  }

  void _showRoleChangeBottomSheet(MandalMember member) {
    final lang = ref.read(languageProvider);
    final currentUserId = SupabaseService.currentUserId;
    if (member.userId == currentUserId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(lang.tr('तुम्ही स्वतःचा रोल बदलू शकत नाही.', 'You cannot change your own role.')),
          ),
        );
      }
      return;
    }

    final List<Map<String, String>> roleOptions = [
      {
        'role': 'Mandal Admin',
        'title': lang.tr('🚩 मंडळ ॲडमिन (Mandal Admin)', '🚩 Mandal Admin'),
        'desc': lang.tr('मंडळाचे संपूर्ण नियंत्रण, वर्गणी दर व नियम बदलणे आणि सदस्य व्यवस्थापन.', 'Full control over mandal settings, rates, and members.'),
      },
      {
        'role': 'Treasurer',
        'title': lang.tr('💰 खजिनदार (Treasurer)', '💰 Treasurer'),
        'desc': lang.tr('कार्यकर्त्यांनी आणलेली रोकड मंजूर करणे (Deposit Approval) व खर्चाची नोंद ठेवणे.', 'Approve deposits submitted by collectors & log expenses.'),
      },
      {
        'role': 'Collector',
        'title': lang.tr('📝 वर्गणी संकलक / कार्यकर्ता (Collector)', '📝 Collector / Worker'),
        'desc': lang.tr('कुटुंबांची नोंद करणे, वर्गणी गोळा करणे, पावती देणे व रक्कम खजिनदाराकडे जमा करणे.', 'Add families, collect vargani, give receipts & submit cash.'),
      },
      {
        'role': 'Member',
        'title': lang.tr('👥 सभासद (Member)', '👥 Member'),
        'desc': lang.tr('मंडळाची सर्वसाधारण माहिती, वर्गणी व पावत्या पाहणे.', 'View general mandal info, receipts & status.'),
      },
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  lang.tr('${member.fullName} यांची भूमिका (Role) निवडा', 'Select Role for ${member.fullName}'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  lang.tr('योग्य भूमिका निवडून आवश्यक ते अधिकार द्या:', 'Select a role to grant permissions:'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                ...roleOptions.map((opt) {
                  final isCurrent = member.roleName == opt['role'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primaryPurple.withOpacity(0.08) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent ? AppColors.primaryPurple : Colors.grey.shade200,
                        width: isCurrent ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt['title']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isCurrent ? AppColors.primaryPurple : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                lang.tr('सध्याची भूमिका', 'Current'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(opt['desc']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      trailing: isCurrent
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryPurple)
                          : const Icon(Icons.circle_outlined, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(ctx);
                        if (!isCurrent) {
                          _updateMemberRole(member, opt['role']!);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRoleMarathiName(String roleName) {
    switch (roleName) {
      case 'Mandal Admin':
      case 'Super Admin':
        return 'मंडळ ॲडमिन';
      case 'Treasurer':
        return 'खजिनदार';
      case 'Collector':
        return 'वर्गणी संकलक';
      case 'Member':
      default:
        return 'सभासद';
    }
  }

  Color _getRoleColor(String roleName) {
    switch (roleName) {
      case 'Mandal Admin':
      case 'Super Admin':
        return AppColors.primaryPurple;
      case 'Treasurer':
        return Colors.green.shade700;
      case 'Collector':
        return AppColors.accentOrange;
      case 'Member':
      default:
        return Colors.blueGrey;
    }
  }

  void _showAddMemberDialog() {
    final lang = ref.read(languageProvider);
    final mandal = ref.read(mandalProvider).selectedMandal;
    if (mandal == null) return;

    final phoneCtrl = TextEditingController();
    final manualNameCtrl = TextEditingController();
    final manualPasswordCtrl = TextEditingController(text: 'Mandal@123');
    bool obscureManualPassword = false;
    bool isSearching = false;
    bool isAdding = false;
    Map<String, dynamic>? foundProfile;
    bool hasSearched = false;
    String? dialogError;
    String selectedRole = 'Collector';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            final cleanPhone = phoneCtrl.text.replaceAll(RegExp(r'^\+91|^0|\s+'), '').trim();
            final isSuperAdmin = cleanPhone == '9699342811' ||
                (foundProfile != null && (foundProfile!['mobile_number'] == '9699342811' || foundProfile!['is_super_admin'] == true));
            final isAlreadyMember = _members.any((m) =>
                (cleanPhone.isNotEmpty && m.mobileNumber != null && m.mobileNumber!.replaceAll(RegExp(r'^\+91|^0|\s+'), '') == cleanPhone) ||
                (foundProfile != null && m.userId == foundProfile!['id']));

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryPurple, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              lang.tr('नवीन सदस्य जोडा', 'Add Member'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 24),
                          tooltip: lang.tr('बंद करा', 'Close'),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lang.tr(
                        'कार्यकर्त्याचा १०-अंकी मोबाईल नंबर टाकून त्याला थेट मंडळात जोडा.',
                        'Enter 10-digit mobile number to add worker directly.',
                      ),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Phone input with instant duplicate & Super Admin check
                    FormLabel(lang.tr('मोबाईल नंबर', 'Mobile Number'), isRequired: true),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      onChanged: (val) async {
                        final clean = val.replaceAll(RegExp(r'^\+91|^0|\s+'), '').trim();
                        if (clean.length == 10) {
                          // 1. Instant Super Admin check
                          if (clean == '9699342811') {
                            setModalState(() {
                              dialogError = lang.tr(
                                '⚠️ हा सुपर ॲडमिनचा नंबर (+91 9699342811) आहे. सुपर ॲडमिनला मंडळ सदस्य म्हणून जोडता येत नाही.',
                                '⚠️ This is Super Admin number (+91 9699342811). Super Admin cannot be added as a member.',
                              );
                              hasSearched = true;
                              foundProfile = null;
                            });
                            return;
                          }

                          // 2. Instant Already-a-member check
                          final existing = _members.where((m) =>
                              m.mobileNumber != null &&
                              m.mobileNumber!.replaceAll(RegExp(r'^\+91|^0|\s+'), '') == clean).firstOrNull;

                          if (existing != null) {
                            setModalState(() {
                              dialogError = lang.tr(
                                '⚠️ हा नंबर (+91 $clean) आधीच "${existing.fullName}" (${_getRoleMarathiName(existing.roleName)}) म्हणून या मंडळात जोडलेला आहे.',
                                '⚠️ Mobile +91 $clean is already a member as "${existing.fullName}" (${existing.roleName}) in this mandal.',
                              );
                              hasSearched = true;
                              foundProfile = null;
                            });
                            return;
                          }

                          // 3. Search profile from Supabase
                          setModalState(() {
                            isSearching = true;
                            dialogError = null;
                          });

                          try {
                            final res = await SupabaseService.client
                                .from('profiles')
                                .select('id, full_name, mobile_number, email')
                                .eq('mobile_number', clean)
                                .maybeSingle();

                            setModalState(() {
                              isSearching = false;
                              hasSearched = true;
                              foundProfile = res;
                            });
                          } catch (e) {
                            setModalState(() {
                              isSearching = false;
                              dialogError = 'शोधताना त्रुटी आली: $e';
                            });
                          }
                        } else {
                          if (dialogError != null || foundProfile != null || hasSearched) {
                            setModalState(() {
                              dialogError = null;
                              foundProfile = null;
                              hasSearched = false;
                            });
                          }
                        }
                      },
                      decoration: InputDecoration(
                        hintText: lang.tr('१० अंकी मोबाईल नंबर टाका', 'Enter 10-digit mobile number'),
                        prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primaryPurple),
                        counterText: '',
                        suffixIcon: IconButton(
                          icon: isSearching
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPurple),
                                )
                              : const Icon(Icons.search_rounded, color: AppColors.primaryPurple),
                          tooltip: lang.tr('शोधा', 'Search'),
                          onPressed: isSearching
                              ? null
                              : () async {
                                  final clean = phoneCtrl.text.replaceAll(RegExp(r'^\+91|^0|\s+'), '').trim();
                                  if (clean.length != 10) {
                                    setModalState(() {
                                      dialogError = lang.tr('कृपया वैध १०-अंकी मोबाईल नंबर टाका.', 'Please enter valid 10-digit mobile number.');
                                      hasSearched = false;
                                      foundProfile = null;
                                    });
                                    return;
                                  }

                                  if (clean == '9699342811') {
                                    setModalState(() {
                                      dialogError = lang.tr(
                                        '⚠️ हा सुपर ॲडमिनचा नंबर (+91 9699342811) आहे. सुपर ॲडमिनला मंडळ सदस्य म्हणून जोडता येत नाही.',
                                        '⚠️ This is Super Admin number (+91 9699342811). Super Admin cannot be added as a member.',
                                      );
                                      hasSearched = true;
                                      foundProfile = null;
                                    });
                                    return;
                                  }

                                  final existing = _members.where((m) =>
                                      m.mobileNumber != null &&
                                      m.mobileNumber!.replaceAll(RegExp(r'^\+91|^0|\s+'), '') == clean).firstOrNull;

                                  if (existing != null) {
                                    setModalState(() {
                                      dialogError = lang.tr(
                                        '⚠️ हा नंबर (+91 $clean) आधीच "${existing.fullName}" (${_getRoleMarathiName(existing.roleName)}) म्हणून या मंडळात जोडलेला आहे.',
                                        '⚠️ Mobile +91 $clean is already a member as "${existing.fullName}" (${existing.roleName}) in this mandal.',
                                      );
                                      hasSearched = true;
                                      foundProfile = null;
                                    });
                                    return;
                                  }

                                  setModalState(() {
                                    isSearching = true;
                                    dialogError = null;
                                  });

                                  try {
                                    final res = await SupabaseService.client
                                        .from('profiles')
                                        .select('id, full_name, mobile_number, email')
                                        .eq('mobile_number', clean)
                                        .maybeSingle();

                                    setModalState(() {
                                      isSearching = false;
                                      hasSearched = true;
                                      foundProfile = res;
                                    });
                                  } catch (e) {
                                    setModalState(() {
                                      isSearching = false;
                                      dialogError = 'शोधताना त्रुटी आली: $e';
                                    });
                                  }
                                },
                        ),
                      ),
                    ),

                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade300, width: 1.2),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                dialogError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Result card if found
                    if (foundProfile != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isAlreadyMember ? Colors.orange.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isAlreadyMember ? Colors.orange.shade300 : Colors.green.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isAlreadyMember ? Colors.orange.shade200 : Colors.green.shade200,
                                  child: Text(
                                    (foundProfile!['full_name'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isAlreadyMember ? Colors.orange.shade900 : Colors.green.shade900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        foundProfile!['full_name'] ?? 'User',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        '+91 ${foundProfile!['mobile_number'] ?? ''}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (isAlreadyMember) ...[
                              const SizedBox(height: 10),
                              Text(
                                lang.tr('⚠️ हा वापरकर्ता आधीच या मंडळाचा सदस्य आहे.', '⚠️ User is already a member of this mandal.'),
                                style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ] else ...[
                              const SizedBox(height: 14),
                              Text(
                                lang.tr('या सदस्याची भूमिका (Role) निवडा:', 'Assign Role:'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedRole,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                items: [
                                  DropdownMenuItem(value: 'Collector', child: Text(lang.tr('📝 वर्गणी संकलक / कार्यकर्ता', '📝 Collector / Worker'))),
                                  DropdownMenuItem(value: 'Treasurer', child: Text(lang.tr('💰 खजिनदार', '💰 Treasurer'))),
                                  DropdownMenuItem(value: 'Mandal Admin', child: Text(lang.tr('🚩 मंडळ ॲडमिन', '🚩 Mandal Admin'))),
                                  DropdownMenuItem(value: 'Member', child: Text(lang.tr('👥 सभासद', '👥 Member'))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedRole = val);
                                },
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: isAdding
                                    ? null
                                    : () async {
                                        final roleId = _roleNameToId[selectedRole];
                                        if (roleId == null) return;

                                        setModalState(() => isAdding = true);
                                        try {
                                          final existing = await SupabaseService.client
                                              .from('mandal_memberships')
                                              .select('id')
                                              .eq('mandal_id', mandal.id)
                                              .eq('user_id', foundProfile!['id'])
                                              .maybeSingle();

                                          if (existing != null) {
                                            await SupabaseService.client
                                                .from('mandal_memberships')
                                                .update({
                                                  'role_id': roleId,
                                                  'status': 'active',
                                                })
                                                .eq('id', existing['id']);
                                          } else {
                                            await SupabaseService.client.from('mandal_memberships').insert({
                                              'mandal_id': mandal.id,
                                              'user_id': foundProfile!['id'],
                                              'role_id': roleId,
                                              'status': 'active',
                                            });
                                          }

                                          if (ctx.mounted) Navigator.pop(ctx);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                backgroundColor: AppColors.success,
                                                content: Text(lang.tr(
                                                  '✅ ${foundProfile!['full_name']} यांना यशस्वीपणे मंडळात जोडले आहे!',
                                                  '✅ Added ${foundProfile!['full_name']} to mandal successfully!',
                                                )),
                                              ),
                                            );
                                            await _loadMembersAndRoles();
                                          }
                                        } catch (e) {
                                          setModalState(() {
                                            isAdding = false;
                                            dialogError = 'सदस्य जोडताना त्रुटी आली: $e';
                                          });
                                        }
                                      },
                                child: isAdding
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(lang.tr('मंडळात सामील करा', 'Add to Mandal')),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else if (hasSearched && foundProfile == null) ...[
                      // Manual Add Member Option (when user not in profiles)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_add_alt_1_rounded, color: AppColors.royalBlue, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lang.tr('मॅन्युअली सदस्य जोडा', 'Add Member Manually'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.royalBlue),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lang.tr(
                                'हा नंबर ॲपवर नोंदणीकृत नाही. तुम्ही त्यांचे पूर्ण नाव टाकून थेट या मंडळात सामील करू शकता:',
                                'This number is not registered yet. Enter full name to add directly to this mandal:',
                              ),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            FormLabel(lang.tr('सदस्याचे पूर्ण नाव', 'Full Name'), isRequired: true),
                            TextField(
                              controller: manualNameCtrl,
                              decoration: InputDecoration(
                                hintText: lang.tr('उदा. संतोष कदम', 'e.g. Santosh Kadam'),
                                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.royalBlue),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              lang.tr('या सदस्याची भूमिका (Role) निवडा:', 'Assign Role:'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedRole,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              items: [
                                DropdownMenuItem(value: 'Collector', child: Text(lang.tr('📝 वर्गणी संकलक / कार्यकर्ता', '📝 Collector / Worker'))),
                                DropdownMenuItem(value: 'Treasurer', child: Text(lang.tr('💰 खजिनदार', '💰 Treasurer'))),
                                DropdownMenuItem(value: 'Mandal Admin', child: Text(lang.tr('🚩 मंडळ ॲडमिन', '🚩 Mandal Admin'))),
                                DropdownMenuItem(value: 'Member', child: Text(lang.tr('👥 सभासद', '👥 Member'))),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedRole = val);
                              },
                            ),
                            const SizedBox(height: 12),

                            // Login Password field (Admin can customize it)
                            FormLabel(lang.tr('लॉगिन पासवर्ड ठरवा', 'Set Login Password'), isRequired: true),
                            TextField(
                              controller: manualPasswordCtrl,
                              obscureText: obscureManualPassword,
                              decoration: InputDecoration(
                                hintText: lang.tr('पासवर्ड टाका (उदा. Mandal@123 किंवा 12345678)', 'Enter password'),
                                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.royalBlue),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureManualPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                  onPressed: () => setModalState(() => obscureManualPassword = !obscureManualPassword),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lang.tr(
                                '💡 ॲडमिन म्हणून तुम्ही या सदस्यासाठी कोणताही पासवर्ड ठेवू शकता. हा पासवर्ड सदस्याला लॉगिन करण्यासाठी सांगा.',
                                '💡 As admin you can set any password for this member. Give this password to the member to log in.',
                              ),
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: isAdding
                                  ? null
                                  : () async {
                                      final name = manualNameCtrl.text.trim();
                                      final pass = manualPasswordCtrl.text.trim().isNotEmpty
                                          ? manualPasswordCtrl.text.trim()
                                          : 'Mandal@123';

                                      if (name.isEmpty) {
                                        setModalState(() => dialogError = lang.tr('कृपया सदस्याचे पूर्ण नाव टाका.', 'Please enter full name.'));
                                        return;
                                      }
                                      if (pass.length < 6) {
                                        setModalState(() => dialogError = lang.tr('पासवर्ड किमान ६ अक्षरांचा असावा.', 'Password must be at least 6 chars.'));
                                        return;
                                      }
                                      final clean = phoneCtrl.text.replaceAll(RegExp(r'^\+91|^0|\s+'), '').trim();
                                      if (clean == '9699342811') {
                                        setModalState(() {
                                          dialogError = lang.tr(
                                            '⚠️ हा सुपर ॲडमिनचा नंबर (+91 9699342811) आहे. सुपर ॲडमिनला मंडळ सदस्य म्हणून जोडता येत नाही.',
                                            '⚠️ This is Super Admin number (+91 9699342811). Super Admin cannot be added as a member.',
                                          );
                                        });
                                        return;
                                      }
                                      final existing = _members.where((m) =>
                                          m.mobileNumber != null &&
                                          m.mobileNumber!.replaceAll(RegExp(r'^\+91|^0|\s+'), '') == clean).firstOrNull;
                                      if (existing != null) {
                                        setModalState(() {
                                          dialogError = lang.tr(
                                            '⚠️ हा नंबर (+91 $clean) आधीच "${existing.fullName}" (${_getRoleMarathiName(existing.roleName)}) म्हणून या मंडळात जोडलेला आहे.',
                                            '⚠️ Mobile +91 $clean is already a member as "${existing.fullName}" (${existing.roleName}) in this mandal.',
                                          );
                                        });
                                        return;
                                      }

                                      setModalState(() {
                                        isAdding = true;
                                        dialogError = null;
                                      });
                                      try {
                                        await SupabaseService.client.rpc('add_manual_member', params: {
                                          'p_mandal_id': mandal.id,
                                          'p_full_name': name,
                                          'p_mobile_number': clean,
                                          'p_role_name': selectedRole,
                                          'p_password': pass,
                                        });

                                        if (ctx.mounted) Navigator.pop(ctx);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: AppColors.success,
                                              content: Text(lang.tr(
                                                '✅ $name यांना जोडले आहे! सेट केलेला पासवर्ड: $pass',
                                                '✅ Added $name! Set password: $pass',
                                              )),
                                              duration: const Duration(seconds: 4),
                                            ),
                                          );
                                          await _loadMembersAndRoles();
                                        }
                                      } catch (e) {
                                        setModalState(() {
                                          isAdding = false;
                                          dialogError = 'सदस्य जोडताना अडचण आली: $e';
                                        });
                                      }
                                    },
                              icon: isAdding
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.person_add_rounded, size: 18),
                              label: Text(lang.tr('➕ मॅन्युअली सदस्य जोडा', '➕ Add Member Manually')),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(lang.tr('किंवा', 'OR'), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green.shade800,
                                side: BorderSide(color: Colors.green.shade700),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.share, size: 16),
                              label: Text(lang.tr('WhatsApp वर आमंत्रण कोड पाठवा', 'Share WhatsApp Invite')),
                              onPressed: () {
                                Navigator.pop(ctx);
                                Share.share(
                                  '🚩 *${mandal.name}* मध्ये सामील व्हा!\n'
                                  'वर्गणी कलेक्शन ॲपमध्ये सामील होण्यासाठी आमचा आमंत्रण कोड वापरा:\n\n'
                                  '👉 कोड: *${mandal.invitationCode}*\n\n'
                                  'ॲप उघडून "मंडळात सामील व्हा" वर क्लिक करा व वरील कोड टाका.',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final mandal = ref.watch(mandalProvider).selectedMandal;
    final currentUserId = SupabaseService.currentUserId;

    final filtered = _members.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return m.fullName.toLowerCase().contains(q) ||
          (m.mobileNumber != null && m.mobileNumber!.contains(q));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('मंडळाचे सदस्य व रोल्स', 'Manage Members & Roles')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: lang.tr('रिफ्रेश', 'Refresh'),
            onPressed: _loadMembersAndRoles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadMembersAndRoles, child: Text(lang.tr('पुन्हा प्रयत्न करा', 'Retry'))),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMembersAndRoles,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Mandal Invite Card
                      if (mandal != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurple.withOpacity(0.08),
                                AppColors.royalBlue.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.temple_hindu_rounded, color: AppColors.primaryPurple, size: 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      mandal.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryPurple),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                lang.tr('मंडळाचा आमंत्रण कोड (Mandal Invite Code):', 'Mandal Invite Code:'),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        mandal.invitationCode,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          letterSpacing: 2.5,
                                          color: AppColors.primaryPurple,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, color: AppColors.primaryPurple, size: 20),
                                      tooltip: lang.tr('कोड कॉपी करा', 'Copy Code'),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: mandal.invitationCode));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppColors.primaryPurple,
                                            content: Text(lang.tr('कोड कॉपी केला: ${mandal.invitationCode}', 'Code copied: ${mandal.invitationCode}')),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share_rounded, color: AppColors.royalBlue, size: 20),
                                      tooltip: lang.tr('WhatsApp वर पाठवा', 'Share via WhatsApp'),
                                      onPressed: () {
                                        Share.share(
                                          '🚩 *${mandal.name}* मध्ये सामील व्हा!\n'
                                          'वर्गणी कलेक्शन ॲपमध्ये सामील होण्यासाठी आमचा आमंत्रण कोड वापरा:\n\n'
                                          '👉 कोड: *${mandal.invitationCode}*\n\n'
                                          'ॲप उघडून "मंडळात सामील व्हा" वर क्लिक करा व वरील कोड टाका.',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                lang.tr(
                                  '💡 हा कोड कार्यकर्ते, खजिनदार किंवा सदस्यांना पाठवा. ॲपमध्ये सामील झाल्यावर तुम्ही त्यांची भूमिका (Role) खाली बदलू शकता.',
                                  '💡 Share this code with workers or treasurer. Once joined, you can assign roles below.',
                                ),
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Search & Member Count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.tr('सामील झालेले सदस्य (${_members.length})', 'Joined Members (${_members.length})'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddMemberDialog,
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: Text(lang.tr('+ सदस्य जोडा', '+ Add Member')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: lang.tr('सदस्य किंवा फोन नंबर शोधा...', 'Search member or phone...'),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      ),
                      const SizedBox(height: 14),

                      // Members List
                      if (filtered.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(28),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.group_off_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? lang.tr('कोणताही सदस्य सापडला नाही.', 'No member found matching query.')
                                    : lang.tr('अद्याप कोणीही सदस्य सामील झालेला नाही.\nवरील कोड पाठवून कार्यकर्त्यांना सामील करा.', 'No members joined yet.\nShare code to invite workers.'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filtered.map((member) {
                          final isSelf = member.userId == currentUserId;
                          final roleColor = _getRoleColor(member.roleName);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: roleColor.withOpacity(0.12),
                                        child: Text(
                                          member.fullName.isNotEmpty ? member.fullName.substring(0, 1).toUpperCase() : 'U',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: roleColor, fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Name & Phone
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    member.fullName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                  ),
                                                ),
                                                if (isSelf)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primaryPurple.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      lang.tr('तुम्ही स्वतः', 'You'),
                                                      style: const TextStyle(fontSize: 10, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            if (member.mobileNumber != null)
                                              Text(
                                                '+91 ${member.mobileNumber}',
                                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // More actions
                                      if (!isSelf)
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                                          tooltip: lang.tr('पर्याय', 'Options'),
                                          onSelected: (val) {
                                            if (val == 'remove') {
                                              _removeMember(member);
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            PopupMenuItem(
                                              value: 'remove',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.person_remove_rounded, size: 18, color: AppColors.error),
                                                  const SizedBox(width: 8),
                                                  Text(lang.tr('मंडळातून काढून टाका', 'Remove Member'), style: const TextStyle(color: AppColors.error)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 18),

                                  // Bottom Row: Current Role Badge & Change Role Action Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: isSelf ? null : () => _showRoleChangeBottomSheet(member),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: roleColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: roleColor.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                member.roleName == 'Treasurer'
                                                    ? Icons.account_balance_wallet_rounded
                                                    : member.roleName == 'Mandal Admin'
                                                        ? Icons.shield_rounded
                                                        : Icons.badge_outlined,
                                                size: 13,
                                                color: roleColor,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                lang == AppLanguage.marathi
                                                    ? _getRoleMarathiName(member.roleName)
                                                    : member.roleName,
                                                style: TextStyle(
                                                  color: roleColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Change Role Button (Never shown for self)
                                      if (!isSelf)
                                        InkWell(
                                          onTap: () => _showRoleChangeBottomSheet(member),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryPurple),
                                                const SizedBox(width: 4),
                                                Text(
                                                  lang.tr('रोल बदला', 'Change Role'),
                                                  style: const TextStyle(
                                                    color: AppColors.primaryPurple,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

