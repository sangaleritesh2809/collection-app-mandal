import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _pages = const [
    OnboardingItem(
      title: 'आपल्या मंडळाचे डिजिटल व्यवस्थापन',
      subtitle: 'मंडळाची सर्व कुटुंबे, सभासद आणि कार्यकर्त्यांची माहिती एकाच ठिकाणी सुरक्षितपणे साठवा.',
      icon: Icons.groups_rounded,
      badgeText: 'Mandal Management',
      accentColor: AppColors.primaryPurple,
    ),
    OnboardingItem(
      title: 'वर्गणी आणि खर्चाचा पारदर्शक हिशोब',
      subtitle: 'रोख किंवा ऑनलाइन QR कोडद्वारे त्वरित वर्गणी गोळा करा व प्रत्येक खर्चाची पक्की पावती ठेवा.',
      icon: Icons.account_balance_wallet_rounded,
      badgeText: 'Instant Collection & Expense',
      accentColor: AppColors.royalBlue,
    ),
    OnboardingItem(
      title: 'प्रत्येक व्यवहाराची सुरक्षित नोंद',
      subtitle: 'खजिनदारांची मंजुरी, रिअल-टाइम अहवाल आणि WhatsApp वर त्वरित डिजिटल पावती शेअर करा.',
      icon: Icons.verified_user_rounded,
      badgeText: 'Approval & Reports',
      accentColor: AppColors.accentOrange,
    ),
  ];

  Future<void> _markOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (_) {}
  }

  void _onNext() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      await _markOnboardingComplete();
      if (mounted) context.go('/login');
    }
  }

  void _onSkip() async {
    await _markOnboardingComplete();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.soft,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/vargani_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.circle, color: AppColors.primaryPurple),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Vargani Collection',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      child: const Text('सोडून द्या (Skip)'),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration Card
                        Container(
                          width: double.infinity,
                          height: 280,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                item.accentColor.withOpacity(0.08),
                                AppColors.lightLavender,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: item.accentColor.withOpacity(0.18)),
                            boxShadow: AppShadows.card,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [item.accentColor, item.accentColor.withOpacity(0.8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: item.accentColor.withOpacity(0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(item.icon, size: 48, color: Colors.white),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: item.accentColor.withOpacity(0.2)),
                                ),
                                child: Text(
                                  item.badgeText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: item.accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primaryPurple : const Color(0xFFD4D0E5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Action Button
                  ElevatedButton.icon(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      shadowColor: AppColors.primaryPurple.withOpacity(0.4),
                    ),
                    icon: Icon(
                      _currentPage == _pages.length - 1 ? Icons.check_circle : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _currentPage == _pages.length - 1 ? 'सुरू करा (Get Started)' : 'पुढे जा (Next)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badgeText;
  final Color accentColor;

  const OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeText,
    required this.accentColor,
  });
}

