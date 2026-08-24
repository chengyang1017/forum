import '../../../../core/network/api_client.dart';
import '../../domain/models/post_model.dart';

class PostApi {
  final ApiClient _apiClient = ApiClient();

  // ============================================================
  // 帖子列表
  // ============================================================

  Future<List<PostModel>> getPosts({
    required String category,
    required String languageCode,
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      '/posts',
      queryParameters: {
        'category': category,
        'languageCode': languageCode,
        'limit': limit,
      },
    );

    final data = response['posts'];

    if (data is! List) {
      throw const PostApiException(
        '服务器返回的帖子列表格式无效',
      );
    }

    try {
      return data
          .map(
            (item) => PostModel.fromJson(
              Map<String, dynamic>.from(
                item as Map,
              ),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      throw const PostApiException(
        '服务器返回的帖子资料格式无效',
      );
    }
  }

  // ============================================================
  // 单篇帖子
  // ============================================================

  Future<PostModel> getPost(
    String postId, {
    String? languageCode,
  }) async {
    final response = await _apiClient.get(
      '/posts/$postId',
      queryParameters: {
        if (languageCode != null)
          'languageCode': languageCode,
      },
    );

    final data = response['post'];

    if (data is! Map) {
      throw const PostApiException(
        '服务器返回的帖子格式无效',
      );
    }

    return PostModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  // ============================================================
  // 创建帖子
  // ============================================================

  Future<PostModel> createPost({
    required String firestoreId,
    required String title,
    required String content,
    required List<dynamic> bodyDelta,
    required String category,
    required String languageCode,
    required List<String> images,
  }) async {
    final response = await _apiClient.post(
      '/posts',
      data: {
        'firestoreId': firestoreId,
        'title': title,
        'content': content,
        'bodyDelta': bodyDelta,
        'category': category,
        'languageCode': languageCode,
        'images': images,
      },
    );

    final data = response['post'];

    if (data is! Map) {
      throw const PostApiException(
        '服务器返回的帖子格式无效',
      );
    }

    return PostModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  // ============================================================
  // 新增语言版本
  // ============================================================

  Future<PostModel> addLanguageVersion({
    required String postId,
    required String languageCode,
    required String title,
    required String content,
    required String type,
    List<dynamic> bodyDelta = const [],
  }) async {
    final response = await _apiClient.post(
      '/posts/$postId/versions',
      data: {
        'languageCode': languageCode,
        'title': title,
        'content': content,
        'bodyDelta': bodyDelta,
        'type': type,
      },
    );

    final data = response['post'];

    if (data is! Map) {
      throw const PostApiException(
        '服务器返回的帖子格式无效',
      );
    }

    return PostModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  // ============================================================
  // 编辑语言版本
  // ============================================================

  Future<PostModel> updateLanguageVersion({
    required String postId,
    required String languageCode,
    required String title,
    required String content,
    List<dynamic>? bodyDelta,
  }) async {
    final response = await _apiClient.patch(
      '/posts/$postId/versions/$languageCode',
      {
        'title': title,
        'content': content,
        if (bodyDelta != null)
          'bodyDelta': bodyDelta,
      },
    );

    final data = response['post'];

    if (data is! Map) {
      throw const PostApiException(
        '服务器返回的帖子格式无效',
      );
    }

    return PostModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  // ============================================================
  // 更新顶部图片
  // ============================================================

  Future<PostModel> updateImages({
    required String postId,
    required List<String> images,
  }) async {
    final response = await _apiClient.patch(
      '/posts/$postId/images',
      {
        'images': images,
      },
    );

    final data = response['post'];

    if (data is! Map) {
      throw const PostApiException(
        '服务器返回的帖子格式无效',
      );
    }

    return PostModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  // ============================================================
  // 删除帖子
  // ============================================================

  Future<List<String>> deletePost(
    String postId,
  ) async {
    final response = await _apiClient.delete(
      '/posts/$postId',
    );

    final data = response['imageUrls'];

    if (data is! List) {
      return const [];
    }

    return data
        .map((item) => item.toString())
        .toList(growable: false);
  }
}

class PostApiException implements Exception {
  final String message;

  const PostApiException(this.message);

  @override
  String toString() => message;
}