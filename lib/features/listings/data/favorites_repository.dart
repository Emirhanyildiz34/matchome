import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/favorite_model.dart';

class FavoritesRepository {
  final SupabaseClient _supabase;

  FavoritesRepository(this._supabase);

  // Favori ekle
  Future<void> addToFavorites({
    required String userId,
    required String listingId,
    required int priceAtFavorite,
    String? category,
    String? notes,
  }) async {
    final data = {
      'user_id': userId,
      'listing_id': listingId,
      'price_at_favorite': priceAtFavorite,
      'notes': notes,
    };
    if (category != null) {
      data['category'] = category;
    }
    await _supabase.from('favorites').insert(data);
  }

  // Favori kaldır
  Future<void> removeFromFavorites(String favoriteId) async {
    await _supabase.from('favorites').delete().eq('id', favoriteId);
  }

  // Favorileri getir (tümü)
  Future<List<FavoriteModel>> getFavorites(String userId) async {
    final response = await _supabase
        .from('favorites')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FavoriteModel.fromJson(json))
        .toList();
  }

  // Kategoriye göre favorileri getir
  Future<List<FavoriteModel>> getFavoritesByCategory(
    String userId,
    String category,
  ) async {
    final response = await _supabase
        .from('favorites')
        .select('*')
        .eq('user_id', userId)
        .eq('category', category)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FavoriteModel.fromJson(json))
        .toList();
  }

  // Favori kategor sini güncelle
  Future<void> updateFavoriteCategory(
      String favoriteId, String newCategory) async {
    await _supabase.from('favorites').update({
      'category': newCategory,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', favoriteId);
  }

  // Favori not ekle/güncelle
  Future<void> updateFavoriteNote(String favoriteId, String note) async {
    await _supabase.from('favorites').update({
      'notes': note,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', favoriteId);
  }

  // Belirli bir ilanın favori olup olmadığını kontrol et
  Future<FavoriteModel?> isFavorited(String userId, String listingId) async {
    final response = await _supabase
        .from('favorites')
        .select('*')
        .eq('user_id', userId)
        .eq('listing_id', listingId)
        .maybeSingle();

    if (response == null) return null;
    return FavoriteModel.fromJson(response);
  }
}
