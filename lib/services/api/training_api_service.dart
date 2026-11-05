import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class TrainingApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.trainings;

  Future<Map<String, dynamic>> getTrainings({
    int? page,
    int? limit,
    String? employeeId,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (employeeId != null) query['employeeId'] = employeeId;
    if (sortBy != null) query['sortBy'] = sortBy;
    if (sortOrder != null) query['sortOrder'] = sortOrder;
    return await get('', query: query);
  }

  Future<Map<String, dynamic>> getTrainingById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createTraining(TrainingModel training) async {
    return await post('', data: training.toJson());
  }

  Future<Map<String, dynamic>> updateTraining(String id, TrainingModel training) async {
    return await patch('/$id', data: training.toJson());
  }

  Future<void> deleteTraining(String id) async {
    await delete('/$id');
  }
}