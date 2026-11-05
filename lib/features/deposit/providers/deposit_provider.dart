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
      state = state.copyWith(treasurers: [
        {'id': 'treasurer-1', 'full_name': 'सुरेश कदम (खजिनदार)', 'mobile_number': '9890123456'},
        {'id': 'admin-1', 'full_name': 'मुरलीधर पाटील (अध्यक्ष)', 'mobile_number': '9822012345'},
      ]);
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
      final demoRequests = [
        DepositRequest(
          id: 'dep-1',
          requestNumber: 'DEP-2026-0001',
          mandalId: mandalId!,
          collectorId: currentUserId ?? 'user-1',
          designatedTreasurerId: 'treasurer-1',
          amount: 2000.0,
          paymentMode: 'cash',
          requestDate: DateTime.now().subtract(const Duration(days: 3)),
          description: 'पाटील परिवाराची वर्गणी खजिनदाराकडे जमा केली.',
          status: 'approved',
          collectorName: 'मुरलीधर पाटील',
          treasurerName: 'सुरेश कदम (खजिनदार)',
          decisionDate: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        DepositRequest(
          id: 'dep-2',
          requestNumber: 'DEP-2026-0002',
          mandalId: mandalId!,
          collectorId: currentUserId ?? 'user-1',
          designatedTreasurerId: 'treasurer-1',
          amount: 1000.0,
          paymentMode: 'upi',
          requestDate: DateTime.now().subtract(const Duration(days: 1)),
          description: 'देशमुख परिवाराकडून UPI द्वारे मिळालेली रक्कम.',
          status: 'pending',
          collectorName: 'मुरलीधर पाटील',
          treasurerName: 'सुरेश कदम (खजिनदार)',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      state = state.copyWith(requests: demoRequests, isLoading: false);
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
      final user = ref.read(authProvider).userProfile;
      final newReq = DepositRequest(
        id: 'dep-${DateTime.now().millisecondsSinceEpoch}',
        requestNumber: reqNumber,
        mandalId: mandalId!,
        collectorId: currentUserId ?? 'user-1',
        designatedTreasurerId: designatedTreasurerId,
        amount: amount,
        paymentMode: paymentMode,
        requestDate: DateTime.now(),
        description: description,
        status: 'pending',
        collectorName: user?.fullName ?? 'कार्यकर्ता',
        treasurerName: 'सुरेश कदम (खजिनदार)',
        createdAt: DateTime.now(),
      );

      final updated = [newReq, ...state.requests];
      state = state.copyWith(requests: updated, isLoading: false);
      return true;
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
      final updated = state.requests.map((r) {
        if (r.id == requestId) {
          return DepositRequest(
            id: r.id,
            requestNumber: r.requestNumber,
            mandalId: r.mandalId,
            collectorId: r.collectorId,
            designatedTreasurerId: r.designatedTreasurerId,
            amount: r.amount,
            paymentMode: r.paymentMode,
            requestDate: r.requestDate,
            description: r.description,
            status: action,
            decidedBy: currentUserId,
            decisionDate: DateTime.now(),
            rejectionReason: action == 'rejected' ? rejectionReason : null,
            collectorName: r.collectorName,
            treasurerName: r.treasurerName,
            createdAt: r.createdAt,
          );
        }
        return r;
      }).toList();

      state = state.copyWith(requests: updated, isLoading: false);
      ref.read(collectionProvider.notifier).loadCollections();
      return true;
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

