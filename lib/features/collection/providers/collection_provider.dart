import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../../family/providers/family_provider.dart';
import '../models/collection.dart';

class CollectionState {
  final List<CollectionRecord> collections;
  final bool isLoading;
  final String? error;
  final PdfReceiptData? lastGeneratedReceipt;

  const CollectionState({
    this.collections = const [],
    this.isLoading = false,
    this.error,
    this.lastGeneratedReceipt,
  });

  CollectionState copyWith({
    List<CollectionRecord>? collections,
    bool? isLoading,
    String? error,
    PdfReceiptData? lastGeneratedReceipt,
  }) {
    return CollectionState(
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastGeneratedReceipt: lastGeneratedReceipt ?? this.lastGeneratedReceipt,
    );
  }

  double get totalCollected => collections.fold(0.0, (sum, c) => sum + c.amount);
  double get undepositedAmount => collections.where((c) => !c.isDeposited).fold(0.0, (sum, c) => sum + c.amount);
}

final collectionProvider = StateNotifierProvider<CollectionNotifier, CollectionState>((ref) {
  final mandalState = ref.watch(mandalProvider);
  final authState = ref.watch(authProvider);
  return CollectionNotifier(ref, mandalState.selectedMandal?.id, authState.userProfile?.id);
});

class CollectionNotifier extends StateNotifier<CollectionState> {
  final Ref ref;
  final String? mandalId;
  final String? currentUserId;

  CollectionNotifier(this.ref, this.mandalId, this.currentUserId) : super(const CollectionState()) {
    if (mandalId != null) {
      loadCollections();
    }
  }

  Future<void> loadCollections() async {
    if (mandalId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    if (!SupabaseService.isInitialized) {
      final demoCollections = [
        CollectionRecord(
          id: 'coll-1',
          mandalId: mandalId!,
          familyId: 'fam-1',
          collectorId: currentUserId ?? 'user-1',
          transactionNumber: 'TXN-2026-000101',
          receiptNumber: 'RCT-2026-000101',
          amount: 2000.0,
          paymentMode: 'cash',
          collectionDate: DateTime.now().subtract(const Duration(days: 3)),
          familyName: 'पाटील परिवार',
          familyHeadName: 'रविंद्र गणपत पाटील',
          collectorName: 'मुरलीधर पाटील (कार्यकर्ता)',
          isDeposited: true,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        CollectionRecord(
          id: 'coll-2',
          mandalId: mandalId!,
          familyId: 'fam-2',
          collectorId: currentUserId ?? 'user-1',
          transactionNumber: 'TXN-2026-000102',
          receiptNumber: 'RCT-2026-000102',
          amount: 1000.0,
          paymentMode: 'upi',
          collectionDate: DateTime.now().subtract(const Duration(days: 1)),
          familyName: 'देशमुख परिवार',
          familyHeadName: 'आनंदराव बापूसाहेब देशमुख',
          collectorName: 'मुरलीधर पाटील (कार्यकर्ता)',
          isDeposited: false,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      state = state.copyWith(collections: demoCollections, isLoading: false);
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('collections')
          .select('''
            *,
            family:families (family_name, family_head_name),
            collector:profiles (full_name)
          ''')
          .eq('mandal_id', mandalId!)
          .order('collection_date', ascending: false)
          .order('created_at', ascending: false);

      final list = (res as List).map((e) => CollectionRecord.fromJson(e)).toList();
      state = state.copyWith(collections: list, isLoading: false);
    } catch (e) {
      debugPrint('Error loading collections: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<PdfReceiptData?> submitCollection({
    required String familyId,
    required double amount,
    required String paymentMode,
    required DateTime collectionDate,
    String? notes,
    required String familyName,
    required String familyHeadName,
    String? houseNumber,
    String? mobileNumber,
    required int totalMembers,
    required double totalVargani,
    required double previousPaid,
  }) async {
    if (mandalId == null) return null;
    state = state.copyWith(isLoading: true, error: null);

    final mandal = ref.read(mandalProvider).selectedMandal;
    final userProfile = ref.read(authProvider).userProfile;
    final collectorName = userProfile?.fullName ?? 'कार्यकर्ता';

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final txnNumber = 'TXN-${DateTime.now().year}-$timestamp';
    final rctNumber = 'RCT-${DateTime.now().year}-$timestamp';

    final receiptData = PdfReceiptData(
      mandalName: mandal?.name ?? 'वर्गणी मंडळ',
      mandalAddress: mandal?.address ?? (mandal?.village != null ? '${mandal?.village}, ${mandal?.district}' : null),
      mandalContact: mandal?.contactNumber,
      receiptNumber: rctNumber,
      transactionNumber: txnNumber,
      date: collectionDate,
      familyName: familyName,
      familyHead: familyHeadName,
      houseNumber: houseNumber,
      mobile: mobileNumber,
      totalMembers: totalMembers,
      amountPaid: amount,
      totalVargani: totalVargani,
      pendingAmount: (totalVargani - (previousPaid + amount)).clamp(0.0, double.infinity),
      paymentMode: paymentMode,
      collectorName: collectorName,
      notes: notes,
    );

    if (!SupabaseService.isInitialized) {
      final newRecord = CollectionRecord(
        id: 'coll-${DateTime.now().millisecondsSinceEpoch}',
        mandalId: mandalId!,
        familyId: familyId,
        collectorId: currentUserId ?? 'demo-user',
        transactionNumber: txnNumber,
        receiptNumber: rctNumber,
        amount: amount,
        paymentMode: paymentMode,
        collectionDate: collectionDate,
        notes: notes,
        familyName: familyName,
        familyHeadName: familyHeadName,
        collectorName: collectorName,
        isDeposited: false,
        createdAt: DateTime.now(),
      );

      final updated = [newRecord, ...state.collections];
      state = state.copyWith(
        collections: updated,
        isLoading: false,
        lastGeneratedReceipt: receiptData,
      );

      // Refresh families
      ref.read(familyProvider.notifier).loadFamilies();
      return receiptData;
    }

    try {
      final userId = SupabaseService.currentUserId ?? currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await SupabaseService.client.from('collections').insert({
        'mandal_id': mandalId,
        'family_id': familyId,
        'collector_id': userId,
        'transaction_number': txnNumber,
        'receipt_number': rctNumber,
        'amount': amount,
        'payment_mode': paymentMode,
        'collection_date': collectionDate.toIso8601String().substring(0, 10),
        'notes': notes,
        'is_deposited': false,
      });

      // Insert audit log
      await SupabaseService.client.from('audit_logs').insert({
        'mandal_id': mandalId,
        'user_id': userId,
        'action': 'COLLECTION_ADDED',
        'module': 'collection',
        'details': {
          'receipt_number': rctNumber,
          'amount': amount,
          'family_id': familyId,
        },
      });

      await loadCollections();
      ref.read(familyProvider.notifier).loadFamilies();

      state = state.copyWith(lastGeneratedReceipt: receiptData);
      return receiptData;
    } catch (e) {
      debugPrint('Error submitting collection: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

