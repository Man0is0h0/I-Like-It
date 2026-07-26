import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../core/models/link_model.dart';
import '../../core/utils/url_utils.dart';
import '../../theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';

class LinkCard extends StatelessWidget {
  final LinkItem link;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool highlight;

  const LinkCard({
    super.key,
    required this.link,
    required this.onTap,
    this.trailing,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final domain = UrlUtils.getDomainFromUrl(link.url);
    final title = link.title.isNotEmpty ? link.title : domain;
    final timeAgo = UrlUtils.formatTimestamp(link.createdAt);

    // Determine type (basic heuristic)
    IconData typeIcon = Icons.link;
    String typeText = 'Link';
    if (link.imageUrl != null && link.imageUrl!.isNotEmpty && domain.isEmpty) {
      typeIcon = Icons.image;
      typeText = 'Image';
    } else if (link.notes != null && link.notes!.isNotEmpty && domain.isEmpty) {
      typeIcon = Icons.article;
      typeText = 'Note';
    }

    return GlassContainer(
      padding: EdgeInsets.zero,
      enableBlur: false,
      borderRadius: BorderRadius.circular(16),
      borderColor: highlight ? AppTheme.primaryColor.withOpacity(0.8) : null,
      color: highlight ? AppTheme.primaryColor.withOpacity(0.08) : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Larger Thumbnail (Mockup style)
                Container(
                  width: 128,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _getDomainColor(domain).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getDomainColor(domain).withOpacity(0.3),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: link.imageUrl != null && link.imageUrl!.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                link.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                              ClipRect(
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                  child: Container(
                                    color: Colors.black.withOpacity(0.15),
                                  ),
                                ),
                              ),
                              Image.network(
                                link.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackInitial(domain),
                              ),
                            ],
                          )
                        : _buildFallbackInitial(domain),
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(typeIcon, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            typeText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackInitial(String domain) {
    final platformLogo = _getPlatformLogo(domain);
    if (platformLogo != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            platformLogo,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.network(
                platformLogo,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _buildAppIconFallback(),
              ),
            ),
          ),
        ],
      );
    }
    return _buildAppIconFallback();
  }

  Widget _buildAppIconFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Image.asset(
          'assets/app_icon_transparent.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  String? _getPlatformLogo(String domain) {
    final cleanDomain = domain.toLowerCase();
    if (cleanDomain.contains('facebook.com') ||
        cleanDomain.contains('fb.com') ||
        cleanDomain.contains('fb.watch')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/6/6c/Facebook_Logo_2023.png';
    }
    if (cleanDomain.contains('instagram.com')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/e/e7/Instagram_logo_2016.png';
    }
    if (cleanDomain.contains('youtube.com') || cleanDomain.contains('youtu.be')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/0/09/YouTube_full-color_icon_%282017%29.png';
    }
    if (cleanDomain.contains('pinterest.com') || cleanDomain.contains('pin.it')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/0/08/Pinterest-logo.png';
    }
    if (cleanDomain.contains('tiktok.com')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/3/34/Tiktok_icon.png';
    }
    if (cleanDomain.contains('twitter.com') ||
        cleanDomain.contains('x.com') ||
        cleanDomain.contains('t.co')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/c/ce/X_logo_2023.png';
    }
    if (cleanDomain.contains('netflix.com')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/0/0c/Netflix_2015_N_logo.png';
    }
    if (cleanDomain.contains('spotify.com')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/1/19/Spotify_logo_without_text.png';
    }
    if (cleanDomain.contains('linkedin.com')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/c/ca/LinkedIn_logo_initials.png';
    }
    if (cleanDomain.contains('reddit.com')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/0/07/Reddit_Icon.png';
    }
    if (cleanDomain.contains('github.com')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/c/c2/GitHub_Glitch_Logo.png';
    }
    return null;
  }

  Color _getDomainColor(String domain) {
    if (domain.isEmpty) return Colors.grey;
    final colors = [
      AppTheme.primaryColor,
      const Color(0xFF059669), // Emerald
      const Color(0xFFD97706), // Amber
      const Color(0xFFDC2626), // Red
      const Color(0xFF7C3AED), // Violet
      const Color(0xFFDB2777), // Pink
      const Color(0xFF2563EB), // Blue
    ];

    final hash = domain.codeUnits.fold<int>(0, (prev, code) => prev + code);
    return colors[hash % colors.length];
  }
}
