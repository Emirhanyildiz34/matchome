import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/listing_repository.dart';
import '../../data/favorites_repository.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/favorite_model.dart';

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepository(Supabase.instance.client);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(Supabase.instance.client);
});

// Filtre durumu
class ListingFilter {
  final String? listingType; // 'room_offer', 'room_search' veya null (hepsi)
  final int? minPrice;
  final int? maxPrice;
  final String? roomCount;
  final String? city;
  final String? district;
  final List<String> features; // Ev özellikleri filtresi
  final String? sortOrder; // 'price_asc', 'price_desc', 'newest', 'most_visited'

  const ListingFilter({
    this.listingType,
    this.minPrice,
    this.maxPrice,
    this.roomCount,
    this.city,
    this.district,
    this.features = const [],
    this.sortOrder,
  });

  ListingFilter copyWith({
    String? Function()? listingType,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    String? Function()? roomCount,
    String? Function()? city,
    String? Function()? district,
    List<String>? features,
    String? Function()? sortOrder,
  }) {
    return ListingFilter(
      listingType: listingType != null ? listingType() : this.listingType,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      roomCount: roomCount != null ? roomCount() : this.roomCount,
      city: city != null ? city() : this.city,
      district: district != null ? district() : this.district,
      features: features ?? this.features,
      sortOrder: sortOrder != null ? sortOrder() : this.sortOrder,
    );
  }

  bool get hasActiveFilters =>
      listingType != null ||
      minPrice != null ||
      maxPrice != null ||
      roomCount != null ||
      (city != null && city!.isNotEmpty) ||
      (district != null && district!.isNotEmpty) ||
      features.isNotEmpty ||
      sortOrder != null;
}

final listingFilterProvider =
    StateProvider<ListingFilter>((ref) => const ListingFilter());

final myListingProvider = FutureProvider.autoDispose<ListingModel?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  return ref.read(listingRepositoryProvider).getMyListing(user.id);
});

final myListingsProvider = FutureProvider.autoDispose<List<ListingModel>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  return ref.read(listingRepositoryProvider).getMyListings(user.id);
});

final activeListingsProvider = FutureProvider.autoDispose<List<ListingModel>>((ref) async {
  final filter = ref.watch(listingFilterProvider);
  final listings = await ref.read(listingRepositoryProvider).getActiveListings(
    listingType: filter.listingType,
    minPrice: filter.minPrice,
    maxPrice: filter.maxPrice,
    roomCount: filter.roomCount,
    city: filter.city,
    district: filter.district,
  );
  // Ev özellikleri filtresi — client-side (Supabase array contains sorgusuna alternatif)
  List<ListingModel> filtered = listings;
  if (filter.features.isNotEmpty) {
    filtered = filtered.where((l) {
      final allFeatures = [...l.houseFeatures, ...l.extraFeatures];
      return filter.features.every((f) => allFeatures.contains(f));
    }).toList();
  }

  // Sıralama
  switch (filter.sortOrder) {
    case 'price_asc':
      filtered.sort((a, b) => a.price.compareTo(b.price));
      break;
    case 'price_desc':
      filtered.sort((a, b) => b.price.compareTo(a.price));
      break;
    case 'newest':
      filtered.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      break;
    case 'most_visited':
      filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      break;
    default:
      // Varsayılan: en yeni önce (DB'den zaten bu sırayla geliyor)
      break;
  }

  return filtered;
});

// Favoriler Provider'ları
final favoritesProvider = FutureProvider.autoDispose<List<FavoriteModel>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  return ref.read(favoritesRepositoryProvider).getFavorites(user.id);
});

final favoritesByCategoryProvider = FutureProvider.autoDispose.family<List<FavoriteModel>, String>((ref, category) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  return ref.read(favoritesRepositoryProvider).getFavoritesByCategory(user.id, category);
});

final isFavoritedProvider = FutureProvider.autoDispose.family<bool, String>((ref, listingId) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  final favorite = await ref.read(favoritesRepositoryProvider).isFavorited(user.id, listingId);
  return favorite != null;
});

// Fiyat Geçmişi Provider'ı
final priceHistoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, listingId) async {
  return ref.read(listingRepositoryProvider).getPriceHistory(listingId);
});

// Sesli/metin arama sorgusu
final searchQueryProvider = StateProvider<String>((ref) => '');
