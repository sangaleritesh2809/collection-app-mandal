class CollectionRecord {
  final String id;
  final String mandalId;
  final String familyId;
  final String collectorId;
  final String? varganiConfigId;
  final String transactionNumber;
  final String receiptNumber;
  final double amount;
  final String paymentMode; // 'cash', 'upi', 'bank_transfer', 'cheque', 'other'
  final DateTime collectionDate;
  final String? notes;
  final String? receiptUrl;
  final String? utrNumber;
  final bool isDeposited;
  final String? depositRequestId;
  final String? familyName;
  final String? familyHeadName;
  final String? mobileNumber;
  final String? collectorName;
  final DateTime createdAt;

  CollectionRecord({
    required this.id,
    required this.mandalId,
    required this.familyId,
    required this.collectorId,
    this.varganiConfigId,
    required this.transactionNumber,
    required this.receiptNumber,
    required this.amount,
    this.paymentMode = 'cash',
    required this.collectionDate,
    this.notes,
    this.receiptUrl,
    this.utrNumber,
    this.isDeposited = false,
    this.depositRequestId,
    this.familyName,
    this.familyHeadName,
    this.mobileNumber,
    this.collectorName,
    required this.createdAt,
  });

  String get contributorDisplayName => (familyHeadName != null && familyHeadName!.isNotEmpty)
      ? familyHeadName!
      : (familyName ?? 'वर्गणीदार');

  factory CollectionRecord.fromJson(Map<String, dynamic> json) {
    return CollectionRecord(
      id: json['id'] as String,
      mandalId: json['mandal_id'] as String,
      familyId: json['family_id'] as String,
      collectorId: json['collector_id'] as String,
      varganiConfigId: json['vargani_config_id'] as String?,
      transactionNumber: json['transaction_number'] as String,
      receiptNumber: json['receipt_number'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMode: json['payment_mode'] as String? ?? 'cash',
      collectionDate: json['collection_date'] != null
          ? DateTime.parse(json['collection_date'] as String)
          : DateTime.now(),
      notes: json['notes'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      utrNumber: json['utr_number'] as String?,
      isDeposited: json['is_deposited'] as bool? ?? false,
      depositRequestId: json['deposit_request_id'] as String?,
      familyName: json['family']?['family_name'] as String? ?? json['family_name'] as String?,
      familyHeadName: json['family']?['family_head_name'] as String? ?? json['family_head_name'] as String?,
      mobileNumber: json['family']?['mobile_number'] as String? ?? json['mobile_number'] as String?,
      collectorName: json['collector']?['full_name'] as String? ?? json['collector_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mandal_id': mandalId,
      'family_id': familyId,
      'collector_id': collectorId,
      'vargani_config_id': varganiConfigId,
      'transaction_number': transactionNumber,
      'receipt_number': receiptNumber,
      'amount': amount,
      'payment_mode': paymentMode,
      'collection_date': collectionDate.toIso8601String().substring(0, 10),
      'notes': notes,
      'receipt_url': receiptUrl,
      'utr_number': utrNumber,
      'is_deposited': isDeposited,
      'deposit_request_id': depositRequestId,
    };
  }
}

