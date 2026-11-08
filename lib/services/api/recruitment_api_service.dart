import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class RecruitmentApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.recruitments;

  Future<Map<String, dynamic>> getRecruitments({
    int? page,
    int? limit,
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (status != null) query['status'] = status;
    if (sortBy != null) query['sortBy'] = sortBy;
    if (sortOrder != null) query['sortOrder'] = sortOrder;
    return await get('', query: query);
  }

  Future<Map<String, dynamic>> getRecruitmentById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createRecruitment(RecruitmentModel recruitment) async {
    return await post('', data: recruitment.toJson());
  }

  Future<Map<String, dynamic>> updateRecruitment(String id, RecruitmentModel recruitment) async {
    return await patch('/$id', data: recruitment.toJson());
  }

  Future<void> deleteRecruitment(String id) async {
    await delete('/$id');
  }
}