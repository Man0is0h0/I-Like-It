import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/link_model.dart';
import 'add_link_dialog.dart';
import 'edit_link_dialog.dart';
import 'link_card.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/sync/sync_manager.dart';
import 'dart:async';
import '../../core/widgets/gradient_scaffold.dart'; // New
import '../../core/widgets/glass_container.dart'; // New

class LinkScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  const LinkScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  List<LinkItem> links = [];
  StreamSubscription? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _loadLinks();
    
    // Listen for background sync updates
    _syncSubscription = SyncManager.instance.onSyncCompleted.listen((_) {
      if (mounted) {
        _loadLinks();
      }
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadLinks() async {
    final result = await DatabaseHelper.instance.getLinks(widget.folderId);

    setState(() {
      links = result.map((e) => LinkItem.fromMap(e)).toList();
    });
  }

  Future<void> _deleteLink(LinkItem link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Link?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.deleteLink(link.id!);
        _loadLinks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete link')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientScaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 100.0,
            backgroundColor: Colors.transparent, // Transparent for gradient
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: GlassContainer(
                padding: const EdgeInsets.all(8),
                borderRadius: BorderRadius.circular(50),
                child: Icon(Icons.arrow_back, size: 20, color: colorScheme.onSurface),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.folderName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
            ),
          ),
          
          if (links.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlassContainer(
                      padding: const EdgeInsets.all(32),
                      borderRadius: BorderRadius.circular(100),
                      child: Icon(
                        Icons.link_off_rounded,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No links here',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save your first link to this collection',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final added = await showDialog<bool>(
                          context: context,
                          builder: (_) =>
                              AddLinkDialog(folderId: widget.folderId),
                        );
                        if (added == true) {
                          _loadLinks();
                          SyncManager.instance.sync();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      icon: const Icon(Icons.add_link, size: 20),
                      label: const Text('Add Link'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final link = links[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LinkCard(
                        link: link,
                        onTap: () {
                          launchUrl(
                            Uri.parse(link.url),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        trailing: PopupMenuButton(
                          icon: Icon(Icons.more_vert, 
                            color: colorScheme.onSurfaceVariant, size: 20),
                          padding: EdgeInsets.zero,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share_outlined, size: 18, color: colorScheme.onSurface),
                                  const SizedBox(width: 8),
                                  Text('Share', style: theme.textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurface),
                                  const SizedBox(width: 8),
                                  Text('Edit', style: theme.textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final edited = await showDialog<bool>(
                                context: context,
                                builder: (_) => EditLinkDialog(link: link),
                              );
                              if (edited == true) {
                                _loadLinks();
                                SyncManager.instance.sync();
                              }
                            } else if (value == 'delete') {
                              await _deleteLink(link);
                              SyncManager.instance.sync();
                            } else if (value == 'share') {
                              Share.share(link.url);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  childCount: links.length,
                ),
              ),
            ),
            
           // Fab padding space
           const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: links.isEmpty ? null : FloatingActionButton(
        backgroundColor: colorScheme.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async {
          final added = await showDialog<bool>(
            context: context,
            builder: (_) => AddLinkDialog(folderId: widget.folderId),
          );
          if (added == true) {
            _loadLinks();
            SyncManager.instance.sync();
          }
        },
        child: Icon(Icons.add_link, size: 28, color: colorScheme.onPrimary),
      ),
    );
  }
}
