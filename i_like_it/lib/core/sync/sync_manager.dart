import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import 'remote_datasource.dart';
import '../auth/user_session_manager.dart';

class SyncManager {
  static final SyncManager instance = SyncManager._();

  late RemoteDataSource _remote;
  final DatabaseHelper _local = DatabaseHelper.instance;
  bool _userCreated = false;

  // Stream to notify UI of sync completion
  final _syncCompleteController = StreamController<void>.broadcast();
  Stream<void> get onSyncCompleted => _syncCompleteController.stream;

  RemoteDataSource get remoteDataSource => _remote;

  SyncManager._();

  void initialize(RemoteDataSource remote) {
    _remote = remote;

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        sync();
      }
    });

    // Initial sync
    sync();
  }

  void resetUserCreated() {
    _userCreated = false;
  }

  Future<void>? _activeSync;

  Future<void> sync() async {
    if (_activeSync != null) {
      return _activeSync;
    }

    _activeSync = _performSync();
    try {
      await _activeSync;
    } finally {
      _activeSync = null;
    }
  }

  Future<void> _performSync() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) return;

    // Check if UserSessionManager is ready
    String userId;
    try {
      userId = UserSessionManager.userId;
    } catch (_) {
      print('[SyncManager] UserSessionManager not ready, deferring sync.');
      return;
    }

    // Check if Supabase auth session is active
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      print('[SyncManager] No active Supabase session. Sync requires authentication.');
      return;
    }
    if (session.isExpired) {
      print('[SyncManager] Supabase session expired. Attempting refresh...');
      try {
        await Supabase.instance.client.auth.refreshSession();
        print('[SyncManager] Session refreshed successfully.');
      } catch (e) {
        print('[SyncManager] Failed to refresh session: $e');
        return;
      }
    }

    print('[SyncManager] Starting sync for user: $userId (session active)...');

    try {
      // 1. Update last_seen
      print('[SyncManager] Updating last seen...');
      await _remote.updateLastSeen();

      // 2. Push Local Changes
      await _pushFolders();
      await _pushLinks();

      // 3. Pull Remote Changes
      final lastSync = DateTime.now()
          .subtract(const Duration(days: 365))
          .toIso8601String();

      await _pullFolders(lastSync);
      await _pullLinks(lastSync);

      print('[SyncManager] Sync completed successfully.');
      _syncCompleteController.add(null);
    } catch (e, st) {
      print('[SyncManager] Sync failed: $e');
      print('[SyncManager] Stack trace: $st');
    }
  }

  Future<void> pushLocalChanges() async {
    try {
      await _pushFolders();
      await _pushLinks();
    } catch (e) {
      print('[SyncManager] Failed to push local changes: $e');
    }
  }

  Future<void> _pushFolders() async {
    final unsynced = await _local.getUnsyncedFolders();
    print('[SyncManager] _pushFolders found ${unsynced.length} unsynced folders');
    for (var folder in unsynced) {
      try {
        final updatedAt =
            folder['updated_at'] as String? ?? DateTime.now().toIso8601String();

        final cloudData = {
          'user_id': UserSessionManager.userId,
          'name': folder['name'],
          'icon': folder['icon'],
          'is_deleted': folder['is_deleted'] == 1,
          'updated_at': updatedAt,
          'system_category': folder['system_category'],
          if (folder['cloud_id'] != null) 'id': folder['cloud_id'],
        };

        print(
          '[SyncManager] Pushing folder ${folder['id']} (cloud_id: ${folder['cloud_id']}) data: $cloudData',
        );
        final response = await _remote.upsertFolder(cloudData);
        await _local.updateFolderSyncStatus(
          folder['id'],
          response['id'],
          updatedAt,
        );
        print('[SyncManager] Successfully pushed folder ${folder['id']} -> cloud_id: ${response['id']}');
      } catch (e, st) {
        print('[SyncManager] ERROR pushing folder ${folder['id']}: $e');
        print('[SyncManager] Stack: $st');
      }
    }
  }

  Future<void> _pushLinks() async {
    final unsynced = await _local.getUnsyncedLinks();
    print('[SyncManager] _pushLinks found ${unsynced.length} unsynced links');
    for (var link in unsynced) {
      try {
        final db = await _local.database;
        final folderRes = await db.query(
          'folders',
          columns: ['cloud_id'],
          where: 'id = ?',
          whereArgs: [link['folder_id']],
        );

        if (folderRes.isEmpty) {
          print(
            '[SyncManager] Skipping link ${link['id']} because folder ${link['folder_id']} not found in local DB',
          );
          continue;
        }

        if (folderRes.first['cloud_id'] == null) {
          print(
            '[SyncManager] Skipping link ${link['id']} because folder ${link['folder_id']} has no cloud_id yet',
          );
          continue;
        }

        final cloudFolderId = folderRes.first['cloud_id'] as String;
        final updatedAt =
            link['updated_at'] as String? ?? DateTime.now().toIso8601String();

        final cloudData = {
          'user_id': UserSessionManager.userId,
          'folder_id': cloudFolderId,
          'url': link['url'],
          'title': link['title'],
          'domain': link['domain'],
          'image_url': link['image_url'],
          'notes': link['notes'],
          'is_deleted': link['is_deleted'] == 1,
          'updated_at': updatedAt,
          if (link['cloud_id'] != null) 'id': link['cloud_id'],
        };

        print(
          '[SyncManager] Pushing link ${link['id']} to cloud_folder $cloudFolderId...',
        );
        final response = await _remote.upsertLink(cloudData);
        await _local.updateLinkSyncStatus(
          link['id'],
          response['id'],
          updatedAt,
        );
        print(
          '[SyncManager] Successfully pushed link ${link['id']}! New cloud_id: ${response['id']}',
        );
      } catch (e, st) {
        print('[SyncManager] ERROR pushing link ${link['id']}: $e');
        print('[SyncManager] Stack: $st');
      }
    }
  }

  Future<void> _pullFolders(String lastSyncTime) async {
    final newFolders = await _remote.fetchNewFolders(lastSyncTime);
    for (var folder in newFolders) {
      await _local.upsertFolderFromCloud(folder);
    }
  }

  Future<void> _pullLinks(String lastSyncTime) async {
    final newLinks = await _remote.fetchNewLinks(lastSyncTime);
    for (var link in newLinks) {
      await _local.upsertLinkFromCloud(link);
    }
  }
}
