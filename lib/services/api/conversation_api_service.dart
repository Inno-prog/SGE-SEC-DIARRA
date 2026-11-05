import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class ConversationApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.conversations;

  Future<Map<String, dynamic>> getConversations() async {
    return await get('');
  }

  Future<Map<String, dynamic>> getConversationById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createConversation(List<String> participants, String name) async {
    return await post('', data: {'participants': participants, 'name': name});
  }

  Future<Map<String, dynamic>> getMessages(String conversationId, {int? page, int? limit}) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    return await get('/$conversationId/messages', query: query);
  }

  Future<Map<String, dynamic>> sendMessage(String conversationId, String content, {List<String>? attachments}) async {
    return await post('/$conversationId/messages', data: {'content': content, 'attachments': attachments ?? []});
  }
}