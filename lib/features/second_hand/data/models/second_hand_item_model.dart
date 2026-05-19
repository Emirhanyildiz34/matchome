class SecondHandCategoryDefinition {
  final String label;
  final String emoji;
  final List<String> subcategories;

  const SecondHandCategoryDefinition({
    required this.label,
    required this.emoji,
    required this.subcategories,
  });
}

class SecondHandItemModel {
  final String? id;
  final String sellerId;
  final String title;
  final String? description;
  final int price;
  final String currency;
  final String category;
  final String? subcategory;
  final String condition;
  final List<String> imageUrls;
  final bool isActive;
  final DateTime? createdAt;
  final String? city;
  final String? district;
  final bool showPhone;
  final String? contactPhone;
  final int viewCount;

  static const Map<String, SecondHandCategoryDefinition> categories = {
    'kiyafet': SecondHandCategoryDefinition(
      label: 'Kıyafet',
      emoji: '👕',
      subcategories: [
        'Tişört',
        'Gömlek',
        'Pantolon',
        'Kot',
        'Elbise',
        'Etek',
        'Ceket',
        'Mont',
        'Sweatshirt',
        'Ayakkabı',
        'Spor Ayakkabı',
        'Terlik',
      ],
    ),
    'aksesuar': SecondHandCategoryDefinition(
      label: 'Aksesuar',
      emoji: '👜',
      subcategories: [
        'Çanta',
        'Cüzdan',
        'Kemer',
        'Şapka',
        'Saat',
        'Gözlük',
        'Küpe',
        'Kolye',
        'Bileklik',
        'Yüzük',
        'Atkı',
        'Bere',
      ],
    ),
    'teknoloji': SecondHandCategoryDefinition(
      label: 'Teknoloji',
      emoji: '💻',
      subcategories: [
        'Telefon',
        'Tablet',
        'Bilgisayar',
        'Laptop',
        'Kulaklık',
        'Akıllı Saat',
        'Hoparlör',
        'Monitör',
        'Klavye',
        'Mouse',
        'Şarj Aleti',
        'Powerbank',
      ],
    ),
    'mutfak': SecondHandCategoryDefinition(
      label: 'Mutfak Gereçleri',
      emoji: '🍳',
      subcategories: [
        'Tencere',
        'Tava',
        'Çaycı',
        'Kettle',
        'Blender',
        'Tabak',
        'Bardak',
        'Çatal Kaşık Bıçak',
        'Saklama Kabı',
        'Kahve Makinesi',
        'Mikrodalga',
        'Mini Fırın',
      ],
    ),
    'ders_kitabi': SecondHandCategoryDefinition(
      label: 'Ders Kitabı',
      emoji: '📚',
      subcategories: [
        'Tıp',
        'Hukuk',
        'Mühendislik',
        'Mimarlık',
        'İktisat',
        'İşletme',
        'Hazırlık',
        'Yabancı Dil',
        'KPSS',
        'ALES',
        'YKS',
        'Roman ve Hikaye',
      ],
    ),
    'mobilya': SecondHandCategoryDefinition(
      label: 'Mobilya',
      emoji: '🪑',
      subcategories: [
        'Çalışma Masası',
        'Sandalye',
        'Kitaplık',
        'Dolap',
        'Komodin',
        'Yatak',
        'Yatak Başlığı',
        'Ayna',
        'Lamba',
        'Askılık',
        'Raf',
        'Puf',
      ],
    ),
    'spor': SecondHandCategoryDefinition(
      label: 'Spor',
      emoji: '⚽',
      subcategories: [
        'Yoga Matı',
        'Dambıl',
        'Bisiklet',
        'Scooter',
        'Top',
        'Raket',
        'Forma',
        'Krampon',
        'Kamp Malzemesi',
        'Suluk',
        'Spor Çantası',
        'Pilates Ekipmanı',
      ],
    ),
    'diger': SecondHandCategoryDefinition(
      label: 'Diğer',
      emoji: '📦',
      subcategories: [
        'Kozmetik',
        'Kırtasiye',
        'Dekorasyon',
        'Oyun Konsolu',
        'Oyuncak',
        'Müzik Enstrümanı',
        'Ev Tekstili',
        'Kişisel Bakım',
        'Hobi Ürünü',
        'Valiz',
        'Pet Ürünü',
        'Diğer',
      ],
    ),
  };

  static const Map<String, String> conditions = {
    'sifir_gibi': '✨ Sıfır Gibi',
    'az_kullanilmis': '👍 Az Kullanılmış',
    'iyi': '😊 İyi',
    'makul': '🔧 Makul',
  };

  SecondHandItemModel({
    this.id,
    required this.sellerId,
    required this.title,
    this.description,
    required this.price,
    this.currency = 'TL',
    required this.category,
    this.subcategory,
    required this.condition,
    this.imageUrls = const [],
    this.isActive = true,
    this.createdAt,
    this.city,
    this.district,
    this.showPhone = false,
    this.contactPhone,
    this.viewCount = 0,
  });

  static List<String> getSubcategories(String category) {
    return categories[category]?.subcategories ?? const [];
  }

  static String? _normalizeText(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _legacyCityPart(String? rawCity) {
    if (rawCity == null || rawCity.isEmpty) return null;
    final parts = rawCity.split(',').map((part) => part.trim()).toList();
    return parts.isEmpty ? null : _normalizeText(parts.first);
  }

  static String? _legacyDistrictPart(String? rawCity) {
    if (rawCity == null || !rawCity.contains(',')) return null;
    final parts = rawCity.split(',').map((part) => part.trim()).toList();
    if (parts.length < 2) return null;
    return _normalizeText(parts.sublist(1).join(', '));
  }

  String get locationLabel => [city, district]
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .join(', ');

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'category': category,
      'subcategory': subcategory,
      'condition': condition,
      'image_urls': imageUrls,
      'is_active': isActive,
      'city': city,
      'district': district,
      'show_phone': showPhone,
      'contact_phone': contactPhone,
    };
  }

  factory SecondHandItemModel.fromJson(Map<String, dynamic> json) {
    final rawCity = _normalizeText(json['city']);
    final rawDistrict = _normalizeText(json['district']);
    return SecondHandItemModel(
      id: json['id'],
      sellerId: json['seller_id'],
      title: json['title'],
      description: json['description'],
      price: json['price'] ?? 0,
      currency: json['currency'] ?? 'TL',
      category: json['category'] ?? 'diger',
      subcategory: _normalizeText(json['subcategory']),
      condition: json['condition'] ?? 'iyi',
      imageUrls: (List<String>.from(json['image_urls'] ?? []))
          .where((url) => url.startsWith('http'))
          .toList(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      city: rawDistrict == null ? _legacyCityPart(rawCity) : rawCity,
      district: rawDistrict ?? _legacyDistrictPart(rawCity),
      showPhone: json['show_phone'] ?? false,
      contactPhone: json['contact_phone'],
      viewCount: json['view_count'] ?? 0,
    );
  }

  SecondHandItemModel copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    int? price,
    String? currency,
    String? category,
    String? subcategory,
    String? condition,
    List<String>? imageUrls,
    bool? isActive,
    DateTime? createdAt,
    String? city,
    String? district,
    bool? showPhone,
    String? contactPhone,
    int? viewCount,
  }) {
    return SecondHandItemModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      condition: condition ?? this.condition,
      imageUrls: imageUrls ?? this.imageUrls,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      city: city ?? this.city,
      district: district ?? this.district,
      showPhone: showPhone ?? this.showPhone,
      contactPhone: contactPhone ?? this.contactPhone,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}
