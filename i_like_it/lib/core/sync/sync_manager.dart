import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import 'remote_datasource.dart';
import '../auth/user_session_manager.dart';

class SyncManager {
  static final SyncManager instance = SyncManager._();
  
  late RemoteDataSource _remote;
  final DatabaseHelper _local = DatabaseHelper.instance;
  bool _isSyncing = false;
  bool _userCreated = false;
  
  // Stream to notify UI of sync completion
  final _syncCompleteController = StreamController<void>.broadcast();
  Stream<void> get onSyncCompleted => _syncCompleteController.stream;

  RemoteDataSource get remoteDataSource => _remote;
  
  SyncManager._();
  
  void initialize(RemoteDataSource remote) {
    _remote = remote;
    
    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        sync();
      }
    });

    // Initial sync
    sync();
  }

  void resetUserCreated() {
    _userCreated = false;
  }

  Future<void> sync() async {
    if (_isSyncing) return;
    
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

    _isSyncing = true;
    print('[SyncManager] Starting sync for user: $userId...');

    try {
      // 1. Update last_seen
      print('[SyncManager] Updating last seen...');
      await _remote.updateLastSeen();
      
      // 2. Push Local Changes
      await _pushFolders();
      await _pushLinks();
      
      // 3. Pull Remote Changes
      final lastSync = DateTime.now().subtract(const Duration(days: 365)).toIso8601String(); 
      
      await _pullFolders(lastSync);
      await _pullLinks(lastSync);
      
      print('[SyncManager] Sync completed successfully.');
      _syncCompleteController.add(null);
    } catch (e) {
      print('[SyncManager] Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushFolders() async {
    final unsynced = await _local.getUnsyncedFolders();
    for (var folder in unsynced) {
      try {
        final updatedAt = folder['updated_at'] as String? ?? DateTime.now().toIso8601String();
        
        final cloudData = {
          'user_id': UserSessionManager.userId,
          'name': folder['name'],
          'icon': folder['icon'],
          'is_deleted': folder['is_deleted'] == 1,
          'updated_at': updatedAt,
          'system_category': folder['system_category'],
          if (folder['cloud_id'] != null) 'id': folder['cloud_id'],
        };

        final response = await _remote.upsertFolder(cloudData);
        await _local.updateFolderSyncStatus(folder['id'], response['id'], updatedAt);
      } catch (e) {
        print('[SyncManager] Error pushing folder ${folder['id']}: $e');
      }
    }
  }

  Future<void> _pushLinks() async {
    final unsynced = await _local.getUnsyncedLinks();
    for (var link in unsynced) {
      try {
        final db = await _local.database;
        final folderRes = await db.query('folders', columns: ['cloud_id'], where: 'id = ?', whereArgs: [link['folder_id']]);
        if (folderRes.isEmpty || folderRes.first['cloud_id'] == null) {
          continue; 
        }
        
        final cloudFolderId = folderRes.first['cloud_id'] as String;
        final updatedAt = link['updated_at'] as String? ?? DateTime.now().toIso8601String();

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

        final response = await _remote.upsertLink(cloudData);
        await _local.updateLinkSyncStatus(link['id'], response['id'], updatedAt);
      } catch (e) {
        print('[SyncManager] Error pushing link ${link['id']}: $e');
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
