import 'package:flutter/material.dart';
import 'package:i_like_it/core/models/folder_model.dart';
import 'package:i_like_it/core/database/database_helper.dart';
import 'package:i_like_it/core/widgets/gradient_scaffold.dart';
import 'folder_card.dart';
import 'add_folder_dialog.dart';
import 'edit_folder_dialog.dart';
import 'package:i_like_it/core/widgets/success_confetti_popup.dart';
import 'package:i_like_it/core/sync/sync_manager.dart';

class AllFoldersScreen extends StatefulWidget {
  const AllFoldersScreen({Key? key}) : super(key: key);

  @override
  State<AllFoldersScreen> createState() => _AllFoldersScreenState();
}

class _AllFoldersScreenState extends State<AllFoldersScreen> {
  List<Folder> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await DatabaseHelper.instance.getFolders();
    if (mounted) {
      setState(() {
        _folders = folders.map((e) => Folder.fromMap(e)).toList();
        _folders.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddFolderDialog() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => const AddFolderDialog(),
    );

    if (result != null) {
      _loadFolders();
      SyncManager.instance.sync();

      if (result is Folder && mounted) {
        await SuccessConfettiPopup.show(
          context: context,
          title: 'Folder Created!',
          message: 'Your folder "${result.name}" has been created successfully',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          'All Folders',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
          ? Center(
              child: Text(
                'No folders yet',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16).copyWith(bottom: 100),
              itemCount: _folders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final folder = _folders[index];
                return FolderCard(folder: folder, onRefresh: _loadFolders);
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFolderDialog,
        backgroundColor: theme.colorScheme.primary,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
      ),
    );
  }
}
