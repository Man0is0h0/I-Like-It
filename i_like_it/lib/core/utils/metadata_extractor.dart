import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

class MetadataExtractor {
  /// Fetch and extract title, description, and main content from a URL
  static Future<Map<String, String>> extractMetadata(String url) async {
    try {
      // Ensure URL has protocol
      String urlWithProtocol = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        urlWithProtocol = 'https://$url';
      }

      final response = await http.get(
        Uri.parse(urlWithProtocol),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('', 408),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch URL: ${response.statusCode}');
      }

      final document = parse(response.body);

      // STEP 1: Try Open Graph title tag (highest priority)
      String title = document.querySelector('meta[property="og:title"]')?.attributes['content'] ?? '';

      // STEP 2: If og:title is empty, fallback to HTML <title> tag
      if (title.isEmpty) {
        title = document.querySelector('title')?.text ?? '';
      }

      // Clean up title
      title = _cleanTitle(title);

      // Get description
      String description = '';
      final metaDescription =
          document.querySelector('meta[name="description"]')?.attributes['content'];
      if (metaDescription != null && metaDescription.isNotEmpty) {
        description = _cleanTitle(metaDescription);
      }

      // Extract main content from the page
      String content = _extractPageContent(document);

      return {
        'title': title,
        'description': description,
        'content': content,
      };
    } catch (e) {
      // If fetch fails, return empty values
      return {
        'title': '',
        'description': '',
        'content': '',
      };
    }
  }

  /// Extract main content from the page (heading, paragraphs, list items)
  static String _extractPageContent(dynamic document) {
    try {
      final contentParts = <String>[];

      // Extract headings (h1, h2, h3)
      for (var heading in document.querySelectorAll('h1, h2, h3')) {
        final text = heading.text.trim();
        if (text.isNotEmpty && text.length > 2) {
          contentParts.add(text);
        }
      }

      // Extract list items
      for (var listItem in document.querySelectorAll('li')) {
        final text = listItem.text.trim();
        if (text.isNotEmpty && text.length > 2) {
          contentParts.add(text);
        }
      }

      // Extract paragraphs
      for (var paragraph in document.querySelectorAll('p')) {
        final text = paragraph.text.trim();
        if (text.isNotEmpty && text.length > 10) {
          contentParts.add(text);
        }
      }

      // Extract from article or main content sections
      for (var article in document.querySelectorAll('article, main, [role="main"]')) {
        final text = article.text.trim();
        if (text.isNotEmpty && text.length > 20) {
          contentParts.add(text);
          break; // Only get the first main content section
        }
      }

      // Join content and limit to 2000 characters
      String fullContent = contentParts.join(' ');
      if (fullContent.length > 2000) {
        fullContent = fullContent.substring(0, 2000);
      }

      return fullContent;
    } catch (e) {
      return '';
    }
  }



  /// Clean up extracted title
  static String _cleanTitle(String title) {
    // Remove extra whitespace and newlines
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Decode HTML entities (basic)
    title = title
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    // Limit length
    if (title.length > 100) {
      title = '${title.substring(0, 97)}...';
    }

    return title;
  }
}
