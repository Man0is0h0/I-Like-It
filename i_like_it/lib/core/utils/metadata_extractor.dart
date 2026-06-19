import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

class MetadataExtractor {
  static String extractCleanUrl(String text) {
    // Extract actual URL if the input is shared text containing a URL
    final urlRegex = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
    final match = urlRegex.firstMatch(text);
    String targetUrl = match != null ? match.group(1)! : text.trim();

    // Clean trailing common punctuation from URL
    while (targetUrl.isNotEmpty &&
        (targetUrl.endsWith('.') ||
            targetUrl.endsWith(',') ||
            targetUrl.endsWith('!') ||
            targetUrl.endsWith('?') ||
            targetUrl.endsWith(')') ||
            targetUrl.endsWith(']'))) {
      targetUrl = targetUrl.substring(0, targetUrl.length - 1);
    }
    return targetUrl;
  }

  static Future<Map<String, String>> extractMetadata(String url) async {
    try {
      String targetUrl = extractCleanUrl(url);

      // Ensure URL has protocol
      String urlWithProtocol = targetUrl;
      if (!targetUrl.startsWith('http://') &&
          !targetUrl.startsWith('https://')) {
        urlWithProtocol = 'https://$targetUrl';
      }

      // Special case for YouTube (they often 429 bots)
      if (urlWithProtocol.contains('youtube.com/watch') ||
          urlWithProtocol.contains('youtu.be/') ||
          urlWithProtocol.contains('youtube.com/shorts/')) {
        String? videoId;
        if (urlWithProtocol.contains('youtu.be/')) {
          videoId = urlWithProtocol.split('youtu.be/').last.split('?').first;
        } else if (urlWithProtocol.contains('youtube.com/shorts/')) {
          videoId = urlWithProtocol
              .split('youtube.com/shorts/')
              .last
              .split('?')
              .first;
        } else {
          try {
            final uri = Uri.parse(urlWithProtocol);
            videoId = uri.queryParameters['v'];
          } catch (_) {}
        }

        if (videoId != null && videoId.isNotEmpty) {
          String title = 'YouTube Video';
          // Use noembed API to reliably fetch YouTube video title
          try {
            final oembedResponse = await http
                .get(
                  Uri.parse(
                    'https://noembed.com/embed?url=https://www.youtube.com/watch?v=$videoId',
                  ),
                )
                .timeout(const Duration(seconds: 5));

            if (oembedResponse.statusCode == 200) {
              final data = jsonDecode(oembedResponse.body);
              title = data['title'] ?? title;
            }
          } catch (_) {}

          return {
            'title': _cleanTitle(title),
            'description': '',
            'content': '',
            'image': 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
          };
        }
      }

      final response = await http
          .get(
            Uri.parse(urlWithProtocol),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            },
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => http.Response('', 408),
          );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch URL: ${response.statusCode}');
      }

      final document = parse(response.body);

      // STEP 1: Try Open Graph title tag (highest priority)
      String title =
          document
              .querySelector('meta[property="og:title"]')
              ?.attributes['content'] ??
          '';

      // STEP 2: If og:title is empty, fallback to HTML <title> tag
      if (title.isEmpty) {
        title = document.querySelector('title')?.text ?? '';
      }

      // Clean up title
      title = _cleanTitle(title);

      // Check if the title is generic or indicating a redirect to a login wall
      final lowerTitle = title.toLowerCase();
      final isGenericTitle =
          lowerTitle.isEmpty ||
          lowerTitle == 'instagram' ||
          lowerTitle == 'facebook' ||
          lowerTitle == 'pinterest' ||
          lowerTitle.contains('login') ||
          lowerTitle.contains('log in') ||
          lowerTitle.contains('sign in') ||
          lowerTitle.contains('signin') ||
          lowerTitle.contains('sign up') ||
          lowerTitle.contains('cookie policy') ||
          lowerTitle.contains('unsupported browser');

      if (isGenericTitle) {
        title = _getFallbackTitle(urlWithProtocol);
      }

