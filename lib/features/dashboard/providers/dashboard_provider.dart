import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../family/providers/family_provider.dart';
import '../../collection/providers/collection_provider.dart';
import '../../deposit/providers/deposit_provider.dart';
import '../../expense/providers/expense_provider.dart';
import '../../mandal/providers/mandal_provider.dart';
import '../models/dashboard_summary.dart';

final dashboardProvider = Provider<DashboardSummary>((ref) {
  final familyState = ref.watch(familyProvider);
  final collectionState = ref.watch(collectionProvider);
  final depositState = ref.watch(depositProvider);
  final expenseState = ref.watch(expenseProvider);

  // 1. Families calculations
  final totalFamilies = familyState.families.length;
  final totalExpected = familyState.families.fold(0.0, (sum, f) => sum + f.totalVargani);
  final totalPending = familyState.families.fold(0.0, (sum, f) => sum + f.pendingAmount);

  // 2. Collections calculations
  final totalCollected = collectionState.totalCollected;
  final Map<String, double> collectionsByMode = {};
  for (final c in collectionState.collections) {
    collectionsByMode[c.paymentMode] = (collectionsByMode[c.paymentMode] ?? 0.0) + c.amount;
  }

  // 3. Deposits calculations
  final totalDeposited = depositState.totalDeposited;
  final pendingDepositsCount = depositState.pendingRequests.length;

  // 4. Expenses calculations
  final approvedExpenses = expenseState.totalApprovedExpenses;
  final pendingExpenses = expenseState.totalPendingExpenses;
  final Map<String, double> expensesByCategory = {};
  for (final e in expenseState.expenses.where((e) => e.isApproved)) {
    expensesByCategory[e.category] = (expensesByCategory[e.category] ?? 0.0) + e.amount;
  }

  // Active Mandal members estimate
  final totalMembers = familyState.families.fold(0, (sum, f) => sum + f.totalMembers);

  return DashboardSummary.calculate(
    totalMembers: totalMembers > 0 ? totalMembers : 25,
    totalFamilies: totalFamilies,
    expectedVargani: totalExpected,
    totalCollected: totalCollected,
    totalPendingVargani: totalPending,
    confirmedDeposits: totalDeposited,
    approvedExpenses: approvedExpenses,
    pendingExpenses: pendingExpenses,
    pendingDepositsCount: pendingDepositsCount,
    categoryExpenses: expensesByCategory,
    modeCollections: collectionsByMode,
  );
});
