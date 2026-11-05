import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class NotificationApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.notifications;

  Future<Map<String, dynamic>> getNotifications({
    int? page,
    int? limit,
    bool? unreadOnly,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (unreadOnly != null) query['unreadOnly'] = unreadOnly;
    return await get('', query: query);
  }

  Future<Map<String, dynamic>> getNotificationById(String id) async {
    return await get('/$id');
  }

  Future<void> markAsRead(String id) async {
    await patch('/$id/read');
  }

  Future<void> markAllAsRead() async {
    await patch('/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await delete('/$id');
  }
}