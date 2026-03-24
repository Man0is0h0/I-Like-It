import 'package:flutter/material.dart';
import '../../core/models/link_model.dart';
import '../../core/utils/url_utils.dart';
import '../../theme/app_theme.dart';
import '../../core/widgets/glass_container.dart'; // New

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

    return GlassContainer(
      padding: EdgeInsets.zero,
      enableBlur: false, // Optimize performance
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon / Favicon placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getDomainColor(domain).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getDomainColor(domain).withOpacity(0.3)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: link.imageUrl != null && link.imageUrl!.isNotEmpty
                      ? Image.network(
                          link.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(domain),
                        )
                      : _buildFallbackInitial(domain),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.link, size: 12, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              domain,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      
                      // Notes (if present)
                      if (link.notes != null && link.notes!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                          ),
                          child: Text(
                            link.notes!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
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
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getDomainColor(String domain) {
    if (domain.isEmpty) return Colors.grey;
    final colors = [
      AppTheme.primaryColor,
      Color(0xFF059669), // Emerald
      Color(0xFFD97706), // Amber
      Color(0xFFDC2626), // Red
      Color(0xFF7C3AED), // Violet
      Color(0xFFDB2777), // Pink
      Color(0xFF2563EB), // Blue
    ];
    
    final hash = domain.codeUnits.fold<int>(0, (prev, code) => prev + code);
    return colors[hash % colors.length];
  }
}
