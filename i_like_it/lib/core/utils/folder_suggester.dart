import '../models/folder_model.dart';
import 'ai_video_analyzer.dart';

class FolderSuggester {
  /// Suggest folders and generate names using AI for videos
  static Future<SuggestionResult> suggestFoldersAsync({
    required String linkUrl,
    required String linkTitle,
    required String linkDescription,
    required String linkContent,
    required List<Folder> existingFolders,
  }) async {
    // Try to get AI suggestions for videos and links
    final aiSuggestions = await AIVideoAnalyzer.analyzeVideoAndSuggestFolders(
      videoUrl: linkUrl,
      videoTitle: linkTitle,
      videoDescription: linkDescription,
      content: linkContent,
      existingFolders: existingFolders.map((f) => f.name).toList(),
    );

    // Extract keywords from title, description, and actual content
    final extractedKeywords = _extractKeywords(
      linkTitle,
      linkDescription,
      linkContent,
    );
    final domain = _extractDomain(linkUrl);

    final aiExisting = aiSuggestions
        .where((s) => s.startsWith('EXISTING:'))
        .toList();
    final newSuggestions = aiSuggestions
        .where((s) => !s.startsWith('EXISTING:'))
        .toList();

    // Augment keywords with AI suggested new folders for better existing folder matching
    final combinedKeywords = [
      ...extractedKeywords,
      ...newSuggestions.expand(
        (s) => s.toLowerCase().split(RegExp(r'[\s_\-]+')),
      ),
    ].where((w) => w.length > 2).toSet().toList();

    // Score existing folders based on combined keyword match
    final scoredFolders = _scoreFolders(
      existingFolders,
      combinedKeywords,
      domain,
    );

    if (aiExisting.isNotEmpty) {
      final aiSuggestedName = aiExisting.first
          .replaceFirst('EXISTING:', '')
          .trim();
      // Find this folder in existingFolders
      try {
        final matchedFolder = existingFolders.firstWhere(
          (f) =>
              f.name.toLowerCase() == aiSuggestedName.toLowerCase() ||
              f.name.toLowerCase().contains(aiSuggestedName.toLowerCase()),
        );
        // If not already in scoredFolders, add it to the top
        if (!scoredFolders.any((sf) => sf.folder.id == matchedFolder.id)) {
          scoredFolders.insert(
            0,
            ScoredFolder(
              folder: matchedFolder,
              score: 10.0,
              matchType: 'AI Match',
            ),
          );
        } else {
          // If it is, bump it to the top
          final existingSf = scoredFolders.firstWhere(
            (sf) => sf.folder.id == matchedFolder.id,
          );
          scoredFolders.remove(existingSf);
          scoredFolders.insert(
            0,
            ScoredFolder(
              folder: matchedFolder,
              score: 10.0,
              matchType: 'AI Match',
            ),
          );
        }
      } catch (_) {}
    }

    // Use AI suggestion if available, otherwise generate from keywords
    final suggestedName = newSuggestions.isNotEmpty
        ? newSuggestions.first
        : _generateFolderName(extractedKeywords, domain);

    return SuggestionResult(
      suggestedFolders: scoredFolders,
      suggestedNewFolderName: suggestedName,
      keywords: extractedKeywords,
      domain: domain,
      aiSuggestions: newSuggestions,
    );
  }

  /// Suggest folders (sync version for backwards compatibility)
  static SuggestionResult suggestFolders({
    required String linkUrl,
    required String linkTitle,
    required String linkDescription,
    required String linkContent,
    required List<Folder> existingFolders,
  }) {
    // Extract keywords from title, description, and actual content
    final keywords = _extractKeywords(linkTitle, linkDescription, linkContent);
    final domain = _extractDomain(linkUrl);

    // Score existing folders based on keyword match
    final scoredFolders = _scoreFolders(existingFolders, keywords, domain);

    // Generate suggested folder name
    final suggestedName = _generateFolderName(keywords, domain);

    return SuggestionResult(
      suggestedFolders: scoredFolders,
      suggestedNewFolderName: suggestedName,
      keywords: keywords,
      domain: domain,
    );
  }

  /// Extract keywords from title, description, and actual page content
  static List<String> _extractKeywords(
    String title,
    String description,
    String content,
  ) {
    // Combine all text with more weight on title
    final allText = '$title $title $description $content'.toLowerCase();

    // Remove common words
    final commonWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
      'may',
      'might',
      'must',
      'can',
      'this',
      'that',
      'these',
      'those',
      'i',
      'you',
      'he',
      'she',
      'it',
      'we',
      'they',
      'what',
      'which',
      'who',
      'when',
      'where',
      'why',
      'how',
      'all',
      'each',
      'every',
      'both',
      'few',
      'more',
      'most',
      'other',
      'some',
      'such',
      'no',
      'nor',
      'not',
      'only',
      'same',
      'so',
      'than',
      'too',
      'very',
      'just',
      'my',
      'your',
      'his',
      'her',
      'its',
      'our',
      'their',
      'as',
      'by',
      'from',
      'with',
      'about',
      'into',
      'through',
      'during',
      'before',
      'after',
      'above',
      'below',
      'up',
      'down',
      'out',
      'off',
      'over',
      'under',
      'again',
      'further',
      'then',
      'once',
      'here',
      'there',
      'if',
      'unless',
      'while',
      'until',
      'because',
      'though',
      'although',
      'now',
      'video',
      'watch',
      'youtube',
      'click',
      'link',
      'page',
      'article',
      'post',
      'read',
      'view',
      'see',
      'get',
      'new',
      'latest',
      'best',
      'top',
    };

