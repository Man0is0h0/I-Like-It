import 'package:flutter/material.dart';
import '../../core/models/link_model.dart';
import '../../core/utils/url_utils.dart';
import '../../theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';

class LinkCard extends StatelessWidget {
  final LinkItem link;
  final VoidCallback onTap;
  final Widget? trailing;

  const LinkCard({
    super.key,
    required this.link,
    required this.onTap,
    this.trailing,
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
                  width: 100,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _getDomainColor(domain).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getDomainColor(domain).withOpacity(0.3),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: link.imageUrl != null && link.imageUrl!.isNotEmpty
                      ? Image.network(
                          link.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackInitial(domain),
                        )
                      : _buildFallbackInitial(domain),
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
    return Center(
      child: Text(
        domain.isNotEmpty ? domain[0].toUpperCase() : '?',
        style: TextStyle(
          color: _getDomainColor(domain),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
