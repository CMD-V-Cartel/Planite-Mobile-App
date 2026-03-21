import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads `.env` from assets (see `pubspec.yaml`).
Future<void> loadEnv() async {
  await dotenv.load(fileName: '.env');
}

String envOrThrow(String key) {
  final String? v = dotenv.env[key];
  if (v == null || v.isEmpty) {
    throw StateError('Missing env key: $key. Copy .env.example to .env.');
  }
  return v;
}

String get supabaseUrl => envOrThrow('SUPABASE_URL');
String get supabaseAnonKey => envOrThrow('SUPABASE_ANON_KEY');
