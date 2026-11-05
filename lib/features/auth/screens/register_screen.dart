import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_label.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        context.go('/mandal-selection');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('नोंदणी यशस्वी झाली! कृपया लॉगिन करा.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pushReplacement('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () {
            ref.read(authProvider.notifier).clearError();
            context.pushReplacement('/login');
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: 500,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Badge / Icon
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.soft,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/vargani_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_add_rounded,
                              size: 34,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Center(
                      child: Text(
                        lang.tr('नवीन खाते तयार करा', 'Create New Account'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    Center(
                      child: Text(
                        lang.tr('मंडळ हिशोब व वर्गणी व्यवस्थापनासाठी आपली माहिती भरा', 'Fill in your details for mandal accounts and vargani management'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (authState.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(color: AppColors.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Full Name
                    FormLabel(AppStrings.tr(BuildContextKey.fullName, lang), isRequired: true),
                    TextFormField(
                      controller: _fullNameController,
                      onChanged: (_) {
                        if (ref.read(authProvider).errorMessage != null) {
                          ref.read(authProvider.notifier).clearError();
                        }
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primaryPurple),
                        hintText: lang.tr('उदा. राहुल सुरेश पाटील', 'e.g. Rahul Suresh Patil'),
                      ),
                      validator: (val) => AppValidators.name(val, lang.tr('पूर्ण नाव', 'Full Name')),
                    ),
                    const SizedBox(height: 16),

                    // Email Address
                    FormLabel(AppStrings.tr(BuildContextKey.email, lang), isRequired: true),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        if (ref.read(authProvider).errorMessage != null) {
                          ref.read(authProvider.notifier).clearError();
                        }
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryPurple),
                        hintText: 'rahul@example.com',
                      ),
                      validator: (val) => AppValidators.email(val, isRequired: true),
                    ),
                    const SizedBox(height: 16),

                    // Mobile Number
                    FormLabel(AppStrings.tr(BuildContextKey.mobile, lang), isRequired: true),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) {
                        if (ref.read(authProvider).errorMessage != null) {
                          ref.read(authProvider.notifier).clearError();
                        }
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_android_rounded, color: AppColors.primaryPurple),
                        prefixText: '+91 ',
                        hintText: '9876543210',
                      ),
                      validator: (val) => AppValidators.mobile(val, isRequired: true),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    FormLabel(AppStrings.tr(BuildContextKey.password, lang), isRequired: true),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) {
                        if (ref.read(authProvider).errorMessage != null) {
                          ref.read(authProvider.notifier).clearError();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: lang.tr('किमान ६ अक्षरांचा पासवर्ड', 'Minimum 6 character password'),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryPurple),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: AppValidators.password,
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    FormLabel(AppStrings.tr(BuildContextKey.confirmPassword, lang), isRequired: true),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) {
                        if (ref.read(authProvider).errorMessage != null) {
                          ref.read(authProvider.notifier).clearError();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: lang.tr('पासवर्ड पुन्हा टाका', 'Re-enter password'),
                        prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryPurple),
                      ),
                      validator: (val) => AppValidators.confirmPassword(val, _passwordController.text),
                    ),
                    const SizedBox(height: 26),

                    // Submit
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppShadows.floating,
                      ),
                      child: ElevatedButton(
                        onPressed: authState.status == AuthStatus.loading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: authState.status == AuthStatus.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                AppStrings.tr(BuildContextKey.register, lang),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lang.tr('आधीच खाते आहे? ', 'Already have an account? '),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(authProvider.notifier).clearError();
                            context.pushReplacement('/login');
                          },
                          child: Text(
                            AppStrings.tr(BuildContextKey.login, lang),
                            style: const TextStyle(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
