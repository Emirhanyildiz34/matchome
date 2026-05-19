class FavoriteModel {
  final String id;
  final String userId;
  final String listingId;
  final String category; // 'yaşam', 'fiyat', 'konum', 'özellik', 'diğer'
  final int priceAtFavorite;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.listingId,
    this.category = 'diğer',
    required this.priceAtFavorite,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'listing_id': listingId,
      'category': category,
      'price_at_favorite': priceAtFavorite,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'],
      userId: json['user_id'],
      listingId: json['listing_id'],
      category: json['category'] ?? 'diğer',
      priceAtFavorite: json['price_at_favorite'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  FavoriteModel copyWith({
    String? id,
    String? userId,
    String? listingId,
    String? category,
    int? priceAtFavorite,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FavoriteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      listingId: listingId ?? this.listingId,
      category: category ?? this.category,
      priceAtFavorite: priceAtFavorite ?? this.priceAtFavorite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
