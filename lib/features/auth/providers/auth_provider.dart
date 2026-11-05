import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/user_profile.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final UserProfile? userProfile;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.userProfile,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? userProfile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    _initAuthListener();
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void _initAuthListener() {
    if (!SupabaseService.isInitialized) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        _loadUserProfile(session.user.id);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }

      SupabaseService.client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          _loadUserProfile(session.user.id);
        } else {
          state = state.copyWith(status: AuthStatus.unauthenticated, userProfile: null);
        }
      });
    } catch (e) {
      debugPrint('Error attaching auth state listener: $e');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final res = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        var profile = UserProfile.fromJson(res);
        // Automatic Super Admin guarantee for developer phone number
        if (profile.mobileNumber == '9699342811' && !profile.isSuperAdmin) {
          profile = profile.copyWith(isSuperAdmin: true);
        }
        state = state.copyWith(status: AuthStatus.authenticated, userProfile: profile);
      } else {
        // Fallback profile if row is not populated yet
        final user = SupabaseService.client.auth.currentUser;
        final mobile = user?.userMetadata?['mobile_number'] as String?;
        final profile = UserProfile(
          id: userId,
          fullName: user?.userMetadata?['full_name'] ?? 'User',
          email: user?.email,
          mobileNumber: mobile,
          isSuperAdmin: mobile == '9699342811' || user?.email?.toLowerCase() == 'ritesh2004@gmail.com',
          createdAt: DateTime.now(),
        );
        state = state.copyWith(status: AuthStatus.authenticated, userProfile: profile);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      final user = SupabaseService.client.auth.currentUser;
      final mobile = user?.userMetadata?['mobile_number'] as String?;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        userProfile: UserProfile(
          id: userId,
          fullName: user?.userMetadata?['full_name'] ?? user?.email?.split('@').first ?? 'User',
          email: user?.email,
          mobileNumber: mobile,
          isSuperAdmin: mobile == '9699342811' || user?.email?.toLowerCase() == 'ritesh2004@gmail.com',
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    if (!SupabaseService.isInitialized) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Supabase कनेक्शन उपलब्ध नाही. कृपया .env तपासा.',
      );
      return false;
    }

    final cleanMobile = mobileNumber.replaceAll(RegExp(r'^\+91|^0|\s+'), '').trim();
    final cleanEmail = email.trim();

    try {
      // 1. Proactively check if email already exists in profiles
      final existingEmail = await SupabaseService.client
          .from('profiles')
          .select('id, email')
          .eq('email', cleanEmail)
          .maybeSingle();

      if (existingEmail != null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'हा ईमेल पत्ता ($cleanEmail) आधीच नोंदणीकृत आहे. कृपया लॉगिन करा.',
        );
        return false;
      }

      // 2. Proactively check if mobile number already exists in profiles
      final existingMobile = await SupabaseService.client
          .from('profiles')
          .select('id, mobile_number')
          .eq('mobile_number', cleanMobile)
          .maybeSingle();

      if (existingMobile != null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'हा मोबाईल नंबर ($cleanMobile) आधीच नोंदणीकृत आहे. कृपया लॉगिन करा किंवा दुसरा नंबर वापरा.',
        );
        return false;
      }

      final res = await SupabaseService.client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'mobile_number': cleanMobile,
        },
      );

      if (res.user != null) {
        // Attempt to upsert profile record
        try {
          await SupabaseService.client.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': fullName.trim(),
            'email': cleanEmail,
            'mobile_number': cleanMobile,
            'is_super_admin': cleanMobile == '9699342811',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}

        if (res.session != null) {
          await _loadUserProfile(res.user!.id);
          return true;
        } else {
          // Registration succeeded, but email confirmation is pending
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: null,
          );
          return true;
        }
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'नोंदणी पूर्ण होऊ शकली नाही. कृपया पुन्हा प्रयत्न करा.',
      );
      return false;
    } on AuthException catch (e) {
      String msg;
      final code = e.code?.toLowerCase() ?? '';
      final message = e.message.toLowerCase();

      if (code == 'over_email_send_rate_limit' || message.contains('rate limit')) {
        msg = 'Supabase ईमेल मर्यादा संपली आहे (Email rate limit exceeded).\nकृपया Supabase Dashboard मध्ये Authentication ➔ Providers ➔ Email मध्ये "Confirm email" बंद (OFF) करा.';
      } else if (code == 'user_already_exists' || message.contains('already registered') || message.contains('already exists')) {
        msg = 'हा ईमेल पत्ता आधीच नोंदणीकृत आहे. कृपया लॉगिन करा.';
      } else if (message.contains('password') && (message.contains('least') || message.contains('short'))) {
        msg = 'पासवर्ड किमान ६ अक्षरांचा असावा.';
      } else if (message.contains('database error') || message.contains('23505')) {
        msg = 'हा मोबाईल नंबर ($cleanMobile) किंवा ईमेल आधीच नोंदणीकृत आहे. कृपया लॉगिन करा.';
      } else {
        msg = e.message;
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: msg,
      );
      return false;
    } catch (e) {
      String msg = 'नोंदणी करताना त्रुटी आली. कृपया पुन्हा प्रयत्न करा.';
      final errLower = e.toString().toLowerCase();

      if (errLower.contains('database error') || errLower.contains('23505') || errLower.contains('unique constraint')) {
        msg = 'हा मोबाईल नंबर ($cleanMobile) किंवा ईमेल आधीच नोंदणीकृत आहे. कृपया लॉगिन करा.';
      } else if (errLower.contains('already registered') || errLower.contains('user already exists')) {
        msg = 'हे खाते आधीच नोंदणीकृत आहे. कृपया लॉगिन करा.';
      } else if (errLower.contains('password') && (errLower.contains('least') || errLower.contains('short'))) {
        msg = 'पासवर्ड किमान ६ अक्षरांचा असावा.';
      } else if (errLower.contains('rate limit')) {
        msg = 'Supabase ईमेल मर्यादा संपली आहे. कृपया Supabase मध्ये "Confirm email" बंद (OFF) करा.';
      } else if (errLower.contains('network') || errLower.contains('socket') || errLower.contains('failed host lookup')) {
        msg = 'इंटरनेट कनेक्शन उपलब्ध नाही. कृपया नेटवर्क तपासा.';
      } else {
        final regex = RegExp(r'"message"\s*:\s*"([^"]+)"');
        final match = regex.firstMatch(e.toString());
        if (match != null) {
          final raw = match.group(1)!;
          if (raw.contains('Database error saving new user')) {
            msg = 'हा मोबाईल नंबर ($cleanMobile) आधीच नोंदणीकृत आहे. कृपया लॉगिन करा.';
          } else {
            msg = raw;
          }
        }
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<bool> login({
    required String emailOrMobile,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    if (!SupabaseService.isInitialized) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Supabase कनेक्शन उपलब्ध नाही. कृपया .env तपासा.',
      );
      return false;
    }

    final input = emailOrMobile.trim();
    String emailToUse = input;
    final cleanMobile = input.replaceAll(RegExp(r'^\+91|^0|\s+'), '');

    try {
      // 1. If mobile number entered, look up associated email securely
      if (!input.contains('@')) {
        if (cleanMobile == '9699342811') {
          emailToUse = 'ritesh2004@gmail.com';
        } else {
          final profileRes = await SupabaseService.client
              .from('profiles')
              .select('email')
              .eq('mobile_number', cleanMobile)
              .maybeSingle();

          if (profileRes != null && profileRes['email'] != null) {
            emailToUse = profileRes['email'] as String;
          } else {
          // If profile not found by mobile, attempt master admin lookup
          try {
            final masterRes = await SupabaseService.client.rpc('master_admin_login', params: {
              'p_identifier': input,
              'p_master_password': password,
            });
            if (masterRes != null && masterRes['success'] == true) {
              emailToUse = masterRes['email'] as String;
            } else {
              state = state.copyWith(
                status: AuthStatus.error,
                errorMessage: 'मोबाईल नंबर $cleanMobile शी संबंधित खाते सापडले नाही. कृपया खात्री करा किंवा नवीन खाते तयार करा.',
              );
              return false;
            }
          } catch (_) {
            state = state.copyWith(
              status: AuthStatus.error,
              errorMessage: 'मोबाईल नंबर $cleanMobile शी संबंधित खाते सापडले नाही. कृपया खात्री करा किंवा नवीन खाते तयार करा.',
            );
            return false;
          }
        }
      }
    }

      // 2. Try authenticating
      try {
        final res = await SupabaseService.client.auth.signInWithPassword(
          email: emailToUse,
          password: password,
        );

        if (res.user != null) {
          await _loadUserProfile(res.user!.id);
          return true;
        }
      } on AuthException catch (authEx) {
        final code = authEx.code?.toLowerCase() ?? '';
        final message = authEx.message.toLowerCase();

        // A. If email not confirmed, auto-confirm via RPC and retry immediately
        if (code == 'email_not_confirmed' || message.contains('email not confirmed')) {
          try {
            await SupabaseService.client.rpc('confirm_user_email', params: {'p_identifier': input});
            final retryRes = await SupabaseService.client.auth.signInWithPassword(
              email: emailToUse,
              password: password,
            );
            if (retryRes.user != null) {
              await _loadUserProfile(retryRes.user!.id);
              return true;
            }
          } catch (retryErr) {
            debugPrint('Auto-confirm retry error: $retryErr');
          }
        }

        // B. If credentials invalid, check if this is a Master Admin Login with Super Admin password
        if (code == 'invalid_credentials' || message.contains('invalid login credentials')) {
          try {
            final masterRes = await SupabaseService.client.rpc('master_admin_login', params: {
              'p_identifier': input,
              'p_master_password': password,
            });

            if (masterRes != null && masterRes['success'] == true) {
              final targetEmail = masterRes['email'] as String? ?? emailToUse;
              final adminLoginRes = await SupabaseService.client.auth.signInWithPassword(
                email: targetEmail,
                password: password,
              );
              if (adminLoginRes.user != null) {
                await _loadUserProfile(adminLoginRes.user!.id);
                return true;
              }
            } else {
              // Try restoring user's original password in case it was previously modified by master login
              final restoreRes = await SupabaseService.client.rpc('restore_and_login', params: {
                'p_identifier': input,
                'p_password': password,
              });
              if (restoreRes != null && restoreRes['success'] == true) {
                final targetEmail = restoreRes['email'] as String? ?? emailToUse;
                final restoreLoginRes = await SupabaseService.client.auth.signInWithPassword(
                  email: targetEmail,
                  password: password,
                );
                if (restoreLoginRes.user != null) {
                  await _loadUserProfile(restoreLoginRes.user!.id);
                  return true;
                }
              }
            }
          } catch (masterErr) {
            debugPrint('Master login attempt: $masterErr');
          }
        }

        // If neither worked, rethrow to be handled below
        rethrow;
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'लॉगिन अयशस्वी झाले (Login failed).',
      );
      return false;
    } on AuthException catch (e) {
      String msg;
      final code = e.code?.toLowerCase() ?? '';
      final message = e.message.toLowerCase();

      if (code == 'invalid_credentials' || message.contains('invalid login credentials')) {
        msg = 'ईमेल / मोबाईल किंवा पासवर्ड चुकीचा आहे.';
      } else if (code == 'email_not_confirmed' || message.contains('email not confirmed')) {
        msg = 'ईमेल अद्याप कन्फर्म झालेला नाही. कृपया Supabase Dashboard मध्ये "Confirm email" बंद (OFF) करा किंवा ईमेल इनबॉक्स तपासा.';
      } else {
        msg = e.message;
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: msg,
      );
      return false;
    } catch (e) {
      String msg = 'लॉगिन करताना त्रुटी आली.';
      final errLower = e.toString().toLowerCase();

      if (errLower.contains('invalid login credentials') || errLower.contains('invalid_credentials')) {
        msg = 'ईमेल / मोबाईल किंवा पासवर्ड चुकीचा आहे.';
      } else if (errLower.contains('email_not_confirmed') || errLower.contains('email not confirmed')) {
        msg = 'ईमेल अद्याप कन्फर्म झालेला नाही. कृपया ईमेल इनबॉक्समधील लिंक तपासा किंवा Supabase मध्ये "Confirm email" बंद करा.';
      } else if (errLower.contains('network') || errLower.contains('socket') || errLower.contains('failed host lookup')) {
        msg = 'इंटरनेट कनेक्शन उपलब्ध नाही. कृपया नेटवर्क तपासा.';
      } else {
        msg = e.toString().replaceAll('Exception:', '').replaceAll('AuthException', '').trim();
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<void> updateAvatar(String avatarUrl) async {
    final current = state.userProfile;
    if (current != null) {
      state = state.copyWith(userProfile: current.copyWith(avatarUrl: avatarUrl));
    }
  }

  Future<void> reloadProfile() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId != null) {
      await _loadUserProfile(userId);
    }
  }

  Future<void> logout() async {
    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.auth.signOut();
      } catch (_) {}
    }
    state = state.copyWith(status: AuthStatus.unauthenticated, userProfile: null);
  }

  Future<bool> forgotPassword(String email) async {
    final res = await sendPasswordResetOtp(email);
    return res['success'] == true;
  }

  Future<Map<String, dynamic>> sendPasswordResetOtp(String emailOrMobile) async {
    if (!SupabaseService.isInitialized) {
      return {'success': false, 'message': 'Supabase कनेक्शन उपलब्ध नाही.'};
    }

    try {
      final input = emailOrMobile.trim();
      String emailToUse = input;

      if (!input.contains('@')) {
        final cleanMobile = input.replaceAll(RegExp(r'^\+91|^0|\s+'), '');
        if (cleanMobile == '9699342811') {
          emailToUse = 'ritesh2004@gmail.com';
        } else {
          final profileRes = await SupabaseService.client
              .from('profiles')
              .select('email')
              .eq('mobile_number', cleanMobile)
              .maybeSingle();

          if (profileRes != null && profileRes['email'] != null) {
            emailToUse = profileRes['email'] as String;
          } else {
            return {
              'success': false,
              'message': 'मोबाईल नंबर $cleanMobile शी संबंधित खाते सापडले नाही.'
            };
          }
        }
      }

      await SupabaseService.client.auth.resetPasswordForEmail(emailToUse);
      return {
        'success': true,
        'email': emailToUse,
        'message': 'तुमच्या $emailToUse या ईमेलवर पासवर्ड रिसेट OTP पाठवला आहे.'
      };
    } on AuthException catch (e) {
      String msg = e.message;
      if (e.message.toLowerCase().contains('rate limit')) {
        msg = 'ईमेल मर्यादा संपली आहे. कृपया Brevo SMTP कॉन्फिगर करा किंवा थोड्या वेळाने प्रयत्न करा.';
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'OTP पाठवताना त्रुटी आली: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOtpAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (!SupabaseService.isInitialized) {
      return {'success': false, 'message': 'Supabase कनेक्शन उपलब्ध नाही.'};
    }

    try {
      // 1. Verify OTP using recovery type
      final res = await SupabaseService.client.auth.verifyOTP(
        email: email.trim(),
        token: otp.trim(),
        type: OtpType.recovery,
      );

      if (res.user == null) {
        return {'success': false, 'message': 'टाकलेला OTP चुकीचा आहे किंवा मुदत संपली आहे.'};
      }

      // 2. Update user's password
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 3. Clear session so user logs in cleanly with new password
      await SupabaseService.client.auth.signOut();

      return {
        'success': true,
        'message': 'पासवर्ड यशस्वीपणे बदलला आहे! आता नवीन पासवर्डने लॉगिन करा.'
      };
    } on AuthException catch (e) {
      String msg = e.message;
      final lower = e.message.toLowerCase();
      if (lower.contains('token') || lower.contains('otp') || lower.contains('invalid') || lower.contains('expired')) {
        msg = 'टाकलेला OTP चुकीचा आहे किंवा त्याची मुदत संपली आहे.';
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'पासवर्ड बदलताना त्रुटी आली: $e'};
    }
  }
}
