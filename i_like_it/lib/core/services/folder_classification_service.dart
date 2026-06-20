import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../sync/sync_manager.dart';
import '../../config/app_config.dart';

class FolderClassificationService {
  static final FolderClassificationService instance =
      FolderClassificationService._();
  FolderClassificationService._();

  String? get _apiKey => AppConfig.instance.geminiApiKey;

  String? _validatedModelEndpoint;
  bool _isInitializing = false;

  // Expanded, specific categories for better analytics
  static const List<String> allowedCategories = [
    // Tech & Dev
    'coding', 'web_development', 'mobile_apps', 'ai_ml', 'data_science',
    'cloud_computing', 'hardware', 'cybersecurity', 'tech_news',

    // Education & Career
    'courses', 'university', 'research', 'books', 'career', 'certificates',

    // Entertainment
    'movies', 'series', 'anime', 'gaming', 'music', 'podcasts', 'youtube',

    // Lifestyle
    'fitness', 'health', 'recipes', 'travel', 'fashion', 'home_decor',

    // Finance
    'investing', 'crypto', 'banking', 'business', 'real_estate',

    // Misc
    'news', 'social_media', 'shopping', 'personal', 'project', 'other',
  ];

  void initialize() {
    // Lazy init via ensureInitialized
  }

  Future<String?> _ensureModelInitialized() async {
    if (_validatedModelEndpoint != null) return _validatedModelEndpoint;
    if (_apiKey == null) return null;
    if (_isInitializing) {
      // Simple spin wait
      await Future.delayed(const Duration(milliseconds: 500));
      return _validatedModelEndpoint;
    }

    _isInitializing = true;
    try {
      print('AI Service: discovering available models...');
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = (data['models'] as List).cast<Map<String, dynamic>>();

        // Prioritize faster models
        final preferences = [
          'models/gemini-2.5-flash',
          'models/gemini-2.5-pro',
          'models/gemini-1.0-pro',
          'models/gemini-pro',
        ];

        for (final pref in preferences) {
          final found = models.firstWhere(
            (m) =>
                m['name'] == pref &&
                (m['supportedGenerationMethods'] as List).contains(
                  'generateContent',
                ),
            orElse: () => {},
          );

          if (found.isNotEmpty) {
            print('AI Service: Selected model ${found['name']}');
            _validatedModelEndpoint =
                'https://generativelanguage.googleapis.com/v1beta/${found['name']}:generateContent';
            return _validatedModelEndpoint;
          }
        }

        // Fallback: take *any* that supports generateContent
        final anyModel = models.firstWhere(
          (m) =>
              (m['name'] as String).contains('gemini') &&
              (m['supportedGenerationMethods'] as List).contains(
                'generateContent',
              ),
          orElse: () => {},
        );

        if (anyModel.isNotEmpty) {
          print('AI Service: Fallback model ${anyModel['name']}');
          _validatedModelEndpoint =
              'https://generativelanguage.googleapis.com/v1beta/${anyModel['name']}:generateContent';
          return _validatedModelEndpoint;
        }
      } else {
        print(
          'AI Service: Failed to list models. HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('AI Service: Model discovery error: $e');
    } finally {
      _isInitializing = false;
    }

    // Ultimate fallback if discovery fails (maybe API key has restriction on ListModels)
    _validatedModelEndpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
    return _validatedModelEndpoint;
  }

  /// Classifies a single folder and updates the DB.
  Future<void> classifyFolder(dynamic folderId, String folderName) async {
    if (_apiKey == null) return;

    try {
      final category = await _getCategoryWithRetry(folderName);
      if (category != null) {
        // Update Local DB
        await DatabaseHelper.instance.updateFolderSystemCategory(
          folderId,
          category,
        );
        print(
          'FolderClassificationService: Updated local folder $folderId with "$category"',
        );

        // Trigger Sync to push to Cloud
        SyncManager.instance.sync();
      }
    } catch (e) {
      print(
        'FolderClassificationService: Failed to classify "$folderName": $e',
      );
    }
  }

  /// Batch classifies uncategorized folders
  Future<int> runBatchMigration() async {
    if (_apiKey == null) throw Exception('API Key not initialized');

    // Ensure we have a valid endpoint before starting batch
    await _ensureModelInitialized();

    final uncategorized = await SyncManager.instance.remoteDataSource
        .fetchFoldersWithoutSystemCategory();
    if (uncategorized.isEmpty) return 0;

    int updatedCount = 0;

    // Process in small batches
    final batches = _chunkList(uncategorized, 10);

    for (final batch in batches) {
      final updates = <Map<String, dynamic>>[];

      for (final folder in batch) {
        final name = folder['name'] as String;
        final id = folder['id'];

        // Delay to respect free tier rate limits (approx 15-30 RPM)
        await Future.delayed(const Duration(milliseconds: 1500));

        try {
          final category = await _getCategoryWithRetry(name);
          if (category != null) {
            updates.add({'id': id, 'system_category': category});
          }
        } catch (e) {
          print('Skipping folder $id ($name) due to error: $e');
        }
      }

      if (updates.isNotEmpty) {
        await SyncManager.instance.remoteDataSource.batchUpdateSystemCategories(
          updates,
        );
        updatedCount += updates.length;
      }
    }

    return updatedCount;
  }

  Future<String?> _getCategoryWithRetry(
    String folderName, {
    int retries = 2,
  }) async {
    for (int i = 0; i <= retries; i++) {
      try {
        return await _callGemini(folderName);
      } catch (e) {
        if (i == retries) {
          print(
            'Gemini HTTP failed "$folderName" after $retries retries. Error: $e',
          );
          return 'other';
        }
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
    return null;
  }

  Future<String> _callGemini(String folderName) async {
    if (folderName.trim().isEmpty) return 'personal';

    final endpoint = await _ensureModelInitialized();
    if (endpoint == null) throw Exception('No valid AI model endpoint found');

    final prompt =
        '''
Classify the following folder name into exactly ONE of these categories:
${allowedCategories.join(', ')}.

Folder name: "$folderName"

Respond with ONLY the category name. No explanation. No punctuation. Lowercase.
''';

    final url = Uri.parse('$endpoint?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text =
        data['candidates']?[0]?['content']?['parts']?[0]?['text']
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';

    // Clean up
    final cleanText = text.replaceAll(RegExp(r'[^a-z]'), '');

    print(
      'AI Debug (HTTP): Input="$folderName" | Raw="$text" | Clean="$cleanText"',
    );

    if (allowedCategories.contains(cleanText)) {
      return cleanText;
    }

    // Fuzzy fallback
    for (final category in allowedCategories) {
      if (text.contains(category)) {
        print('AI Debug: Fuzzy matched "$category" for "$folderName"');
        return category;
      }
    }

    print('AI Debug: No match found for "$folderName". Defaulting to "other"');
    return 'other';
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }
}
