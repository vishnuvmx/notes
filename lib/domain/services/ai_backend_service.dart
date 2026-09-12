import 'dart:convert';
import 'dart:io';
import '../../core/config/api_config.dart';

/// Custom exception for AI backend failures.
class AiServiceException implements Exception {
  final String message;
  final int? statusCode;

  const AiServiceException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Service connecting Tack to the secure Node.js backend for Smart Actions.
class AiBackendService {
  static const Duration _timeout = Duration(seconds: 15);

  /// Internal helper to dispatch smart actions to backend
  static Future<Map<String, dynamic>> _sendAction({
    required String action,
    required String content,
    String? title,
  }) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) {
      throw const AiServiceException('Note content cannot be empty.');
    }

    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/ai/smart-action');

    final payload = jsonEncode({
      'action': action,
      'content': cleanContent,
      'title': title,
    });

    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=UTF-8');
      request.write(payload);

      final response = await request.close().timeout(_timeout);
      final responseBody = await response.transform(utf8.decoder).join();

      Map<String, dynamic> json;
      try {
        json = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (_) {
        throw AiServiceException('Invalid response from AI server (${response.statusCode})', response.statusCode);
      }

      if (response.statusCode == 200) {
        return json;
      } else if (response.statusCode == 429) {
        throw AiServiceException(
          json['error'] as String? ?? 'Rate limit reached. Please wait a few moments.',
          429,
        );
      } else {
        throw AiServiceException(
          json['error'] as String? ?? 'AI server error (${response.statusCode})',
          response.statusCode,
        );
      }
    } on SocketException {
      throw const AiServiceException(
        'Cannot connect to AI server. Check connection or verify server is running.',
      );
    } on HandshakeException {
      throw const AiServiceException('Secure connection error with AI server.');
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException('Request failed: ${e.toString()}');
    } finally {
      client.close();
    }
  }

  /// 1. Tidy & Polish: cleans formatting, punctuation, structure
  static Future<String> tidyAndPolish(String content, {String? title}) async {
    final res = await _sendAction(action: 'tidy', content: content, title: title);
    return res['result'] as String? ?? content;
  }

  /// 2. Extract Checklist: turns tasks/todos into '- [ ] task' lines
  static Future<String> extractChecklist(String content, {String? title}) async {
    final res = await _sendAction(action: 'checklist', content: content, title: title);
    return res['result'] as String? ?? '';
  }

  /// 3. Summarize: returns 3 concise bullet points
  static Future<String> summarize(String content, {String? title}) async {
    final res = await _sendAction(action: 'summarize', content: content, title: title);
    return res['result'] as String? ?? '';
  }

  /// 4. Suggest Title & Tags: returns structured title and tags list
  static Future<({String title, List<String> tags})> suggestTitleAndTags(
    String content, {
    String? title,
  }) async {
    final res = await _sendAction(action: 'title_tags', content: content, title: title);
    final newTitle = res['title'] as String? ?? (title ?? 'Untitled Note');
    final rawTags = res['tags'] as List<dynamic>? ?? [];
    final cleanTags = rawTags.map((t) => t.toString().replaceAll('#', '').trim()).toList();
    return (title: newTitle, tags: cleanTags);
  }
}
