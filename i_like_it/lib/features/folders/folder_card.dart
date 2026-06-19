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

  IconData _parseIcon(String? iconCode) {
    if (iconCode == null || iconCode.isEmpty) return Icons.folder_rounded;
    // Hex codepoint map matching FolderIconPicker
    final map = {
      // Folder Icons
      '0xe3b0': Icons.folder,
      '0xf06b': Icons.folder_open,
      '0xf07b': Icons.folder_special,
      // Document Icons
      '0xf1c6': Icons.description,
      '0xf0f6': Icons.file_present,
      '0xe80c': Icons.article,
      '0xe8d0': Icons.note,
      '0xe3c9': Icons.notes,
      // Media Icons
      '0xe8a5': Icons.image,
      '0xe04b': Icons.video_library,
      '0xf001': Icons.music_note,
      '0xe3fc': Icons.photo,
      '0xe04e': Icons.videocam,
      '0xe3b1': Icons.collections,
      // Organization Icons
      '0xe875': Icons.bookmark,
      '0xe839': Icons.favorite,
      '0xf591': Icons.star,
      '0xe5ca': Icons.label,
      '0xe3b8': Icons.category,
      '0xe863': Icons.archive,
      // Business/Work Icons
      '0xe8e0': Icons.work,
      '0xe8d5': Icons.business,
      '0xe8d3': Icons.engineering,
      '0xf1bc': Icons.assignment,
      '0xe8dd': Icons.task,
      '0xe8dc': Icons.checklist,
      '0xe192': Icons.attach_money,
      '0xf170': Icons.trending_up,
      // Personal Icons
      '0xe871': Icons.home,
      '0xf0e6': Icons.school,
      '0xf086': Icons.lightbulb,
      '0xe919': Icons.psychology,
      '0xf195': Icons.travel_explore,
      '0xf04a': Icons.sports_basketball,
      // Tech Icons
      '0xf123': Icons.code,
      '0xf0d6': Icons.settings,
      '0xe30b': Icons.computer,
      '0xe325': Icons.phone_android,
      '0xe3ce': Icons.terminal,
      '0xe30c': Icons.storage,
      // Shopping & Lifestyle
      '0xe5dd': Icons.shopping_bag,
      '0xe53a': Icons.shopping_cart,
      '0xe32e': Icons.restaurant,
      '0xe6d3': Icons.local_cafe,
      '0xe8a0': Icons.health_and_safety,
      '0xe8c9': Icons.fitness_center,
      // Social & Communication
      '0xe0b9': Icons.people,
      '0xe0ba': Icons.person,
      '0xe0c0': Icons.mail,
      '0xe0c1': Icons.chat,
      '0xe0c2': Icons.comment,
      '0xe0c8': Icons.notifications,
      // Time & Calendar
      '0xe935': Icons.calendar_today,
      '0xe937': Icons.schedule,
      '0xe8c5': Icons.event,
      // Misc
      '0xe25c': Icons.lock,
      '0xe899': Icons.key,
      '0xe8d7': Icons.palette,
      '0xf05a': Icons.pets,
      '0xe55b': Icons.info,
      '0xe5d5': Icons.help,
    };
    return map[iconCode] ?? Icons.folder_rounded;
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
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
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
