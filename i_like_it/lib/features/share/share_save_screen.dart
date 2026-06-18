import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/folder_model.dart';
import '../../core/utils/metadata_extractor.dart';
import '../../core/widgets/success_confetti_popup.dart';
import '../../theme/app_theme.dart';
import '../links/folder_suggestion_dialog.dart';
import '../../core/widgets/gradient_scaffold.dart'; // New

class ShareSaveScreen extends StatefulWidget {
  final String sharedLink;
  final VoidCallback? onLinkSaved;

  const ShareSaveScreen({
    super.key,
    required this.sharedLink,
    this.onLinkSaved,
  });

  @override
  State<ShareSaveScreen> createState() => _ShareSaveScreenState();
}

class _ShareSaveScreenState extends State<ShareSaveScreen> {
  List<Folder> folders = [];
  bool loading = true;
  late final String cleanUrl;

  @override
  void initState() {
    super.initState();
    cleanUrl = MetadataExtractor.extractCleanUrl(widget.sharedLink);
    _loadFoldersAndShowSuggestions();
  }

  Future<void> _loadFoldersAndShowSuggestions() async {
    // Check if we extracted a valid URL (should start with http/https)
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      print('[SHARE_SCREEN] No valid URL found in shared text: $cleanUrl');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid link found in shared text'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Wait for the snackbar to be readable, then close the app
      await Future.delayed(const Duration(seconds: 2));
      
      const platform = MethodChannel('shared_link');
      try {
        await platform.invokeMethod('closeApp');
      } catch (e) {
        if (mounted) Navigator.pop(context);
      }
      return;
    }

    print('[SHARE_SCREEN] Loading folders...');
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('folders', orderBy: 'created_at DESC');

    if (!mounted) return;

    setState(() {
      folders = result.map((e) => Folder.fromMap(e)).toList();
      loading = false;
    });

