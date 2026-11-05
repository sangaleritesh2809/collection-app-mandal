class FamilyMember {
  final String id;
  final String familyId;
  final String mandalId;
  final String memberName;
  final String? mobileNumber;
  final int? age;
  final String? gender;
  final String status;
  final DateTime createdAt;

  FamilyMember({
    required this.id,
    required this.familyId,
    required this.mandalId,
    required this.memberName,
    this.mobileNumber,
    this.age,
    this.gender,
    this.status = 'active',
    required this.createdAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      mandalId: json['mandal_id'] as String,
      memberName: json['member_name'] as String,
      mobileNumber: json['mobile_number'] as String?,
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'mandal_id': mandalId,
      'member_name': memberName,
      'mobile_number': mobileNumber,
      'age': age,
      'gender': gender,
      'status': status,
    };
  }
}

