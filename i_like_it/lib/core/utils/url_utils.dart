class UrlUtils {
  /// Extract domain name from URL
  static String getDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;
      
      // Remove 'www.' if present
      if (domain.startsWith('www.')) {
        return domain.substring(4);
      }
      return domain;
    } catch (e) {
      return 'Link';
    }
  }

  /// Extract path or meaningful part from URL for better title
  static String getTitleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;
      
      // Remove 'www.' if present
      String displayDomain = domain.startsWith('www.') 
          ? domain.substring(4) 
          : domain;
      
      // If there's a path, add first segment to make it more meaningful
      if (uri.path.isNotEmpty && uri.path != '/') {
        final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (pathSegments.isNotEmpty) {
          final firstSegment = pathSegments.first;
          // Capitalize and clean up
          final cleanedSegment = firstSegment.replaceAll('-', ' ').replaceAll('_', ' ');
          return '$displayDomain · ${cleanedSegment.substring(0, 1).toUpperCase()}${cleanedSegment.substring(1)}';
        }
      }
      
      return displayDomain;
    } catch (e) {
      return url.length > 50 ? '${url.substring(0, 50)}...' : url;
    }
  }

  /// Format timestamp to a readable string
  static String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as "Jan 17, 2025"
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dateTime.month - 1];
      return '$month ${dateTime.day}, ${dateTime.year}';
    }
  }

  /// Truncate URL for display
  static String truncateUrl(String url, {int maxLength = 40}) {
    if (url.length <= maxLength) {
      return url;
    }
    return '${url.substring(0, maxLength)}...';
  }
}
