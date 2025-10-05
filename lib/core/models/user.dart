// lib/core/models/user.dart

enum UserRole {
  guest,
  caterer,
}

class User {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
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
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: _parseRole(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
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
      case 'caterer':
        return UserRole.caterer;
      case 'guest':
      default:
        return UserRole.guest;
    }
  }

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    if (firstName != null) {
      return firstName!;
    }
    return email;
  }

  bool get isGuest => role == UserRole.guest;
  bool get isCaterer => role == UserRole.caterer;

  User copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
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
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
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
