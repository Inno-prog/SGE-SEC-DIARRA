import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class AgendaApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.agenda;

  Future<Map<String, dynamic>> getAgendaEvents({
    int? page,
    int? limit,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (from != null) query['from'] = from.toIso8601String();
    if (to != null) query['to'] = to.toIso8601String();
    return await get('', query: query);
  }

  Future<Map<String, dynamic>> getAgendaEventById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createAgendaEvent(AgendaModel event) async {
    return await post('', data: event.toJson());
  }

  Future<Map<String, dynamic>> updateAgendaEvent(String id, AgendaModel event) async {
    return await patch('/$id', data: event.toJson());
  }

  Future<void> deleteAgendaEvent(String id) async {
    await delete('/$id');
  }
}