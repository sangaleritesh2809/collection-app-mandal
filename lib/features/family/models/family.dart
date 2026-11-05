class Family {
  final String id;
  final String mandalId;
  final String familyCode;
  final String familyName;
  final String familyHeadName;
  final String? houseNumber;
  final String? address;
  final String? village;
  final String? mobileNumber;
  final int totalMembers;
  final String? varganiConfigId;
  final double totalVargani;
  final double paidAmount;
  final double pendingAmount;
  final String status;
  final DateTime createdAt;

  Family({
    required this.id,
    required this.mandalId,
    required this.familyCode,
    required this.familyName,
    required this.familyHeadName,
    this.houseNumber,
    this.address,
    this.village,
    this.mobileNumber,
    this.totalMembers = 1,
    this.varganiConfigId,
    this.totalVargani = 0.0,
    this.paidAmount = 0.0,
    this.pendingAmount = 0.0,
    this.status = 'active',
    required this.createdAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as String,
      mandalId: json['mandal_id'] as String,
      familyCode: json['family_code'] as String? ?? 'FAM-001',
      familyName: json['family_name'] as String,
      familyHeadName: json['family_head_name'] as String,
      houseNumber: json['house_number'] as String?,
      address: json['address'] as String?,
      village: json['village'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      totalMembers: (json['total_members'] as num?)?.toInt() ?? 1,
      varganiConfigId: json['vargani_config_id'] as String?,
      totalVargani: (json['total_vargani'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mandal_id': mandalId,
      'family_code': familyCode,
      'family_name': familyName,
      'family_head_name': familyHeadName,
      'house_number': houseNumber,
      'address': address,
      'village': village,
      'mobile_number': mobileNumber,
      'total_members': totalMembers,
      'vargani_config_id': varganiConfigId,
      'total_vargani': totalVargani,
      'paid_amount': paidAmount,
      'pending_amount': pendingAmount,
      'status': status,
    };
  }

  bool get isFullyPaid => pendingAmount <= 0 && totalVargani > 0;
  bool get isPartiallyPaid => paidAmount > 0 && pendingAmount > 0;
  bool get isUnpaid => paidAmount == 0;
}

