import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSessionManager {
  static const _storage = FlutterSecureStorage();
  static const _keyUserId = 'user_id';
  static const _keyEmail = 'email';
  static const _keyIsBackedUp =
      'is_backed_up'; // To track if user is fully logged in

  static String? _currentUserId;
  static String? _currentEmail;

  static String get userId => _currentUserId!;
  static String? get email => _currentEmail;

  /// Initialize session: recover existing ID and Email
  static Future<void> initialize() async {
    try {
      String? storedId = await _storage.read(key: _keyUserId);

      if (storedId != null) {
        _currentUserId = storedId;
        _currentEmail = await _storage.read(key: _keyEmail);
        print("UserSessionManager: Initialized with User ID: $_currentUserId");
      } else {
        print("UserSessionManager: Initialized fresh app State.");
      }
    } catch (e) {
      print("UserSessionManager: Error initializing session: $e");
      // Fallback or retry logic could go here
    }
  }

  /// Check if the user is fully logged in
  static Future<bool> isBackedUp() async {
    final val = await _storage.read(key: _keyIsBackedUp);
    return val == 'true';
  }

  /// Login: Save the Session
  static Future<void> loginWithEmail(String newUserId, String newEmail) async {
    await _storage.write(key: _keyUserId, value: newUserId);
    await _storage.write(key: _keyEmail, value: newEmail);
    await _storage.write(key: _keyIsBackedUp, value: 'true'); // Is logged in

    _currentUserId = newUserId;
    _currentEmail = newEmail;
  }

  /// Logout: Clear all session data
  static Future<void> clearSession() async {
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyIsBackedUp);

    _currentUserId = null;
    _currentEmail = null;
    print("UserSessionManager: Session cleared.");
  }
}
