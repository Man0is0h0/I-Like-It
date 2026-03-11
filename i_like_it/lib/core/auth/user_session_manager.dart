import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nanoid/nanoid.dart';
import 'package:uuid/uuid.dart';

class UserSessionManager {
  static const _storage = FlutterSecureStorage();
  static const _keyUserId = 'user_id';
  static const _keyRecoveryCode = 'recovery_code'; // Only stored temporarily or if we want to show it in settings
  static const _keyIsBackedUp = 'is_backed_up'; // To track if user has seen/copied the code

  static String? _currentUserId;
  static String? _currentRecoveryCode;

  static String get userId => _currentUserId!;
  static String? get recoveryCode => _currentRecoveryCode;

  /// Initialize session: recover existing ID or generate new one
  static Future<void> initialize() async {
    try {
      String? storedId = await _storage.read(key: _keyUserId);
      
      if (storedId == null) {
        // Fresh install: Generate new identity
        await _generateNewIdentity();
      } else {
        _currentUserId = storedId;
        _currentRecoveryCode = await _storage.read(key: _keyRecoveryCode);
      }
      
      print("UserSessionManager: Initialized with User ID: $_currentUserId");
    } catch (e) {
      print("UserSessionManager: Error initializing session: $e");
      // Fallback or retry logic could go here
    }
  }

  /// Generate new UUID and Recovery Code
  static Future<void> _generateNewIdentity() async {
    final uuid = const Uuid().v4();
    // Generate a readable 16-char code (e.g. ABCD-EFGH-IJKL-MNOP)
    final code = _generateRecoveryCode();
    
    await _storage.write(key: _keyUserId, value: uuid);
    await _storage.write(key: _keyRecoveryCode, value: code);
    await _storage.write(key: _keyIsBackedUp, value: 'false');
    
    _currentUserId = uuid;
    _currentRecoveryCode = code;
    
    // Note: The hash of this code needs to be sent to the cloud along with the user_id
    // This will happen in the RemoteDataSource / SyncManager layer.
  }

  static String _generateRecoveryCode() {
    // 16 chars, alphanumeric, split by dashes for readability
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final raw = customAlphabet(alphabet, 16);
    return '${raw.substring(0, 4)}-${raw.substring(4, 8)}-${raw.substring(8, 12)}-${raw.substring(12, 16)}';
  }

  /// Hash the recovery code for cloud storage/verification
  static String hashRecoveryCode(String code) {
    // Normalize: uppercase, remove dashes/spaces
    final normalized = code.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Mark the recovery code as backed up by the user
  static Future<void> markAsBackedUp() async {
    await _storage.write(key: _keyIsBackedUp, value: 'true');
  }

  /// Check if the user has backed up their code
  static Future<bool> isBackedUp() async {
    final val = await _storage.read(key: _keyIsBackedUp);
    return val == 'true';
  }

  /// Restore session from a manual recovery (e.g. entering code/email)
  static Future<void> restoreSession(String newUserId, String newRecoveryCode) async {
    await _storage.write(key: _keyUserId, value: newUserId);
    await _storage.write(key: _keyRecoveryCode, value: newRecoveryCode); // Assuming we keep it
    await _storage.write(key: _keyIsBackedUp, value: 'true'); // Restored means they have it
    
    _currentUserId = newUserId;
    _currentRecoveryCode = newRecoveryCode;
  }

  /// Logout: Clear all session data
  static Future<void> clearSession() async {
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyRecoveryCode);
    await _storage.delete(key: _keyIsBackedUp);
    
    _currentUserId = null;
    _currentRecoveryCode = null;
    print("UserSessionManager: Session cleared.");
  }
}
