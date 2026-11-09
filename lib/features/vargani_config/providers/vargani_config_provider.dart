import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../models/vargani_config.dart';

class VarganiConfigState {
  final List<VarganiConfig> configs;
  final VarganiConfig? activeConfig;
  final bool isLoading;
  final String? error;

  const VarganiConfigState({
    this.configs = const [],
    this.activeConfig,
    this.isLoading = false,
    this.error,
  });

  VarganiConfigState copyWith({
    List<VarganiConfig>? configs,
    VarganiConfig? activeConfig,
    bool? isLoading,
    String? error,
  }) {
    return VarganiConfigState(
      configs: configs ?? this.configs,
      activeConfig: activeConfig ?? this.activeConfig,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final varganiConfigProvider = StateNotifierProvider<VarganiConfigNotifier, VarganiConfigState>((ref) {
  final mandalState = ref.watch(mandalProvider);
  return VarganiConfigNotifier(ref, mandalState.selectedMandal?.id);
});

class VarganiConfigNotifier extends StateNotifier<VarganiConfigState> {
  final Ref ref;
  final String? mandalId;

  VarganiConfigNotifier(this.ref, this.mandalId) : super(const VarganiConfigState()) {
    if (mandalId != null) {
      loadConfigs();
    }
  }

  Future<void> loadConfigs() async {
    if (mandalId == null) {
      state = const VarganiConfigState();
      return;
    }
    state = state.copyWith(isLoading: true, error: null);

    if (!SupabaseService.isInitialized) {
      state = state.copyWith(configs: [], activeConfig: null, isLoading: false);
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('vargani_configs')
          .select()
          .eq('mandal_id', mandalId!)
          .order('created_at', ascending: false);

      List<VarganiConfig> list = (res as List).map((e) => VarganiConfig.fromJson(e)).toList();

      // If this mandal does not have any vargani config yet, create a default one for this mandal
      if (list.isEmpty) {
        final inserted = await SupabaseService.client.from('vargani_configs').insert({
          'mandal_id': mandalId!,
          'name': 'गणेशोत्सव वर्गणी ${DateTime.now().year}',
          'financial_year': '${DateTime.now().year}-${DateTime.now().year + 1}',
          'calculation_type': 'per_member',
          'per_member_amount': 500.00,
          'fixed_amount': 2000.00,
          'is_active': true,
        }).select().single();

        final defConfig = VarganiConfig.fromJson(inserted);
        list = [defConfig];
      }

      final active = list.firstWhere(
        (c) => c.isActive,
        orElse: () => list.first,
      );

      state = state.copyWith(
        configs: list,
        activeConfig: active,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading vargani configs: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> saveConfig({
    String? id,
    required String name,
    required String financialYear,
    required String calculationType,
    required double perMemberAmount,
    required double fixedAmount,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? dueDate,
    double discount = 0.0,
    double specialContribution = 0.0,
  }) async {
    if (mandalId == null) return false;
    state = state.copyWith(isLoading: true, error: null);

    if (!SupabaseService.isInitialized) {
      state = state.copyWith(isLoading: false, error: 'डेटाबेस कनेक्शन उपलब्ध नाही');
      return false;
    }

    try {
      // 1. Deactivate other configs strictly for this mandal
      await SupabaseService.client
          .from('vargani_configs')
          .update({'is_active': false})
          .eq('mandal_id', mandalId!);

      final payload = {
        'mandal_id': mandalId!,
        'name': name,
        'financial_year': financialYear,
        'calculation_type': calculationType,
        'per_member_amount': perMemberAmount,
        'fixed_amount': fixedAmount,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'discount': discount,
        'special_contribution': specialContribution,
        'is_active': true,
      };

      String savedId = id ?? '';
      if (id != null && id.isNotEmpty) {
        await SupabaseService.client
            .from('vargani_configs')
            .update(payload)
            .eq('id', id)
            .eq('mandal_id', mandalId!);
        savedId = id;
      } else {
        final inserted = await SupabaseService.client
            .from('vargani_configs')
            .insert(payload)
            .select()
            .single();
        savedId = inserted['id'] as String;
      }

      // 2. Synchronize ONLY families without payments (preserve all existing payment records!)
      await _syncFamiliesForMandal(
        savedConfigId: savedId,
        calculationType: calculationType,
        perMemberAmount: perMemberAmount,
        fixedAmount: fixedAmount,
        discount: discount,
        specialContribution: specialContribution,
      );

      await loadConfigs();
      return true;
    } catch (e) {
      debugPrint('Error saving config: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> _syncFamiliesForMandal({
    required String savedConfigId,
    required String calculationType,
    required double perMemberAmount,
    required double fixedAmount,
    required double discount,
    required double specialContribution,
  }) async {
    try {
      // Select families and protect any existing payment records
      final families = await SupabaseService.client
          .from('families')
          .select('id, total_members, paid_amount, is_custom_vargani')
          .eq('mandal_id', mandalId!);

      for (final f in (families as List)) {
        final fid = f['id'] as String;
        final members = (f['total_members'] as num?)?.toInt() ?? 1;
        final paid = (f['paid_amount'] as num?)?.toDouble() ?? 0.0;
        final isCustom = f['is_custom_vargani'] == true;

        // CRITICAL: If payments have already been made (paid > 0) or family has a custom amount,
        // DO NOT change existing records! Lock them so neither DB triggers nor updates change them.
        if (paid > 0 || isCustom) {
          if (!isCustom && paid > 0) {
            try {
              // Ensure DB trigger trg_vargani_config_apply ignores this family
              await SupabaseService.client.from('families').update({
                'is_custom_vargani': true,
              }).eq('id', fid);
            } catch (_) {}
          }
          continue;
        }

        // Only update unpaid families (paid == 0.0 and not custom)
        double total = 0.0;
        if (calculationType == 'per_member') {
          total = (members * perMemberAmount) - discount + specialContribution;
        } else {
          total = fixedAmount - discount + specialContribution;
        }
        if (total < 0) total = 0.0;
        final pending = total;

        await SupabaseService.client.from('families').update({
          'vargani_config_id': savedConfigId,
          'total_vargani': total,
          'pending_amount': pending,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', fid).eq('mandal_id', mandalId!);
      }
    } catch (e) {
      debugPrint('Error syncing mandal families with config: $e');
    }
  }
}
