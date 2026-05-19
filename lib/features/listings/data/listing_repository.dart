import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/listing_model.dart';

class ListingRepository {
  final SupabaseClient _supabase;

  ListingRepository(this._supabase);

  Future<void> createListing(ListingModel listing) async {
    await _supabase.from('listings').insert(listing.toJson());
  }

  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    await _supabase.from('listings').update(data).eq('id', id);
  }

  Future<void> deleteListing(String id) async {
    await _supabase.from('listings').delete().eq('id', id);
  }

  Future<List<ListingModel>> getActiveListings({
    String? listingType,
    int? minPrice,
    int? maxPrice,
    String? roomCount,
    String? city,
    String? district,
  }) async {
    var query = _supabase
        .from('listings')
        .select('*')
        .eq('is_active', true);

    if (listingType != null && listingType.isNotEmpty) {
      query = query.eq('listing_type', listingType);
    }
    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
    }
    if (roomCount != null && roomCount.isNotEmpty) {
      query = query.eq('room_count', roomCount);
    }
    if (city != null && city.isNotEmpty) {
      query = query.ilike('address_text', '%$city%');
    }
    if (district != null && district.isNotEmpty) {
      query = query.ilike('address_text', '%$district%');
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => ListingModel.fromJson(json))
        .toList();
  }

  Future<ListingModel?> getMyListing(String userId) async {
    final response = await _supabase
        .from('listings')
        .select('*')
        .eq('host_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return ListingModel.fromJson(response);
  }

  Future<List<ListingModel>> getMyListings(String userId) async {
    final response = await _supabase
        .from('listings')
        .select('*')
        .eq('host_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ListingModel.fromJson(json))
        .toList();
  }

  // İlanı kaldırma (unpublish - soft delete)
  Future<void> unpublishListing(String id) async {
    await _supabase
        .from('listings')
        .update({'unpublished_at': DateTime.now().toIso8601String(), 'is_active': false})
        .eq('id', id);
  }

  // İlanı yeniden yayınlama
  Future<void> republishListing(String id) async {
    await _supabase
        .from('listings')
        .update({'unpublished_at': null, 'is_active': true, 'published_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  // Fiyat değişimini kaydet
  Future<void> recordPriceChange(String listingId, int newPrice) async {
    await _supabase.from('price_history').insert({
      'listing_id': listingId,
      'price': newPrice,
      'changed_at': DateTime.now().toIso8601String(),
    });
  }

  // Fiyat geçmişini getir
  Future<List<Map<String, dynamic>>> getPriceHistory(String listingId) async {
    final response = await _supabase
        .from('price_history')
        .select('*')
        .eq('listing_id', listingId)
        .order('changed_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
