import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIVideoAnalyzer {
  static String? _geminiApiKey = dotenv.env['GEMINI_API_KEY'];

  /// Analyze video URL and suggest folder names using Gemini API
  static Future<List<String>> analyzeVideoAndSuggestFolders({
    required String videoUrl,
    required String videoTitle,
    required String videoDescription,
  }) async {
    try {
      print('[AI_ANALYZER] Analyzing video: $videoTitle');

      final prompt = _buildVideoAnalysisPrompt(videoTitle, videoDescription);
      return await _callGeminiAPI(prompt);
    } catch (e) {
      print('[AI_ANALYZER] Error analyzing video: $e');
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

  /// Build prompt for video analysis
  static String _buildVideoAnalysisPrompt(String title, String description) {
    return '''Based on this video information, suggest 3 concise folder names that would organize this content well. Return only folder names, one per line.

Video Title: $title
Description: $description

Format your response as a simple list with just the folder names. Each name should be 1-3 words maximum and descriptive.''';
  }

  /// Parse folder suggestions from AI response
  static List<String> _parseFolderSuggestions(String response) {
    try {
      final suggestions = <String>[];

      // Look for numbered suggestions
      final lines = response.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        // Extract text after numbers, dashes, or bullets
        String suggestion = trimmed;
        suggestion = suggestion
            .replaceAll(RegExp(r'^["\d+"\-*)\\]\s]*'), '')
            .trim();
        // Remove leading/trailing quotes
        if (suggestion.startsWith('"') || suggestion.startsWith("'")) {
          suggestion = suggestion.substring(1);
        }
        if (suggestion.endsWith('"') || suggestion.endsWith("'")) {
          suggestion = suggestion.substring(0, suggestion.length - 1);
        }

        if (suggestion.isNotEmpty && suggestion.length < 50) {
          suggestions.add(suggestion);
        }
      }

      // Return top 5 suggestions
      return suggestions.take(5).toList();
    } catch (e) {
      print('[AI_ANALYZER] Error parsing suggestions: $e');
      return [];
    }
  }
}