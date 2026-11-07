import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'supabase_service.dart';

/// Service managing Google AdMob configuration, consent (UMP), and ad lifecycle.
/// Android-only banner monetization with separate development and production configs.
class AdMobService {
  // Official Google AdMob Android Test IDs
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  static bool _initialized = false;
  static bool isAdsEnabled = true;
  static bool isTestMode = true;
  static String? productionBannerAdUnitId;

  /// Safely initialize Google Mobile Ads SDK and request UMP consent.
  /// Won't crash or block app startup / Supabase flow if offline or if SDK fails.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Initialize Google Mobile Ads SDK
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('✅ AdMob SDK initialized successfully');

      // 2. Request Google UMP (User Messaging Platform) consent
      _requestUmpConsent();

      // 3. Fetch remote ad settings from Supabase in background
      _fetchRemoteSettings();
    } catch (e) {
      debugPrint('⚠️ AdMob initialization warning (non-fatal): $e');
    }
  }

  /// Request Google UMP Consent according to official standards.
  static void _requestUmpConsent() {
    try {
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            if (formError != null) {
              debugPrint('⚠️ Consent form notice: ${formError.message}');
            }
          });
        },
        (FormError error) {
          debugPrint('⚠️ Consent info notice: ${error.message}');
        },
      );
    } catch (e) {
      debugPrint('⚠️ UMP Consent notice: $e');
    }
  }

  /// Fetch remote ad settings from Supabase `ad_settings` table.
  static Future<void> _fetchRemoteSettings() async {
    try {
      final response = await SupabaseService.client
          .from('ad_settings')
          .select('is_ads_enabled, is_test_mode, banner_ad_unit_id_android')
          .limit(1)
          .maybeSingle();

      if (response != null) {
        isAdsEnabled = response['is_ads_enabled'] ?? true;
        isTestMode = response['is_test_mode'] ?? true;
        productionBannerAdUnitId = response['banner_ad_unit_id_android'];
        debugPrint('✅ Ad settings loaded from Supabase: enabled=$isAdsEnabled, testMode=$isTestMode');
      }
    } catch (e) {
      debugPrint('⚠️ Ad settings fetch fallback to defaults: $e');
    }
  }

  /// Get the active Banner Ad Unit ID based on environment and settings.
  /// RULE: Never use production ads during testing/debug mode!
  static String get bannerAdUnitId {
    // In debug mode or if test mode is explicitly enabled, ALWAYS use Google test ID
    if (kDebugMode || isTestMode) {
      return testBannerAdUnitId;
    }

    // In release mode with test mode disabled, use production ID if configured
    final prodId = productionBannerAdUnitId?.trim();
    if (prodId != null && prodId.isNotEmpty && !prodId.contains('~')) {
      return prodId;
    }

    // Fallback to test ID if production ID is not configured
    return testBannerAdUnitId;
  }

  /// Refresh remote settings on demand (e.g. after Super Admin update)
  static Future<void> reloadSettings() async {
    await _fetchRemoteSettings();
  }

  /// Super Admin: Update ad settings in Supabase
  static Future<bool> updateAdSettings({
    required bool enabled,
    required bool testMode,
    required String bannerAdUnitId,
  }) async {
    try {
      final currentUserId = SupabaseService.currentUserId;
      final existing = await SupabaseService.client
          .from('ad_settings')
          .select('id')
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        await SupabaseService.client.from('ad_settings').update({
          'is_ads_enabled': enabled,
          'is_test_mode': testMode,
          'banner_ad_unit_id_android': bannerAdUnitId.trim(),
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': currentUserId,
        }).eq('id', existing['id']);
      } else {
        await SupabaseService.client.from('ad_settings').insert({
          'is_ads_enabled': enabled,
          'is_test_mode': testMode,
          'banner_ad_unit_id_android': bannerAdUnitId.trim(),
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': currentUserId,
        });
      }

      isAdsEnabled = enabled;
      isTestMode = testMode;
      productionBannerAdUnitId = bannerAdUnitId.trim();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to update ad settings: $e');
      return false;
    }
  }
}

