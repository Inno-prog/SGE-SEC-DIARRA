import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/user_model.dart';

class UserApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.users;

  Future<Map<String, dynamic>> getUsers({
    int? page,
    int? limit,
    String? search,
    String? role,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (search != null) query['search'] = search;
    if (role != null) query['role'] = role;
    return await get('', query: query);
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createUser(UserModel user, {required String password}) async {
    return await post('', data: {
      ...user.toJson(),
      'password': password,
    });
  }

  Future<Map<String, dynamic>> updateUser(String id, UserModel user) async {
    return await patch('/$id', data: user.toJson());
  }

  Future<void> deleteUser(String id) async {
    await delete('/$id');
  }

  Future<Map<String, dynamic>> updateUserRole(String id, String role) async {
    return await patch('/$id/role', data: {'role': role});
  }

  Future<Map<String, dynamic>> updateUserStatus(String id, bool isActive) async {
    return await patch('/$id/status', data: {'isActive': isActive});
  }
}