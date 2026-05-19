class ConversationModel {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final String? participant1Name;
  final String? participant2Name;
  final String? listingId;
  final String listingType; // 'listing' veya 'second_hand'
  final String? listingImageUrl;
  final String? listingTitle;

  const ConversationModel({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessage,
    required this.lastMessageAt,
    this.participant1Name,
    this.participant2Name,
    this.listingId,
    this.listingType = 'listing',
    this.listingImageUrl,
    this.listingTitle,
  });

  String otherUserName(String currentUserId) {
    if (participant1Id == currentUserId) {
      return participant2Name ?? 'Kullanıcı';
    }
    return participant1Name ?? 'Kullanıcı';
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final p1 = json['p1'] as Map<String, dynamic>?;
    final p2 = json['p2'] as Map<String, dynamic>?;

    return ConversationModel(
      id: json['id'] as String,
      participant1Id: json['participant1_id'] as String,
      participant2Id: json['participant2_id'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String).toLocal()
          : DateTime.now(),
      participant1Name: p1?['full_name'] as String?,
      participant2Name: p2?['full_name'] as String?,
      listingId: json['listing_id'] as String?,
      listingType: (json['listing_type'] as String?) ?? 'listing',
      listingImageUrl: json['listing_image_url'] as String?,
      listingTitle: json['listing_title'] as String?,
    );
  }
}
