class Expense {
  final String id;
  final String mandalId;
  final String title;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final String paidBy;
  final String paidTo;
  final String paymentMode;
  final String? description;
  final String? billImageUrl;
  final String? receiptImageUrl;
  final String? createdBy;
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final String? approvedBy;
  final DateTime? approvalDate;
  final String? rejectionReason;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.mandalId,
    required this.title,
    required this.category,
    required this.amount,
    required this.expenseDate,
    required this.paidBy,
    required this.paidTo,
    this.paymentMode = 'cash',
    this.description,
    this.billImageUrl,
    this.receiptImageUrl,
    this.createdBy,
    this.approvalStatus = 'approved',
    this.approvedBy,
    this.approvalDate,
    this.rejectionReason,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      mandalId: json['mandal_id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      expenseDate: json['expense_date'] != null
          ? DateTime.parse(json['expense_date'] as String)
          : DateTime.now(),
      paidBy: json['paid_by'] as String? ?? 'मंडळ',
      paidTo: json['paid_to'] as String,
      paymentMode: json['payment_mode'] as String? ?? 'cash',
      description: json['description'] as String?,
      billImageUrl: json['bill_image_url'] as String?,
      receiptImageUrl: json['receipt_image_url'] as String?,
      createdBy: json['created_by'] as String?,
      approvalStatus: json['approval_status'] as String? ?? 'approved',
      approvedBy: json['approved_by'] as String?,
      approvalDate: json['approval_date'] != null
          ? DateTime.parse(json['approval_date'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get isApproved => approvalStatus == 'approved';
  bool get isPending => approvalStatus == 'pending';
}

