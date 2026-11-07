import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../auth/providers/auth_provider.dart';

class AdSettingsScreen extends ConsumerStatefulWidget {
  const AdSettingsScreen({super.key});

  @override
  ConsumerState<AdSettingsScreen> createState() => _AdSettingsScreenState();
}

class _AdSettingsScreenState extends ConsumerState<AdSettingsScreen> {
  final _bannerUnitCtrl = TextEditingController();
  bool _isAdsEnabled = true;
  bool _isTestMode = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _bannerUnitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final res = await SupabaseService.client
          .from('ad_settings')
          .select()
          .limit(1)
          .maybeSingle();

      if (res != null) {
        _isAdsEnabled = res['is_ads_enabled'] ?? true;
        _isTestMode = res['is_test_mode'] ?? true;
        _bannerUnitCtrl.text = res['banner_ad_unit_id_android'] ?? '';
      } else {
        _isAdsEnabled = AdMobService.isAdsEnabled;
        _isTestMode = AdMobService.isTestMode;
        _bannerUnitCtrl.text = AdMobService.productionBannerAdUnitId ?? '';
      }
    } catch (e) {
      debugPrint('Error loading ad settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final success = await AdMobService.updateAdSettings(
        enabled: _isAdsEnabled,
        testMode: _isTestMode,
        bannerAdUnitId: _bannerUnitCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✅ AdMob सेटिंग्ज यशस्वीरित्या सेव्ह झाल्या!'
                  : '❌ सेटिंग्ज सेव्ह करताना त्रुटी आली. कृपया तपासा.',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authProvider);
    final user = authState.userProfile;

    // Security Gate: Super Admin only
    if (user?.isSuperAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('अनधिकृत प्रवेश')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '⚠️ ही स्क्रीन फक्त सुपर ॲडमिनसाठी राखीव आहे.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(lang.tr('Google AdMob व्यवस्थापन', 'Google AdMob Management')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: ResponsiveContainer(
                  maxWidth: 720,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.tr('Google AdMob बॅनर जाहिराती', 'Google AdMob Banner Ads'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lang.tr(
                                      'केवळ डॅशबोर्डवर बॅनर जाहिराती दाखवल्या जातात. पेमेंट किंवा पावत्यांवर जाहिराती नसतात.',
                                      'Adaptive banner ads shown only on dashboard. Critical screens remain ad-free.',
                                    ),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Toggles Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              activeColor: AppColors.primaryPurple,
                              title: Text(
                                lang.tr('ॲपमध्ये जाहिराती दाखवा (Ads Enabled)', 'Enable Ads in App'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                lang.tr(
                                  'बंद केल्यास संपूर्ण ॲपमध्ये जाहिराती थांबतील',
                                  'Turn off to disable all ads across the app',
                                ),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              value: _isAdsEnabled,
                              onChanged: (val) => setState(() => _isAdsEnabled = val),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              activeColor: AppColors.accentOrange,
                              title: Text(
                                lang.tr('टेस्ट मोड सुरू ठेवा (Test Mode)', 'Enable Test Mode'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                lang.tr(
                                  'सुरू असल्यास गुगलच्या अधिकृत टेस्ट ॲड वापरल्या जातील (ॲप बॅन होण्यापासून रक्षण होते)',
                                  'Always uses official Google test ads to protect account during testing',
                                ),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              value: _isTestMode,
                              onChanged: (val) => setState(() => _isTestMode = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Ad Unit Configuration Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.tr('Android प्रोडक्शन Banner Ad Unit ID', 'Android Production Banner Ad Unit ID'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lang.tr(
                                'तुमच्या Google AdMob कन्सोलवरून मिळालेला बॅनर युनिट आयडी येथे टाका:',
                                'Enter your Banner Unit ID from Google AdMob console:',
                              ),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _bannerUnitCtrl,
                              decoration: InputDecoration(
                                hintText: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
                                prefixIcon: const Icon(Icons.ad_units_rounded),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.paste_rounded),
                                  onPressed: () async {
                                    final data = await Clipboard.getData('text/plain');
                                    if (data?.text != null) {
                                      _bannerUnitCtrl.text = data!.text!.trim();
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.lightLavender,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline, size: 16, color: AppColors.primaryPurple),
                                      const SizedBox(width: 6),
                                      Text(
                                        lang.tr('गुगल ऑफिशियल टेस्ट आयडी:', 'Google Official Test IDs:'),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const SelectableText(
                                    'App ID: ca-app-pub-3940256099942544~3347511713\nBanner Unit: ca-app-pub-3940256099942544/6300978111',
                                    style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isSaving ? null : _saveSettings,
                        icon: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _isSaving
                              ? lang.tr('जतन करत आहे...', 'Saving...')
                              : lang.tr('सेटिंग्ज सेव्ह करा', 'Save Settings'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

