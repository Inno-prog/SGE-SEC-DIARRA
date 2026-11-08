import 'api_client.dart';
import '../../core/constants/api_constants.dart';

abstract class BaseApiService {
  final ApiClient _apiClient = ApiClient();

  ApiClient get apiClient => _apiClient;

  String get baseEndpoint;

  Future<void> initialize() async {
    await _apiClient.initialize();
  }

  // Helper methods for common operations
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _apiClient.get('$baseEndpoint$path', queryParameters: query);
    return response.data;
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    final response = await _apiClient.post('$baseEndpoint$path', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> patch(String path, {dynamic data}) async {
    final response = await _apiClient.patch('$baseEndpoint$path', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    final response = await _apiClient.put('$baseEndpoint$path', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await _apiClient.delete('$baseEndpoint$path');
    return response.data;
  }
}