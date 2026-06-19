import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print("Starting legal documents upload script...");

  // Read .env manually to avoid Flutter UI framework dependencies in pure Dart CLI
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print("Error: .env file not found in current directory.");
    exit(1);
  }

  final lines = await envFile.readAsLines();
  String? url;
  String? anonKey;

  for (var line in lines) {
    if (line.startsWith('SUPABASE_URL=')) {
      url = line.substring('SUPABASE_URL='.length).trim();
    } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
      anonKey = line.substring('SUPABASE_ANON_KEY='.length).trim();
    }
  }

  if (url == null || anonKey == null) {
    print("Error: SUPABASE_URL or SUPABASE_ANON_KEY missing in .env.");
    exit(1);
  }

  print("Connecting to Supabase at $url...");

  final client = SupabaseClient(url, anonKey);

  try {
    // 1. Upload Privacy Policy
    final privacyFile = File('../client_items/Privacy_Policy_iLikeIt.html');
    if (!privacyFile.existsSync()) {
      print("Error: Privacy Policy file not found in client_items.");
      exit(1);
    }

    print("Uploading Privacy Policy...");
    await client.storage
        .from('legal-docs')
        .upload(
          'Privacy_Policy_iLikeIt.html',
          privacyFile,
          fileOptions: const FileOptions(
            contentType: 'text/html',
            upsert: true,
          ),
        );
    print("Privacy Policy uploaded successfully!");

    // 2. Upload Terms of Use
    final termsFile = File('../client_items/Terms_Use_iLikeIt.html');
    if (!termsFile.existsSync()) {
      print("Error: Terms of Use file not found in client_items.");
      exit(1);
    }

    print("Uploading Terms of Use...");
    await client.storage
        .from('legal-docs')
        .upload(
          'Terms_Use_iLikeIt.html',
          termsFile,
          fileOptions: const FileOptions(
            contentType: 'text/html',
            upsert: true,
          ),
        );
    print("Terms of Use uploaded successfully!");

    final publicPrivacyUrl = client.storage
        .from('legal-docs')
        .getPublicUrl('Privacy_Policy_iLikeIt.html');
    final publicTermsUrl = client.storage
        .from('legal-docs')
        .getPublicUrl('Terms_Use_iLikeIt.html');

    print("\n=============================================");
    print("🎉 UPLOAD COMPLETED SUCCESSFULLY!");
    print("=============================================");
    print("Privacy Policy URL:\n$publicPrivacyUrl");
    print("\nTerms of Use URL:\n$publicTermsUrl");
    print("=============================================\n");
  } catch (e) {
    print("\n❌ Upload failed: $e");
    print(
      "\n💡 Tip: If you get a '403 Forbidden' or 'Bucket not found' error, make sure you ran the SQL commands in 'project-backend/storage_setup.sql' in your Supabase SQL Editor first.",
    );
  }
}
