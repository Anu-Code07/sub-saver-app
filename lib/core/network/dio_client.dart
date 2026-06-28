import 'package:dio/dio.dart';

class DioClient {
  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  late final Dio _dio;

  Dio get dio => _dio;
}
