import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  String get fullName => '$prenom $nom';

  bool hasPermission(String permission) =>
      role == 'admin' || permissions.contains(permission);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      role: data['role'] ?? 'employee',
      employeeId: data['employeeId'],
      photoUrl: data['photoUrl'],
      isActive: data['isActive'] ?? true,
twoFactorEnabled: data['twoFactorEnabled'] ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
        permissions: List<String>.from(data['permissions'] ?? []),
        darkMode: data['darkMode'] ?? false,
        emailNotifications: data['emailNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'role': role,
        'employeeId': employeeId,
        'photoUrl': photoUrl,
        'isActive': isActive,
        'twoFactorEnabled': twoFactorEnabled,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
        'permissions': permissions,
        'darkMode': darkMode,
        'emailNotifications': emailNotifications,
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
      );
}
