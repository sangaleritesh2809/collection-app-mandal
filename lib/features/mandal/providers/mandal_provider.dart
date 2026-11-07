import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/mandal.dart';

class MandalState {
  final List<Mandal> userMandals;
  final Mandal? selectedMandal;
  final Set<String> userPermissions; // e.g. {'view_dashboard', 'add_collection', 'add_family'}
  final Set<String> userModules; // e.g. {'dashboard', 'collection', 'family', 'deposit', 'expense', 'reports', 'mandal'}
  final bool isLoading;
  final String? error;

  const MandalState({
    this.userMandals = const [],
    this.selectedMandal,
    this.userPermissions = const {},
    this.userModules = const {},
    this.isLoading = false,
    this.error,
  });

  MandalState copyWith({
    List<Mandal>? userMandals,
    Mandal? selectedMandal,
    Set<String>? userPermissions,
    Set<String>? userModules,
    bool? isLoading,
    String? error,
  }) {
    return MandalState(
      userMandals: userMandals ?? this.userMandals,
      selectedMandal: selectedMandal ?? this.selectedMandal,
      userPermissions: userPermissions ?? this.userPermissions,
      userModules: userModules ?? this.userModules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Check whether the current user has access to a specific module
  bool hasModulePermission(String module) {
    if (selectedMandal == null) return false;
    final role = selectedMandal!.userRole ?? '';
    if (role == 'Mandal Admin' || role == 'Super Admin') {
      return true;
    }
    if (userModules.isNotEmpty) {
      return userModules.contains(module);
    }
    // Fallback based on default system roles if dynamic permissions are loading
    return _defaultRoleModules(role).contains(module);
  }

  /// Check whether the current user has a specific granular permission code
  bool hasPermission(String permissionCode) {
    if (selectedMandal == null) return false;
    final role = selectedMandal!.userRole ?? '';
    if (role == 'Mandal Admin' || role == 'Super Admin') {
      return true;
    }
    if (userPermissions.isNotEmpty) {
      return userPermissions.contains(permissionCode);
    }
    return _defaultRolePermissions(role).contains(permissionCode);
  }

  static Set<String> _defaultRoleModules(String? role) {
    switch (role) {
      case 'Mandal Admin':
      case 'Super Admin':
        return {'dashboard', 'mandal', 'family', 'collection', 'deposit', 'expense', 'reports', 'settings'};
      case 'Treasurer':
        return {'dashboard', 'collection', 'deposit', 'expense', 'reports', 'settings'};
      case 'Collector':
        return {'dashboard', 'family', 'collection', 'deposit', 'reports', 'settings'};
      case 'Member':
      default:
        return {'dashboard', 'collection', 'settings'};
    }
  }

  static Set<String> _defaultRolePermissions(String? role) {
    switch (role) {
      case 'Mandal Admin':
      case 'Super Admin':
        return {
          'view_dashboard', 'manage_mandal', 'add_family', 'edit_family', 'delete_family',
          'add_member', 'edit_member', 'view_collection', 'add_collection', 'edit_collection',
          'create_deposit_request', 'approve_deposit_request', 'reject_deposit_request',
          'add_expense', 'approve_expense', 'view_reports', 'export_reports', 'manage_users', 'manage_roles'
        };
      case 'Treasurer':
        return {
          'view_dashboard', 'view_collection', 'add_collection',
          'approve_deposit_request', 'reject_deposit_request',
          'add_expense', 'approve_expense', 'view_reports', 'export_reports'
        };
      case 'Collector':
        return {
          'view_dashboard', 'add_family', 'edit_family', 'add_member',
          'view_collection', 'add_collection', 'create_deposit_request', 'view_reports'
        };
      case 'Member':
      default:
        return {'view_dashboard', 'view_collection'};
    }
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

      final userProfile = authState.userProfile;
      final isSuperAdmin = userProfile?.isSuperAdmin == true ||
          userProfile?.mobileNumber == '9699342811' ||
          userProfile?.email == 'ritesh2004@gmail.com';

      final List<Mandal> mandals = [];

      if (isSuperAdmin) {
        // Super Admin sees ALL mandals in the system!
        final allMandalsRes = await SupabaseService.client
            .from('mandals')
            .select('*')
            .eq('is_active', true)
            .order('created_at', ascending: false);

        for (final item in (allMandalsRes as List)) {
          mandals.add(Mandal.fromJson(item as Map<String, dynamic>, role: 'Super Admin'));
        }
      } else {
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

        for (final item in (res as List)) {
          final mandalData = item['mandal'] as Map<String, dynamic>?;
          final roleData = item['role'] as Map<String, dynamic>?;
          if (mandalData != null) {
            mandals.add(Mandal.fromJson(mandalData, role: roleData?['name'] as String? ?? 'Member'));
          }
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

      if (activeMandal != null) {
        await _loadPermissionsForSelectedMandal(activeMandal.id, userId);
      }
    } catch (e) {
      debugPrint('Error loading mandals: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadPermissionsForSelectedMandal(String mandalId, String userId) async {
    final userProfile = authState.userProfile;
    final isSuperAdmin = userProfile?.isSuperAdmin == true ||
        userProfile?.mobileNumber == '9699342811' ||
        userProfile?.email == 'ritesh2004@gmail.com';

    if (isSuperAdmin) {
      state = state.copyWith(
        userPermissions: {'*'},
        userModules: {'collection', 'expense', 'family', 'deposit', 'report', 'settings'},
      );
      return;
    }

    try {
      final membership = await SupabaseService.client
          .from('mandal_memberships')
          .select('role_id, role:roles (name)')
          .eq('mandal_id', mandalId)
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (membership != null && membership['role_id'] != null) {
        final roleId = membership['role_id'] as String;
        final permsRes = await SupabaseService.client
            .from('role_permissions')
            .select('permission:permissions (code, module)')
            .eq('role_id', roleId);

        final Set<String> perms = {};
        final Set<String> modules = {};
        for (final p in (permsRes as List)) {
          final pMap = p['permission'] as Map<String, dynamic>?;
          if (pMap != null) {
            final code = pMap['code'] as String?;
            final mod = pMap['module'] as String?;
            if (code != null) perms.add(code);
            if (mod != null) modules.add(mod);
          }
        }

        state = state.copyWith(
          userPermissions: perms,
          userModules: modules,
        );
      }
    } catch (e) {
      debugPrint('Error loading dynamic permissions: $e');
    }
  }

  Future<void> selectMandal(Mandal mandal) async {
    state = state.copyWith(selectedMandal: mandal);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_mandal_id', mandal.id);
    } catch (_) {}

    final userId = SupabaseService.currentUserId;
    if (userId != null) {
      await _loadPermissionsForSelectedMandal(mandal.id, userId);
    }
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

      final mandalCode = await _generateUnique8CharMandalCode();
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
      if (userId == null) throw Exception('वापरकर्ता लॉगिन नाही.');

      final cleanCode = invitationCode.trim().toUpperCase();
      if (cleanCode.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'कृपया आमंत्रण कोड टाका.');
        return false;
      }

      // 1. Find mandal by invitation code
      final mandalRes = await SupabaseService.client
          .from('mandals')
          .select('id, name')
          .eq('invitation_code', cleanCode)
          .maybeSingle();

      if (mandalRes == null) {
        state = state.copyWith(isLoading: false, error: 'अवैध आमंत्रण कोड. कृपया योग्य कोड टाका.');
        return false;
      }

      final mandalId = mandalRes['id'] as String;

      // 2. Fetch default 'Member' role for new invite-code joins
      final roleRes = await SupabaseService.client
          .from('roles')
          .select('id')
          .eq('name', 'Member')
          .maybeSingle();

      final roleId = roleRes?['id'] as String?;
      if (roleId == null) throw Exception('डीफॉल्ट रोल आढळला नाही.');

      // 3. Check if membership already exists
      final existing = await SupabaseService.client
          .from('mandal_memberships')
          .select('id, status, role_id')
          .eq('mandal_id', mandalId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // If already exists, activate status without overwriting existing role
        await SupabaseService.client
            .from('mandal_memberships')
            .update({'status': 'active'})
            .eq('id', existing['id']);
      } else {
        await SupabaseService.client.from('mandal_memberships').insert({
          'mandal_id': mandalId,
          'user_id': userId,
          'role_id': roleId,
          'status': 'active',
        });
      }

      // 4. Save newly joined mandal as last selected mandal
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_mandal_id', mandalId);

      // 5. Reload user mandals
      await loadUserMandals();

      // 6. Explicitly select the newly joined mandal so user immediately enters it
      final newlyJoined = state.userMandals.where((m) => m.id == mandalId).firstOrNull ??
          (state.userMandals.isNotEmpty ? state.userMandals.first : null);
      if (newlyJoined != null) {
        await selectMandal(newlyJoined);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint('Error joining mandal: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateMandalPaymentQr({
    required String mandalId,
    String? upiId,
    String? upiPayeeName,
    String? qrCodeUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final payload = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (upiId != null) payload['upi_id'] = upiId.trim();
      if (upiPayeeName != null) payload['upi_payee_name'] = upiPayeeName.trim();
      if (qrCodeUrl != null) payload['qr_code_url'] = qrCodeUrl.trim();

      await SupabaseService.client
          .from('mandals')
          .update(payload)
          .eq('id', mandalId);

      if (state.selectedMandal != null && state.selectedMandal!.id == mandalId) {
        final updated = state.selectedMandal!.copyWith(
          upiId: upiId ?? state.selectedMandal!.upiId,
          upiPayeeName: upiPayeeName ?? state.selectedMandal!.upiPayeeName,
          qrCodeUrl: qrCodeUrl ?? state.selectedMandal!.qrCodeUrl,
        );
        state = state.copyWith(selectedMandal: updated, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      debugPrint('Error updating mandal payment QR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<String> _generateUnique8CharMandalCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 32 chars, no ambiguous I, O, 1, 0
    final rand = Random.secure();
    for (int attempt = 0; attempt < 10; attempt++) {
      final randomPart = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
      final candidate = 'VG$randomPart'; // Always exactly 8 characters

      try {
        final existing = await SupabaseService.client
            .from('mandals')
            .select('id')
            .eq('invitation_code', candidate)
            .maybeSingle();

        if (existing == null) {
          return candidate;
        }
      } catch (_) {
        return candidate;
      }
    }
    final fallback = 'VG${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase().padLeft(6, 'X').substring(0, 6)}';
    return fallback;
  }
}
