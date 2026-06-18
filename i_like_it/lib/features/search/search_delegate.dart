import 'package:flutter/material.dart';
import '../../core/utils/metadata_extractor.dart';
import '../../core/utils/url_utils.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/folder_model.dart';
import '../../core/models/link_model.dart';
import '../../theme/app_theme.dart';
import '../links/link_screen.dart';
import '../../core/widgets/gradient_background.dart'; // New
import '../../core/widgets/glass_container.dart'; // New

class GlobalSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return GradientBackground(
      child: _buildSearchResults(context),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(100),
                child: Icon(
                  Icons.search,
                  size: 64,
                  color: AppTheme.textLight.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Search folders and links',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return GradientBackground(
      child: _buildSearchResults(context),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: DatabaseHelper.instance.searchFoldersAndLinks(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        final folderList = data['folders']!.map((e) => Folder.fromMap(e)).toList();
        final linkList = data['links']!.map((e) => LinkItem.fromMap(e)).toList();

        if (folderList.isEmpty && linkList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No results found for "$query"',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (folderList.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  'FOLDERS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              ...folderList.map((folder) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassContainer(
                  padding: EdgeInsets.zero,
                  enableBlur: false, // Optimize performance
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.folder, color: AppTheme.primaryColor),
                    ),
                    title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textLight),
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
                  ),
                ),
              )),
              const SizedBox(height: 24),
            ],
            if (linkList.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  'LINKS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              ...linkList.map((link) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassContainer(
                  padding: EdgeInsets.zero,
                  enableBlur: false, // Optimize performance
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: const Icon(Icons.link, size: 20),
                    ),
                    title: Text(link.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      link.url, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    onTap: () {
                      String url = MetadataExtractor.extractCleanUrl(link.url);
                      if (!url.startsWith('http://') && !url.startsWith('https://')) {
                        url = 'https://$url';
                      }
                      UrlUtils.launchBrowserOrApp(context, url);
                    },
                  ),
                ),
              )),
            ],
          ],
        );
      },
    );
  }
}
