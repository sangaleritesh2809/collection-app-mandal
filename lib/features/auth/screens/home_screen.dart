import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../../mandal/providers/mandal_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final mandalState = ref.watch(mandalProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.08),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Bar with Language switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'डिजिटल मंडळ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => ref.read(languageProvider.notifier).toggleLanguage(),
                      icon: const Icon(Icons.language, size: 18),
                      label: Text(lang == AppLanguage.marathi ? 'English' : 'मराठी'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // App Branding & Icon
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: AppColors.saffronGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      size: 46,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Titles
                Text(
                  AppStrings.tr(BuildContextKey.appName, lang),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.tr(BuildContextKey.appTagline, lang),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),

                // If already logged in, show Quick Access to Dashboard or Mandal Selection
                if (auth.status == AuthStatus.authenticated) ...[
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.15),
                                child: const Icon(Icons.person, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      auth.userProfile?.fullName ?? 'User',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      mandalState.selectedMandal?.name ?? 'मंडळ निवडलेले नाही',
                                      style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/dashboard'),
                              icon: const Icon(Icons.dashboard),
                              label: Text(AppStrings.tr(BuildContextKey.dashboard, lang)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/mandal-selection'),
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text('मंडळ बदला / निवडा (Switch Mandal)'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Primary Login & Register Actions
                  ElevatedButton.icon(
                    onPressed: () => context.push('/login'),
                    icon: const Icon(Icons.login),
                    label: Text(AppStrings.tr(BuildContextKey.login, lang)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/register'),
                    icon: const Icon(Icons.person_add),
                    label: Text(AppStrings.tr(BuildContextKey.register, lang)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Mandal Actions Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'मंडळ व्यवस्थापन पर्याय',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_home_work, color: AppColors.primary),
                          ),
                          title: Text(
                            AppStrings.tr(BuildContextKey.createMandal, lang),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('तुमच्या उत्सवासाठी नवीन मंडळ नोंदणी करा'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/create-mandal'),
                        ),
                        const Divider(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.group_add, color: Colors.blue),
                          ),
                          title: Text(
                            AppStrings.tr(BuildContextKey.joinMandal, lang),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('आमंत्रण कोड वापरून हजर व्हा'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/join-mandal'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Footer Links: About, Terms, Privacy, Support
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _showDialog(context, 'ॲप बद्दल (About Us)', 'वर्गणी कलेक्शन हे सर्व प्रकारच्या सार्वजनिक उत्सव मंडळांसाठी, गणेशोत्सव, नवरात्रोत्सव व शिवजयंती मंडळांसाठी हिशेब व वर्गणी संकलन सुलभ करणारे डिजिटल ॲप आहे.'),
                      child: const Text('About App', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => _showDialog(context, 'गोपनीयता धोरण (Privacy Policy)', 'सर्व आर्थिक नोंदी आणि सदस्यांची माहिती पूर्णपणे सुरक्षित असून Supabase Row Level Security द्वारे संरक्षित आहे.'),
                      child: const Text('Privacy Policy', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => _showDialog(context, 'नियम व अटी (Terms & Conditions)', 'हे ॲप केवळ अधिकृत मंडळ पदाधिकाऱ्यांनी जमा-खर्चाच्या पारदर्शक नोंदी ठेवण्यासाठी वापरावे.'),
                      child: const Text('Terms & Conditions', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => _showDialog(context, 'मदत व संपर्क (Support)', 'तांत्रिक मदतीसाठी कृपया support@vargani.com वर संपर्क साधा.'),
                      child: const Text('Contact Support', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    '© 2026 Vargani Collection • सुरक्षित व पारदर्शक',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(content, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ठीक आहे (OK)'),
          ),
        ],
      ),
    );
  }
}

