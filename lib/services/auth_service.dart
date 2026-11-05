import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api/auth_api_service.dart';
import '../services/api/user_api_service.dart';

class AuthService {
  final AuthApiService _authApi = AuthApiService();
  final UserApiService _userApi = UserApiService();

  // Stream of auth state changes
  Future<UserModel?> get currentUser async {
    if (!_authApi.isAuthenticated) return null;
    try {
      final response = await _authApi.getProfile();
      // Backend might return user directly or with success field
      if (response['user'] != null) {
        return UserModel.fromJson(response['user']);
      }
    } catch (e) {
      // Token might be invalid
    }
    return null;
  }

  Stream<UserModel?> get authStateChanges async* {
    // Check initial state
    final userData = await currentUser;
    if (userData != null) {
      yield userData;
    } else {
      yield null;
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    final data = await _authApi.login(email, password);
    // Original code expected: { user: {...}, accessToken: "...", refreshToken: "..." }
    // Some backends don't include 'success' field
    if (data['user'] != null && data['accessToken'] != null) {
      final user = UserModel.fromJson(data['user']);
      _authApi.setTokens(data['accessToken'], data['refreshToken']);

      // Fetch complete profile to ensure employeeId is populated
      // (login response may not include employeeId for all users)
      try {
        final profileResponse = await _authApi.getProfile();
        if (profileResponse['user'] != null) {
          return UserModel.fromJson(profileResponse['user']);
        }
      } catch (e) {
        // If profile fetch fails, return user from login response
        debugPrint('Failed to fetch profile after login: $e');
      }

      return user;
    }
    throw Exception(data['message'] ?? data['error'] ?? 'Login failed');
  }

  Future<void> signOut() async {
    await _authApi.logout();
    _authApi.clearTokens();
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final response = await _userApi.getUserById(uid);
      if (response['success'] == true && response['user'] != null) {
        return UserModel.fromJson(response['user']);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<UserModel> createUser({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String role,
    String? employeeId,
  }) async {
    final user = UserModel(
      id: '', // Will be set by server
      email: email,
      nom: nom,
      prenom: prenom,
      role: role,
      employeeId: employeeId,
      createdAt: DateTime.now(),
    );
    final response = await _userApi.createUser(user, password: password);
    if (response['success'] == true && response['user'] != null) {
      return UserModel.fromJson(response['user']);
    }
    throw Exception(response['message'] ?? 'Failed to create user');
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    await _authApi.changePassword(currentPassword, newPassword);
  }

  Future<void> sendPasswordReset(String email) async {
    await _authApi.requestPasswordReset(email);
  }

  Future<void> updateUser(UserModel user) async {
    await _userApi.updateUser(user.id, user);
  }

  Future<void> deleteUser(String uid) async {
    await _userApi.deleteUser(uid);
  }

  Future<List<UserModel>> getAllUsers() async {
    final response = await _userApi.getUsers();
    final List<dynamic> users = response['data'] ?? [];
    return users.map((u) => UserModel.fromJson(u)).toList();
  }

  // Stream version for providers
  Stream<List<UserModel>> watchAllUsers() async* {
    try {
      final users = await getAllUsers();
      yield users;
    } catch (e) {
      yield [];
    }
  }
}