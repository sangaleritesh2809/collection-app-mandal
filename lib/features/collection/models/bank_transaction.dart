class BankTransaction {
  final String id;
  final String? mandalId;
  final double amount;
  final String utrNumber;
  final String? senderInfo;
  final String? bankName;
  final String? rawSms;
  final bool isClaimed;
  final String? claimedByReceipt;
  final DateTime? claimedAt;
  final DateTime createdAt;

  const BankTransaction({
    required this.id,
    this.mandalId,
    required this.amount,
    required this.utrNumber,
    this.senderInfo,
    this.bankName,
    this.rawSms,
    this.isClaimed = false,
    this.claimedByReceipt,
    this.claimedAt,
    required this.createdAt,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    return BankTransaction(
      id: json['id'] as String,
      mandalId: json['mandal_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      utrNumber: json['utr_number'] as String,
      senderInfo: json['sender_info'] as String?,
      bankName: json['bank_name'] as String?,
      rawSms: json['raw_sms'] as String?,
      isClaimed: json['is_claimed'] as bool? ?? false,
      claimedByReceipt: json['claimed_by_receipt'] as String?,
      claimedAt: json['claimed_at'] != null ? DateTime.parse(json['claimed_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (mandalId != null) 'mandal_id': mandalId,
      'amount': amount,
      'utr_number': utrNumber,
      if (senderInfo != null) 'sender_info': senderInfo,
      if (bankName != null) 'bank_name': bankName,
      if (rawSms != null) 'raw_sms': rawSms,
      'is_claimed': isClaimed,
      if (claimedByReceipt != null) 'claimed_by_receipt': claimedByReceipt,
      if (claimedAt != null) 'claimed_at': claimedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

