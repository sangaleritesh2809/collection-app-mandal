import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  static SupabaseClient get client {
    if (_client == null) {
      try {
        _client = Supabase.instance.client;
      } catch (e) {
        debugPrint('Supabase not yet initialized: $e');
        throw Exception('Supabase is not initialized. Please configure credentials.');
      }
    }
    return _client!;
  }

  static bool get isInitialized => _isInitialized;

  static Future<bool> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('No .env found or failed to load: $e');
    }

    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || anonKey.isEmpty || url.contains('your-project-id')) {
      debugPrint('Supabase URL or Anon key is missing or default in .env');
      _isInitialized = false;
      return false;
    }

    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      _isInitialized = false;
      return false;
    }
  }

  static User? get currentUser => _isInitialized ? client.auth.currentUser : null;
  static String? get currentUserId => currentUser?.id;
}
