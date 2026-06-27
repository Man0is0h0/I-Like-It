import 'package:supabase/supabase.dart';
import 'dart:io';

Future<void> main() async {
  try {
    final client = SupabaseClient(
      'YOUR_SUPABASE_URL',
      'YOUR_SUPABASE_ANON_KEY',
    );
    final response = await client.rpc(
      'request_recovery_otp',
      params: {'p_email': 'test3@test.com'},
    );
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
