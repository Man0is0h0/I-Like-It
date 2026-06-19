import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  static AppConfig get instance => _instance;

  // Environment Keys
  static const String _kSupabaseUrl = 'SUPABASE_URL';
  static const String _kSupabaseAnonKey = 'SUPABASE_ANON_KEY';
  static const String _kGeminiApiKey = 'GEMINI_API_KEY';
  static const String _kPrivacyPolicyUrl = 'PRIVACY_POLICY_URL';
  static const String _kTermsUseUrl = 'TERMS_USE_URL';

  late final String supabaseUrl;
  late final String supabaseAnonKey;
  late final String geminiApiKey;
  late final String privacyPolicyUrl;
  late final String termsUseUrl;
  
  bool _initialized = false;

  /// Loads environment variables and validates required keys
  Future<void> initialize() async {
    if (_initialized) return;

    await dotenv.load(fileName: ".env");

    supabaseUrl = _getRequired(_kSupabaseUrl);
    supabaseAnonKey = _getRequired(_kSupabaseAnonKey);
    geminiApiKey = dotenv.env[_kGeminiApiKey] ?? '';
    privacyPolicyUrl = dotenv.env[_kPrivacyPolicyUrl] ?? '';
    termsUseUrl = dotenv.env[_kTermsUseUrl] ?? '';

    _initialized = true;
  }

  String _getRequired(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Create a .env file and add required key: $key');
    }
    return value;
  }
}
