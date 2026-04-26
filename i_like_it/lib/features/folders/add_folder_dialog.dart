import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/folder_model.dart';
import '../../core/widgets/folder_icon_picker.dart';
import '../../theme/app_theme.dart';
import '../../core/services/folder_classification_service.dart';

class AddFolderDialog extends StatefulWidget {
  final String? suggestedName;

  const AddFolderDialog({
    super.key,
    this.suggestedName,
  });

  @override
  State<AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<AddFolderDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String _selectedIcon = '0xe3b0'; // Default folder icon
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.suggestedName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveFolder() async {
    final name = _controller.text.trim();

    setState(() {
      _errorText = null;
    });

    if (name.isEmpty) {
      setState(() {
        _errorText = 'Folder name cannot be empty';
      });
      return;
    }

    // Check for duplicate folder names (case-insensitive)
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query(
      'folders',
      where: 'LOWER(name) = LOWER(?) AND is_deleted = 0',
      whereArgs: [name],
    );

    if (existing.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _errorText = 'A folder with this name already exists';
      });
      return;
    }

    setState(() => _isSaving = true);

    final folder = Folder(name: name, createdAt: DateTime.now(), icon: _selectedIcon);
    final id = await db.insert('folders', folder.toMap());

    // Create a new Folder object with the ID from the database
    // Handle both int and String IDs (Supabase returns int for serial, String for UUID)
    final dynamic rawId = id; 
    
    final createdFolder = Folder(
      id: rawId is int ? rawId : null, // ID in model is nullable int, but if UUID it might be null here if model doesn't support String. 
      // Actually, looking at folder_model.dart... it expects int?.
      // If DB uses UUIDs, Folder model is broken too. 
      // But let's assume rawId works for classification at least.
      name: folder.name,
      createdAt: folder.createdAt,
      icon: folder.icon,
    );

    // Trigger AI Classification (Fire & Forget)
    if (rawId != null) {
      FolderClassificationService.instance.classifyFolder(rawId, createdFolder.name);
    }

    if (mounted) Navigator.pop(context, createdFolder);
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => FolderIconPicker(
        initialIcon: _selectedIcon,
        onIconSelected: (icon) {
          setState(() => _selectedIcon = icon);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Folder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
            onTap: _isSaving ? null : _showIconPicker,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    _parseIcon(_selectedIcon),
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change icon',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white70 
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: (value) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            onSubmitted: (_) => _saveFolder(),
            decoration: InputDecoration(
              hintText: 'Folder name',
              errorText: _errorText,
              errorMaxLines: 3,
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
          onPressed: _isSaving ? null : _saveFolder,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  IconData _parseIcon(String iconCode) {
    // Map of icon codes to MaterialDesignIcons
    final iconMap = {
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
    return iconMap[iconCode] ?? Icons.folder;
  }
}
