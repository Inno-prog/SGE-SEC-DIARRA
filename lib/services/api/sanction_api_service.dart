import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class SanctionApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.sanctions;

  Future<Map<String, dynamic>> getSanctions({
    int? page,
    int? limit,
    String? employeeId,
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (employeeId != null) query['employeeId'] = employeeId;
    if (status != null) query['status'] = status;
    if (sortBy != null) query['sortBy'] = sortBy;
    if (sortOrder != null) query['sortOrder'] = sortOrder;
    return await get('', query: query);
  }

  Future<Map<String, dynamic>> getSanctionById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createSanction(SanctionModel sanction) async {
    return await post('', data: sanction.toJson());
  }

  Future<Map<String, dynamic>> updateSanction(String id, SanctionModel sanction) async {
    return await patch('/$id', data: sanction.toJson());
  }

  Future<void> deleteSanction(String id) async {
    await delete('/$id');
  }
}