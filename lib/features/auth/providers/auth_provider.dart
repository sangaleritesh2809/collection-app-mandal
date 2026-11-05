import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  }) {
    return AuthState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage,
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
        final profile = UserProfile.fromJson(res);
        state = state.copyWith(status: AuthStatus.authenticated, userProfile: profile);
      } else {
        // Fallback profile if row is not populated yet
        final user = SupabaseService.client.auth.currentUser;
        final profile = UserProfile(
          id: userId,
          fullName: user?.userMetadata?['full_name'] ?? 'User',
          email: user?.email,
          mobileNumber: user?.userMetadata?['mobile_number'],
          createdAt: DateTime.now(),
        );
        state = state.copyWith(status: AuthStatus.authenticated, userProfile: profile);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      final user = SupabaseService.client.auth.currentUser;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        userProfile: UserProfile(
          id: userId,
          fullName: user?.userMetadata?['full_name'] ?? user?.email?.split('@').first ?? 'User',
          email: user?.email,
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

    try {
      final res = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'mobile_number': mobileNumber,
        },
      );

      if (res.user != null) {
        // Create or update public.profiles
        try {
          await SupabaseService.client.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': fullName,
            'email': email,
            'mobile_number': mobileNumber,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}

        await _loadUserProfile(res.user!.id);
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Registration failed. Please try again.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception:', ''),
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

    try {
      String emailToUse = emailOrMobile;

      // If mobile number entered, look up associated email securely or sign in
      if (!emailOrMobile.contains('@')) {
        final profileRes = await SupabaseService.client
            .from('profiles')
            .select('email')
            .eq('mobile_number', emailOrMobile)
            .maybeSingle();

        if (profileRes != null && profileRes['email'] != null) {
          emailToUse = profileRes['email'] as String;
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'या मोबाईल नंबरशी संबंधित खाते सापडले नाही (No account found for this mobile number).',
          );
          return false;
        }
      }

      final res = await SupabaseService.client.auth.signInWithPassword(
        email: emailToUse,
        password: password,
      );

      if (res.user != null) {
        await _loadUserProfile(res.user!.id);
        return true;
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'लॉगिन अयशस्वी (Login failed)',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception:', ''),
      );
      return false;
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
    if (!SupabaseService.isInitialized) return true;
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}
