import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIVideoAnalyzer {
  static String? _geminiApiKey = dotenv.env['GEMINI_API_KEY'];
  static final Map<String, List<String>> _cache = {};

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

      final prompt = _buildVideoAnalysisPrompt(
        videoTitle,
        videoDescription,
        content,
        existingFolders,
      );
      return await _callGeminiAPI(prompt);
    } catch (e) {
      print('[AI_ANALYZER] Error analyzing content: $e');
      return [];
    }
  }

  /// Call Gemini API
  static Future<List<String>> _callGeminiAPI(String prompt) async {
    if (_cache.containsKey(prompt)) {
      print('[AI_ANALYZER] Returning cached response to avoid rate limits');
      return _cache[prompt]!;
    }

    try {
      // Re-fetch key in case it was reloaded, though redundant if static
      _geminiApiKey = dotenv.env['GEMINI_API_KEY'];

      if (_geminiApiKey == null ||
          _geminiApiKey!.isEmpty ||
          _geminiApiKey == 'YOUR_API_KEY_HERE') {
        print('[AI_ANALYZER] Gemini API key not configured');
        return [];
      }

      int maxRetries = 3;
      for (int i = 0; i < maxRetries; i++) {
        try {
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
              .timeout(const Duration(seconds: 20));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final text =
                data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
            print('[AI_ANALYZER] Raw Gemini response:\n$text');
            final parsed = _parseFolderSuggestions(text);
            _cache[prompt] = parsed;
            return parsed;
          } else if (response.statusCode == 429) {
            print(
              '[AI_ANALYZER] Gemini API error: 429. Retrying in ${i + 1} seconds...',
            );
            if (i == maxRetries - 1) return [];
            await Future.delayed(Duration(seconds: i + 1));
          } else {
            print('[AI_ANALYZER] Gemini API error: ${response.statusCode}');
            return [];
          }
        } catch (e) {
          print('[AI_ANALYZER] Gemini API call attempt ${i + 1} failed: $e');
          if (i == maxRetries - 1) return [];
          await Future.delayed(Duration(seconds: i + 1));
        }
      }
      return [];
    } catch (e) {
      print('[AI_ANALYZER] Gemini API call failed: $e');
      return [];
    }
  }

  /// Build prompt for content analysis
  static String _buildVideoAnalysisPrompt(
    String title,
    String description,
    String? content,
    List<String>? existingFolders,
  ) {
    String existingFoldersText =
        existingFolders != null && existingFolders.isNotEmpty
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

        // Use RegExp to catch NEW: and EXISTING: even if wrapped in markdown like **NEW:** or *NEW:*
        final newMatch = RegExp(
          r'^\*?\*?NEW:\*?\*?\s*(.*)',
          caseSensitive: false,
        ).firstMatch(trimmed);
        final existingMatch = RegExp(
          r'^\*?\*?EXISTING:\*?\*?\s*(.*)',
          caseSensitive: false,
        ).firstMatch(trimmed);

        if (newMatch != null) {
          String suggestion = newMatch.group(1)!.trim();
          suggestion = suggestion
              .replaceAll(RegExp(r'^["\d+"\-*)\\]\s]*'), '')
              .trim();
          if (suggestion.startsWith('"') || suggestion.startsWith("'")) {
            suggestion = suggestion.substring(1);
          }
          if (suggestion.endsWith('"') || suggestion.endsWith("'")) {
            suggestion = suggestion.substring(0, suggestion.length - 1);
          }
          if (suggestion.isNotEmpty && suggestion.length < 50) {
            suggestions.add(suggestion);
          }
        } else if (existingMatch != null) {
          String existing = existingMatch.group(1)!.trim();
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