      // Get description
      String description = '';
      final metaDescription = document
          .querySelector('meta[name="description"]')
          ?.attributes['content'];
      if (metaDescription != null && metaDescription.isNotEmpty) {
        description = _cleanTitle(metaDescription);
      }

      // Extract main content from the page
      String content = _extractPageContent(document);

      String imageUrl =
          document
              .querySelector('meta[property="og:image"]')
              ?.attributes['content'] ??
          '';
      if (imageUrl.isEmpty) {
        imageUrl =
            document
                .querySelector('meta[name="twitter:image"]')
                ?.attributes['content'] ??
            '';
      }
      if (imageUrl.isEmpty) {
        imageUrl =
            document
                .querySelector('link[rel="apple-touch-icon"]')
                ?.attributes['href'] ??
            '';
      }
      if (imageUrl.isEmpty) {
        imageUrl =
            document.querySelector('link[rel="icon"]')?.attributes['href'] ??
            '';
      }
      if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
        try {
          final uri = Uri.parse(urlWithProtocol);
          imageUrl = uri.resolve(imageUrl).toString();
        } catch (_) {}
      }

      return {
        'title': title,
        'description': description,
        'content': content,
        'image': imageUrl,
      };
    } catch (e) {
      // If fetch fails, return fallback values
      return {
        'title': _getFallbackTitle(url),
        'description': '',
        'content': '',
        'image': '',
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
      for (var article in document.querySelectorAll(
        'article, main, [role="main"]',
      )) {
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

  static bool _isLikelyId(String s) {
    // Purely numeric
    if (RegExp(r'^\d+$').hasMatch(s)) return true;
    // Alphanumeric hash (mix of letters and digits, length between 5 and 15)
    if (s.length >= 5 &&
        s.length <= 15 &&
        RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z\d_]+$').hasMatch(s))
      return true;
    // Instagram / Facebook style post IDs
    if (s.startsWith('C_') || s.startsWith('p_') || s.startsWith('v_'))
      return true;
    // YouTube watch id or short code (usually 11 chars of alphanumeric/hyphen/underscore)
    if (s.length == 11 && RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(s)) return true;
    return false;
  }

  static String _getFallbackTitle(String url) {
    try {
      String targetUrl = extractCleanUrl(url);

      final uri = Uri.parse(targetUrl);
      var host = uri.host.replaceAll('www.', '').toLowerCase();

      // Map domain to a friendly name
      String platform = host;
      if (host.contains('youtube.com') || host.contains('youtu.be')) {
        platform = 'YouTube';
      } else if (host.contains('pinterest.com') || host.contains('pin.it')) {
        platform = 'Pinterest';
      } else if (host.contains('instagram.com')) {
        platform = 'Instagram';
      } else if (host.contains('facebook.com') ||
          host.contains('fb.watch') ||
          host.contains('fb.me')) {
        platform = 'Facebook';
      } else if (host.contains('tiktok.com')) {
        platform = 'TikTok';
      } else if (host.contains('twitter.com') ||
          host.contains('t.co') ||
          host.contains('x.com')) {
        platform = 'Twitter';
      } else {
        // Capitalize the first part of host
        final parts = host.split('.');
        if (parts.isNotEmpty) {
          platform = '${parts[0][0].toUpperCase()}${parts[0].substring(1)}';
        }
      }

      // Try to find a meaningful identifier/title from path
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (pathSegments.isNotEmpty) {
        // Filter out generic short segments like 'p', 'pin', 'watch', 'share', 'posts' and purely numeric/hex ones
        final meaningfulSegments = pathSegments.where((s) {
          final isGeneric =
              s == 'p' ||
              s == 'pin' ||
              s == 'watch' ||
              s == 'share' ||
              s == 'posts' ||
              s == 'post';
          final isId = _isLikelyId(s);
          return !isGeneric && !isId && s.length > 2;
        }).toList();

        if (meaningfulSegments.isNotEmpty) {
          final segment = meaningfulSegments.first;
          final cleaned = segment.replaceAll('-', ' ').replaceAll('_', ' ');
          if (cleaned.length > 3) {
            return '$platform - ${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
          }
        }
      }
      return '$platform Link';
    } catch (_) {
      return 'Shared Link';
    }
  }
}
