import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // TODO: Supabase auth logic (signIn, signUp vb.) buraya eklenebilir
  // veya features/auth/data/repositories içine taşınabilir.
}
