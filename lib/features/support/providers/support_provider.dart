import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../models/support_ticket.dart';

class SupportState {
  final bool isLoading;
  final bool isSubmitting;
  final List<SupportTicket> userTickets;
  final List<SupportTicket> allTickets;
  final String? error;

  const SupportState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.userTickets = const [],
    this.allTickets = const [],
    this.error,
  });

  SupportState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<SupportTicket>? userTickets,
    List<SupportTicket>? allTickets,
    String? error,
  }) {
    return SupportState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      userTickets: userTickets ?? this.userTickets,
      allTickets: allTickets ?? this.allTickets,
      error: error,
    );
  }

  int get openTicketsCount => allTickets.where((t) => t.status == 'open' || t.status == 'in_progress').length;
}

final supportProvider = StateNotifierProvider<SupportNotifier, SupportState>((ref) {
  return SupportNotifier(ref);
});

class SupportNotifier extends StateNotifier<SupportState> {
  final Ref _ref;

  SupportNotifier(this._ref) : super(const SupportState()) {
    loadUserTickets();
  }

  /// Load tickets submitted by the current user
  Future<void> loadUserTickets() async {
    if (!SupabaseService.isInitialized) return;
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await SupabaseService.client
          .from('support_tickets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final tickets = (res as List).map((json) => SupportTicket.fromJson(json)).toList();
      state = state.copyWith(isLoading: false, userTickets: tickets);
    } catch (e) {
      debugPrint('Error loading user support tickets: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load all tickets across all Mandals (for Super Admin)
  Future<void> loadAllTicketsForSuperAdmin() async {
    if (!SupabaseService.isInitialized) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await SupabaseService.client
          .from('support_tickets')
          .select()
          .order('created_at', ascending: false);

      final tickets = (res as List).map((json) => SupportTicket.fromJson(json)).toList();
      state = state.copyWith(isLoading: false, allTickets: tickets);
    } catch (e) {
      debugPrint('Error loading all tickets for super admin: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new support ticket / issue message
  Future<bool> createTicket({
    required String category,
    required String subject,
    required String description,
    String priority = 'medium',
    Uint8List? screenshotBytes,
  }) async {
    if (!SupabaseService.isInitialized) return false;

    final user = _ref.read(authProvider).userProfile;
    final activeMandal = _ref.read(mandalProvider).selectedMandal;
    final currentAuthUser = SupabaseService.client.auth.currentUser;

    if (currentAuthUser == null) {
      state = state.copyWith(error: 'लॉगिन केलेले नाही.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      String? screenshotUrl;

      // 1. Upload screenshot if selected
      if (screenshotBytes != null) {
        final fileName = 'issue_${currentAuthUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await SupabaseService.client.storage
            .from('support_attachments')
            .uploadBinary(fileName, screenshotBytes);

        screenshotUrl = SupabaseService.client.storage
            .from('support_attachments')
            .getPublicUrl(fileName);
      }

      // 2. Format location
      String? location;
      if (activeMandal != null) {
        final parts = [activeMandal.village, activeMandal.taluka, activeMandal.district]
            .where((p) => p != null && p.trim().isNotEmpty)
            .toList();
        if (parts.isNotEmpty) {
          location = parts.join(', ');
        }
      }

      // 3. Insert record into database
      final payload = {
        'user_id': currentAuthUser.id,
        'user_name': user?.fullName ?? 'सदस्य',
        'user_mobile': user?.mobileNumber,
        'user_email': user?.email ?? currentAuthUser.email,
        'mandal_id': activeMandal?.id,
        'mandal_name': activeMandal?.name ?? 'मंडळ निवडलेले नाही',
        'mandal_code': activeMandal?.invitationCode,
        'mandal_location': location,
        'user_role': activeMandal?.userRole ?? 'सदस्य',
        'category': category,
        'subject': subject,
        'description': description,
        'screenshot_url': screenshotUrl,
        'priority': priority,
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final res = await SupabaseService.client
          .from('support_tickets')
          .insert(payload)
          .select()
          .single();

      final newTicket = SupportTicket.fromJson(res);
      state = state.copyWith(
        isSubmitting: false,
        userTickets: [newTicket, ...state.userTickets],
      );

      return true;
    } catch (e) {
      debugPrint('Error creating support ticket: $e');
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Super Admin: reply to ticket and update status
  Future<bool> replyToTicket({
    required String ticketId,
    required String replyText,
    required String newStatus,
  }) async {
    if (!SupabaseService.isInitialized) return false;
    final adminId = SupabaseService.client.auth.currentUser?.id;

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final now = DateTime.now().toIso8601String();
      await SupabaseService.client.from('support_tickets').update({
        'admin_reply': replyText,
        'admin_reply_at': now,
        'status': newStatus,
        'replied_by': adminId,
        'updated_at': now,
      }).eq('id', ticketId);

      // Refresh both lists
      await loadAllTicketsForSuperAdmin();
      await loadUserTickets();

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      debugPrint('Error replying to ticket: $e');
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

