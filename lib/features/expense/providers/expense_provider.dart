import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../models/expense.dart';

class ExpenseState {
  final List<Expense> expenses;
  final bool isLoading;
  final String? error;
  final String selectedCategory; // 'All' or specific category

  const ExpenseState({
    this.expenses = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'All',
  });

  ExpenseState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    String? error,
    String? selectedCategory,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  List<Expense> get filteredExpenses {
    if (selectedCategory == 'All') return expenses;
    return expenses.where((e) => e.category == selectedCategory).toList();
  }

  double get totalApprovedExpenses => expenses.where((e) => e.isApproved).fold(0.0, (sum, e) => sum + e.amount);
  double get totalPendingExpenses => expenses.where((e) => e.isPending).fold(0.0, (sum, e) => sum + e.amount);
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  final mandalState = ref.watch(mandalProvider);
  return ExpenseNotifier(mandalState.selectedMandal?.id, ref);
});

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final String? mandalId;
  final Ref ref;

  ExpenseNotifier(this.mandalId, this.ref) : super(const ExpenseState()) {
    if (mandalId != null) {
      loadExpenses();
    }
  }

  void filterCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> loadExpenses() async {
    if (mandalId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    if (!SupabaseService.isInitialized) {
      final demoExpenses = [
        Expense(
          id: 'exp-1',
          mandalId: mandalId!,
          title: 'मंडप व स्टेज डेकोरेशन ॲडव्हान्स',
          category: 'Decoration',
          amount: 5000.0,
          expenseDate: DateTime.now().subtract(const Duration(days: 4)),
          paidBy: 'सुरेश कदम (खजिनदार)',
          paidTo: 'साई डेकोरेटर्स',
          paymentMode: 'bank_transfer',
          description: 'मुख्य स्टेज व मंडप उभारणीसाठी पहिली उचल.',
          approvalStatus: 'approved',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Expense(
          id: 'exp-2',
          mandalId: mandalId!,
          title: 'लाईट व ध्वनिक्षेपक बुकिंग',
          category: 'Sound System',
          amount: 2500.0,
          expenseDate: DateTime.now().subtract(const Duration(days: 2)),
          paidBy: 'सुरेश कदम (खजिनदार)',
          paidTo: 'गणेश साऊंड सिस्टिम',
          paymentMode: 'cash',
          description: 'आगमन मिरवणुकीसाठी साऊंड सिस्टिम डिपॉझिट.',
          approvalStatus: 'approved',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
      state = state.copyWith(expenses: demoExpenses, isLoading: false);
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('expenses')
          .select()
          .eq('mandal_id', mandalId!)
          .order('expense_date', ascending: false);

      final list = (res as List).map((e) => Expense.fromJson(e)).toList();
      state = state.copyWith(expenses: list, isLoading: false);
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addExpense({
    required String title,
    required String category,
    required double amount,
    required DateTime expenseDate,
    required String paidBy,
    required String paidTo,
    required String paymentMode,
    String? description,
    String? billImageUrl,
  }) async {
    if (mandalId == null) return false;
    state = state.copyWith(isLoading: true, error: null);

    if (!SupabaseService.isInitialized) {
      final newExp = Expense(
        id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
        mandalId: mandalId!,
        title: title,
        category: category,
        amount: amount,
        expenseDate: expenseDate,
        paidBy: paidBy,
        paidTo: paidTo,
        paymentMode: paymentMode,
        description: description,
        billImageUrl: billImageUrl,
        approvalStatus: 'approved',
        createdAt: DateTime.now(),
      );
      final updated = [newExp, ...state.expenses];
      state = state.copyWith(expenses: updated, isLoading: false);
      return true;
    }

    try {
      final userId = SupabaseService.currentUserId;
      await SupabaseService.client.from('expenses').insert({
        'mandal_id': mandalId,
        'title': title,
        'category': category,
        'amount': amount,
        'expense_date': expenseDate.toIso8601String().substring(0, 10),
        'paid_by': paidBy,
        'paid_to': paidTo,
        'payment_mode': paymentMode,
        'description': description,
        'bill_image_url': billImageUrl,
        'created_by': userId,
        'approval_status': 'approved',
      });

      await loadExpenses();
      return true;
    } catch (e) {
      debugPrint('Error adding expense: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
