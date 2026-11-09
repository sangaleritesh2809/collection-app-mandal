import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mandal/providers/mandal_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Fast instant navigation (reduced from 2200ms to 400ms for immediate loading!)
    _navTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      await _handleNavigation();
    });
  }

  Future<void> _handleNavigation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      final lastMandalId = prefs.getString('last_selected_mandal_id');

      final authState = ref.read(authProvider);
      final mandalState = ref.read(mandalProvider);

      final isAuthenticated = authState.status == AuthStatus.authenticated ||
          wasLoggedIn ||
          (SupabaseService.isInitialized && SupabaseService.currentUser != null);

      if (!mounted) return;

      if (isAuthenticated) {
        // User is logged in! Never show login page on app reopen
        if (mandalState.selectedMandal != null || lastMandalId != null) {
          context.go('/dashboard');
        } else {
          context.go('/mandal-selection');
        }
      } else {
        // User is NOT logged in: only show onboarding on fresh install
        if (hasSeenOnboarding) {
          context.go('/login');
        } else {
          context.go('/onboarding');
        }
      }
    } catch (e) {
      debugPrint('Navigation error in splash screen: $e');
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppColors.primaryPurple.withOpacity(0.04),
              AppColors.royalBlue.withOpacity(0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated Logo
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 130,
                      height: 130,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.floating,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/vargani_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_wallet, size: 56, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App Name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ShaderMask(
                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                    child: const Text(
                      'Vargani Collection',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Marathi Tagline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'आपल्या वर्गणीचा, आपल्या मंडळाचा हिशोब',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Subtle Loading Spinner
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple.withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'सुरक्षित व पारदर्शक मंडळ प्रणाली',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
