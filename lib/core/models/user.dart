enum UserRole {
  gast,
  cateraar,
}

class User {
  final int id;
  final String email;
  final String? voornaam;
  final String? achternaam;
  final String? fullName;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    this.voornaam,
    this.achternaam,
    this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      voornaam: json['voornaam'] as String?,
      achternaam: json['achternaam'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: _parseRole(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'voornaam': voornaam,
      'achternaam': achternaam,
      'full_name': fullName,
      'phone': phone,
      'role': role.name,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  static UserRole _parseRole(String? roleString) {
    switch (roleString?.toLowerCase()) {
      case 'cateraar':
        return UserRole.cateraar;
      case 'gast':
      default:
        return UserRole.gast;
    }
  }

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    if (voornaam != null && achternaam != null) {
      return '$voornaam $achternaam'.trim();
    }
    if (voornaam != null) {
      return voornaam!;
    }
    return email;
  }

  bool get isGuest => role == UserRole.gast;
  bool get isCateraar => role == UserRole.cateraar;

  User copyWith({
    int? id,
    String? email,
    String? voornaam,
    String? achternaam,
    String? fullName,
    String? phone,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      voornaam: voornaam ?? this.voornaam,
      achternaam: achternaam ?? this.achternaam,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, role: $role, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