    // Show suggestion dialog after folders are loaded
    _showSuggestionDialog();
  }

  Future<void> _showSuggestionDialog() async {
    print('[SHARE_SCREEN] Showing suggestion dialog');
    try {
      print('[SHARE_SCREEN] Extracting metadata and content...');
      final metadata = await MetadataExtractor.extractMetadata(cleanUrl);
      String title = metadata['title'] ?? '';
      final description = metadata['description'] ?? '';
      final content = metadata['content'] ?? '';
      final imageUrl = metadata['image'] ?? '';

      // Extract extra text from sharedLink (often contains the real title!)
      String sharedText = widget.sharedLink.replaceAll(cleanUrl, '').trim();
      if (sharedText.isNotEmpty) {
        // Clean up common share prefixes
        sharedText = sharedText.replaceAll(RegExp(r'^Check this out:\s*', caseSensitive: false), '');
        
        // Use shared text if it's substantial, or if the extracted title is generic
        if (sharedText.length > 3) {
          title = sharedText;
        } else if (title.isEmpty || title.contains('Link') || title == 'YouTube Video') {
          title = sharedText.isNotEmpty ? sharedText : title;
        }
      }

      if (!mounted) {
        print('[SHARE_SCREEN] Widget not mounted after metadata extraction');
        return;
      }

      print('[SHARE_SCREEN] Showing suggestion dialog with ${folders.length} folders');
      // Show folder suggestion dialog
      final selectedFolder = await showDialog<Folder>(
        context: context,
        barrierDismissible: false,
        builder: (_) => FolderSuggestionDialog(
          linkUrl: cleanUrl,
          linkTitle: title,
          linkDescription: description,
          linkContent: content,
          folders: folders,
        ),
      );

      print('[SHARE_SCREEN] Dialog returned: $selectedFolder');

      if (selectedFolder == null || !mounted) {
        print('[SHARE_SCREEN] No folder selected or widget unmounted');
        // Close the app if no folder selected
        const platform = MethodChannel('shared_link');
        try {
          await platform.invokeMethod('closeApp');
        } catch (e) {
          if (mounted) Navigator.pop(context);
        }
        return;
      }

      // Save link to selected folder
      // Show edit dialog
      if (!mounted) return;
      
      final result = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _EditLinkDialog(
          title: title,
          url: cleanUrl,
        ),
      );

      if (result == null) {
         print('[SHARE_SCREEN] Edit dialog cancelled');
         // If cancelled, we arguably should just close the app or return to prev state
         // For now, let's close the app as this is a "Save" flow interruption
         const platform = MethodChannel('shared_link');
         try {
           await platform.invokeMethod('closeApp');
         } catch (e) {
           if (mounted) Navigator.pop(context);
         }
         return;
      }

      await _saveLinkToFolder(
        cleanUrl, 
        selectedFolder, 
        result['title'] ?? title, 
        description,
        result['note'] ?? '',
        imageUrl,
      );
    } catch (e, st) {
      print('[SHARE_SCREEN] Error in suggestion: $e');
      print('[SHARE_SCREEN] Stack: $st');
      // If metadata extraction fails, show simple picker
      if (!mounted) return;
      _showSimpleFolderPicker();
    }
  }

  /// Simple folder picker (fallback)
  void _showSimpleFolderPicker() {
    print('[SHARE_SCREEN] Showing simple folder picker (fallback)');
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: 400,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Save to folder',
                    style: AppTheme.heading3,
                  ),
                ),
                Expanded(
                  child: folders.isEmpty
                      ? const Center(
                          child: Text('No folders available'),
                        )
                      : ListView.builder(
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            return ListTile(
                              leading: Icon(
                                Icons.folder,
                                color: AppTheme.primaryColor,
                              ),
                              title: Text(
                                folder.name,
                                style: AppTheme.bodyLarge,
                              ),
                              onTap: () async {
                                // Show edit dialog even for fallback
                                final result = await showDialog<Map<String, String>>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => _EditLinkDialog(
                                    title: cleanUrl,
                                    url: cleanUrl,
                                  ),
                                );

                                if (result == null) return;

                                await _saveLinkToFolder(
                                  cleanUrl,
                                  folder,
                                  result['title'] ?? cleanUrl,
                                  '',
                                  result['note'] ?? '',
                                  '',
                                );
                                // Removed redundant pops as _saveLinkToFolder handles closing the app
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveLinkToFolder(
    String url,
    Folder folder,
    String title,
    String description,
    String note,
    String imageUrl,
  ) async {
    try {
      var normalizedUrl = _normalizeUrlForComparison(url);

      print('[SHARE_SCREEN] Checking duplicate for URL: $normalizedUrl in folder: ${folder.id}');

      // Check for duplicate link URLs in this folder
      final db = await DatabaseHelper.instance.database;
      final existing = await db.query(
        'links',
        where: 'folder_id = ?',
        whereArgs: [folder.id],
      );

      // Check if any existing link has the same base URL
      final isDuplicate = existing.any((link) {
        final existingNormalized = _normalizeUrlForComparison(link['url'] as String);
        return existingNormalized == normalizedUrl;
      });

      if (isDuplicate) {
        print('[SHARE_SCREEN] Duplicate detected! Not saving.');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This link already exists in this folder')),
        );
        
        // Wait a moment for SnackBar to be visible, then close the app
        await Future.delayed(const Duration(seconds: 1));
        
        if (!mounted) return;
        
        // Close the app using platform channel to return to caller
        const platform = MethodChannel('shared_link');
        try {
          await platform.invokeMethod('closeApp');
        } catch (e) {
          print('Error closing app: $e');
          // Fallback: just pop the navigation
          if (mounted) Navigator.pop(context);
        }
        return;
      }

      // Use title if available, otherwise use domain
      String displayTitle = title;
      if (displayTitle.isEmpty) {
        try {
          final uri = Uri.parse(url);
          displayTitle = uri.host.replaceAll('www.', '');
        } catch (e) {
          displayTitle = 'Link';
        }
      }

      await DatabaseHelper.instance.insertLink({
        'folder_id': folder.id,
        'url': url,
        'title': displayTitle,
        'domain': _extractDomain(url),
        'image_url': imageUrl.isNotEmpty ? imageUrl : null,
        'notes': note,
      });

      print('[SHARE_SCREEN] Saved link to folder ${folder.id}');

      print('[SHARE_SCREEN] Triggering Confetti Popup (mounted: $mounted)');
      if (!mounted) {
        print('[SHARE_SCREEN] ABORTING: Not mounted!');
        return;
      }

      // Show success popup
      await SuccessConfettiPopup.show(
        context: context,
        title: 'Link Saved!',
        message: 'Your link has been saved successfully',
      );
      print('[SHARE_SCREEN] Confetti Popup finished, closing app...');

      // Close the app using platform channel to return to caller
      const platform = MethodChannel('shared_link');
      try {
        await platform.invokeMethod('closeApp');
      } catch (e) {
        print('Error closing app: $e');
        // Fallback: clear shared link state and pop navigation
        widget.onLinkSaved?.call();
        if (mounted) Navigator.pop(context);
      }
    } catch (e, st) {
      print('SAVE FAILED: $e');
      print('$st');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save link')),
      );
      
      // Wait a moment for SnackBar to be visible, then close the app
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      // Close the app using platform channel to return to caller
      const platform = MethodChannel('shared_link');
      try {
        await platform.invokeMethod('closeApp');
      } catch (e) {
        print('Error closing app: $e');
        // Fallback: just pop the navigation
        if (mounted) Navigator.pop(context);
      }
    }
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceAll('www.', '');
    } catch (e) {
      return '';
    }
  }

  String _normalizeUrlForComparison(String url) {
    try {
      final uri = Uri.parse(url);
      // Remove trailing slash and query parameters for comparison
      String path = uri.path;
      if (path.endsWith('/') && path.length > 1) {
        path = path.substring(0, path.length - 1);
      }
      // Return scheme + host + path (ignore query and fragment)
      return '${uri.scheme}://${uri.host}$path';
    } catch (e) {
      // Fallback: just remove trailing slash
      return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    }
  }



  @override
  void dispose() {
    print('[SHARE_SCREEN] ShareSaveScreen DISPOSED');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Save link to'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EditLinkDialog extends StatefulWidget {
  final String title;
  final String url;

  const _EditLinkDialog({
    required this.title,
    required this.url,
  });

  @override
  State<_EditLinkDialog> createState() => _EditLinkDialogState();
}

class _EditLinkDialogState extends State<_EditLinkDialog> {
  late TextEditingController _titleController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, {
      'title': _titleController.text.trim(),
      'note': _noteController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Link Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.url,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white70 
                    : AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                alignLabelWithHint: true,
                hintText: 'Add your notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}