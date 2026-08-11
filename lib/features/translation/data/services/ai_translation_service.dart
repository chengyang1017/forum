import 'package:cloud_functions/cloud_functions.dart';

class AiTranslationResult {
  final String title;
  final String content;

  const AiTranslationResult({
    required this.title,
    required this.content,
  });
}

class AiTranslationService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: 'asia-southeast1',
  );

  Future<AiTranslationResult> translatePost({
    required String title,
    required String content,
    required String sourceLanguageCode,
    required String targetLanguageCode,
    required String targetLanguageName,
  }) async {
    final callable =
        _functions.httpsCallable(
      'translatePost',
    );

    final result = await callable.call({
      'title': title,
      'content': content,
      'sourceLanguageCode':
          sourceLanguageCode,
      'targetLanguageCode':
          targetLanguageCode,
      'targetLanguageName':
          targetLanguageName,
    });

    final data =
        Map<String, dynamic>.from(
      result.data as Map,
    );

    return AiTranslationResult(
      title:
          data['title']?.toString() ?? '',
      content:
          data['content']?.toString() ?? '',
    );
  }
}