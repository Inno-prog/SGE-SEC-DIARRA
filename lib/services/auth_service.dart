import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    if (!userDoc.exists) {
      final defaultPrenom = email.split('@').first.split('.').first;
      await userRef.set({
        'email': email,
        'nom': '',
        'prenom': defaultPrenom,
        'role': AppConstants.roleEmployee,
        'employeeId': null,
        'photoUrl': null,
        'isActive': true,
        'twoFactorEnabled': false,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'permissions': [],
        'darkMode': false,
        'emailNotifications': true,
      });
    } else {
      await userRef.update({'lastLogin': Timestamp.now()});
    }
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
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserModel(
      id: cred.user!.uid,
      email: email,
      nom: nom,
      prenom: prenom,
      role: role,
      employeeId: employeeId,
      createdAt: DateTime.now(),
      darkMode: false,
      emailNotifications: true,
    );
    await _db.collection(AppConstants.colUsers).doc(user.id).set(user.toFirestore());
    return user;
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
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
