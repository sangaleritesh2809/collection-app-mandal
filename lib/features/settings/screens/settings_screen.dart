import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        title: const Text('माझे खाते व सेटिंग्ज (Profile & Settings)'),
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
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.soft,
                        ),
                        child: Center(
                          child: Text(
                            (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'वापरकर्ता',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 3),
                            if (user?.mobileNumber != null)
                              Text('📞 +91 ${user!.mobileNumber!}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            if (user?.email != null)
                              Text('✉️ ${user!.email!}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightLavender,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activeMandal?.userRole ?? 'सदस्य',
                          style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 11),
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
                            const Text('सक्रिय मंडळ (Active Mandal)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'सक्रिय',
                                style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
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
                                const Text('मंडळ आमंत्रण कोड (Invite Code):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                                  tooltip: 'कोड कॉपी करा',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: activeMandal.invitationCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('आमंत्रण कोड कॉपी झाला!')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF25D366)),
                                  tooltip: 'कोड शेअर करा',
                                  onPressed: () {
                                    Share.share(
                                      '🚩 *${activeMandal.name}* 🚩\nमंडळात सामील होण्यासाठी हा आमंत्रण कोड वापरा: *${activeMandal.invitationCode}*\n\nVargani Collection ॲप डाउनलोड करा.',
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
                          title: const Text('वर्गणी दर व नियम (Vargani Settings)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            configState.activeConfig != null
                                ? '${configState.activeConfig!.name} • ${configState.activeConfig!.calculationType == "per_member" ? "${AppFormatters.formatCurrency(configState.activeConfig!.perMemberAmount)}/सदस्य" : "${AppFormatters.formatCurrency(configState.activeConfig!.fixedAmount)}/कुटुंब"}'
                                : 'या मंडळाचे वर्गणी दर निश्चित करा',
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
                          title: const Text('पेमेंट UPI व QR कोड (Payment QR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            activeMandal.upiId != null || activeMandal.qrCodeUrl != null
                                ? '${activeMandal.upiId ?? "QR फोटो जोडला आहे"} • स्कॅनर सक्रिय'
                                : 'मंडळाचा UPI QR कोड किंवा फोटो जोडा',
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
                        title: const Text('मंडळ बदला (Switch Mandal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('दुसऱ्या मंडळात स्विच करा किंवा नवीन नोंदणी करा', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/mandal-selection'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.language_rounded, color: AppColors.royalBlue),
                        title: const Text('भाषा बदला (Language)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(lang == AppLanguage.marathi ? 'मराठी (सक्रिय)' : 'English', style: const TextStyle(fontSize: 12)),
                        trailing: Switch(
                          activeColor: AppColors.primaryPurple,
                          value: lang == AppLanguage.marathi,
                          onChanged: (_) => ref.read(languageProvider.notifier).toggleLanguage(),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.speed_rounded, color: AppColors.success),
                        title: const Text('सर्व्हर गती तपासा (Speed Test)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('क्लाउड डेटाबेस रिस्पॉन्स वेळ पडताळा', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.bolt, color: AppColors.success),
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('सर्व्हर गती तपासत आहे...')),
                          );
                          final ms = await SupabaseService.checkLatency();
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.bolt, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('डेटाबेस गती निकाल'),
                                  ],
                                ),
                                content: Text('रिस्पॉन्स वेळ: $ms ms\n\n✅ सुरक्षित SSL/TLS एन्क्रिप्टेड, RLS सुरक्षित.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ठीक आहे')),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.support_agent_rounded, color: AppColors.accentOrange),
                        title: const Text('समस्या नोंदवा / मदत (Report Issue)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('काही अडचण आल्यास थेट सुपर ॲडमिनला मेसेज करा', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/report-issue'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.mark_email_read_outlined, color: AppColors.primaryPurple),
                        title: const Text('माझ्या तक्रारी व उत्तरे (My Issues)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('पाठवलेल्या अडचणींची स्थिती व ॲडमिनचे उत्तर पहा', style: TextStyle(fontSize: 12)),
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
                      title: const Text(
                        'सुपर ॲडमिन: सर्व मंडळांचे मेसेज',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                      subtitle: const Text('सर्व मंडळांकडून आलेल्या अडचणी, संपर्क व उत्तर देणे', style: TextStyle(fontSize: 12)),
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
                        title: const Text('बाहेर पडायचे आहे का? (Logout)'),
                        content: const Text('तुम्ही चालू खात्यातून बाहेर पडू इच्छिता?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('नाही')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('बाहेर पडा'),
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
