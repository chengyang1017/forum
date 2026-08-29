import '../../../../core/network/api_client.dart';
import '../../domain/models/post_comment_model.dart';

class CommentApi {
  final ApiClient _apiClient = ApiClient();

  Future<List<PostCommentModel>> getComments(String postId) async {
    final response = await _apiClient.get(
      '/posts/${Uri.encodeComponent(postId)}/comments',
    );

    final data = response['comments'];

    if (data is! List) {
      throw const CommentApiException('服务器返回的评论列表格式无效');
    }

    try {
      return data
          .map(
            (item) => PostCommentModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      throw const CommentApiException('服务器返回的评论资料格式无效');
    }
  }

  Future<PostCommentModel> createComment({
    required String postId,
    String text = '',
    String? imageUrl,
  }) async {
    final response = await _apiClient.post(
      '/posts/${Uri.encodeComponent(postId)}/comments',
      data: {'text': text, 'imageUrl': ?imageUrl},
    );

    final data = response['comment'];

    if (data is! Map) {
      throw const CommentApiException('服务器返回的评论格式无效');
    }

    return PostCommentModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<PostCommentModel> createReply({
    required String postId,
    required String commentId,
    required String text,
  }) async {
    final response = await _apiClient.post(
      '/posts/${Uri.encodeComponent(postId)}/comments/'
      '${Uri.encodeComponent(commentId)}/replies',
      data: {'text': text},
    );

    final data = response['reply'];

    if (data is! Map) {
      throw const CommentApiException('服务器返回的回复格式无效');
    }

    return PostCommentModel.fromJson(Map<String, dynamic>.from(data));
  }
}

class CommentApiException implements Exception {
  final String message;

  const CommentApiException(this.message);

  @override
  String toString() => message;
}
