import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';

/// Reusable Google AdMob Anchored Adaptive Banner widget.
/// Designed exclusively for the Home Dashboard.
/// Handles loading, failed requests, offline mode, and safe disposal.
class HomeBannerAd extends StatefulWidget {
  const HomeBannerAd({super.key});

  @override
  State<HomeBannerAd> createState() => _HomeBannerAdState();
}

class _HomeBannerAdState extends State<HomeBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  AdSize? _adSize;
  Orientation? _currentOrientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (_currentOrientation != orientation) {
      _currentOrientation = orientation;
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    // If ads are disabled remotely, do not load
    if (!AdMobService.isAdsEnabled) {
      if (mounted) setState(() => _isAdLoaded = false);
      return;
    }

    if (_isLoading) return;
    _isLoading = true;

    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0) {
      _isLoading = false;
      return;
    }

    // Dispose existing ad before creating a new one
    await _bannerAd?.dispose();
    _bannerAd = null;

    if (!mounted) {
      _isLoading = false;
      return;
    }

    // Get Anchored Adaptive Banner size
    final adaptiveSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted) {
      _isLoading = false;
      return;
    }

    final size = adaptiveSize ?? AdSize.banner;
    _adSize = size;

    try {
      final banner = BannerAd(
        adUnitId: AdMobService.bannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _bannerAd = ad as BannerAd;
              _isAdLoaded = true;
              _isLoading = false;
            });
            debugPrint('✅ AdMob Banner loaded: ${ad.responseInfo?.responseId}');
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('⚠️ AdMob Banner failed to load: ${error.message} (code: ${error.code})');
            ad.dispose();
            if (mounted) {
              setState(() {
                _bannerAd = null;
                _isAdLoaded = false;
                _isLoading = false;
              });
            }
          },
          onAdOpened: (ad) => debugPrint('ℹ️ AdMob Banner opened'),
          onAdClosed: (ad) => debugPrint('ℹ️ AdMob Banner closed'),
        ),
      );

      await banner.load();
    } catch (e) {
      debugPrint('⚠️ AdMob load exception: $e');
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Graceful fallback: collapse completely to 0 height if disabled, failed, or not loaded
    if (!AdMobService.isAdsEnabled || !_isAdLoaded || _bannerAd == null || _adSize == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _adSize!.width.toDouble(),
      height: _adSize!.height.toDouble(),
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

