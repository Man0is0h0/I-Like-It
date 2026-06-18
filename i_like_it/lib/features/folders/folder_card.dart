import 'package:flutter/material.dart';
import 'package:i_like_it/core/models/folder_model.dart';
import 'package:i_like_it/core/widgets/glass_container.dart';
import 'package:i_like_it/features/links/link_screen.dart';
import 'package:i_like_it/theme/app_theme.dart';
import 'package:i_like_it/core/database/database_helper.dart';
import 'package:i_like_it/core/sync/sync_manager.dart';
import 'edit_folder_dialog.dart';

class FolderCard extends StatelessWidget {
  final Folder folder;
  final VoidCallback onRefresh;

  const FolderCard({
    Key? key,
    required this.folder,
    required this.onRefresh,
  }) : super(key: key);

  Color _getDomainColor(String domain) {
    if (domain.isEmpty) return Colors.grey;
    final colors = [
      AppTheme.primaryColor,
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF7C3AED),
      const Color(0xFFDB2777),
      const Color(0xFF2563EB),
    ];
    final hash = domain.codeUnits.fold<int>(0, (prev, code) => prev + code);
    return colors[hash % colors.length];
  }

  IconData _parseIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) return Icons.folder_rounded;
    // Map of common icon names back to IconData
    final map = {
      'work': Icons.work_rounded,
      'shopping': Icons.shopping_bag_rounded,
      'favorite': Icons.favorite_rounded,
      'recipe': Icons.restaurant_rounded,
      'travel': Icons.flight_takeoff_rounded,
      'study': Icons.school_rounded,
      'finance': Icons.account_balance_wallet_rounded,
      'health': Icons.favorite_rounded,
      'gaming': Icons.sports_esports_rounded,
      'music': Icons.music_note_rounded,
      'video': Icons.video_library_rounded,
      'book': Icons.book_rounded,
      'article': Icons.article_rounded,
      'project': Icons.assignment_rounded,
      'idea': Icons.lightbulb_rounded,
      'home': Icons.home_rounded,
      'family': Icons.family_restroom_rounded,
      'code': Icons.code_rounded,
    };
    return map[iconName] ?? Icons.folder_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(16),
      enableBlur: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LinkScreen(
                  folderId: folder.id!,
                  folderName: folder.name,
                ),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getDomainColor(folder.name).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_parseIcon(folder.icon), color: _getDomainColor(folder.name), size: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${folder.itemCount} ${folder.itemCount == 1 ? 'Item' : 'Items'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: colorScheme.onSurfaceVariant),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text('Rename', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                        const SizedBox(width: 12),
                        Text('Delete', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'edit') {
                    final edited = await showDialog<bool>(
                      context: context,
                      builder: (_) => EditFolderDialog(folder: folder),
                    );
                    if (edited == true) {
                      onRefresh();
                      SyncManager.instance.sync();
                    }
                  } else if (value == 'delete') {
                    // Show confirmation
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Folder'),
                        content: Text('Are you sure you want to delete "${folder.name}"? Links inside will not be deleted.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      await DatabaseHelper.instance.deleteFolder(folder.id!);
                      onRefresh();
                      SyncManager.instance.sync();
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
