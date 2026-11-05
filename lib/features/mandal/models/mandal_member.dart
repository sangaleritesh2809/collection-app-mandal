class MandalMember {
  final String membershipId;
  final String userId;
  final String fullName;
  final String? mobileNumber;
  final String? email;
  final String? avatarUrl;
  final String roleId;
  final String roleName;
  final String status;
  final DateTime joinedAt;

  MandalMember({
    required this.membershipId,
    required this.userId,
    required this.fullName,
    this.mobileNumber,
    this.email,
    this.avatarUrl,
    required this.roleId,
    required this.roleName,
    required this.status,
    required this.joinedAt,
  });

  factory MandalMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};
    final role = json['roles'] as Map<String, dynamic>? ?? {};

    return MandalMember(
      membershipId: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: profile['full_name'] as String? ?? 'वापरकर्ता',
      mobileNumber: profile['mobile_number'] as String?,
      email: profile['email'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      roleId: json['role_id'] as String? ?? '',
      roleName: role['name'] as String? ?? 'Collector',
      status: json['status'] as String? ?? 'active',
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

