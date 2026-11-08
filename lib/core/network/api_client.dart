import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../constants/api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;

  Dio get dio => _dio;

  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': ApiConstants.contentType,
        // Prevent caching to avoid 304 responses
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
      // Disable automatic response validation to handle 304 manually
      validateStatus: (status) {
        // Only treat 2xx as success, throw on 3xx, 4xx, 5xx
        return status != null && status >= 200 && status < 300;
      },
    ));

    // Load tokens from storage
    await _loadTokens();

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add cache-busting headers for GET requests
        if (options.method == 'GET') {
          options.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
          options.headers['Pragma'] = 'no-cache';
          options.headers['Expires'] = '0';
          // Add timestamp to prevent caching
          options.queryParameters['_t'] = DateTime.now().millisecondsSinceEpoch;
        }

        if (_accessToken != null) {
          options.headers[ApiConstants.authorization] =
              '${ApiConstants.bearer} $_accessToken';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Handle 304 Not Modified - retry without cache
        if (response.statusCode == 304) {
          developer.log('Received 304, this should not happen with cache-busting headers');
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _refreshToken != null && !_isRefreshing) {
          _isRefreshing = true;
          try {
            await _refreshAccessToken();
            // Retry the original request
            final options = error.requestOptions;
            options.headers[ApiConstants.authorization] =
                '${ApiConstants.bearer} $_accessToken';
            final response = await _dio.fetch(options);
            handler.resolve(response);
            return;
          } catch (e) {
            await _clearTokens();
            // Navigate to login if needed
          } finally {
            _isRefreshing = false;
          }
        }
        handler.next(error);
      },
    ));

    // Add logging interceptor in debug mode
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: false,
      responseHeader: false,
    ));
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _accessToken = null;
    _refreshToken = null;
  }

  Future<void> _refreshAccessToken() async {
    final response = await _dio.post(
      '${ApiConstants.auth}${ApiConstants.refresh}',
      data: {'refreshToken': _refreshToken},
    );

    if (response.statusCode == 200) {
      final data = response.data;
      await _saveTokens(data['accessToken'], data['refreshToken']);
    } else {
      throw Exception('Failed to refresh token');
    }
  }

  void setTokens(String accessToken, String refreshToken) {
    _saveTokens(accessToken, refreshToken);
  }

  void clearTokens() {
    _clearTokens();
  }

  bool get isAuthenticated => _accessToken != null;

  // HTTP Methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}