import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../../collection/providers/collection_provider.dart';
import '../models/deposit_request.dart';

class DepositState {
  final List<DepositRequest> requests;
  final List<Map<String, dynamic>> treasurers;
  final bool isLoading;
  final String? error;

  const DepositState({
    this.requests = const [],
    this.treasurers = const [],
    this.isLoading = false,
    this.error,
  });

  DepositState copyWith({
    List<DepositRequest>? requests,
    List<Map<String, dynamic>>? treasurers,
    bool? isLoading,
    String? error,
  }) {
    return DepositState(
      requests: requests ?? this.requests,
      treasurers: treasurers ?? this.treasurers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<DepositRequest> get pendingRequests => requests.where((r) => r.isPending).toList();
  List<DepositRequest> get approvedRequests => requests.where((r) => r.isApproved).toList();
  List<DepositRequest> get rejectedRequests => requests.where((r) => r.isRejected).toList();

  double get totalDeposited => approvedRequests.fold(0.0, (sum, r) => sum + r.amount);
  double get totalPendingDeposit => pendingRequests.fold(0.0, (sum, r) => sum + r.amount);
}

final depositProvider = StateNotifierProvider<DepositNotifier, DepositState>((ref) {
  final mandalState = ref.watch(mandalProvider);
  final authState = ref.watch(authProvider);
  return DepositNotifier(ref, mandalState.selectedMandal?.id, authState.userProfile?.id);
});

class DepositNotifier extends StateNotifier<DepositState> {
  final Ref ref;
  final String? mandalId;
  final String? currentUserId;

  DepositNotifier(this.ref, this.mandalId, this.currentUserId) : super(const DepositState()) {
    if (mandalId != null) {
      loadDepositRequests();
      loadTreasurers();
    }
  }

  Future<void> loadTreasurers() async {
    if (mandalId == null) return;

    if (!SupabaseService.isInitialized) {
      state = state.copyWith(treasurers: []);
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('mandal_memberships')
          .select('''
            user:profiles (id, full_name, mobile_number),
            role:roles (name)
          ''')
          .eq('mandal_id', mandalId!)
          .eq('status', 'active');

      final List<Map<String, dynamic>> list = [];
      for (final item in (res as List)) {
        final userData = item['user'] as Map<String, dynamic>?;
        final roleData = item['role'] as Map<String, dynamic>?;
        if (userData != null) {
          list.add({
            'id': userData['id'],
            'full_name': '${userData['full_name']} (${roleData?['name'] ?? 'सदस्य'})',
            'mobile_number': userData['mobile_number'],
          });
        }
      }
      state = state.copyWith(treasurers: list);
    } catch (e) {
      debugPrint('Error loading treasurers: $e');
    }
  }

  Future<void> loadDepositRequests() async {
    if (mandalId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    if (!SupabaseService.isInitialized) {
      state = state.copyWith(requests: [], isLoading: false);
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('deposit_requests')
          .select('''
            *,
            collector:profiles!collector_id (full_name),
            treasurer:profiles!designated_treasurer_id (full_name)
          ''')
          .eq('mandal_id', mandalId!)
          .order('created_at', ascending: false);

      final list = (res as List).map((e) => DepositRequest.fromJson(e)).toList();
      state = state.copyWith(requests: list, isLoading: false);
    } catch (e) {
      debugPrint('Error loading deposit requests: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createDepositRequest({
    required String designatedTreasurerId,
    required double amount,
    required String paymentMode,
    String? description,
  }) async {
    if (mandalId == null) return false;
    state = state.copyWith(isLoading: true, error: null);

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final reqNumber = 'DEP-${DateTime.now().year}-$timestamp';

    if (!SupabaseService.isInitialized) {
      state = state.copyWith(isLoading: false, error: 'डेटाबेस कनेक्शन उपलब्ध नाही');
      return false;
    }

    try {
      final userId = SupabaseService.currentUserId ?? currentUserId;
      if (userId == null) throw Exception('User not logged in');

      await SupabaseService.client.from('deposit_requests').insert({
        'request_number': reqNumber,
        'mandal_id': mandalId,
        'collector_id': userId,
        'designated_treasurer_id': designatedTreasurerId,
        'amount': amount,
        'payment_mode': paymentMode,
        'request_date': DateTime.now().toIso8601String().substring(0, 10),
        'description': description,
        'status': 'pending',
      });

      await loadDepositRequests();
      return true;
    } catch (e) {
      debugPrint('Error creating deposit request: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> processRequest({
    required String requestId,
    required String action, // 'approved' or 'rejected'
    String? rejectionReason,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    if (!SupabaseService.isInitialized) {
      state = state.copyWith(isLoading: false, error: 'डेटाबेस कनेक्शन उपलब्ध नाही');
      return false;
    }

    try {
      // Call atomic PostgreSQL RPC function
      await SupabaseService.client.rpc('process_deposit_request', params: {
        'p_request_id': requestId,
        'p_action': action,
        'p_rejection_reason': rejectionReason,
      });

      await loadDepositRequests();
      ref.read(collectionProvider.notifier).loadCollections();
      return true;
    } catch (e) {
      debugPrint('Error processing deposit request: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

