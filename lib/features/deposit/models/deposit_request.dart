class DepositRequest {
  final String id;
  final String requestNumber;
  final String mandalId;
  final String collectorId;
  final String designatedTreasurerId;
  final double amount;
  final String paymentMode;
  final DateTime requestDate;
  final String? description;
  final String status; // 'pending', 'approved', 'rejected'
  final String? decidedBy;
  final DateTime? decisionDate;
  final String? rejectionReason;
  final String? collectorName;
  final String? treasurerName;
  final String? deciderName;
  final DateTime createdAt;

  DepositRequest({
    required this.id,
    required this.requestNumber,
    required this.mandalId,
    required this.collectorId,
    required this.designatedTreasurerId,
    required this.amount,
    this.paymentMode = 'cash',
    required this.requestDate,
    this.description,
    this.status = 'pending',
    this.decidedBy,
    this.decisionDate,
    this.rejectionReason,
    this.collectorName,
    this.treasurerName,
    this.deciderName,
    required this.createdAt,
  });

  factory DepositRequest.fromJson(Map<String, dynamic> json) {
    return DepositRequest(
      id: json['id'] as String,
      requestNumber: json['request_number'] as String,
      mandalId: json['mandal_id'] as String,
      collectorId: json['collector_id'] as String,
      designatedTreasurerId: json['designated_treasurer_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMode: json['payment_mode'] as String? ?? 'cash',
      requestDate: json['request_date'] != null
          ? DateTime.parse(json['request_date'] as String)
          : DateTime.now(),
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      decidedBy: json['decided_by'] as String?,
      decisionDate: json['decision_date'] != null
          ? DateTime.parse(json['decision_date'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      collectorName: json['collector']?['full_name'] as String? ?? json['collector_name'] as String?,
      treasurerName: json['treasurer']?['full_name'] as String? ?? json['treasurer_name'] as String?,
      deciderName: json['decider']?['full_name'] as String? ?? json['decider_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

