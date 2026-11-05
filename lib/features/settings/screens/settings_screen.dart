import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../../vargani_config/providers/vargani_config_provider.dart';
import '../../../core/utils/formatters.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref, String? userId) async {
    if (userId == null) return;

    final lang = ref.read(languageProvider);
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                lang.tr('प्रोफाइल फोटो निवडा', 'Choose Profile Photo'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.lightLavender,
                  child: Icon(Icons.photo_library, color: AppColors.primaryPurple),
                ),
                title: Text(lang.tr('गॅलरीतून निवडा', 'Choose from Gallery')),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.lightLavender,
                  child: Icon(Icons.camera_alt, color: AppColors.primaryPurple),
                ),
                title: Text(lang.tr('कॅमेऱ्याने फोटो काढा', 'Take Photo with Camera')),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Supabase storage
      await SupabaseService.client.storage
          .from('support_attachments')
          .uploadBinary(fileName, bytes);

      final publicUrl = SupabaseService.client.storage
          .from('support_attachments')
          .getPublicUrl(fileName);

      // Update in public.profiles table
      await SupabaseService.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      // Update riverpod state
      await ref.read(authProvider.notifier).updateAvatar(publicUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ प्रोफाइल फोटो यशस्वीरित्या अपडेट झाला!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('फोटो अपलोड अयशस्वी: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authProvider);
    final mandalState = ref.watch(mandalProvider);
    final configState = ref.watch(varganiConfigProvider);
    final themeMode = ref.watch(themeModeProvider);
    final activeMandal = mandalState.selectedMandal;
    final user = authState.userProfile;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(lang.tr('माझे खाते व सेटिंग्ज', 'My Profile & Settings')),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            maxWidth: 760,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Profile Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Clickable Avatar with Camera badge
                      GestureDetector(
                        onTap: () => _pickAndUploadAvatar(context, ref, user?.id),
                        child: Stack(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: AppShadows.soft,
                              ),
                              child: ClipOval(
                                child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                                    ? Image.network(
                                        user.avatarUrl!,
                                        fit: BoxFit.cover,
                                        width: 64,
                                        height: 64,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            (user.fullName.isNotEmpty == true) ? user.fullName[0].toUpperCase() : 'U',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.white),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : 'U',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.white),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppColors.accentOrange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: AppShadows.soft,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // User Details with Role Badge nicely placed with Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'वापरकर्ता',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryPurple.withOpacity(0.18)),
                              ),
                              child: Text(
                                user?.isSuperAdmin == true ? '👑 Super Admin' : (activeMandal?.userRole ?? 'सदस्य'),
                                style: const TextStyle(
                                  color: AppColors.primaryPurple,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (user?.mobileNumber != null)
                              Row(
                                children: [
                                  const Icon(Icons.phone_android_rounded, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+91 ${user!.mobileNumber!}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 2),
                            if (user?.email != null)
                              Row(
                                children: [
                                  const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      user!.email!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Active Mandal Info Card
                if (activeMandal != null) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(lang.tr('सक्रिय मंडळ', 'Active Mandal'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                lang.tr('सक्रिय', 'Active'),
                                style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeMandal.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                        ),
                        if (activeMandal.village != null)
                          Text('📍 ${activeMandal.village}, ${activeMandal.district ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const Divider(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lang.tr('मंडळ आमंत्रण कोड:', 'Mandal Invite Code:'), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  activeMandal.invitationCode,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: AppColors.primaryPurple),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primaryPurple),
                                  tooltip: lang.tr('कोड कॉपी करा', 'Copy Code'),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: activeMandal.invitationCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(lang.tr('आमंत्रण कोड कॉपी झाला!', 'Invite code copied!'))),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF25D366)),
                                  tooltip: lang.tr('कोड शेअर करा', 'Share Code'),
                                  onPressed: () {
                                    Share.share(
                                      '🚩 *${activeMandal.name}* 🚩\n${lang.tr("मंडळात सामील होण्यासाठी हा आमंत्रण कोड वापरा:", "Use this invite code to join the mandal:")} *${activeMandal.invitationCode}*\n\nVargani Collection App.',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 22),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.tune_rounded, color: AppColors.primaryPurple, size: 20),
                          ),
                          title: Text(lang.tr('वर्गणी दर व नियम', 'Vargani Settings'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            configState.activeConfig != null
                                ? '${configState.activeConfig!.name} • ${configState.activeConfig!.calculationType == "per_member" ? "${AppFormatters.formatCurrency(configState.activeConfig!.perMemberAmount)}/${lang.tr('सदस्य', 'member')}" : "${AppFormatters.formatCurrency(configState.activeConfig!.fixedAmount)}/${lang.tr('कुटुंब', 'family')}"}'
                                : lang.tr('या मंडळाचे वर्गणी दर निश्चित करा', 'Set vargani rates for this mandal'),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => context.push('/vargani-config'),
                        ),
                        const Divider(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.qr_code_2_rounded, color: AppColors.royalBlue, size: 20),
                          ),
                          title: Text(lang.tr('पेमेंट UPI व QR कोड', 'Payment UPI & QR Code'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            activeMandal.upiId != null || activeMandal.qrCodeUrl != null
                                ? '${activeMandal.upiId ?? lang.tr("QR फोटो जोडला आहे", "QR image attached")} • ${lang.tr("स्कॅनर सक्रिय", "Scanner Active")}'
                                : lang.tr('मंडळाचा UPI QR कोड किंवा फोटो जोडा', 'Add Mandal UPI QR or image'),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => context.push('/mandal-payment-settings'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // App Navigation Preferences
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryPurple),
                        title: Text(lang.tr('मंडळ बदला', 'Switch Mandal'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(lang.tr('दुसऱ्या मंडळात स्विच करा किंवा नवीन नोंदणी करा', 'Switch to another mandal or register new'), style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/mandal-selection'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.language_rounded, color: AppColors.royalBlue),
                        title: Text(lang.tr('भाषा बदला', 'Change Language'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(lang == AppLanguage.marathi ? 'मराठी' : 'English', style: const TextStyle(fontSize: 12)),
                        trailing: Switch(
                          activeColor: AppColors.primaryPurple,
                          value: lang == AppLanguage.marathi,
                          onChanged: (_) => ref.read(languageProvider.notifier).toggleLanguage(),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.speed_rounded, color: AppColors.success),
                        title: Text(lang.tr('सर्व्हर गती तपासा', 'Speed Test'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(lang.tr('क्लाउड डेटाबेस रिस्पॉन्स वेळ पडताळा', 'Verify cloud database latency'), style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.bolt, color: AppColors.success),
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(lang.tr('सर्व्हर गती तपासत आहे...', 'Checking server latency...'))),
                          );
                          final ms = await SupabaseService.checkLatency();
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Row(
                                  children: [
                                    const Icon(Icons.bolt, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(lang.tr('डेटाबेस गती निकाल', 'Database Latency Result')),
                                  ],
                                ),
                                content: Text('${lang.tr("रिस्पॉन्स वेळ:", "Response time:")} $ms ms\n\n✅ ${lang.tr("सुरक्षित SSL/TLS एन्क्रिप्टेड, RLS सुरक्षित.", "SSL/TLS encrypted, RLS secured.")}'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.tr('ठीक आहे', 'OK'))),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.support_agent_rounded, color: AppColors.accentOrange),
                        title: Text(lang.tr('समस्या नोंदवा / मदत', 'Report Issue / Help'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(lang.tr('काही अडचण आल्यास थेट सुपर ॲडमिनला मेसेज करा', 'Directly message Super Admin if facing issues'), style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/report-issue'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.mark_email_read_outlined, color: AppColors.primaryPurple),
                        title: Text(lang.tr('माझ्या तक्रारी व उत्तरे', 'My Issues & Replies'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(lang.tr('पाठवलेल्या अडचणींची स्थिती व ॲडमिनचे उत्तर पहा', 'Check submitted issues status and replies'), style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/my-tickets'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Super Admin Panel Section (Visible only to Super Admins)
                if (user?.isSuperAdmin == true) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.error, size: 28),
                      title: Text(
                        lang.tr('सुपर ॲडमिन: सर्व मंडळांचे मेसेज', 'Super Admin: All Mandal Tickets'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                      subtitle: Text(lang.tr('सर्व मंडळांकडून आलेल्या अडचणी, संपर्क व उत्तर देणे', 'Manage reported issues from all mandals'), style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.error),
                      onTap: () => context.push('/super-admin-tickets'),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Logout Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text(lang.tr('बाहेर पडायचे आहे का?', 'Do you want to logout?')),
                        content: Text(lang.tr('तुम्ही चालू खात्यातून बाहेर पडू इच्छिता?', 'Are you sure you want to log out from this account?')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(lang.tr('नाही', 'No'))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(lang.tr('बाहेर पडा', 'Logout')),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(AppStrings.tr(BuildContextKey.logout, lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
