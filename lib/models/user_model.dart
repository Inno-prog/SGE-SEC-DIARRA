class UserModel {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String role;
  final String? employeeId;
  final String? photoUrl;
  final bool isActive;
  final bool twoFactorEnabled;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final List<String> permissions;
  final bool darkMode;
  final bool emailNotifications;
  final bool mustChangePassword;

  UserModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.role,
    this.employeeId,
    this.photoUrl,
    this.isActive = true,
    this.twoFactorEnabled = false,
    required this.createdAt,
    this.lastLogin,
    this.permissions = const [],
    this.darkMode = false,
    this.emailNotifications = true,
    this.mustChangePassword = false,
  });

  String get fullName => '$prenom $nom';

  bool hasPermission(String permission) =>
      role == 'admin' || permissions.contains(permission);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      role: json['role'] ?? 'employee',
      employeeId: json['employeeId'] ?? json['employee_id'],
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      twoFactorEnabled: json['twoFactorEnabled'] ?? json['two_factor_enabled'] ?? false,
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String())
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null || json['last_login'] != null
          ? DateTime.parse(json['lastLogin'] ?? json['last_login'] ?? DateTime.now().toIso8601String())
          : null,
      permissions: List<String>.from(json['permissions'] ?? []),
      darkMode: json['darkMode'] ?? json['dark_mode'] ?? false,
      emailNotifications: json['emailNotifications'] ?? json['email_notifications'] ?? true,
      mustChangePassword: json['mustChangePassword'] ?? json['must_change_password'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'role': role,
        'employeeId': employeeId,
        'photoUrl': photoUrl,
        'isActive': isActive,
        'twoFactorEnabled': twoFactorEnabled,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin?.toIso8601String(),
        'permissions': permissions,
        'darkMode': darkMode,
        'emailNotifications': emailNotifications,
        'mustChangePassword': mustChangePassword,
      };

  UserModel copyWith({
    String? nom,
    String? prenom,
    String? role,
    String? employeeId,
    String? photoUrl,
    bool? isActive,
    bool? twoFactorEnabled,
    List<String>? permissions,
    bool? darkMode,
    bool? emailNotifications,
    bool? mustChangePassword,
  }) =>
      UserModel(
        id: id,
        email: email,
        nom: nom ?? this.nom,
        prenom: prenom ?? this.prenom,
        role: role ?? this.role,
        employeeId: employeeId ?? this.employeeId,
        photoUrl: photoUrl ?? this.photoUrl,
        isActive: isActive ?? this.isActive,
        twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
        createdAt: createdAt,
        lastLogin: lastLogin,
        permissions: permissions ?? this.permissions,
        darkMode: darkMode ?? this.darkMode,
        emailNotifications: emailNotifications ?? this.emailNotifications,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );
}