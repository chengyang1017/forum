import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/models/admin_report.dart';

class AdminApi {
  final ApiClient _apiClient;

  AdminApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // ============================================================
  // Admin permission
  // ============================================================

  Future<bool> isAdmin() async {
    try {
      final response = await _apiClient.get('/admin/me');

      return response['admin'] is Map;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        return false;
      }

      throw AdminApiException(_messageForError(error));
    }
  }

  // ============================================================
  // Reports
  // ============================================================

  Future<AdminReportPage> getReports({
    String status = 'pending',
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final response = await _apiClient.get(
        '/admin/reports',
        queryParameters: {
          'status': status,
          'limit': limit,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
      );

      return AdminReportPage.fromJson(response);
    } on DioException catch (error) {
      throw AdminApiException(_messageForError(error));
    }
  }

  Future<AdminReport> updateReportStatus({
    required String reportId,
    required String status,
    String? note,
  }) async {
    final trimmedNote = note?.trim();

    try {
      final response = await _apiClient.patch(
        '/admin/reports/'
        '${Uri.encodeComponent(reportId)}'
        '/status',
        {
          'status': status,
          if (trimmedNote != null && trimmedNote.isNotEmpty)
            'note': trimmedNote,
        },
      );

      final rawReport = response['report'];

      if (rawReport is! Map) {
        throw const AdminApiException('??????????????');
      }

      return AdminReport.fromJson(Map<String, dynamic>.from(rawReport));
    } on DioException catch (error) {
      throw AdminApiException(_messageForError(error));
    }
  }

  String _messageForError(DioException error) {
    final rawData = error.response?.data;

    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    final code = data['error']?.toString();

    switch (code) {
      case 'ADMIN_REQUIRED':
        return '????????';

      case 'INVALID_REPORT_QUERY':
        return '????????';

      case 'INVALID_REPORT_ID':
        return '?? ID ??';

      case 'REPORT_NOT_FOUND':
        return '?????';

      case 'INVALID_REPORT_STATUS':
        return '??????';

      case 'ADMIN_GET_REPORTS_FAILED':
        return '??????';

      case 'ADMIN_UPDATE_REPORT_FAILED':
        return '????????';

      default:
        return '?????????????';
    }
  }
}

class AdminApiException implements Exception {
  final String message;

  const AdminApiException(this.message);

  @override
  String toString() => message;
}
