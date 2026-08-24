import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiClient {
  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://192.168.x.x:3000/api/v1',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final user = FirebaseAuth.instance.currentUser;

          if (user != null) {
            final token = await user.getIdToken();

            if (token != null) {
              options.headers['Authorization'] =
                  'Bearer $token';
            }
          }

          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      path,
      data: data,
    );

    return response.data ?? <String, dynamic>{};
  }

//   Future<Map<String, dynamic>> get(
//   String path,
// ) async {
//   final response =
//       await _dio.get<Map<String, dynamic>>(
//     path,
//   );

//   return response.data ?? <String, dynamic>{};
// }

Future<Map<String, dynamic>> get(
  String path, {
  Map<String, dynamic>? queryParameters,
}) async {
  final response = await _dio.get<Map<String, dynamic>>(
    path,
    queryParameters: queryParameters,
  );

  return response.data ?? <String, dynamic>{};
}

Future<Map<String, dynamic>> patch(
  String path,
  Map<String, dynamic> data,
) async {
  final response =
      await _dio.patch<Map<String, dynamic>>(
    path,
    data: data,
  );

  return response.data ?? <String, dynamic>{};
}

Future<Map<String, dynamic>> post(
  String path, {
  Object? data,
}) async {
  final response = await _dio.post<Map<String, dynamic>>(
    path,
    data: data,
  );

  return response.data ?? <String, dynamic>{};
}

Future<Map<String, dynamic>> delete(
  String path, {
  Object? data,
}) async {
  final response = await _dio.delete<Map<String, dynamic>>(
    path,
    data: data,
  );

  return response.data ?? <String, dynamic>{};
}
}