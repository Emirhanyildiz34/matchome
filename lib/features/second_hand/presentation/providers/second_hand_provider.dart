import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/second_hand_repository.dart';
import '../../data/models/second_hand_item_model.dart';

final secondHandRepositoryProvider = Provider<SecondHandRepository>((ref) {
  return SecondHandRepository(Supabase.instance.client);
});

class SecondHandFilter {
  final String? category;
  final String? subcategory;
  final String? city;
  final String? district;
  final int? minPrice;
  final int? maxPrice;

  const SecondHandFilter({
    this.category,
    this.subcategory,
    this.city,
    this.district,
    this.minPrice,
    this.maxPrice,
  });

  SecondHandFilter copyWith({
    String? Function()? category,
    String? Function()? subcategory,
    String? Function()? city,
    String? Function()? district,
    int? Function()? minPrice,
    int? Function()? maxPrice,
  }) {
    return SecondHandFilter(
      category: category != null ? category() : this.category,
      subcategory: subcategory != null ? subcategory() : this.subcategory,
      city: city != null ? city() : this.city,
      district: district != null ? district() : this.district,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    );
  }

  bool get hasActiveFilters =>
      category != null ||
      subcategory != null ||
      city != null ||
      district != null ||
      minPrice != null ||
      maxPrice != null;
}

final secondHandFilterProvider =
    StateProvider<SecondHandFilter>((ref) => const SecondHandFilter());

final secondHandSearchProvider = StateProvider<String>((ref) => '');

final secondHandItemsProvider =
    FutureProvider.autoDispose<List<SecondHandItemModel>>((ref) async {
  final filter = ref.watch(secondHandFilterProvider);
  return ref.read(secondHandRepositoryProvider).getActiveItems(
        category: filter.category,
        subcategory: filter.subcategory,
        city: filter.city,
        district: filter.district,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
      );
});

final mySecondHandItemsProvider =
    FutureProvider.autoDispose<List<SecondHandItemModel>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  return ref.read(secondHandRepositoryProvider).getMyItems(user.id);
});
