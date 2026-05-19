/// Python scraper tarafından kazınan resmi üniversite duyuruları modeli.
class ScrapedAnnouncementModel {
  final String id;
  final String university;
  final String title;
  final String? content;
  final String? summary;
  final String category;
  final DateTime? publishedAt;
  final DateTime? scrapedAt;
  final String? sourceUrl;
  final String? externalLink;
  final String? imageUrl;
  final bool isActive;

  ScrapedAnnouncementModel({
    required this.id,
    required this.university,
    required this.title,
    this.content,
    this.summary,
    this.category = 'genel',
    this.publishedAt,
    this.scrapedAt,
    this.sourceUrl,
    this.externalLink,
    this.imageUrl,
    this.isActive = true,
  });

  factory ScrapedAnnouncementModel.fromJson(Map<String, dynamic> json) {
    return ScrapedAnnouncementModel(
      id: json['id'] as String,
      university: json['university'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      summary: json['summary'] as String?,
      category: json['category'] as String? ?? 'genel',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      scrapedAt: json['scraped_at'] != null
          ? DateTime.tryParse(json['scraped_at'] as String)
          : null,
      sourceUrl: json['source_url'] as String?,
      externalLink: json['external_link'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
