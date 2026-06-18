import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIVideoAnalyzer {
  static String? _geminiApiKey = dotenv.env['GEMINI_API_KEY'];

  /// Analyze link content and suggest folder names using Gemini API
  static Future<List<String>> analyzeVideoAndSuggestFolders({
    required String videoUrl,
    required String videoTitle,
    required String videoDescription,
    String? content,
    List<String>? existingFolders,
  }) async {
    try {
      print('[AI_ANALYZER] Analyzing content: $videoTitle');

      final prompt = _buildVideoAnalysisPrompt(videoTitle, videoDescription, content, existingFolders);
      return await _callGeminiAPI(prompt);
    } catch (e) {
      print('[AI_ANALYZER] Error analyzing content: $e');
      return [];
    }
  }

  /// Call Gemini API
  static Future<List<String>> _callGeminiAPI(String prompt) async {
    try {
       // Re-fetch key in case it was reloaded, though redundant if static
      _geminiApiKey = dotenv.env['GEMINI_API_KEY'];

      if (_geminiApiKey == null || _geminiApiKey!.isEmpty || _geminiApiKey == 'YOUR_API_KEY_HERE') {
        print('[AI_ANALYZER] Gemini API key not configured');
        return [];
      }

      final response = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        return _parseFolderSuggestions(text);
      } else {
        print('[AI_ANALYZER] Gemini API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[AI_ANALYZER] Gemini API call failed: $e');
      return [];
    }
  }

  /// Build prompt for content analysis
  static String _buildVideoAnalysisPrompt(String title, String description, String? content, List<String>? existingFolders) {
    String existingFoldersText = existingFolders != null && existingFolders.isNotEmpty
        ? 'Existing Folders to choose from:\n- ' + existingFolders.join('\n- ')
        : 'No existing folders.';

    return '''Based on this content information, suggest 3 concise NEW folder names that would organize this content well, AND pick the 1 BEST matching existing folder if any (or none).

Content Information:
Title: $title
Description: $description
Page Content/Keywords: ${content != null && content.length > 500 ? content.substring(0, 500) : content ?? "None"}

$existingFoldersText

Format your response exactly like this:
NEW: Folder Name 1
NEW: Folder Name 2
NEW: Folder Name 3
EXISTING: [Best matching existing folder name, or "None"]''';
  }

  /// Parse folder suggestions from AI response
  static List<String> _parseFolderSuggestions(String response) {
    try {
      final suggestions = <String>[];

      final lines = response.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        // Extract folder names from NEW: and EXISTING: prefixes
        if (trimmed.startsWith('NEW:')) {
          String suggestion = trimmed.replaceFirst('NEW:', '').trim();
          suggestion = suggestion.replaceAll(RegExp(r'^["\d+"\-*)\\]\s]*'), '').trim();
          if (suggestion.startsWith('"') || suggestion.startsWith("'")) {
            suggestion = suggestion.substring(1);
          }
          if (suggestion.endsWith('"') || suggestion.endsWith("'")) {
            suggestion = suggestion.substring(0, suggestion.length - 1);
          }
          if (suggestion.isNotEmpty && suggestion.length < 50) {
            suggestions.add(suggestion);
          }
        } else if (trimmed.startsWith('EXISTING:')) {
           String existing = trimmed.replaceFirst('EXISTING:', '').trim();
           if (existing.toLowerCase() != 'none' && existing.isNotEmpty) {
             // Prefix existing suggestions to differentiate them if needed, or just insert at front
             suggestions.insert(0, "EXISTING:" + existing);
           }
        }
      }

      return suggestions.take(5).toList();
    } catch (e) {
      print('[AI_ANALYZER] Error parsing suggestions: $e');
      return [];
    }
  }
}