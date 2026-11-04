import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/user_model.dart';

class AuthApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.auth;

  Future<Map<String, dynamic>> login(String email, String password) async {
    return await post(ApiConstants.login, data: {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    return await post(ApiConstants.register, data: userData);
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return await post(ApiConstants.refresh, data: {'refreshToken': refreshToken});
  }

  Future<void> logout() async {
    await post(ApiConstants.logout);
    clearTokens();
  }

  Future<Map<String, dynamic>> verifyAuth() async {
    return await get(ApiConstants.verify);
  }

  Future<Map<String, dynamic>> getProfile() async {
    return await get(ApiConstants.profile);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return await patch(ApiConstants.profile, data: data);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await post(ApiConstants.changePassword, data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> requestPasswordReset(String email) async {
    await post(ApiConstants.passwordReset, data: {'email': email});
  }

  void setTokens(String accessToken, String refreshToken) {
    apiClient.setTokens(accessToken, refreshToken);
  }

  void clearTokens() {
    apiClient.clearTokens();
  }

  bool get isAuthenticated => apiClient.isAuthenticated;
}