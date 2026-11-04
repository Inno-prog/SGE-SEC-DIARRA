import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class AuditApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.audit;

  Future<Map<String, dynamic>> getAuditLogs({
    int? page,
    int? limit,
    String? userId,
    String? action,
    String? collection,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (userId != null) query['userId'] = userId;
    if (action != null) query['action'] = action;
    if (collection != null) query['collection'] = collection;
    if (from != null) query['from'] = from.toIso8601String();
    if (to != null) query['to'] = to.toIso8601String();
    return await get('', query: query);
  }
}