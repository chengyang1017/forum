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
        throw const AdminApiException('服务器返回的审核资料格式无效');
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
        return '你没有管理员权限';

      case 'INVALID_REPORT_QUERY':
        return '举报筛选条件无效';

      case 'INVALID_REPORT_ID':
        return '举报 ID 无效';

      case 'REPORT_NOT_FOUND':
        return '举报不存在';

      case 'INVALID_REPORT_STATUS':
        return '审核状态无效';

      case 'ADMIN_GET_REPORTS_FAILED':
        return '加载举报失败';

      case 'ADMIN_UPDATE_REPORT_FAILED':
        return '更新举报状态失败';

      default:
        return '管理员请求失败，请稍后重试';
    }
  }
}

class AdminApiException implements Exception {
  final String message;

  const AdminApiException(this.message);

  @override
  String toString() => message;
}
