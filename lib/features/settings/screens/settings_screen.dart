import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mandal/providers/mandal_provider.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authProvider);
    final mandalState = ref.watch(mandalProvider);
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

