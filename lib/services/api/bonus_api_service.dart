import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class BonusApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.bonuses;

  Future<Map<String, dynamic>> getBonuses({
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
    if (status != null) query['statut'] = status;
    if (sortBy != null) query['sortBy'] = sortBy;
    if (sortOrder != null) query['sortOrder'] = sortOrder;
    return await get('', query: query);
  }

  Future<Map<String, dynamic>> getBonusById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createBonus(BonusModel bonus) async {
    return await post('', data: bonus.toJson());
  }

  Future<Map<String, dynamic>> updateBonus(String id, BonusModel bonus) async {
    return await patch('/$id', data: bonus.toJson());
  }

  Future<void> deleteBonus(String id) async {
    await delete('/$id');
  }
}