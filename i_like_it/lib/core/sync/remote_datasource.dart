import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/user_session_manager.dart';

class RemoteDataSource {
  final SupabaseClient _client;

  RemoteDataSource(this._client);

  // --- Users ---

  Future<void> createUser(String userId, String recoveryHash, {String? encryptedCode}) async {
    await _client.from('users').upsert({
      'id': userId,
      'recovery_hash': recoveryHash,
      if (encryptedCode != null) 'encrypted_recovery_code': encryptedCode,
      'last_seen_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateUserEmail(String email) async {
    final userId = UserSessionManager.userId;
    await _client.from('users').update({
      'email': email,
    }).eq('id', userId);
  }

  Future<void> updateLastSeen() async {
    print('[RemoteDataSource] Entering updateLastSeen...');
    try {
      final userId = UserSessionManager.userId;
      final now = DateTime.now().toUtc().toIso8601String();
      
      // Update and select to verify it worked (RLS will return empty if not allowed)
      final response = await _client.from('users').update({
        'last_seen_at': now,
      }).eq('id', userId).select();
      
      if (response.isEmpty) {
        print('[RemoteDataSource] WARNING: updateLastSeen returned empty. RLS might be blocking update for $userId');
      } else {
        print('[RemoteDataSource] Success: Updated last_seen_at to $now');
      }
    } catch (e) {
      print('Failed to update last_seen_at: $e');
    }
  }

  Future<String?> fetchUserEmail() async {
    final userId = UserSessionManager.userId;
    final response = await _client
        .from('users')
        .select('email')
        .eq('id', userId)
        .maybeSingle();
    
    if (response != null) {
      return response['email'] as String?;
    }
    return null;
  }
  
  // --- Folders ---

  Future<Map<String, dynamic>> upsertFolder(Map<String, dynamic> folderData) async {
    final response = await _client.from('folders').upsert(folderData).select().single();
    return response;
  }

  Future<List<Map<String, dynamic>>> fetchNewFolders(String lastSyncTime) async {
    final userId = UserSessionManager.userId;
    // We fetch any folder belonging to this user updated after lastSyncTime
    final response = await _client
        .from('folders')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSyncTime)
        .order('updated_at'); // Ensure order for consistency
    return List<Map<String, dynamic>>.from(response);
  }

  // --- Links ---

  Future<Map<String, dynamic>> upsertLink(Map<String, dynamic> linkData) async {
    final response = await _client.from('links').upsert(linkData).select().single();
    return response;
  }

  Future<List<Map<String, dynamic>>> fetchNewLinks(String lastSyncTime) async {
    final userId = UserSessionManager.userId;
    final response = await _client
        .from('links')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSyncTime)
        .order('updated_at');
    return List<Map<String, dynamic>>.from(response);
  }
  
  // --- Recovery ---
  
  Future<String?> findUserIdByRecoveryHash(String hash) async {
    final response = await _client
        .from('users')
        .select('id')
        .eq('recovery_hash', hash)
        .maybeSingle();
        
    if (response != null) {
      return response['id'] as String;
    }
    return null;
  }
  
  Future<String?> fetchEncryptedRecoveryCode(String userId) async {
     final response = await _client
        .from('users')
        .select('encrypted_recovery_code')
        .eq('id', userId)
        .maybeSingle();
        
    if (response != null) {
      return response['encrypted_recovery_code'] as String?;
    }
    return null;
  }
  
  Future<String?> findUserIdByEmail(String email) async {
    final response = await _client
        .from('users')
        .select('id')
        .eq('email', email)
        .maybeSingle();

    if (response != null) {
      return response['id'] as String;
    }
    return null;
  }
  
  // --- OTP (RPC Functions) ---
  
  Future<bool> requestOtp(String email) async {
    try {
      final response = await _client.rpc('request_recovery_otp', params: {'p_email': email});
      return response['success'] == true;
    } catch (e) {
      print('RPC request_recovery_otp failed: $e');
      return false;
    }
  }
  
  Future<bool> verifyOtp(String email, String code) async {
    try {
      final response = await _client.rpc('verify_recovery_otp', params: {'p_email': email, 'p_code': code});
      return response['success'] == true;
    } catch (e) {
      print('RPC verify_recovery_otp failed: $e');
      return false;
    }
  }
  // --- Admin ---

