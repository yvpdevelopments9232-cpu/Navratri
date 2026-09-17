import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://ifhwminbybeypntvmscf.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlmaHdtaW5ieWJleXBudHZtc2NmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg5MzI1MTcsImV4cCI6MjEwNDUwODUxN30._JjyqEemOvt5esiZ8ncVFMrNay6kK4fWmlifcLkyfD8';

  static const String serviceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlmaHdtaW5ieWJleXBudHZtc2NmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4ODkzMjUxNywiZXhwIjoyMTA0NTA4NTE3fQ.Bcqj98RxQ-cVqqX08jkVeZomDmfetKjzUrVzc00Z1jk';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );
    } catch (e) {
      debugPrint('Supabase initialization warning: $e');
    }
  }
}
