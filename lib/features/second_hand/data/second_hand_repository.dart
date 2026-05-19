import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/second_hand_item_model.dart';

class SecondHandRepository {
  final SupabaseClient _supabase;

  SecondHandRepository(this._supabase);

  Future<void> createItem(SecondHandItemModel item) async {
    await _supabase.from('second_hand_items').insert(item.toJson());
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await _supabase.from('second_hand_items').update(data).eq('id', id);
  }

  Future<void> deleteItem(String id) async {
    await _supabase.from('second_hand_items').delete().eq('id', id);
  }

  Future<List<SecondHandItemModel>> getActiveItems({
    String? category,
    String? subcategory,
    String? city,
    String? district,
    int? minPrice,
    int? maxPrice,
  }) async {
    var query =
        _supabase.from('second_hand_items').select('*').eq('is_active', true);

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (subcategory != null && subcategory.isNotEmpty) {
      query = query.eq('subcategory', subcategory);
    }
    if (city != null && city.isNotEmpty) {
      query = query.eq('city', city);
    }
    if (district != null && district.isNotEmpty) {
      query = query.eq('district', district);
    }
    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => SecondHandItemModel.fromJson(json))
        .toList();
  }

  Future<List<SecondHandItemModel>> getMyItems(String userId) async {
    final response = await _supabase
        .from('second_hand_items')
        .select('*')
        .eq('seller_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => SecondHandItemModel.fromJson(json))
        .toList();
  }

  Future<void> deactivateItem(String id) async {
    await _supabase
        .from('second_hand_items')
        .update({'is_active': false}).eq('id', id);
  }

  Future<void> reactivateItem(String id) async {
    await _supabase
        .from('second_hand_items')
        .update({'is_active': true}).eq('id', id);
  }
}
