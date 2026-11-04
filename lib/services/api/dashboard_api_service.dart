import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';

class DashboardApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.dashboard;

  Future<Map<String, dynamic>> getStats() async {
    return await get('/stats');
  }

  Future<Map<String, dynamic>> getBirthdaysThisMonth() async {
    return await get('/birthdays');
  }
}