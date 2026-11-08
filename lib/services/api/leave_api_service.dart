import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class LeaveApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.leaves;

  Future<Map<String, dynamic>> getLeaves({
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
    if (status != null) query['statut'] = _statusForApi(status);
    if (sortBy != null) query['sortBy'] = sortBy;
    if (sortOrder != null) query['sortOrder'] = sortOrder;
    return await get('', query: query);
  }

  String _statusForApi(String status) {
    switch (status) {
      case 'approuvé':
        return 'approuve';
      case 'refusé':
        return 'rejete';
      case 'annulé':
        return 'annule';
      default:
        return status;
    }
  }

  Future<Map<String, dynamic>> getLeaveById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createLeave(LeaveModel leave) async {
    return await post('', data: leave.toJson());
  }

  Future<Map<String, dynamic>> updateLeave(String id, LeaveModel leave) async {
    return await patch('/$id', data: leave.toJson());
  }

  Future<Map<String, dynamic>> updateLeaveStatus(
    String id,
    String status,
    String validatedBy,
    String? comment,
  ) async {
    return await patch('/$id/status', data: {
      'status': status,
      'validatedBy': validatedBy,
      'comment': comment,
    });
  }

  Future<void> deleteLeave(String id) async {
    await delete('/$id');
  }
}