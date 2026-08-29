import '../../../../core/network/api_client.dart';

class AiTranslationResult {
  final String title;
  final String content;

  const AiTranslationResult({required this.title, required this.content});
}

class AiTranslationService {
  AiTranslationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AiTranslationResult> translatePost({
    required String title,
    required String content,
    required String sourceLanguageCode,
    required String targetLanguageCode,
    required String targetLanguageName,
  }) async {
    final data = await _apiClient.post(
      '/translations/posts',
      data: {
        'title': title,
        'content': content,
        'sourceLanguageCode': sourceLanguageCode,
        'targetLanguageCode': targetLanguageCode,
        'targetLanguageName': targetLanguageName,
      },
    );

    return AiTranslationResult(
      title: data['title']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
    );
  }
}
