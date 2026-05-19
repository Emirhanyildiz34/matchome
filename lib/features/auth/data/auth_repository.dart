import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // E-posta ve Şifre ile Kayıt Ol (SMS gerektirmez)
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required bool isStudent,
    String? city,
    String? district,
    String? university,
    String? campus,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone_number': phone,
        'role': isStudent ? 'student' : 'professional',
        'city': city,
        'district': district,
        'university': university,
        'campus': campus,
      },
    );

    // Eğer session null ise, kullanıcıyı login'e zorla veya session bekle
    if (response.session == null) {
      // Otomatik onay kapalıysa veya bir sorun varsa session gelmeyebilir.
      // Bu durumda manuel login denenebilir.
      await _supabase.auth.signInWithPassword(email: email, password: password);
    }
  }

  // E-posta ve Şifre ile Giriş Yap
  Future<void> signInWithEmail(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Eski Telefon Metotları (Opsiyonel olarak durabilir)
  Future<void> signUpWithPhone({
    required String phone,
    required String password,
    required String fullName,
    required bool isStudent,
    String? city,
    String? district,
    String? university,
    String? campus,
  }) async {
    await _supabase.auth.signUp(
      phone: phone,
      password: password,
      channel: OtpChannel.sms,
      data: {
        'full_name': fullName,
        'role': isStudent ? 'student' : 'professional',
        'city': city,
        'district': district,
        'university': university,
        'campus': campus,
      },
    );
  }

  // Çıkış Yap
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Google ile Giriş / Kayıt Ol
  // – Supabase Google OAuth'u tarayıcıda açar
  // – Kullanıcı giriş yaptıktan sonra deep link ile uygulamaya döner
  // – supabase_flutter v2, gelen deep link'i otomatik işler ve oturumu oluşturur
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.matchhome://login-callback/',
    );
  }

  // Kullanıcı Durumunu Dinle
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Mevcut Kullanıcıyı Getir
  User? get currentUser => _supabase.auth.currentUser;
}
