class AdminReportPage {
  final List<AdminReport> reports;
  final int limit;
  final String? nextCursor;

  const AdminReportPage({
    required this.reports,
    required this.limit,
    required this.nextCursor,
  });

  factory AdminReportPage.fromJson(Map<String, dynamic> json) {
    final rawReports = json['reports'];
    final rawPagination = json['pagination'];

    final reports = rawReports is List
        ? rawReports
              .whereType<Map>()
              .map(
                (item) => AdminReport.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <AdminReport>[];

    final pagination = rawPagination is Map
        ? Map<String, dynamic>.from(rawPagination)
        : <String, dynamic>{};

    return AdminReportPage(
      reports: reports,
      limit: _readInt(pagination['limit'], fallback: reports.length),
      nextCursor: pagination['nextCursor']?.toString(),
    );
  }
}

class AdminReport {
  final String id;
  final String reason;
  final String? details;
  final String status;

  final String? adminNote;
  final DateTime? handledAt;
  final AdminReportActor? handledBy;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final AdminReportActor reporter;
  final AdminReportPost post;

  const AdminReport({
    required this.id,
    required this.reason,
    required this.details,
    required this.status,
    required this.adminNote,
    required this.handledAt,
    required this.handledBy,
    required this.createdAt,
    required this.updatedAt,
    required this.reporter,
    required this.post,
  });

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    final reporterData = _readMap(json['reporter']);

    final handledByData = _readNullableMap(json['handledBy']);

    final postData = _readMap(json['post']);

    return AdminReport(
      id: json['id']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      details: _readNullableString(json['details']),
      status: json['status']?.toString() ?? '',
      adminNote: _readNullableString(json['adminNote']),
      handledAt: _readDateTime(json['handledAt']),
      handledBy: handledByData == null
          ? null
          : AdminReportActor.fromJson(handledByData),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
      reporter: AdminReportActor.fromJson(reporterData),
      post: AdminReportPost.fromJson(postData),
    );
  }
}

class AdminReportActor {
  final String username;
  final String? nickname;
  final String? avatarUrl;

  const AdminReportActor({
    required this.username,
    required this.nickname,
    required this.avatarUrl,
  });

  String get displayName {
    final trimmedNickname = nickname?.trim() ?? '';

    if (trimmedNickname.isNotEmpty) {
      return trimmedNickname;
    }

    return username;
  }

  factory AdminReportActor.fromJson(Map<String, dynamic> json) {
    return AdminReportActor(
      username: json['username']?.toString() ?? '',
      nickname: _readNullableString(json['nickname']),
      avatarUrl: _readNullableString(json['avatarUrl']),
    );
  }
}

class AdminReportPost {
  final String databaseId;
  final String id;

  final String title;
  final String content;

  final String languageCode;
  final String primaryLanguageCode;

  final AdminReportPostAuthor? author;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminReportPost({
    required this.databaseId,
    required this.id,
    required this.title,
    required this.content,
    required this.languageCode,
    required this.primaryLanguageCode,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminReportPost.fromJson(Map<String, dynamic> json) {
    final authorData = _readNullableMap(json['author']);

    return AdminReportPost(
      databaseId: json['databaseId']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      languageCode: json['languageCode']?.toString() ?? '',
      primaryLanguageCode: json['primaryLanguageCode']?.toString() ?? '',
      author: authorData == null
          ? null
          : AdminReportPostAuthor.fromJson(authorData),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }
}

class AdminReportPostAuthor {
  final String firebaseUid;
  final String username;
  final String? nickname;

  const AdminReportPostAuthor({
    required this.firebaseUid,
    required this.username,
    required this.nickname,
  });

  String get displayName {
    final trimmedNickname = nickname?.trim() ?? '';

    if (trimmedNickname.isNotEmpty) {
      return trimmedNickname;
    }

    return username;
  }

  factory AdminReportPostAuthor.fromJson(Map<String, dynamic> json) {
    return AdminReportPostAuthor(
      firebaseUid: json['firebaseUid']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      nickname: _readNullableString(json['nickname']),
    );
  }
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

Map<String, dynamic>? _readNullableMap(Object? value) {
  if (value is! Map) {
    return null;
  }

  return Map<String, dynamic>.from(value);
}

String? _readNullableString(Object? value) {
  final text = value?.toString().trim();

  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}

DateTime? _readDateTime(Object? value) {
  final text = value?.toString();

  if (text == null || text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}

int _readInt(Object? value, {required int fallback}) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
