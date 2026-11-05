import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import '../../../core/services/supabase_service.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../../vargani_config/providers/vargani_config_provider.dart';
import '../models/family.dart';
import '../models/family_member.dart';

class FamilyState {
  final List<Family> families;
  final List<Family> filteredFamilies;
  final Map<String, List<FamilyMember>> membersCache;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String filterType; // 'all', 'unpaid', 'partially_paid', 'fully_paid'

  const FamilyState({
    this.families = const [],
    this.filteredFamilies = const [],
    this.membersCache = const {},
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.filterType = 'all',
  });

  FamilyState copyWith({
    List<Family>? families,
    List<Family>? filteredFamilies,
    Map<String, List<FamilyMember>>? membersCache,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? filterType,
  }) {
    return FamilyState(
      families: families ?? this.families,
      filteredFamilies: filteredFamilies ?? this.filteredFamilies,
      membersCache: membersCache ?? this.membersCache,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      filterType: filterType ?? this.filterType,
    );
  }
}

final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  final mandalState = ref.watch(mandalProvider);
  final configState = ref.watch(varganiConfigProvider);
  return FamilyNotifier(mandalState.selectedMandal?.id, configState.activeConfig?.id, configState.activeConfig?.perMemberAmount ?? 500.0);
});

class FamilyNotifier extends StateNotifier<FamilyState> {
  final String? mandalId;
  final String? activeConfigId;
  final double perMemberRate;

  FamilyNotifier(this.mandalId, this.activeConfigId, this.perMemberRate) : super(const FamilyState()) {
    if (mandalId != null) {
      loadFamilies();
    }
  }

  void _applyFilter() {
    var result = List<Family>.from(state.families);

    // Filter by payment status
    if (state.filterType == 'unpaid') {
      result = result.where((f) => f.isUnpaid).toList();
    } else if (state.filterType == 'partially_paid') {
      result = result.where((f) => f.isPartiallyPaid).toList();
    } else if (state.filterType == 'fully_paid') {
      result = result.where((f) => f.isFullyPaid).toList();
    }

    // Search by name, head name, or code
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      result = result.where((f) =>
        f.familyName.toLowerCase().contains(q) ||
        f.familyHeadName.toLowerCase().contains(q) ||
        f.familyCode.toLowerCase().contains(q) ||
        (f.mobileNumber != null && f.mobileNumber!.contains(q))
      ).toList();
    }

