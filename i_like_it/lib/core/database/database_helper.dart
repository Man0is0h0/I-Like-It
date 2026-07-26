import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Stream to notify UI of database changes
  final _dbChangeController = StreamController<void>.broadcast();
  Stream<void> get onDatabaseChanged => _dbChangeController.stream;

  void notifyDatabaseChanged() {
    _dbChangeController.add(null);
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'i_like_it.db');

    final db = await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _sanitizeExistingLinks(db);
    return db;
  }

  Future<void> _sanitizeExistingLinks(Database db) async {
    try {
      final List<Map<String, dynamic>> links = await db.query('links');
      for (var link in links) {
        final String rawUrl = link['url'] as String? ?? '';
        final urlRegex = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
        final match = urlRegex.firstMatch(rawUrl);
        if (match != null) {
          String cleanUrl = match.group(1)!;

          while (cleanUrl.isNotEmpty &&
              (cleanUrl.endsWith('.') ||
                  cleanUrl.endsWith(',') ||
                  cleanUrl.endsWith('!') ||
                  cleanUrl.endsWith('?') ||
                  cleanUrl.endsWith(')') ||
                  cleanUrl.endsWith(']'))) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
          }

          if (cleanUrl != rawUrl) {
            print(
              '[DB_SANITY] Cleaning raw URL in DB: "$rawUrl" -> "$cleanUrl"',
            );
            await db.update(
              'links',
              {'url': cleanUrl},
              where: 'id = ?',
              whereArgs: [link['id']],
            );
          }
        }
      }
    } catch (e) {
      print('[DB_SANITY] Error sanitizing existing links: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE folders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      created_at TEXT NOT NULL,
      icon TEXT DEFAULT '0xe3b0',
      cloud_id TEXT,
      updated_at TEXT,
      is_deleted INTEGER DEFAULT 0,
      synced_at TEXT,
      system_category TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE links (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      folder_id INTEGER NOT NULL,
      url TEXT NOT NULL,
      title TEXT NOT NULL,
      domain TEXT,
      image_url TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      cloud_id TEXT,
      updated_at TEXT,
      is_deleted INTEGER DEFAULT 0,
      synced_at TEXT,
      FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE,
      UNIQUE(folder_id, url)
    )
  ''');

    await db.execute('CREATE INDEX idx_links_folder_id ON links(folder_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add notes column if upgrading from version 1
      try {
        await db.execute('ALTER TABLE links ADD COLUMN notes TEXT');
      } catch (e) {
        // Column may already exist
        print('Migration v1->v2 error: $e');
      }
    }
    if (oldVersion < 3) {
      // Modify unique constraint from just URL to (folder_id, url)
      try {
        // Drop the old index/constraint by recreating the table
        await db.transaction((txn) async {
          // Create backup
          await txn.execute('''
            CREATE TABLE links_backup AS 
            SELECT id, folder_id, url, title, domain, image_url, notes, created_at FROM links
          ''');

          // Drop old table
          await txn.execute('DROP TABLE links');

          // Create new table with correct constraint
          await txn.execute('''
            CREATE TABLE links (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              folder_id INTEGER NOT NULL,
              url TEXT NOT NULL,
              title TEXT NOT NULL,
              domain TEXT,
              image_url TEXT,
              notes TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE,
              UNIQUE(folder_id, url)
            )
          ''');

          // Restore data
          await txn.execute('''
            INSERT INTO links 
            SELECT id, folder_id, url, title, domain, image_url, notes, created_at FROM links_backup
          ''');

          // Drop backup
          await txn.execute('DROP TABLE links_backup');

          // Recreate index
          await txn.execute(
            'CREATE INDEX idx_links_folder_id ON links(folder_id)',
          );
        });
        print('Migration v2->v3 completed successfully');
      } catch (e) {
        print('Migration v2->v3 error: $e');
        // If migration fails, the app will still work with old schema
      }
    }
    if (oldVersion < 4) {
      // Add icon column to folders
      try {
        await db.execute(
          "ALTER TABLE folders ADD COLUMN icon TEXT DEFAULT '0xe3b0'",
        );
        print('Migration v3->v4 completed successfully');
      } catch (e) {
        print('Migration v3->v4 error: $e');
      }
    }
    if (oldVersion < 5) {
      // Add sync columns: cloud_id, updated_at, is_deleted, synced_at
      try {
        await db.execute('ALTER TABLE folders ADD COLUMN cloud_id TEXT');
        await db.execute('ALTER TABLE folders ADD COLUMN updated_at TEXT');
        await db.execute(
          'ALTER TABLE folders ADD COLUMN is_deleted INTEGER DEFAULT 0',
        );
        await db.execute('ALTER TABLE folders ADD COLUMN synced_at TEXT');

        await db.execute('ALTER TABLE links ADD COLUMN cloud_id TEXT');
        await db.execute('ALTER TABLE links ADD COLUMN updated_at TEXT');
        await db.execute(
          'ALTER TABLE links ADD COLUMN is_deleted INTEGER DEFAULT 0',
        );
        await db.execute('ALTER TABLE links ADD COLUMN synced_at TEXT');

        // Initialize updated_at for existing records
        final now = DateTime.now().toIso8601String();
        await db.execute("UPDATE folders SET updated_at = '$now'");
        await db.execute("UPDATE links SET updated_at = '$now'");

        print('Migration v4->v5 completed successfully');
      } catch (e) {
        print('Migration v4->v5 error: $e');
      }
    }
    if (oldVersion < 6) {
      // Add system_category to folders
      try {
        await db.execute('ALTER TABLE folders ADD COLUMN system_category TEXT');
        print('Migration v5->v6 completed successfully');
      } catch (e) {
        print('Migration v5->v6 error: $e');
      }
    }
    if (oldVersion < 7) {
      // Catch missing system_category from fresh installs on v6
      try {
        await db.execute('ALTER TABLE folders ADD COLUMN system_category TEXT');
        print('Migration v6->v7 completed successfully');
      } catch (e) {
        print('Migration v6->v7 error (already exists): $e');
      }
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> searchFoldersAndLinks(
    String query,
  ) async {
    final db = await database;
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return {'folders': [], 'links': []};
    }

    final terms = cleanQuery.split(' ').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (terms.isEmpty) {
      return {'folders': [], 'links': []};
    }

    // Build folders search clause
    final foldersWhere = terms.map((_) => 'name LIKE ?').join(' AND ');
    final foldersArgs = terms.map((t) => '%$t%').toList();

    final folders = await db.query(
      'folders',
      where: '($foldersWhere) AND is_deleted = 0',
      whereArgs: foldersArgs,
      orderBy: 'created_at DESC',
    );

    // Build links search clause
    final linksWhere = terms
        .map((_) => '(l.title LIKE ? OR l.url LIKE ? OR l.notes LIKE ?)')
        .join(' AND ');
    final linksArgs = <String>[];
    for (final term in terms) {
      final termWithWildcard = '%$term%';
      linksArgs.add(termWithWildcard);
      linksArgs.add(termWithWildcard);
      linksArgs.add(termWithWildcard);
    }

    final links = await db.rawQuery('''
      SELECT l.*, f.name as folder_name
      FROM links l
      LEFT JOIN folders f ON l.folder_id = f.id
      WHERE ($linksWhere) AND l.is_deleted = 0
      ORDER BY l.created_at DESC
    ''', linksArgs);

    return {'folders': folders, 'links': links};
  }

  // --- Folder CRUD ---

  Future<int> insertFolder(Map<String, dynamic> folder) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final data = Map<String, dynamic>.from(folder);
    data['created_at'] = now;
    data['updated_at'] = now;
    data['is_deleted'] = 0;
    final result = await db.insert('folders', data);
    notifyDatabaseChanged();
    return result;
  }

  Future<int> updateFolder(Map<String, dynamic> folder) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final data = Map<String, dynamic>.from(folder);
    data['updated_at'] = now;
    final result = await db.update(
      'folders',
      data,
      where: 'id = ?',
      whereArgs: [folder['id']],
    );
    notifyDatabaseChanged();
    return result;
  }

  Future<int> deleteFolder(int id) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Soft delete links
    await db.update(
      'links',
      {'is_deleted': 1, 'updated_at': now},
      where: 'folder_id = ?',
      whereArgs: [id],
    );

    // Soft delete folder
    final result = await db.update(
      'folders',
      {'is_deleted': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyDatabaseChanged();
    return result;
  }

  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT f.*, COUNT(l.id) as item_count 
      FROM folders f 
      LEFT JOIN links l ON f.id = l.folder_id AND l.is_deleted = 0 
      WHERE f.is_deleted = 0 
      GROUP BY f.id 
      ORDER BY f.created_at DESC
    ''');
  }

  Future<void> updateFolderSystemCategory(int id, String category) async {
    final db = await database;
    await db.update(
      'folders',
      {
        'system_category': category,
        'updated_at': DateTime.now()
            .toIso8601String(), // specific update needs sync
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyDatabaseChanged();
  }

  // --- Link CRUD ---

  Future<int> insertLink(Map<String, dynamic> link) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final data = Map<String, dynamic>.from(link);
    data['created_at'] = now;
    data['updated_at'] = now;
    data['is_deleted'] = 0;
    final result = await db.insert('links', data);
    notifyDatabaseChanged();
    return result;
  }

  Future<int> updateLink(Map<String, dynamic> link) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final data = Map<String, dynamic>.from(link);
    data['updated_at'] = now;
    final result = await db.update(
      'links',
      data,
      where: 'id = ?',
      whereArgs: [link['id']],
    );
    notifyDatabaseChanged();
    return result;
  }

  Future<int> deleteLink(int id) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final result = await db.update(
      'links',
      {'is_deleted': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyDatabaseChanged();
    return result;
  }

  Future<List<Map<String, dynamic>>> getLinks(int folderId) async {
    final db = await database;
    return await db.query(
      'links',
      where: 'folder_id = ? AND is_deleted = 0',
      whereArgs: [folderId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getRecentLinks({int limit = 3}) async {
    final db = await database;
    return await db.query(
      'links',
      where: 'is_deleted = 0',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getAllLinks() async {
    final db = await database;
    return await db.query(
      'links',
      where: 'is_deleted = 0',
      orderBy: 'created_at DESC',
    );
  }

  Future<int> getLinksCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM links WHERE is_deleted = 0'),
    );
    return count ?? 0;
  }

  // --- Sync Helpers ---

  Future<bool> hasUserGeneratedData() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM folders WHERE is_deleted = 0'),
    );
    return (count ?? 0) > 0;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedFolders() async {
    final db = await database;
    return await db.query(
      'folders',
      where: 'cloud_id IS NULL OR updated_at > IFNULL(synced_at, "")',
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLinks() async {
    final db = await database;
    return await db.query(
      'links',
      where: 'cloud_id IS NULL OR updated_at > IFNULL(synced_at, "")',
    );
  }

  Future<void> updateFolderSyncStatus(
    int localId,
    String cloudId,
    String syncedAt,
  ) async {
    final db = await database;
    await db.update(
      'folders',
      {'cloud_id': cloudId, 'synced_at': syncedAt},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> updateLinkSyncStatus(
    int localId,
    String cloudId,
    String syncedAt,
  ) async {
    final db = await database;
    await db.update(
      'links',
      {'cloud_id': cloudId, 'synced_at': syncedAt},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> upsertFolderFromCloud(Map<String, dynamic> data) async {
    final db = await database;
    final cloudId = data['id'];
    // Map cloud fields to local fields
    final localData = {
      'cloud_id': cloudId,
      'name': data['name'],
      'icon': data['icon'],
      'updated_at': data['updated_at'],
      'created_at': data['created_at'],
      'is_deleted': (data['is_deleted'] == true) ? 1 : 0,
      'synced_at': DateTime.now().toIso8601String(),
      'system_category': data['system_category'],
    };

    // Check if exists by cloud_id
    final existing = await db.query(
      'folders',
      where: 'cloud_id = ?',
      whereArgs: [cloudId],
    );
    if (existing.isNotEmpty) {
      await db.update(
        'folders',
        localData,
        where: 'cloud_id = ?',
        whereArgs: [cloudId],
      );
    } else {
      await db.insert('folders', localData);
    }
  }

  Future<void> upsertLinkFromCloud(Map<String, dynamic> data) async {
    final db = await database;
    final cloudId = data['id'];
    final folderCloudId = data['folder_id'];

    // Find local folder ID from cloud folder ID
    final folder = await db.query(
      'folders',
      columns: ['id'],
      where: 'cloud_id = ?',
      whereArgs: [folderCloudId],
    );
    if (folder.isEmpty) {
      // If folder doesn't exist locally yet, we can't insert the link properly.
      // Sync logic should ensure folders sync first.
      return;
    }
    final localFolderId = folder.first['id'];

    final localData = {
      'cloud_id': cloudId,
      'folder_id': localFolderId,
      'url': data['url'],
      'title': data['title'],
      'domain': data['domain'],
      'image_url': data['image_url'],
      'notes': data['notes'],
      'updated_at': data['updated_at'],
      'created_at': data['created_at'],
      'is_deleted': (data['is_deleted'] == true) ? 1 : 0,
      'synced_at': DateTime.now().toIso8601String(),
    };

    final existing = await db.query(
      'links',
      where: 'cloud_id = ?',
      whereArgs: [cloudId],
    );
    if (existing.isNotEmpty) {
      await db.update(
        'links',
        localData,
        where: 'cloud_id = ?',
        whereArgs: [cloudId],
      );
    } else {
      await db.insert('links', localData);
    }
  }

  /// Wipe all local data (for logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('links');
      await txn.delete('folders');
    });
    print('DatabaseHelper: All data cleared.');
  }
}
