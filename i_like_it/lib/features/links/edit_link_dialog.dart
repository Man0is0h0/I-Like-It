import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/link_model.dart';
import '../../theme/app_theme.dart';

class EditLinkDialog extends StatefulWidget {
  final LinkItem link;

  const EditLinkDialog({super.key, required this.link});

  @override
  State<EditLinkDialog> createState() => _EditLinkDialogState();
}

class _EditLinkDialogState extends State<EditLinkDialog> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.link.title);
    _notesController = TextEditingController(text: widget.link.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLink() async {
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    await DatabaseHelper.instance.updateLink({
      'id': widget.link.id,
      'title': title,
      'notes': notes.isEmpty ? null : notes,
    });

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontSize: 14,
    );

    return AlertDialog(
      title: const Text('Edit Link'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title',
              style:
                  (Theme.of(context).textTheme.bodyMedium ??
                          AppTheme.bodyMedium)
                      .copyWith(fontWeight: FontWeight.w600),
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
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Notes',
              style:
                  (Theme.of(context).textTheme.bodyMedium ??
                          AppTheme.bodyMedium)
                      .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: inputStyle,
              decoration: InputDecoration(
                hintText: 'Add notes... (optional)',
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
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveLink,
          child: _isSaving
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
    );
  }
}