  Future<String?> fetchUserRole() async {
    final userId = UserSessionManager.userId;
    final response = await _client
        .from('users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    
    if (response != null) {
      return response['role'] as String?;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    // RLS allows admins to see all rows
    final response = await _client
        .from('users')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> fetchSystemStats() async {
    final usersCount = await _client.from('users').count(CountOption.exact);
    final linksCount = await _client.from('links').count(CountOption.exact);
    final foldersCount = await _client.from('folders').count(CountOption.exact);
    
    // Active users (last 24h)
    final yesterday = DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String();
    final activeUsers = await _client
        .from('users')
        .count(CountOption.exact)
        .gte('last_seen_at', yesterday);

    return {
      'users': usersCount,
      'links': linksCount,
      'folders': foldersCount,
      'active_users': activeUsers,
    };
  }
  
  // --- Analytics & Categorization ---

  /// Fetches folders that have no category assigned
  Future<List<Map<String, dynamic>>> fetchUncategorizedFolders() async {
    // Assuming 'category' column exists. If strictly assuming schema, 
    // it might fail if column is missing. But we must assume it exists per requirements.
    try {
      final response = await _client
          .from('folders')
          .select('id, name')
          .filter('category', 'is', null)
          .limit(100); // Process in chunks
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching uncategorized folders: $e');
      return [];
    }
  }

  /// Bulk updates folder categories
  Future<void> updateFolderCategories(List<Map<String, dynamic>> updates) async {
    if (updates.isEmpty) return;
    try {
      await _client.from('folders').upsert(updates);
    } catch (e) {
      print('Error updating folder categories: $e');
      rethrow;
    }
  }

  /// Fetches ALL folder categories for the donut chart
  Future<Map<String, int>> fetchFolderCategoriesDistribution() async {
    try {
      final response = await _client
          .from('folders')
          .select('category');
          
      final distribution = <String, int>{};
      for (final item in response) {
        final category = item['category'] as String? ?? 'Uncategorized';
        distribution[category] = (distribution[category] ?? 0) + 1;
      }
      return distribution;
    } catch (e) {
      print('Error fetching category distribution: $e');
      return {};
    }
  }

  /// Fetches User Growth data (created_at of all users)
  /// Returns list of timestamps to be aggregated by the UI
  Future<List<DateTime>> fetchUserGrowthData() async {
    try {
      final response = await _client
          .from('users')
          .select('created_at')
          .order('created_at');
      
      return (response as List).map((e) => DateTime.parse(e['created_at'])).toList();
    } catch (e) {
      print('Error fetching user growth: $e');
      return [];
    }
  }
  // --- AI Classification Support ---

  Future<List<Map<String, dynamic>>> fetchFoldersWithoutSystemCategory() async {
    try {
      final response = await _client
          .from('folders')
          .select('id, name')
          .eq('is_deleted', false) // Ignore deleted folders
          .or('system_category.is.null,system_category.eq.other') 
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching uncategorized folders: $e');
      return [];
    }
  }

  Future<void> updateFolderSystemCategory(dynamic id, String category) async {
    try {
      await _client.from('folders').update({
        'system_category': category,
      }).eq('id', id);
    } catch (e) {
      print('Error updating folder category: $e');
    }
  }

  Future<void> batchUpdateSystemCategories(List<Map<String, dynamic>> updates) async {
    if (updates.isEmpty) return;
    
    // Use individual updates instead of upsert to avoid accidentally re-inserting 
    // deleted folders (which causes a constraint violation).
    // Parallelize for performance.
    final futures = updates.map((update) async {
      try {
        final id = update['id'];
        final category = update['system_category'];
        if (id != null && category != null) {
           await _client.from('folders').update({
            'system_category': category,
          }).eq('id', id);
        }
      } catch (e) {
        // Ignore errors for individual updates (e.g. if row deleted)
        print('Skipping update for missing folder: $e');
      }
    });

    try {
      await Future.wait(futures);
    } catch (e) {
      print('Error during batch update: $e');
    }
  }

  /// Fetches strict system category distribution
  Future<Map<String, int>> fetchSystemCategoryDistribution() async {
    try {
      final response = await _client
          .from('folders')
          .select('system_category');
          
      final distribution = <String, int>{};
      for (final item in response) {
        final category = item['system_category'] as String? ?? 'other';
        distribution[category] = (distribution[category] ?? 0) + 1;
      }
      return distribution;
    } catch (e) {
      print('Error fetching system category distribution: $e');
      return {};
    }
  } // End Function
} // End Class
