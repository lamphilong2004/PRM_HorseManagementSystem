import 'package:dio/dio.dart';

import '../storage/session_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required SessionStorage sessionStorage})
    : _sessionStorage = sessionStorage,
      dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: const {'Content-Type': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _accessToken ?? await _loadStoredToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static const baseUrl = String.fromEnvironment(
    'VITE_API_BASE_URL',
    defaultValue: 'https://managerhourse-be.onrender.com',
  );

  final Dio dio;
  final SessionStorage _sessionStorage;
  String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Future<Response<dynamic>> get(String path) {
    return _send(() => dio.get<dynamic>(path));
  }

  Future<Response<dynamic>> post(String path, Object body) {
    return _send(() => dio.post<dynamic>(path, data: body));
  }

  Future<Response<dynamic>> patch(String path, [Object? body]) {
    return _send(() => dio.patch<dynamic>(path, data: body));
  }

  Future<Response<dynamic>> put(String path, Object body) {
    return _send(() => dio.put<dynamic>(path, data: body));
  }

  Future<Response<dynamic>> delete(String path) {
    return _send(() => dio.delete<dynamic>(path));
  }

  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<String?> _loadStoredToken() async {
    final session = await _sessionStorage.loadSession();
    _accessToken = session?.token;
    return _accessToken;
  }

  ApiException _toApiException(DioException error) {
    final data = error.response?.data;
    final statusCode = error.response?.statusCode;
    var message = 'Failed';

    if (data is Map<String, dynamic>) {
      final apiMessage = data['message'] ?? data['error'];
      if (apiMessage != null) {
        message = apiMessage.toString();
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    } else if (error.message != null && error.message!.isNotEmpty) {
      message = error.message!;
    }

    return ApiException(message, statusCode: statusCode);
  }
}
