import 'package:supabase/supabase.dart';
import 'dart:io';

Future<void> main() async {
  try {
    final client = SupabaseClient(
      'https://izlahmslmpmfeecpgkav.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6bGFobXNsbXBtZmVlY3Bna2F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1MjY1NzQsImV4cCI6MjA4NTEwMjU3NH0.IwRKEcmNLZ6yF9kbCGuJUGs_2uwza31oM_KtAlPTobc',
    );
    final response = await client.rpc('request_recovery_otp', params: {'p_email': 'test3@test.com'});
    print('Response type: ${response.runtimeType}');
    print('Response value: $response');
    if (response is Map) {
      print('Success flag: ${response['success']}');
      print('Evaluates to true: ${response['success'] == true}');
    }
    exit(0);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
