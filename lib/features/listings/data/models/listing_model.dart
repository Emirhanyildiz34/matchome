class ListingModel {
  final String? id;
  final String hostId;
  final String title;
  final String? description;
  final int price;
  final String currency; // 'TL', 'EUR', 'USD', 'GBP'
  final bool utilitiesIncluded;
  final String? roomCount;
  final List<String> houseFeatures;
  final List<String> imageUrls;
  final String? addressText;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final String listingType; // 'room_offer' veya 'room_search'
  final DateTime? createdAt;
  final String? homeType; // 'müstakil', 'apartman', 'site' (room_offer için)
  final int? emptyRooms; // Boş oda sayısı (room_offer için)
  final DateTime? publishedAt; // İlanın yayına alındığı tarih
  final DateTime? unpublishedAt; // İlanın kaldırıldığı tarih (soft delete)
  final List<String> extraFeatures; // ['Ütü', 'Tost Makinesi', 'Saç Kurutma']
  final bool showPhone; // Telefon numarası gösterilsin mi?
  final String? hostPhone; // İlan sahibinin telefon numarası
  final int viewCount; // Görüntülenme sayısı
  final bool hasDeposit; // Depozito var mı?
  final int? depositAmount; // Depozito tutarı (TL)
  final String? preferredGender; // ''male'', 'female' veya null (fark etmez)
  final String? nearbyUniversity; // Yakın üniversite adı

  ListingModel({
    this.id,
    required this.hostId,
    required this.title,
    this.description,
    required this.price,
    this.currency = 'TL',
    this.utilitiesIncluded = false,
    this.roomCount,
    this.houseFeatures = const [],
    this.imageUrls = const [],
    this.addressText,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.listingType = 'room_offer',
    this.createdAt,
    this.homeType,
    this.emptyRooms,
    this.publishedAt,
    this.unpublishedAt,
    this.extraFeatures = const [],
    this.showPhone = false,
    this.hostPhone,
    this.viewCount = 0,
    this.hasDeposit = false,
    this.depositAmount,
    this.preferredGender,
    this.nearbyUniversity,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'host_id': hostId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'utilities_included': utilitiesIncluded,
      'room_count': roomCount,
      'house_features': houseFeatures,
      'image_urls': imageUrls,
      'address_text': addressText,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'listing_type': listingType,
      'home_type': homeType,
      'empty_rooms': emptyRooms,
      'published_at': publishedAt?.toIso8601String(),
      'unpublished_at': unpublishedAt?.toIso8601String(),
      'extra_features': extraFeatures,
      'show_phone': showPhone,
      'host_phone': hostPhone,
      'has_deposit': hasDeposit,
      if (depositAmount != null) 'deposit_amount': depositAmount,
      'preferred_gender': preferredGender,
      'nearby_university': nearbyUniversity,
    };
  } // Not: view_count DB tarafınca yönetilir, toJson'a eklenmez

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'],
      hostId: json['host_id'],
      title: json['title'],
      description: json['description'],
      price: json['price'] ?? 0,
      currency: json['currency'] ?? 'TL',
      utilitiesIncluded: json['utilities_included'] ?? false,
      roomCount: json['room_count'],
      houseFeatures: List<String>.from(json['house_features'] ?? []),
      imageUrls: (List<String>.from(json['image_urls'] ?? []))
          .where((url) => url.startsWith('http'))
          .toList(),
      addressText: json['address_text'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isActive: json['is_active'] ?? true,
      listingType: json['listing_type'] ?? 'room_offer',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      homeType: json['home_type'],
      emptyRooms: json['empty_rooms'],
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      unpublishedAt: json['unpublished_at'] != null
          ? DateTime.parse(json['unpublished_at'])
          : null,
      extraFeatures: List<String>.from(json['extra_features'] ?? []),
      showPhone: json['show_phone'] ?? false,
      hostPhone: json['host_phone'],
      viewCount: json['view_count'] ?? 0,
      hasDeposit: json['has_deposit'] ?? false,
      depositAmount: json['deposit_amount'],
      preferredGender: json['preferred_gender'] as String?,
      nearbyUniversity: json['nearby_university'] as String?,
    );
  }

  ListingModel copyWith({
    String? id,
    String? hostId,
    String? title,
    String? description,
    int? price,
    String? currency,
    bool? utilitiesIncluded,
    String? roomCount,
    List<String>? houseFeatures,
    List<String>? imageUrls,
    String? addressText,
    double? latitude,
    double? longitude,
    bool? isActive,
    String? listingType,
    DateTime? createdAt,
    String? homeType,
    int? emptyRooms,
    DateTime? publishedAt,
    DateTime? unpublishedAt,
    List<String>? extraFeatures,
    bool? showPhone,
    String? hostPhone,
    int? viewCount,
    bool? hasDeposit,
    int? depositAmount,
    String? Function()? preferredGender,
    String? Function()? nearbyUniversity,
  }) {
    return ListingModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      utilitiesIncluded: utilitiesIncluded ?? this.utilitiesIncluded,
      roomCount: roomCount ?? this.roomCount,
      houseFeatures: houseFeatures ?? this.houseFeatures,
      imageUrls: imageUrls ?? this.imageUrls,
      addressText: addressText ?? this.addressText,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      listingType: listingType ?? this.listingType,
      createdAt: createdAt ?? this.createdAt,
      homeType: homeType ?? this.homeType,
      emptyRooms: emptyRooms ?? this.emptyRooms,
      publishedAt: publishedAt ?? this.publishedAt,
      unpublishedAt: unpublishedAt ?? this.unpublishedAt,
      extraFeatures: extraFeatures ?? this.extraFeatures,
      showPhone: showPhone ?? this.showPhone,
      hostPhone: hostPhone ?? this.hostPhone,
      viewCount: viewCount ?? this.viewCount,
      hasDeposit: hasDeposit ?? this.hasDeposit,
      depositAmount: depositAmount ?? this.depositAmount,
      preferredGender:
          preferredGender != null ? preferredGender() : this.preferredGender,
      nearbyUniversity:
          nearbyUniversity != null ? nearbyUniversity() : this.nearbyUniversity,
    );
  }
}
