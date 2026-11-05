class Mandal {
  final String id;
  final String mandalId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? address;
  final String? village;
  final String? taluka;
  final String? district;
  final String state;
  final String? contactNumber;
  final String? email;
  final DateTime? establishmentDate;
  final String invitationCode;
  final bool isActive;
  final String? userRole; // Role of current logged-in user in this mandal
  final DateTime createdAt;

  Mandal({
    required this.id,
    required this.mandalId,
    required this.name,
    this.description,
    this.logoUrl,
    this.address,
    this.village,
    this.taluka,
    this.district,
    this.state = 'Maharashtra',
    this.contactNumber,
    this.email,
    this.establishmentDate,
    required this.invitationCode,
    this.isActive = true,
    this.userRole,
    required this.createdAt,
  });

  factory Mandal.fromJson(Map<String, dynamic> json, {String? role}) {
    return Mandal(
      id: json['id'] as String,
      mandalId: json['mandal_id'] as String? ?? 'MD-001',
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      address: json['address'] as String?,
      village: json['village'] as String?,
      taluka: json['taluka'] as String?,
      district: json['district'] as String?,
      state: json['state'] as String? ?? 'Maharashtra',
      contactNumber: json['contact_number'] as String?,
      email: json['email'] as String?,
      establishmentDate: json['establishment_date'] != null
          ? DateTime.tryParse(json['establishment_date'] as String)
          : null,
      invitationCode: json['invitation_code'] as String? ?? 'VG2026A',
      isActive: json['is_active'] as bool? ?? true,
      userRole: role ?? json['role'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mandal_id': mandalId,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'address': address,
      'village': village,
      'taluka': taluka,
      'district': district,
      'state': state,
      'contact_number': contactNumber,
      'email': email,
      'establishment_date': establishmentDate?.toIso8601String(),
      'invitation_code': invitationCode,
      'is_active': isActive,
    };
  }

  Mandal copyWith({
    String? name,
    String? description,
    String? logoUrl,
    String? address,
    String? village,
    String? taluka,
    String? district,
    String? contactNumber,
    String? email,
    bool? isActive,
    String? userRole,
  }) {
    return Mandal(
      id: id,
      mandalId: mandalId,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      village: village ?? this.village,
      taluka: taluka ?? this.taluka,
      district: district ?? this.district,
      state: state,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      establishmentDate: establishmentDate,
      invitationCode: invitationCode,
      isActive: isActive ?? this.isActive,
      userRole: userRole ?? this.userRole,
      createdAt: createdAt,
    );
  }
}

