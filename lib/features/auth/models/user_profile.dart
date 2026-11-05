class UserProfile {
  final String id;
  final String fullName;
  final String? email;
  final String? mobileNumber;
  final String? avatarUrl;
  final bool isSuperAdmin;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.mobileNumber,
    this.avatarUrl,
    this.isSuperAdmin = false,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'User',
      email: json['email'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isSuperAdmin: json['is_super_admin'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'mobile_number': mobileNumber,
      'avatar_url': avatarUrl,
      'is_super_admin': isSuperAdmin,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? mobileNumber,
    String? avatarUrl,
    bool? isSuperAdmin,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      createdAt: createdAt,
    );
  }
}

