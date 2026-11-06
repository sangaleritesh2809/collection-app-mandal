import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_label.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
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
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
      emailOrMobile: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      final selectedMandal = ref.read(mandalProvider).selectedMandal;
      if (selectedMandal != null) {
        context.go('/dashboard');
      } else {
        context.go('/mandal-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: 480,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo with glow
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.floating,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/vargani_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 42,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // App Title
                    const Center(
                      child: Text(
                        'Vargani Collection',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Welcome Text
                    Center(
                      child: Text(
                        lang.tr('मंडळ व्यवस्थापनात आपले स्वागत आहे! लॉग इन करा.', 'Welcome to Mandal Management! Please Log In.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Error Box if any
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
                                style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Email or Mobile Field
                    FormLabel(
                      lang.tr(
                        '${AppStrings.tr(BuildContextKey.email, lang)} किंवा ${AppStrings.tr(BuildContextKey.mobile, lang)}',
                        '${AppStrings.tr(BuildContextKey.email, lang)} or ${AppStrings.tr(BuildContextKey.mobile, lang)}',
                      ),
                      isRequired: true,
                    ),
                    TextFormField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        if (ref.read(authProvider).errorMessage != null) {
                          ref.read(authProvider.notifier).clearError();
                        }
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryPurple),
                        hintText: lang.tr('ईमेल किंवा मोबाईल नंबर टाका', 'Enter your email or mobile number'),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'कृपया ईमेल किंवा मोबाईल नंबर टाका.';
                        }
                        final trimmed = val.trim();
                        if (trimmed.contains('@')) {
                          return AppValidators.email(trimmed, isRequired: true);
                        } else if (RegExp(r'^[0-9+]+$').hasMatch(trimmed)) {
                          return AppValidators.mobile(trimmed, isRequired: true);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Password Field
                    FormLabel(AppStrings.tr(BuildContextKey.password, lang), isRequired: true),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        LengthLimitingTextInputFormatter(16),
                      ],
                      onChanged: (_) {
                        if (ref.read(authProvider).errorMessage != null) {
                          ref.read(authProvider.notifier).clearError();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: lang.tr('पासवर्ड टाका', 'Enter your password'),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryPurple),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'पासवर्ड आवश्यक आहे.';
                        }
                        if (val.contains(' ')) {
                          return 'पासवर्डमध्ये स्पेस (Space) असू नये.';
                        }
                        if (val.length < 8) {
                          return 'पासवर्ड किमान ८ अक्षरांचा असावा.';
                        }
                        if (val.length > 16) {
                          return 'पासवर्ड जास्तीत जास्त १६ अक्षरांचा असावा.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotPasswordDialog(context, lang),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.royalBlue,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.tr(BuildContextKey.forgotPassword, lang),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Login Button with Primary Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppShadows.floating,
                      ),
                      child: ElevatedButton(
                        onPressed: authState.status == AuthStatus.loading ? null : _handleLogin,
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
                                AppStrings.tr(BuildContextKey.login, lang),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lang.tr('नवीन खाते तयार करायचे आहे? ', 'Want to create a new account? '),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(authProvider.notifier).clearError();
                            context.pushReplacement('/register');
                          },
                          child: Text(
                            AppStrings.tr(BuildContextKey.register, lang),
                            style: const TextStyle(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context, AppLanguage lang) {
    final identifierCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    int step = 0; // 0 = Enter Email/Mobile, 1 = Enter OTP & New Password
    bool isLoading = false;
    bool obscureNew = true;
    String? resolvedEmail;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step == 0 ? Icons.lock_reset_rounded : Icons.mark_email_read_rounded,
                  color: AppColors.primaryPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step == 0
                      ? lang.tr('पासवर्ड रिसेट करा', 'Reset Password')
                      : lang.tr('OTP व नवीन पासवर्ड', 'Enter OTP & New Password'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dialogError!,
                            style: const TextStyle(color: AppColors.error, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (step == 0) ...[
                  Text(
                    lang.tr(
                      'तुमचा नोंदणीकृत ईमेल किंवा मोबाईल नंबर टाका. आम्ही पासवर्ड रिसेट करण्यासाठी ६-अंकी OTP पाठवू.',
                      'Enter your registered email or mobile number. We will send a 6-digit OTP to reset your password.',
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  FormLabel(
                    lang.tr('ईमेल किंवा मोबाईल नंबर', 'Email or Mobile Number'),
                    isRequired: true,
                  ),
                  TextField(
                    controller: identifierCtrl,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      if (dialogError != null) setDialogState(() => dialogError = null);
                    },
                    decoration: InputDecoration(
                      hintText: lang.tr('ईमेल किंवा मोबाईल नंबर टाका', 'Enter your email or mobile number'),
                      prefixIcon: const Icon(Icons.contact_mail_outlined, color: AppColors.primaryPurple),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${lang.tr("OTP पाठवला आहे:", "OTP sent to:")}\n$resolvedEmail',
                            style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // OTP field
                  FormLabel(lang.tr('६-अंकी OTP कोड', '6-Digit OTP Code'), isRequired: true),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.bold),
                    onChanged: (_) {
                      if (dialogError != null) setDialogState(() => dialogError = null);
                    },
                    decoration: InputDecoration(
                      hintText: lang.tr('६ अंकी OTP टाका', 'Enter 6-digit OTP'),
                      counterText: '',
                      prefixIcon: const Icon(Icons.password_rounded, color: AppColors.primaryPurple),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // New Password
                  FormLabel(lang.tr('नवीन पासवर्ड', 'New Password'), isRequired: true),
                  TextField(
                    controller: newPasswordCtrl,
                    obscureText: obscureNew,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      LengthLimitingTextInputFormatter(16),
                    ],
                    onChanged: (_) {
                      if (dialogError != null) setDialogState(() => dialogError = null);
                    },
                    decoration: InputDecoration(
                      hintText: lang.tr('नवीन पासवर्ड टाका', 'Enter your password'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryPurple),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Confirm Password
                  FormLabel(lang.tr('पासवर्ड पुन्हा टाका', 'Confirm Password'), isRequired: true),
                  TextField(
                    controller: confirmPasswordCtrl,
                    obscureText: obscureNew,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      LengthLimitingTextInputFormatter(16),
                    ],
                    onChanged: (_) {
                      if (dialogError != null) setDialogState(() => dialogError = null);
                    },
                    decoration: InputDecoration(
                      hintText: lang.tr('पासवर्ड पुन्हा टाका', 'Re-enter your password'),
                      prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryPurple),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Resend OTP
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        lang.tr('पुन्हा OTP पाठवा', 'Resend OTP'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setDialogState(() {
                                isLoading = true;
                                dialogError = null;
                              });
                              final res = await ref.read(authProvider.notifier).sendPasswordResetOtp(resolvedEmail!);
                              setDialogState(() {
                                isLoading = false;
                                if (res['success'] != true) {
                                  dialogError = res['message'] as String?;
                                }
                              });
                              if (res['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res['message'] as String)),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: Text(lang.tr('रद्द करा', 'Cancel'), style: const TextStyle(color: AppColors.textSecondary)),
            ),
            if (step == 0)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final input = identifierCtrl.text.trim();
                        if (input.isEmpty) {
                          setDialogState(() => dialogError = 'कृपया ईमेल किंवा मोबाईल नंबर टाका.');
                          return;
                        }

                        setDialogState(() {
                          isLoading = true;
                          dialogError = null;
                        });

                        final res = await ref.read(authProvider.notifier).sendPasswordResetOtp(input);

                        setDialogState(() {
                          isLoading = false;
                          if (res['success'] == true) {
                            resolvedEmail = res['email'] as String?;
                            step = 1;
                          } else {
                            dialogError = res['message'] as String?;
                          }
                        });
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(lang.tr('OTP पाठवा', 'Send OTP')),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final otp = otpCtrl.text.trim();
                        final newPass = newPasswordCtrl.text;
                        final confirmPass = confirmPasswordCtrl.text;

                        if (otp.length != 6) {
                          setDialogState(() => dialogError = 'कृपया ६-अंकी वैध OTP कोड टाका.');
                          return;
                        }
                        final passErr = AppValidators.password(newPass);
                        if (passErr != null) {
                          setDialogState(() => dialogError = passErr);
                          return;
                        }
                        final confirmErr = AppValidators.confirmPassword(confirmPass, newPass);
                        if (confirmErr != null) {
                          setDialogState(() => dialogError = confirmErr);
                          return;
                        }

                        setDialogState(() {
                          isLoading = true;
                          dialogError = null;
                        });

                        final res = await ref.read(authProvider.notifier).verifyOtpAndResetPassword(
                              email: resolvedEmail!,
                              otp: otp,
                              newPassword: newPass,
                            );

                        setDialogState(() => isLoading = false);

                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] as String),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        } else {
                          setDialogState(() => dialogError = res['message'] as String?);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(lang.tr('पासवर्ड बदला', 'Reset Password')),
              ),
          ],
        ),
      ),
    );
  }
}
