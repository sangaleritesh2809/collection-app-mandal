class DashboardSummary {
  final int totalMandalMembers;
  final int totalFamilies;
  final double totalExpectedVargani;
  final double totalCollected;
  final double totalPendingVargani;
  final double totalDeposited;
  final double awaitingDeposit;
  final double totalApprovedExpenses;
  final double totalPendingExpenses;
  final double availableBalance;
  final int pendingDepositRequestsCount;
  final Map<String, double> expensesByCategory;
  final Map<String, double> collectionsByMode;

  DashboardSummary({
    this.totalMandalMembers = 0,
    this.totalFamilies = 0,
    this.totalExpectedVargani = 0.0,
    this.totalCollected = 0.0,
    this.totalPendingVargani = 0.0,
    this.totalDeposited = 0.0,
    this.awaitingDeposit = 0.0,
    this.totalApprovedExpenses = 0.0,
    this.totalPendingExpenses = 0.0,
    this.availableBalance = 0.0,
    this.pendingDepositRequestsCount = 0,
    this.expensesByCategory = const {},
    this.collectionsByMode = const {},
  });

  factory DashboardSummary.calculate({
    required int totalMembers,
    required int totalFamilies,
    required double expectedVargani,
    required double totalCollected,
    required double totalPendingVargani,
    required double confirmedDeposits,
    required double approvedExpenses,
    required double pendingExpenses,
    required int pendingDepositsCount,
    required Map<String, double> categoryExpenses,
    required Map<String, double> modeCollections,
  }) {
    final awaiting = (totalCollected - confirmedDeposits).clamp(0.0, double.infinity);
    final balance = confirmedDeposits - approvedExpenses;

    return DashboardSummary(
      totalMandalMembers: totalMembers,
      totalFamilies: totalFamilies,
      totalExpectedVargani: expectedVargani,
      totalCollected: totalCollected,
      totalPendingVargani: totalPendingVargani,
      totalDeposited: confirmedDeposits,
      awaitingDeposit: awaiting,
      totalApprovedExpenses: approvedExpenses,
      totalPendingExpenses: pendingExpenses,
      availableBalance: balance,
      pendingDepositRequestsCount: pendingDepositsCount,
      expensesByCategory: categoryExpenses,
      collectionsByMode: modeCollections,
    );
  }
}

