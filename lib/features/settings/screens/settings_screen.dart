import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/supabase_service.dart';
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
      appBar: AppBar(
        title: Text(AppStrings.tr(BuildContextKey.settings, lang)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'वापरकर्ता',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (user?.mobileNumber != null)
                            Text(user!.mobileNumber!, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                          if (user?.email != null)
                            Text(user!.email!, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Active Mandal Info Card
            if (activeMandal != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('सक्रिय मंडळ (Active Mandal)', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              activeMandal.userRole ?? 'सदस्य',
                              style: const TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activeMandal.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (activeMandal.village != null)
                        Text('${activeMandal.village}, ${activeMandal.district ?? ''}', style: const TextStyle(fontSize: 13)),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('मंडळ आमंत्रण कोड (Invite Code):', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                              const SizedBox(height: 2),
                              Text(
                                activeMandal.invitationCode,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2, color: AppColors.primary),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                tooltip: 'कोड कॉपी करा',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: activeMandal.invitationCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('आमंत्रण कोड कॉपी झाला!')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.share, size: 20, color: Colors.green),
                                tooltip: 'कोड शेअर करा',
                                onPressed: () {
                                  Share.share(
                                    '🚩 *${activeMandal.name}* 🚩\nमंडळात सामील होण्यासाठी हा आमंत्रण कोड वापरा: *${activeMandal.invitationCode}*\n\nवर्गणी कलेक्शन ॲप डाउनलोड करा.',
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tune, color: AppColors.primary, size: 22),
                        ),
                        title: const Text('वर्गणी दर व नियम (Vargani Settings)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          configState.activeConfig != null
                              ? '${configState.activeConfig!.name} • ${configState.activeConfig!.calculationType == "per_member" ? "${AppFormatters.formatCurrency(configState.activeConfig!.perMemberAmount)}/सदस्य" : "${AppFormatters.formatCurrency(configState.activeConfig!.fixedAmount)}/कुटुंब"}'
                              : 'या मंडळाचे वर्गणी दर निश्चित करा',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
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
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.qr_code_2, color: Colors.green, size: 22),
                        ),
                        title: const Text('पेमेंट UPI व QR कोड (Payment QR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          activeMandal.upiId != null || activeMandal.qrCodeUrl != null
                              ? '${activeMandal.upiId ?? "QR फोटो जोडला आहे"} • स्कॅनर सक्रिय'
                              : 'मंडळाचा UPI QR कोड किंवा फोटो जोडा',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => context.push('/mandal-payment-settings'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Preferences
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.swap_horiz, color: AppColors.primary),
                    title: const Text('मंडळ बदला (Switch Mandal)'),
                    subtitle: const Text('इतर मंडळ निवडा किंवा नवीन नोंदणी करा'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/mandal-selection'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.blue),
                    title: const Text('भाषा बदला (Language)'),
                    subtitle: Text(lang == AppLanguage.marathi ? 'मराठी' : 'English'),
                    trailing: Switch(
                      value: lang == AppLanguage.marathi,
                      onChanged: (_) => ref.read(languageProvider.notifier).toggleLanguage(),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined, color: Colors.purple),
                    title: const Text('डार्क मोड (Dark Mode)'),
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.speed, color: Colors.green),
                    title: const Text('सर्व्हर गती तपासा (API Speed Test)'),
                    subtitle: const Text('क्लाउड डेटाबेस रिस्पॉन्स टाईम पडताळा'),
                    trailing: const Icon(Icons.network_check, color: AppColors.primary),
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('एपीआय गती तपासत आहे...')),
                      );
                      final ms = await SupabaseService.checkLatency();
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.bolt, color: Colors.green),
                                SizedBox(width: 8),
                                Text('API गती निकाल'),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('रिस्पॉन्स वेळ: $ms ms', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                                const SizedBox(height: 8),
                                Text(
                                  ms < 300
                                      ? '✅ उत्कृष्ट गती! डेटाबेस जलद काम करत आहे.'
                                      : '⚠️ मध्यम गती. इंटरनेट कनेक्शन तपासा.',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                const Text('सुरक्षा: SSL/TLS 1.3 एन्क्रिप्टेड, RLS सुरक्षित', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ठीक आहे')),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
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
                    if (context.mounted) context.go('/');
                  }
                },
                icon: const Icon(Icons.logout),
                label: Text(AppStrings.tr(BuildContextKey.logout, lang)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

