import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/link_model.dart';
import '../../core/utils/metadata_extractor.dart';
import '../../core/widgets/success_confetti_popup.dart';
import '../../theme/app_theme.dart';

class AddLinkDialog extends StatefulWidget {
  final int folderId;

  const AddLinkDialog({super.key, required this.folderId});

  @override
  State<AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<AddLinkDialog> {
  final _controller = TextEditingController();
  bool _saving = false;

  Future<void> _saveLink() async {
    print('[ADD_LINK] _saveLink called');
    var url = _controller.text.trim();

    if (!url.startsWith('http')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid URL')));
      return;
    }

    // Normalize URL: remove trailing slash and query parameters for consistent comparison
    var normalizedUrl = _normalizeUrlForComparison(url);

    print(
      '[ADD_LINK] Checking duplicate for URL: $normalizedUrl in folder: ${widget.folderId}',
    );

    // Check for duplicate link URLs in this folder
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query(
      'links',
      where: 'folder_id = ?',
      whereArgs: [widget.folderId],
    );

    // Check if any existing link has the same base URL
    final isDuplicate = existing.any((link) {
      final existingNormalized = _normalizeUrlForComparison(
        link['url'] as String,
      );
      return existingNormalized == normalizedUrl;
    });

    print(
      '[ADD_LINK] Found ${existing.length} total links, duplicate: $isDuplicate',
    );

    if (isDuplicate) {
      print('[ADD_LINK] Duplicate detected! Not saving.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This link already exists in this folder'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Extract metadata from the URL
      final metadata = await MetadataExtractor.extractMetadata(url);
      String title = metadata['title'] ?? '';
      String imageUrl = metadata['image'] ?? '';

      // If no title found, use domain as title
      if (title.isEmpty) {
        try {
          final uri = Uri.parse(url);
          title = uri.host.replaceAll('www.', '');
        } catch (e) {
          title = 'Link';
        }
      }

      // Show dialog to let user add notes
      if (!mounted) {
        setState(() => _saving = false);
        return;
      }
      final details = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => _DetailsDialog(initialTitle: title),
      );

      // Check again for duplicates before inserting (in case dialog took a long time)
      final duplicateCheck = await db.query(
        'links',
        where: 'folder_id = ?',
        whereArgs: [widget.folderId],
      );

      final isDuplicateCheck = duplicateCheck.any((link) {
        final existingNormalized = _normalizeUrlForComparison(
          link['url'] as String,
        );
        return existingNormalized == normalizedUrl;
      });

      if (isDuplicateCheck) {
        if (!mounted) {
          setState(() => _saving = false);
          return;
        }
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This link was already saved')),
        );
        if (mounted) Navigator.pop(context);
        return;
      }

      final finalTitle = details?['title'] ?? title;
      final notes = details?['notes'] ?? '';

      final link = LinkItem(
        folderId: widget.folderId,
        url: url,
        title: finalTitle.isNotEmpty ? finalTitle : title,
        domain: _extractDomain(url),
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        notes: notes,
        createdAt: DateTime.now(),
      );

      try {
        await DatabaseHelper.instance.insertLink(link.toMap());
        print('Saved link with URL: $url to folder: ${widget.folderId}');
      } on DatabaseException catch (e) {
        if (e.toString().contains('UNIQUE constraint failed')) {
          if (!mounted) {
            setState(() => _saving = false);
            return;
          }
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This link already exists in this folder'),
            ),
          );
          if (mounted) Navigator.pop(context);
          return;
        }
        rethrow;
      }

      if (mounted) {
        // Show success popup
        await SuccessConfettiPopup.show(
          context: context,
          title: 'Link Saved!',
          message: 'Your link has been saved successfully',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      // Handle duplicate constraint errors
      if (e is DatabaseException &&
          e.toString().contains('UNIQUE constraint failed')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This link already exists in this folder'),
          ),
        );
      } else {
        String displayError = 'Failed to save link. Please try again.';
        final lowerMsg = e.toString().toLowerCase();
        if (!lowerMsg.contains('exception') && 
            !lowerMsg.contains('api key') && 
            !lowerMsg.contains('socket') && 
            !lowerMsg.contains('supabase')) {
          displayError = 'Failed to save link: $e';
        }
        
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(displayError)));
      }
    }
  }

  String? _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceAll('www.', '');
    } catch (e) {
      return null;
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontSize: 14,
    );

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
      title: const Text('Add Link'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: inputStyle,
        decoration: InputDecoration(
          hintText: 'Paste link here',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onSubmitted: (_) => _saveLink(),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _saveLink,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    ));
  }
}

class _DetailsDialog extends StatefulWidget {
  final String initialTitle;

  const _DetailsDialog({required this.initialTitle});

  @override
  State<_DetailsDialog> createState() => _DetailsDialogState();
}

class _DetailsDialogState extends State<_DetailsDialog> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontSize: 14,
    );

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
      title: const Text('Link Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Title',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: inputStyle,
              decoration: InputDecoration(
                hintText: 'Link title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notes (Optional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: inputStyle,
              decoration: InputDecoration(
                hintText:
                    'Add your notes... (e.g., "Funny cat video", "Read later")',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, {
            'title': widget.initialTitle,
            'notes': '',
          }),
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'title': _titleController.text.trim(),
              'notes': _notesController.text.trim(),
            });
          },
          child: const Text('Save'),
        ),
      ],
    ));
  }
}
