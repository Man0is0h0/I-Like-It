import 'package:flutter/material.dart';

class FolderIconPicker extends StatefulWidget {
  final String initialIcon;
  final ValueChanged<String> onIconSelected;

  const FolderIconPicker({
    super.key,
    required this.initialIcon,
    required this.onIconSelected,
  });

  @override
  State<FolderIconPicker> createState() => _FolderIconPickerState();
}

class _FolderIconPickerState extends State<FolderIconPicker> {
  late String _selectedIcon;
  late TextEditingController _searchController;
  List<Map<String, dynamic>> _filteredIcons = [];

  static const List<Map<String, dynamic>> allAvailableIcons = [
    // Folder Icons
    {'code': '0xe3b0', 'icon': Icons.folder, 'name': 'Folder', 'category': 'Folder'},
    {'code': '0xf06b', 'icon': Icons.folder_open, 'name': 'Open Folder', 'category': 'Folder'},
    {'code': '0xf07b', 'icon': Icons.folder_special, 'name': 'Special', 'category': 'Folder'},
    // Document Icons
    {'code': '0xf1c6', 'icon': Icons.description, 'name': 'Document', 'category': 'Document'},
    {'code': '0xf0f6', 'icon': Icons.file_present, 'name': 'File', 'category': 'Document'},
    {'code': '0xe80c', 'icon': Icons.article, 'name': 'Article', 'category': 'Document'},
    {'code': '0xe8d0', 'icon': Icons.note, 'name': 'Note', 'category': 'Document'},
    {'code': '0xe3c9', 'icon': Icons.notes, 'name': 'Notes', 'category': 'Document'},
    // Media Icons
    {'code': '0xe8a5', 'icon': Icons.image, 'name': 'Image', 'category': 'Media'},
    {'code': '0xe04b', 'icon': Icons.video_library, 'name': 'Video', 'category': 'Media'},
    {'code': '0xf001', 'icon': Icons.music_note, 'name': 'Music', 'category': 'Media'},
    {'code': '0xe3fc', 'icon': Icons.photo, 'name': 'Photo', 'category': 'Media'},
    {'code': '0xe04e', 'icon': Icons.videocam, 'name': 'Camera', 'category': 'Media'},
    {'code': '0xe3b1', 'icon': Icons.collections, 'name': 'Gallery', 'category': 'Media'},
    // Organization Icons
    {'code': '0xe875', 'icon': Icons.bookmark, 'name': 'Bookmark', 'category': 'Organization'},
    {'code': '0xe839', 'icon': Icons.favorite, 'name': 'Favorite', 'category': 'Organization'},
    {'code': '0xf591', 'icon': Icons.star, 'name': 'Star', 'category': 'Organization'},
    {'code': '0xe5ca', 'icon': Icons.label, 'name': 'Label', 'category': 'Organization'},
    {'code': '0xe3b8', 'icon': Icons.category, 'name': 'Category', 'category': 'Organization'},
    {'code': '0xe863', 'icon': Icons.archive, 'name': 'Archive', 'category': 'Organization'},
    // Business/Work Icons
    {'code': '0xe8e0', 'icon': Icons.work, 'name': 'Work', 'category': 'Business'},
    {'code': '0xe8d5', 'icon': Icons.business, 'name': 'Business', 'category': 'Business'},
    {'code': '0xe8d3', 'icon': Icons.engineering, 'name': 'Engineering', 'category': 'Business'},
    {'code': '0xf1bc', 'icon': Icons.assignment, 'name': 'Assignment', 'category': 'Business'},
    {'code': '0xe8dd', 'icon': Icons.task, 'name': 'Task', 'category': 'Business'},
    {'code': '0xe8dc', 'icon': Icons.checklist, 'name': 'Checklist', 'category': 'Business'},
    {'code': '0xe192', 'icon': Icons.attach_money, 'name': 'Finance', 'category': 'Business'},
    {'code': '0xf170', 'icon': Icons.trending_up, 'name': 'Trending', 'category': 'Business'},
    // Personal Icons
    {'code': '0xe871', 'icon': Icons.home, 'name': 'Home', 'category': 'Personal'},
    {'code': '0xf0e6', 'icon': Icons.school, 'name': 'School', 'category': 'Personal'},
    {'code': '0xf086', 'icon': Icons.lightbulb, 'name': 'Ideas', 'category': 'Personal'},
    {'code': '0xe919', 'icon': Icons.psychology, 'name': 'Brain', 'category': 'Personal'},
    {'code': '0xf195', 'icon': Icons.travel_explore, 'name': 'Travel', 'category': 'Personal'},
    {'code': '0xf04a', 'icon': Icons.sports_basketball, 'name': 'Sports', 'category': 'Personal'},
    // Tech Icons
    {'code': '0xf123', 'icon': Icons.code, 'name': 'Code', 'category': 'Tech'},
    {'code': '0xf0d6', 'icon': Icons.settings, 'name': 'Settings', 'category': 'Tech'},
    {'code': '0xe30b', 'icon': Icons.computer, 'name': 'Computer', 'category': 'Tech'},
    {'code': '0xe325', 'icon': Icons.phone_android, 'name': 'Mobile', 'category': 'Tech'},
    {'code': '0xe3ce', 'icon': Icons.terminal, 'name': 'Terminal', 'category': 'Tech'},
    {'code': '0xe30c', 'icon': Icons.storage, 'name': 'Storage', 'category': 'Tech'},
    // Shopping & Lifestyle
    {'code': '0xe5dd', 'icon': Icons.shopping_bag, 'name': 'Shopping', 'category': 'Lifestyle'},
    {'code': '0xe53a', 'icon': Icons.shopping_cart, 'name': 'Cart', 'category': 'Lifestyle'},
    {'code': '0xe32e', 'icon': Icons.restaurant, 'name': 'Food', 'category': 'Lifestyle'},
    {'code': '0xe6d3', 'icon': Icons.local_cafe, 'name': 'Cafe', 'category': 'Lifestyle'},
    {'code': '0xe8a0', 'icon': Icons.health_and_safety, 'name': 'Health', 'category': 'Lifestyle'},
    {'code': '0xe8c9', 'icon': Icons.fitness_center, 'name': 'Fitness', 'category': 'Lifestyle'},
    // Social & Communication
    {'code': '0xe0b9', 'icon': Icons.people, 'name': 'People', 'category': 'Social'},
    {'code': '0xe0ba', 'icon': Icons.person, 'name': 'Person', 'category': 'Social'},
    {'code': '0xe0c0', 'icon': Icons.mail, 'name': 'Email', 'category': 'Social'},
    {'code': '0xe0c1', 'icon': Icons.chat, 'name': 'Chat', 'category': 'Social'},
    {'code': '0xe0c2', 'icon': Icons.comment, 'name': 'Comment', 'category': 'Social'},
    {'code': '0xe0c8', 'icon': Icons.notifications, 'name': 'Notifications', 'category': 'Social'},
    // Time & Calendar
    {'code': '0xe935', 'icon': Icons.calendar_today, 'name': 'Calendar', 'category': 'Time'},
    {'code': '0xe937', 'icon': Icons.schedule, 'name': 'Schedule', 'category': 'Time'},
    {'code': '0xe192', 'icon': Icons.access_time, 'name': 'Time', 'category': 'Time'},
    {'code': '0xe8c5', 'icon': Icons.event, 'name': 'Event', 'category': 'Time'},
    // Misc
    {'code': '0xe25c', 'icon': Icons.lock, 'name': 'Lock', 'category': 'Misc'},
    {'code': '0xe899', 'icon': Icons.key, 'name': 'Key', 'category': 'Misc'},
    {'code': '0xe8d7', 'icon': Icons.palette, 'name': 'Palette', 'category': 'Misc'},
    {'code': '0xf05a', 'icon': Icons.pets, 'name': 'Pet', 'category': 'Misc'},
    {'code': '0xe55b', 'icon': Icons.info, 'name': 'Info', 'category': 'Misc'},
    {'code': '0xe5d5', 'icon': Icons.help, 'name': 'Help', 'category': 'Misc'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon;
    _searchController = TextEditingController();
    _filteredIcons = List.from(allAvailableIcons);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIcons = List.from(allAvailableIcons);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredIcons = allAvailableIcons
            .where((icon) =>
                (icon['name'] as String).toLowerCase().contains(lowerQuery) ||
                (icon['category'] as String).toLowerCase().contains(lowerQuery))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select Folder Icon',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _updateSearch,
              decoration: InputDecoration(
                hintText: 'Search icons...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredIcons.isEmpty
                ? Center(
                    child: Text(
                      'No icons found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredIcons.length,
                    itemBuilder: (context, index) {
                      final iconData = _filteredIcons[index];
                      final isSelected = _selectedIcon == iconData['code'];

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedIcon = iconData['code']);
                        },
                        child: Tooltip(
                          message: iconData['name'] as String,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.shade300,
                                width: isSelected ? 3 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  iconData['icon'] as IconData,
                                  size: 28,
                                  color: isSelected ? Colors.blue : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onIconSelected(_selectedIcon);
                    Navigator.pop(context);
                  },
                  child: const Text('Select'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
