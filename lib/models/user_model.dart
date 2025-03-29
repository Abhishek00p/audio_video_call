enum UserRole { admin, member, user }

class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final bool isActive;
  final DateTime? subscriptionExpiryDate;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.isActive = true,
    this.subscriptionExpiryDate,
  });

  bool get isMember => role == UserRole.member;
  bool get isAdmin => role == UserRole.admin;
  bool get isRegularUser => role == UserRole.user;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.user,
      ),
      isActive: json['isActive'] ?? true,
      subscriptionExpiryDate: json['subscriptionExpiryDate'] != null
          ? DateTime.parse(json['subscriptionExpiryDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.toString().split('.').last,
      'isActive': isActive,
      'subscriptionExpiryDate':
          subscriptionExpiryDate?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    UserRole? role,
    bool? isActive,
    DateTime? subscriptionExpiryDate,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      subscriptionExpiryDate: subscriptionExpiryDate ?? this.subscriptionExpiryDate,
    );
  }
}