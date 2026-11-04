import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class AttendanceApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.attendances;

  Future<Map<String, dynamic>> getAttendances({
    int? page,
    int? limit,
    String? date,
    String? employeeId,
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (date != null) query['date'] = date;
    if (employeeId != null) query['employeeId'] = employeeId;
    if (status != null) query['status'] = status;
    if (sortBy != null) query['sortBy'] = sortBy;
    if (sortOrder != null) query['sortOrder'] = sortOrder;
    return await get('', query: query);
  }

  Future<Map<String, dynamic>> getAttendanceById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createAttendance(AttendanceModel attendance) async {
    return await post('', data: attendance.toJson());
  }

  Future<Map<String, dynamic>> updateAttendance(String id, AttendanceModel attendance) async {
    return await patch('/$id', data: attendance.toJson());
  }

  Future<void> deleteAttendance(String id) async {
    await delete('/$id');
  }

  Future<Map<String, dynamic>> getTodayAttendance() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}T00:00:00.000Z';
    return await get('', query: {'date': dateStr});
  }
}