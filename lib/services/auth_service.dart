import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../firebase_options.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user == null) return null;
    final userRef = _db.collection(AppConstants.colUsers).doc(cred.user!.uid);
    final userDoc = await userRef.get();
    final updates = <String, dynamic>{'lastLogin': Timestamp.now()};
    if (!userDoc.exists) {
      final defaultPrenom = email.split('@').first.split('.').first;
      updates.addAll({
        'email': email,
        'nom': '',
        'prenom': defaultPrenom,
        'role': AppConstants.roleEmployee,
        'employeeId': cred.user!.uid,
        'photoUrl': null,
        'isActive': true,
        'twoFactorEnabled': false,
        'createdAt': Timestamp.now(),
        'permissions': [],
        'darkMode': false,
        'emailNotifications': true,
      });
    } else {
      final data = userDoc.data() ?? {};
      if ((data['employeeId'] ?? null) == null) {
        updates['employeeId'] = cred.user!.uid;
      }
    }
    await userRef.set(updates, SetOptions(merge: true));
    return getUserById(cred.user!.uid);
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> createUser({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String role,
    String? employeeId,
  }) async {
    final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
    final signUpUri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    );

    final res = await http.post(
      signUpUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      final code = data['error']?['message'] as String? ?? 'unknown';
      final message = switch (code) {
        'EMAIL_EXISTS' => 'Cette adresse email est déjà utilisée par un autre compte.',
        'OPERATION_NOT_ALLOWED' => 'La création de compte par mot de passe n\'est pas activée.',
        'TOO_MANY_ATTEMPTS_TRY_LATER' => 'Trop de requêtes. Veuillez patienter avant de réessayer.',
        'WEAK_PASSWORD : Password should be at least 6 characters' =>
          'Le mot de passe doit comporter au moins 6 caractères.',
        _ => data['error']?['message'] ?? 'Erreur lors de la création de l\'utilisateur ($code)',
      };
      throw FirebaseAuthException(code: code, message: message);
    }

    final uid = data['localId'] as String;

    final user = UserModel(
      id: uid,
      email: email,
      nom: nom,
      prenom: prenom,
      role: role,
      employeeId: employeeId ?? uid,
      createdAt: DateTime.now(),
      darkMode: false,
      emailNotifications: true,
      mustChangePassword: true,
    );

    await _db.collection(AppConstants.colUsers).doc(uid).set(user.toFirestore());
    return user;
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (_) {
      final currentApiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final uri = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$currentApiKey');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'requestType': 'PASSWORD_RESET', 'email': email}),
      );
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw FirebaseAuthException(
          code: error['error']['message'] ?? 'unknown',
          message: error['error']['message'],
        );
      }
    }
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection(AppConstants.colUsers).doc(user.id).update(user.toFirestore());
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection(AppConstants.colUsers).doc(uid).delete();
  }

  Stream<List<UserModel>> watchAllUsers() {
    return _db.collection(AppConstants.colUsers).snapshots().map(
          (s) => s.docs.map(UserModel.fromFirestore).toList(),
        );
  }
}
