import 'package:supabase_flutter/supabase_flutter.dart';

class AIVideoAnalyzer {
  /// Analyze link content and suggest folder names using Edge Function
  static Future<List<String>> analyzeVideoAndSuggestFolders({
    required String videoUrl,
    required String videoTitle,
    required String videoDescription,
    String? content,
    List<String>? existingFolders,
  }) async {
    try {
      print('[AI_ANALYZER] Analyzing content via Edge Function: $videoTitle');

      final response = await Supabase.instance.client.functions.invoke(
        'analyze-bookmark',
        body: {
          'title': videoTitle,
          'description': videoDescription,
          'content': content,
          'existingFolders': existingFolders ?? [],
        },
      );

      final data = response.data;
      if (data == null || data is! Map) {
        throw Exception('Invalid response from analyze-bookmark Edge Function');
      }

      final suggestions = <String>[];
      
      final bestExisting = data['bestExistingFolder'] as String?;
      if (bestExisting != null && bestExisting.isNotEmpty && bestExisting.toLowerCase() != 'none') {
        suggestions.add("EXISTING:" + bestExisting);
      }

      final newFolders = data['newFolders'] as List<dynamic>?;
      if (newFolders != null) {
        for (final folder in newFolders) {
          if (folder is String && folder.isNotEmpty) {
            suggestions.add(folder);
          }
        }
      }

      return suggestions;
    } catch (e) {
      print('[AI_ANALYZER] Error analyzing content via Edge Function: $e');
      rethrow;
    }
  }
}