    state = state.copyWith(filteredFamilies: result);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilter();
  }

  void setFilterType(String type) {
    state = state.copyWith(filterType: type);
    _applyFilter();
  }

  Future<void> loadFamilies() async {
    if (mandalId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    if (!SupabaseService.isInitialized) {
      // Demo fallback families for instant preview
      final demoFamilies = [
        Family(
          id: 'fam-1',
          mandalId: mandalId!,
          familyCode: 'FAM-001',
          familyName: 'पाटील परिवार',
          familyHeadName: 'रविंद्र गणपत पाटील',
          houseNumber: '१२/अ',
          address: 'शिवाजी चौक',
          village: 'वडगाव',
          mobileNumber: '9822012345',
          totalMembers: 4,
          totalVargani: 2000.0,
          paidAmount: 2000.0,
          pendingAmount: 0.0,
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        Family(
          id: 'fam-2',
          mandalId: mandalId!,
          familyCode: 'FAM-002',
          familyName: 'देशमुख परिवार',
          familyHeadName: 'आनंदराव बापूसाहेब देशमुख',
          houseNumber: '४५',
          address: 'गणेश गल्ली',
          village: 'वडगाव',
          mobileNumber: '9822054321',
          totalMembers: 5,
          totalVargani: 2500.0,
          paidAmount: 1000.0,
          pendingAmount: 1500.0,
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 18)),
        ),
        Family(
          id: 'fam-3',
          mandalId: mandalId!,
          familyCode: 'FAM-003',
          familyName: 'शिंदे परिवार',
          familyHeadName: 'तानाजी विठोबा शिंदे',
          houseNumber: '७८',
          address: 'मारुती मंदिराजवळ',
          village: 'वडगाव',
          mobileNumber: '9422098765',
          totalMembers: 3,
          totalVargani: 1500.0,
          paidAmount: 0.0,
          pendingAmount: 1500.0,
          status: 'active',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];

      state = state.copyWith(
        families: demoFamilies,
        filteredFamilies: demoFamilies,
        isLoading: false,
      );
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('families')
          .select()
          .eq('mandal_id', mandalId!)
          .eq('status', 'active')
          .order('family_code', ascending: true);

      final list = (res as List).map((e) => Family.fromJson(e)).toList();
      state = state.copyWith(families: list, isLoading: false);
      _applyFilter();
    } catch (e) {
      debugPrint('Error loading families: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<FamilyMember>> loadMembersForFamily(String familyId) async {
    if (state.membersCache.containsKey(familyId)) {
      return state.membersCache[familyId]!;
    }

    if (!SupabaseService.isInitialized) {
      final demoMembers = [
        FamilyMember(
          id: 'mem-1',
          familyId: familyId,
          mandalId: mandalId ?? '',
          memberName: 'कुटुंब प्रमुख (Head)',
          age: 48,
          gender: 'Male',
          status: 'active',
          createdAt: DateTime.now(),
        ),
        FamilyMember(
          id: 'mem-2',
          familyId: familyId,
          mandalId: mandalId ?? '',
          memberName: 'सौ. पत्नी',
          age: 44,
          gender: 'Female',
          status: 'active',
          createdAt: DateTime.now(),
        ),
      ];
      final newCache = Map<String, List<FamilyMember>>.from(state.membersCache);
      newCache[familyId] = demoMembers;
      state = state.copyWith(membersCache: newCache);
      return demoMembers;
    }

    try {
      final res = await SupabaseService.client
          .from('family_members')
          .select()
          .eq('family_id', familyId)
          .eq('status', 'active')
          .order('created_at', ascending: true);

      final members = (res as List).map((e) => FamilyMember.fromJson(e)).toList();
      final newCache = Map<String, List<FamilyMember>>.from(state.membersCache);
      newCache[familyId] = members;
      state = state.copyWith(membersCache: newCache);
      return members;
    } catch (e) {
      debugPrint('Error loading family members: $e');
      return [];
    }
  }

  Future<bool> addFamily({
    required String familyName,
    required String familyHeadName,
    String? houseNumber,
    String? address,
    String? village,
    String? mobileNumber,
    int initialMembersCount = 1,
    double? customTotalVargani,
  }) async {
    if (mandalId == null) return false;
    state = state.copyWith(isLoading: true, error: null);

    final expectedVargani = customTotalVargani ?? (initialMembersCount * perMemberRate);

    if (!SupabaseService.isInitialized) {
      final newFamily = Family(
        id: 'fam-${DateTime.now().millisecondsSinceEpoch}',
        mandalId: mandalId!,
        familyCode: 'FAM-${(state.families.length + 1).toString().padLeft(3, '0')}',
        familyName: familyName,
        familyHeadName: familyHeadName,
        houseNumber: houseNumber,
        address: address,
        village: village,
        mobileNumber: mobileNumber,
        totalMembers: initialMembersCount,
        totalVargani: expectedVargani,
        paidAmount: 0.0,
        pendingAmount: expectedVargani,
        status: 'active',
        createdAt: DateTime.now(),
      );
      final updatedList = [...state.families, newFamily];
      state = state.copyWith(families: updatedList, isLoading: false);
      _applyFilter();
      return true;
    }

    try {
      final code = 'FAM-${(state.families.length + 1).toString().padLeft(3, '0')}';

      final res = await SupabaseService.client.from('families').insert({
        'mandal_id': mandalId,
        'family_code': code,
        'family_name': familyName,
        'family_head_name': familyHeadName,
        'house_number': houseNumber,
        'address': address,
        'village': village,
        'mobile_number': mobileNumber,
        'total_members': initialMembersCount,
        'vargani_config_id': activeConfigId,
        'total_vargani': expectedVargani,
        'paid_amount': 0.0,
        'pending_amount': expectedVargani,
        'status': 'active',
      }).select().single();

      final familyId = res['id'] as String;

      // Add Head as first family member
      await SupabaseService.client.from('family_members').insert({
        'family_id': familyId,
        'mandal_id': mandalId,
        'member_name': familyHeadName,
        'mobile_number': mobileNumber,
        'status': 'active',
      });

      await loadFamilies();
      return true;
    } catch (e) {
      debugPrint('Error adding family: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> addMemberToFamily({
    required String familyId,
    required String memberName,
    String? mobileNumber,
    int? age,
    String? gender,
  }) async {
    if (mandalId == null) return false;

    if (!SupabaseService.isInitialized) {
      final newMember = FamilyMember(
        id: 'mem-${DateTime.now().millisecondsSinceEpoch}',
        familyId: familyId,
        mandalId: mandalId!,
        memberName: memberName,
        mobileNumber: mobileNumber,
        age: age,
        gender: gender,
        status: 'active',
        createdAt: DateTime.now(),
      );
      final currentList = state.membersCache[familyId] ?? [];
      final newCache = Map<String, List<FamilyMember>>.from(state.membersCache);
      newCache[familyId] = [...currentList, newMember];
      state = state.copyWith(membersCache: newCache);
      return true;
    }

    try {
      await SupabaseService.client.from('family_members').insert({
        'family_id': familyId,
        'mandal_id': mandalId,
        'member_name': memberName,
        'mobile_number': mobileNumber,
        'age': age,
        'gender': gender,
        'status': 'active',
      });

      // Clear cache and reload
      final newCache = Map<String, List<FamilyMember>>.from(state.membersCache);
      newCache.remove(familyId);
      state = state.copyWith(membersCache: newCache);

      await loadMembersForFamily(familyId);
      await loadFamilies();
      return true;
    } catch (e) {
      debugPrint('Error adding member: $e');
      return false;
    }
  }

  Future<bool> archiveMember({
    required String familyId,
    required String memberId,
  }) async {
    if (!SupabaseService.isInitialized) return true;

    try {
      // Safe archival process
      await SupabaseService.client.from('family_members').update({
        'status': 'archived',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', memberId);

      final newCache = Map<String, List<FamilyMember>>.from(state.membersCache);
      newCache.remove(familyId);
      state = state.copyWith(membersCache: newCache);

      await loadMembersForFamily(familyId);
      await loadFamilies();
      return true;
    } catch (e) {
      debugPrint('Error archiving member: $e');
      return false;
    }
  }
}
