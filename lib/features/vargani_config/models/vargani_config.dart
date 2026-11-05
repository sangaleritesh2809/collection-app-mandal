class VarganiConfig {
  final String id;
  final String mandalId;
  final String name;
  final String financialYear;
  final String calculationType; // 'per_member', 'per_family', 'fixed'
  final double perMemberAmount;
  final double fixedAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? dueDate;
  final double discount;
  final double specialContribution;
  final bool isActive;

  VarganiConfig({
    required this.id,
    required this.mandalId,
    required this.name,
    required this.financialYear,
    this.calculationType = 'per_member',
    this.perMemberAmount = 0.0,
    this.fixedAmount = 0.0,
    this.startDate,
    this.endDate,
    this.dueDate,
    this.discount = 0.0,
    this.specialContribution = 0.0,
    this.isActive = true,
  });

  factory VarganiConfig.fromJson(Map<String, dynamic> json) {
    return VarganiConfig(
      id: json['id'] as String,
      mandalId: json['mandal_id'] as String,
      name: json['name'] as String,
      financialYear: json['financial_year'] as String? ?? '2026-2027',
      calculationType: json['calculation_type'] as String? ?? 'per_member',
      perMemberAmount: (json['per_member_amount'] as num?)?.toDouble() ?? 0.0,
      fixedAmount: (json['fixed_amount'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'] as String) : null,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      specialContribution: (json['special_contribution'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'is_active': isActive,
    };
  }

  double calculateTotalForFamily(int memberCount) {
    if (calculationType == 'per_member') {
      final base = memberCount * perMemberAmount;
      return (base - discount + specialContribution).clamp(0.0, double.infinity);
    } else {
      return (fixedAmount - discount + specialContribution).clamp(0.0, double.infinity);
    }
  }
}

