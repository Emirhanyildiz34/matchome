import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';

// Repository'i sağlayan temel provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// Anlık kimlik doğrulama durumunu dinleyen (login oldu/olmadı) stream provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// Eğer gerekiyorsa o anki kullanıcıyı getiren yardımcı provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user;
});

// Kullanıcı profil verilerini getiren provider
final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  // full_name yoksa veya varsayılan 'Yeni Kullanıcı' ise auth metadata'sına bak
  if (response != null) {
    final dbName = response['full_name'];
    if (dbName == null || dbName == 'Yeni Kullanıcı' || dbName.toString().trim().isEmpty) {
      final metaName = user.userMetadata?['full_name'];
      if (metaName != null && metaName.toString().trim().isNotEmpty) {
        response['full_name'] = metaName;
        // Profiles tablosunu da güncelle (arka planda)
        Supabase.instance.client
            .from('profiles')
            .update({'full_name': metaName})
            .eq('id', user.id)
            .then((_) {})
            .catchError((_) {});
      }
    }
  }

  return response;
});
