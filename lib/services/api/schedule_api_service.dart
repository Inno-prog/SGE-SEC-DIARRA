import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/schedule_model.dart';

class ScheduleApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.schedules;

  Future<Map<String, dynamic>> getSchedules({
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

  Future<Map<String, dynamic>> getScheduleById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createSchedule(ScheduleModel schedule) async {
    return await post('', data: schedule.toJson());
  }

  Future<Map<String, dynamic>> updateSchedule(String id, ScheduleModel schedule) async {
    return await patch('/$id', data: schedule.toJson());
  }

  Future<void> deleteSchedule(String id) async {
    await delete('/$id');
  }
}