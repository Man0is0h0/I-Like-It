import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/models/folder_model.dart';
import '../../core/utils/folder_suggester.dart';
import '../../theme/app_theme.dart';
import '../folders/add_folder_dialog.dart';

class FolderSuggestionDialog extends StatefulWidget {
  final String linkTitle;
  final String linkDescription;
  final String linkUrl;
  final String linkContent;
  final List<Folder> folders;

  const FolderSuggestionDialog({
    super.key,
    required this.linkTitle,
    required this.linkDescription,
    required this.linkUrl,
    required this.linkContent,
    required this.folders,
  });

  @override
  State<FolderSuggestionDialog> createState() => _FolderSuggestionDialogState();
}

class _FolderSuggestionDialogState extends State<FolderSuggestionDialog> {
  late Future<SuggestionResult> suggestionFuture;
  bool isLoadingAI = false;
  SuggestionResult? _lastSuggestion;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use async version to get AI suggestions
    suggestionFuture = FolderSuggester.suggestFoldersAsync(
      linkUrl: widget.linkUrl,
      linkTitle: widget.linkTitle,
      linkDescription: widget.linkDescription,
      linkContent: widget.linkContent,
      existingFolders: widget.folders,
    );

    // Call setState when suggestion resolves to rebuild parent actions with _lastSuggestion
    suggestionFuture.then((result) {
      if (mounted) {
        setState(() {
          _lastSuggestion = result;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
      title: const Text('Select or Create Folder'),
      content: FutureBuilder<SuggestionResult>(
        future: suggestionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing video...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Text('Error loading suggestions');
          }

          final suggestion = snapshot.data!;
          _lastSuggestion = suggestion;

          // Filter folders based on search query
          final query = _searchQuery.toLowerCase();
          final filteredSuggested = suggestion.suggestedFolders
              .where((sf) => sf.folder.name.toLowerCase().contains(query))
              .toList();
          final otherFolders = widget.folders
              .where(
                (f) => !suggestion.suggestedFolders.any(
                  (sf) => sf.folder.id == f.id,
                ),
              )
              .where((f) => f.name.toLowerCase().contains(query))
              .toList();
          final filteredAI = suggestion.aiSuggestions
              .where((name) => name.toLowerCase().contains(query))
              .toList();

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search folders...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),

                // Show AI suggestions if available
                if (filteredAI.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'AI Suggestions:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.lightbulb,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...filteredAI.map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: GestureDetector(
                              onTap: () => _createFolderWithName(name),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.green.withOpacity(0.05),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.add_circle,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Suggested folders
                if (filteredSuggested.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suggested folders:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...filteredSuggested.map((scoredFolder) {
                          final isStrongMatch = scoredFolder.score >= 3;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: isStrongMatch
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 24,
                                  )
                                : const Icon(
                                    Icons.folder,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  ),
                            title: Text(scoredFolder.folder.name),
                            subtitle: Text(
                              scoredFolder.matchType,
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () =>
                                Navigator.pop(context, scoredFolder.folder),
                          );
                        }),
                      ],
                    ),
                  ),

                // Other folders
                if (otherFolders.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Other folders:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...otherFolders.map((folder) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.folder_open, size: 24),
                            title: Text(folder.name),
                            onTap: () => Navigator.pop(context, folder),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            if (_lastSuggestion != null) {
              _showCreateFolderDialog(_lastSuggestion!);
            } else {
              _createFolderWithName('');
            }
          },
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create new folder',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              if (_lastSuggestion != null &&
                  _lastSuggestion!.suggestedNewFolderName.isNotEmpty)
                Text(
                  _lastSuggestion!.suggestedNewFolderName,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ));
  }

  void _createFolderWithName(String name) async {
    final result = await showDialog<Folder>(
      context: context,
      builder: (context) => AddFolderDialog(suggestedName: name),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  void _showCreateFolderDialog(SuggestionResult suggestion) async {
    final result = await showDialog<Folder>(
      context: context,
      builder: (context) =>
          AddFolderDialog(suggestedName: suggestion.suggestedNewFolderName),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }
}
