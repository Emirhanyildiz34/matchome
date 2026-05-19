class CampusAnnouncementModel {
  final String? id;
  final String authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final String university;
  final String? campus;

  /// 'campus' → yalnızca bu kampüsteki öğrenciler görür
  /// 'university' → tüm üniversite öğrencileri görür
  final String visibilityScope;
  final String title;
  final String? content;
  final String category;
  final List<String> imageUrls;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? eventDate;
  final double? latitude;
  final double? longitude;
  final String? addressText;
  final bool isActive;
  final DateTime? createdAt;

  // Etkinlik/Topluluk duyuruları için
  final int? maxParticipants;
  final String? participationFee;

  // Kayıp eşya ilanları için
  final String? lastSeenLocation;
  final DateTime? lastSeenDate;

  // İlan tamamlandı (bulundu veya kontenjan doldu) durumu
  final bool isResolved;

  static const Map<String, Map<String, String>> categories = {
    'genel': {'label': 'Genel Duyuru', 'emoji': '📢'},
    'etkinlik': {'label': 'Etkinlik', 'emoji': '🎉'},
    'kayip_esya': {'label': 'Kayıp Eşya', 'emoji': '🔍'},
  };

  CampusAnnouncementModel({
    this.id,
    required this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    required this.university,
    this.campus,
    this.visibilityScope = 'campus',
    required this.title,
    this.content,
    this.category = 'genel',
    this.imageUrls = const [],
    this.startDate,
    this.endDate,
    this.eventDate,
    this.latitude,
    this.longitude,
    this.addressText,
    this.isActive = true,
    this.createdAt,
    this.maxParticipants,
    this.participationFee,
    this.lastSeenLocation,
    this.lastSeenDate,
    this.isResolved = false,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'author_id': authorId,
      'university': university,
      if (campus != null) 'campus': campus,
      'visibility_scope': visibilityScope,
      'title': title,
      'content': content,
      'category': category,
      'image_urls': imageUrls,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (eventDate != null) 'event_date': eventDate!.toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (addressText != null) 'address_text': addressText,
      'is_active': isActive,
      if (maxParticipants != null) 'max_participants': maxParticipants,
      if (participationFee != null) 'participation_fee': participationFee,
      if (lastSeenLocation != null) 'last_seen_location': lastSeenLocation,
      if (lastSeenDate != null)
        'last_seen_date': lastSeenDate!.toIso8601String(),
      'is_resolved': isResolved,
    };
  }

  factory CampusAnnouncementModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return CampusAnnouncementModel(
      id: json['id'] as String?,
      authorId: json['author_id'] as String? ?? '',
      authorName: profile?['full_name'] as String?,
      authorAvatarUrl: profile?['avatar_url'] as String?,
      university: json['university'] as String? ?? '',
      campus: json['campus'] as String?,
      visibilityScope: json['visibility_scope'] as String? ?? 'campus',
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      category: json['category'] as String? ?? 'genel',
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      eventDate: json['event_date'] != null
          ? DateTime.tryParse(json['event_date'] as String)
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      addressText: json['address_text'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      maxParticipants: json['max_participants'] as int?,
      participationFee: json['participation_fee'] as String?,
      lastSeenLocation: json['last_seen_location'] as String?,
      lastSeenDate: json['last_seen_date'] != null
          ? DateTime.tryParse(json['last_seen_date'] as String)
          : null,
      isResolved: json['is_resolved'] as bool? ?? false,
    );
  }
}
