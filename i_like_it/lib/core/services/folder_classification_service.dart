import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../database/database_helper.dart';
import '../sync/sync_manager.dart';

class ClassificationResult {
  final String category;
  final int confidence;

  ClassificationResult(this.category, this.confidence);

  Map<String, dynamic> toJson() => {
        'category': category,
        'confidence': confidence,
      };
}

class FolderClassificationService {
  static final FolderClassificationService instance =
      FolderClassificationService._();
  FolderClassificationService._();

  Map<String, Map<String, int>>? _rules;
  bool _isInitializing = false;
  
  // The threshold below which we fallback to 'other'
  static const int _confidenceThreshold = 15;

  /// Loads the classification rules from JSON if not already loaded.
  Future<void> _ensureRulesLoaded() async {
    if (_rules != null) return;
    if (_isInitializing) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _ensureRulesLoaded();
    }

    _isInitializing = true;
    try {
      final jsonString =
          await rootBundle.loadString('assets/classification_rules.json');
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      
      _rules = {};
      for (final entry in decoded.entries) {
        final category = entry.key;
        final keywordsMap = entry.value as Map<String, dynamic>;
        _rules![category] = keywordsMap.map((k, v) => MapEntry(k, v as int));
      }
      print('FolderClassificationService: Rules loaded successfully.');
    } catch (e) {
      print('FolderClassificationService: Failed to load rules. Error: $e');
      _rules = {}; // empty fallback
    } finally {
      _isInitializing = false;
    }
  }

  /// Normalizes and tokenizes a folder name for exact word matching
  List<String> _tokenize(String text) {
    // Lowercase
    String normalized = text.toLowerCase();
    // Remove punctuation
    normalized = normalized.replaceAll(RegExp(r'[^\w\s]'), ' ');
    // Split into tokens
    return normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  /// Calculates the classification score for a given folder name
  Future<ClassificationResult> _calculateScore(String folderName) async {
    await _ensureRulesLoaded();

    if (_rules == null || _rules!.isEmpty) {
      return ClassificationResult('other', 0);
    }

    final tokens = _tokenize(folderName);
    final normalizedString = tokens.join(' ');

    if (tokens.isEmpty) {
      return ClassificationResult('other', 0);
    }

    String bestCategory = 'other';
    int maxScore = 0;

    for (final entry in _rules!.entries) {
      final category = entry.key;
      final keywords = entry.value;

      int categoryScore = 0;

      for (final keywordEntry in keywords.entries) {
        final keyword = keywordEntry.key.toLowerCase();
        final weight = keywordEntry.value;

        // Check for exact phrase match
        if (keyword.contains(' ')) {
          // It's a phrase, check if the normalized string contains it bounded by word boundaries
          final regex = RegExp(r'\b' + RegExp.escape(keyword) + r'\b');
          if (regex.hasMatch(normalizedString)) {
            categoryScore += weight;
          }
        } else {
          // Single word, exact match
          if (tokens.contains(keyword)) {
            categoryScore += weight;
          }
        }
      }

      if (categoryScore > maxScore) {
        maxScore = categoryScore;
        bestCategory = category;
      }
    }

    if (maxScore < _confidenceThreshold) {
      return ClassificationResult('other', maxScore);
    }

    return ClassificationResult(bestCategory, maxScore);
  }

  /// Classifies a single folder and updates the DB.
  /// Preserves the Future API design as requested.
  Future<ClassificationResult> classifyFolder(
      dynamic folderId, String folderName) async {
    try {
      final result = await _calculateScore(folderName);
      
      // Update Local DB
      await DatabaseHelper.instance.updateFolderSystemCategory(
        folderId,
        result.category,
      );
      print(
        'FolderClassificationService: Classified "$folderName" as "${result.category}" (Confidence: ${result.confidence})',
      );

      // Trigger Sync to push to Cloud
      SyncManager.instance.sync();
      
      return result;
    } catch (e) {
      print(
        'FolderClassificationService: Failed to classify "$folderName": $e',
      );
      return ClassificationResult('other', 0);
    }
  }

  /// Batch classifies uncategorized folders
  Future<int> runBatchMigration() async {
    await _ensureRulesLoaded();

    final uncategorized = await SyncManager.instance.remoteDataSource
        .fetchFoldersWithoutSystemCategory();
    if (uncategorized.isEmpty) return 0;

    int updatedCount = 0;

    // Process in small batches
    final batches = _chunkList(uncategorized, 50);

    for (final batch in batches) {
      final updates = <Map<String, dynamic>>[];

      for (final folder in batch) {
        final name = folder['name'] as String;
        final id = folder['id'];

        try {
          final result = await _calculateScore(name);
          updates.add({'id': id, 'system_category': result.category});
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
