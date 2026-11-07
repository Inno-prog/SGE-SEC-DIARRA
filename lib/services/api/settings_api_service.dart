import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';

class SettingsApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.settings;

  Future<Map<String, dynamic>> getSettings() async {
    return await get('');
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    return await patch('', data: data);
  }

  Future<String?> getCompanyName() async {
    try {
      final response = await getSettings();
      return response['companyName'] ?? response['company_name'];
    } catch (e) {
      return null;
    }
  }
}