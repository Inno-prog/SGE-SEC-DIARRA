import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/department_model.dart';

class DepartmentApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.departments;

  Future<Map<String, dynamic>> getDepartments({
    int? page,
    int? limit,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (search != null) query['search'] = search;
    return await get('', query: query);
  }

  Future<Map<String, dynamic>> getDepartmentById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createDepartment(DepartmentModel department) async {
    return await post('', data: department.toJson());
  }

  Future<Map<String, dynamic>> updateDepartment(String id, DepartmentModel department) async {
    return await patch('/$id', data: department.toJson());
  }

  Future<void> deleteDepartment(String id) async {
    await delete('/$id');
  }
}