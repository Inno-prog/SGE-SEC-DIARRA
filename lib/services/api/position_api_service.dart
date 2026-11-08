import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/department_model.dart';

class PositionApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.positions;

  Future<Map<String, dynamic>> getPositions({
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

  Future<Map<String, dynamic>> getPositionById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createPosition(PositionModel position) async {
    return await post('', data: position.toJson());
  }

  Future<Map<String, dynamic>> updatePosition(String id, PositionModel position) async {
    return await patch('/$id', data: position.toJson());
  }

  Future<void> deletePosition(String id) async {
    await delete('/$id');
  }
}