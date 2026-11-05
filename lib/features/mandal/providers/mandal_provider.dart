import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/mandal.dart';

class MandalState {
  final List<Mandal> userMandals;
  final Mandal? selectedMandal;
  final bool isLoading;
  final String? error;

  const MandalState({
    this.userMandals = const [],
    this.selectedMandal,
    this.isLoading = false,
    this.error,
  });

  MandalState copyWith({
    List<Mandal>? userMandals,
    Mandal? selectedMandal,
    bool? isLoading,
    String? error,
  }) {
    return MandalState(
      userMandals: userMandals ?? this.userMandals,
      selectedMandal: selectedMandal ?? this.selectedMandal,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final mandalProvider = StateNotifierProvider<MandalNotifier, MandalState>((ref) {
  final auth = ref.watch(authProvider);
  return MandalNotifier(auth);
});

class MandalNotifier extends StateNotifier<MandalState> {
  final AuthState authState;

  MandalNotifier(this.authState) : super(const MandalState()) {
    if (authState.status == AuthStatus.authenticated) {
      loadUserMandals();
    }
  }

  Future<void> loadUserMandals() async {
    state = state.copyWith(isLoading: true, error: null);

    if (!SupabaseService.isInitialized) {
      state = state.copyWith(userMandals: [], selectedMandal: null, isLoading: false);
      return;
    }

    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Query memberships with joined mandal and role details
      final res = await SupabaseService.client
          .from('mandal_memberships')
          .select('''
            id,
            status,
            mandal:mandals (*),
            role:roles (name)
          ''')
          .eq('user_id', userId)
          .eq('status', 'active');

      final List<Mandal> mandals = [];
      for (final item in (res as List)) {
        final mandalData = item['mandal'] as Map<String, dynamic>?;
        final roleData = item['role'] as Map<String, dynamic>?;
        if (mandalData != null) {
          mandals.add(Mandal.fromJson(mandalData, role: roleData?['name'] as String? ?? 'Member'));
        }
      }

      // Restore previously saved selected mandal if available
      final prefs = await SharedPreferences.getInstance();
      final lastMandalId = prefs.getString('last_selected_mandal_id');
      Mandal? activeMandal;

      if (mandals.isNotEmpty) {
        if (lastMandalId != null) {
          activeMandal = mandals.firstWhere(
            (m) => m.id == lastMandalId,
            orElse: () => mandals.first,
          );
        } else {
          activeMandal = mandals.first;
        }
      }

      state = state.copyWith(
        userMandals: mandals,
        selectedMandal: activeMandal,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading mandals: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectMandal(Mandal mandal) async {
    state = state.copyWith(selectedMandal: mandal);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_mandal_id', mandal.id);
    } catch (_) {}
  }

  Future<bool> createMandal({
    required String name,
    String? description,
    String? address,
    String? village,
    String? taluka,
    String? district,
    String? contactNumber,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    if (!SupabaseService.isInitialized) {
      state = state.copyWith(isLoading: false, error: 'Supabase कनेक्शन उपलब्ध नाही.');
      return false;
    }

    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      final mandalCode = 'VG${DateTime.now().year}${DateTime.now().millisecond}';
      final mandalIdStr = 'MD-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';

      // 1. Insert Mandal
      final mandalRes = await SupabaseService.client.from('mandals').insert({
        'mandal_id': mandalIdStr,
        'name': name,
        'description': description,
        'address': address,
        'village': village,
        'taluka': taluka,
        'district': district,
        'contact_number': contactNumber,
        'email': email,
        'invitation_code': mandalCode,
        'created_by': userId,
      }).select().single();

      final mandalId = mandalRes['id'] as String;

      // 2. Fetch 'Mandal Admin' role
      final roleRes = await SupabaseService.client
          .from('roles')
          .select('id')
          .eq('name', 'Mandal Admin')
          .limit(1)
          .maybeSingle();

      String? roleId = roleRes?['id'] as String?;

      // 3. Link creator as Mandal Admin in mandal_memberships
      if (roleId != null) {
        await SupabaseService.client.from('mandal_memberships').insert({
          'mandal_id': mandalId,
          'user_id': userId,
          'role_id': roleId,
          'status': 'active',
        });
      }

      // 4. Create default Vargani configuration for the new mandal
      await SupabaseService.client.from('vargani_configs').insert({
        'mandal_id': mandalId,
        'name': '$name वर्गणी ${DateTime.now().year}',
        'financial_year': '${DateTime.now().year}-${DateTime.now().year + 1}',
        'calculation_type': 'per_member',
        'per_member_amount': 500.00,
        'is_active': true,
      });

      await loadUserMandals();
      return true;
    } catch (e) {
      debugPrint('Error creating mandal: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> joinMandal(String invitationCode) async {
    state = state.copyWith(isLoading: true, error: null);

    if (!SupabaseService.isInitialized) {
      state = state.copyWith(isLoading: false);
      return true;
    }

    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      // Find mandal by code
      final mandalRes = await SupabaseService.client
          .from('mandals')
          .select('id, name')
          .eq('invitation_code', invitationCode.trim().toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (mandalRes == null) {
        state = state.copyWith(isLoading: false, error: 'अवैध आमंत्रण कोड (Invalid Invitation Code)');
        return false;
      }

      final mandalId = mandalRes['id'] as String;

      // Check if already a member
      final existing = await SupabaseService.client
          .from('mandal_memberships')
          .select('id')
          .eq('mandal_id', mandalId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        state = state.copyWith(isLoading: false, error: 'तुम्ही आधीच या मंडळाचे सदस्य आहात.');
        return false;
      }

      // Default role as 'Member' or 'Collector'
      final roleRes = await SupabaseService.client
          .from('roles')
          .select('id')
          .eq('name', 'Member')
          .limit(1)
          .maybeSingle();

      final roleId = roleRes?['id'] as String;

      await SupabaseService.client.from('mandal_memberships').insert({
        'mandal_id': mandalId,
        'user_id': userId,
        'role_id': roleId,
        'status': 'active',
      });

      await loadUserMandals();
      return true;
    } catch (e) {
      debugPrint('Error joining mandal: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

