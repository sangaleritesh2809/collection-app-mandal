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
  return VarganiConfigNotifier(mandalState.selectedMandal?.id);
});

class VarganiConfigNotifier extends StateNotifier<VarganiConfigState> {
  final String? mandalId;

  VarganiConfigNotifier(this.mandalId) : super(const VarganiConfigState()) {
    if (mandalId != null) {
      loadConfigs();
    }
  }

  Future<void> loadConfigs() async {
    if (mandalId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    if (!SupabaseService.isInitialized) {
      final demoConfig = VarganiConfig(
        id: 'demo-config-1',
        mandalId: mandalId!,
        name: 'गणेशोत्सव २०२६ वर्गणी',
        financialYear: '2026-2027',
        calculationType: 'per_member',
        perMemberAmount: 500.0,
        fixedAmount: 2000.0,
        isActive: true,
      );
      state = state.copyWith(
        configs: [demoConfig],
        activeConfig: demoConfig,
        isLoading: false,
      );
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('vargani_configs')
          .select()
          .eq('mandal_id', mandalId!)
          .order('created_at', ascending: false);

      final list = (res as List).map((e) => VarganiConfig.fromJson(e)).toList();
      final active = list.firstWhere((c) => c.isActive, orElse: () => list.isNotEmpty ? list.first : null as dynamic);

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
      final newConfig = VarganiConfig(
        id: id ?? 'demo-config-${DateTime.now().millisecondsSinceEpoch}',
        mandalId: mandalId!,
        name: name,
        financialYear: financialYear,
        calculationType: calculationType,
        perMemberAmount: perMemberAmount,
        fixedAmount: fixedAmount,
        startDate: startDate,
        endDate: endDate,
        dueDate: dueDate,
        discount: discount,
        specialContribution: specialContribution,
        isActive: true,
      );
      state = state.copyWith(
        configs: [newConfig, ...state.configs.where((c) => c.id != newConfig.id)],
        activeConfig: newConfig,
        isLoading: false,
      );
      return true;
    }

    try {
      final payload = {
        'mandal_id': mandalId,
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

      if (id != null) {
        await SupabaseService.client.from('vargani_configs').update(payload).eq('id', id);
      } else {
        await SupabaseService.client.from('vargani_configs').insert(payload);
      }

      await loadConfigs();
      return true;
    } catch (e) {
      debugPrint('Error saving config: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