    // Split into words and filter
    final words = allText
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where(
          (word) =>
              word.isNotEmpty && word.length > 2 && !commonWords.contains(word),
        )
        .toList();

    // Count occurrences and get top keywords
    final keywordMap = <String, int>{};
    for (final word in words) {
      keywordMap[word] = (keywordMap[word] ?? 0) + 1;
    }

    // Sort by frequency and return top 8 (more keywords for better matching)
    final topKeywords = keywordMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return topKeywords.take(8).map((e) => e.key).toList();
  }

  /// Extract domain from URL
  static String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.replaceAll('www.', '').toLowerCase();

      // Handle known shortened domains
      if (host == 'pin.it') return 'pinterest';
      if (host == 'youtu.be') return 'youtube';
      if (host == 'fb.watch' || host == 'fb.me') return 'facebook';
      if (host == 't.co') return 'twitter';
      if (host == 'lnkd.in') return 'linkedin';

      // Get domain name (remove TLD)
      final parts = host.split('.');
      return parts.isNotEmpty ? parts[0] : '';
    } catch (e) {
      return '';
    }
  }

  /// Score existing folders based on keyword match
  static List<ScoredFolder> _scoreFolders(
    List<Folder> folders,
    List<String> keywords,
    String domain,
  ) {
    final scoredFolders = folders.map((folder) {
      final folderNameLower = folder.name.toLowerCase();
      final folderWords = folderNameLower.split(RegExp(r'[\s_\-]+'));
      var score = 0.0;
      var matchedKeywords = 0;

      // Check for keyword matches in folder name
      for (final keyword in keywords) {
        // Exact word match in folder name (highest value)
        if (folderWords.any((w) => w == keyword)) {
          score += 3.0;
          matchedKeywords++;
        }
        // Partial/word-prefix match (lower value)
        else if (folderWords.any(
          (w) => w.startsWith(keyword) || keyword.startsWith(w),
        )) {
          score += 1.5;
          matchedKeywords++;
        }
      }

      // Check for domain match
      if (domain.isNotEmpty && folderNameLower.contains(domain)) {
        score += 2.0;
      }

      // Reduce score if only 1 short keyword matched (likely coincidental)
      if (matchedKeywords == 1 && keywords.isNotEmpty) {
        final matchedKw = keywords.firstWhere(
          (k) => folderNameLower.contains(k),
          orElse: () => '',
        );
        if (matchedKw.length <= 3) {
          score *= 0.5; // Penalize single short-word matches
        }
      }

      return ScoredFolder(
        folder: folder,
        score: score,
        matchType: _getMatchType(score, keywords, domain, folder.name),
      );
    }).toList();

    // Sort by score (descending)
    scoredFolders.sort((a, b) => b.score.compareTo(a.score));

    // Only return folders with meaningful matches (score >= 1.5)
    return scoredFolders.where((f) => f.score >= 1.5).take(3).toList();
  }

  /// Check if folder is a known category
  static bool _isCategoryFolder(String folderName) {
    const categories = {
      'tutorial',
      'guide',
      'documentation',
      'reference',
      'news',
      'article',
      'blog',
      'post',
      'video',
      'podcast',
      'music',
      'audio',
      'code',
      'github',
      'development',
      'programming',
      'design',
      'ui',
      'ux',
      'graphic',
      'business',
      'marketing',
      'sales',
      'analytics',
      'personal',
      'todo',
      'reading list',
      'bookmarks',
    };

    final lowerName = folderName.toLowerCase();
    return categories.any((cat) => lowerName.contains(cat));
  }

  /// Determine match type for UI display
  static String _getMatchType(
    double score,
    List<String> keywords,
    String domain,
    String folderName,
  ) {
    if (score >= 3) return 'Strong match';
    if (score >= 1.5) return 'Good match';
    if (score > 0) return 'Possible match';
    return 'Other';
  }

  /// Generate suggested folder name
  static String _generateFolderName(List<String> keywords, String domain) {
    if (keywords.isEmpty && domain.isEmpty) {
      return 'New Folder';
    }

    if (keywords.isNotEmpty) {
      // Capitalize first keyword
      final firstKeyword = keywords[0];
      return '${firstKeyword[0].toUpperCase()}${firstKeyword.substring(1)}';
    }

    if (domain.isNotEmpty) {
      return '${domain[0].toUpperCase()}${domain.substring(1)}';
    }

    return 'New Folder';
  }
}

class SuggestionResult {
  final List<ScoredFolder> suggestedFolders;
  final String suggestedNewFolderName;
  final List<String> keywords;
  final String domain;
  final List<String> aiSuggestions;

  SuggestionResult({
    required this.suggestedFolders,
    required this.suggestedNewFolderName,
    required this.keywords,
    required this.domain,
    this.aiSuggestions = const [],
  });
}

class ScoredFolder {
  final Folder folder;
  final double score;
  final String matchType;

  ScoredFolder({
    required this.folder,
    required this.score,
    required this.matchType,
  });
}
