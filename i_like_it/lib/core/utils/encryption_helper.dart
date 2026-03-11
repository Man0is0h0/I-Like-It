import 'package:encrypt/encrypt.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EncryptionHelper {
  // Try to use an environment variable for the AES Key, or fallback to a hardcoded secure 32-byte string.
  static final String _keyString = dotenv.env['AES_SECRET_KEY'] ?? 'I_LIKE_IT_SECURE_ENCRYPTION_K_32'; // Must be exactly 32 chars
  
  static final Key _key = Key.fromUtf8(_keyString.substring(0, 32));
  static final Encrypter _encrypter = Encrypter(AES(_key));

  /// Encrypts a plain text string securely using AES.
  static String encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    try {
      final iv = IV.fromSecureRandom(16); // Generate random IV for every encryption
      final encrypted = _encrypter.encrypt(plainText, iv: iv);
      // We prepend the base64 IV to the ciphertext so we can decrypt later. Format: IV:CIPHER
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      print('Encryption error: $e');
      return '';
    }
  }

  /// Decrypts a previously encrypted string.
  static String decrypt(String encryptedText) {
    if (encryptedText.isEmpty || !encryptedText.contains(':')) return '';
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return '';
      
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('Decryption error: $e');
      return '';
    }
  }
}
