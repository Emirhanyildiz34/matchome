import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/campus_repository.dart';
import '../../data/campus_cleanup_service.dart';
import '../../data/models/campus_announcement_model.dart';
import '../../data/models/scraped_announcement_model.dart';

final campusRepositoryProvider = Provider<CampusRepository>((ref) {
  return CampusRepository(Supabase.instance.client);
});

final campusCleanupServiceProvider = Provider<CampusCleanupService>((ref) {
  return CampusCleanupService(ref.read(campusRepositoryProvider));
});

/// Resmi (scraper'dan gelen) duyurular
final scrapedAnnouncementsProvider = FutureProvider.autoDispose
    .family<List<ScrapedAnnouncementModel>, String>((ref, university) async {
  return ref.read(campusRepositoryProvider).getScrapedAnnouncements(university);
});

/// Topluluk (kullanıcı) duyuruları
final campusAnnouncementsProvider = FutureProvider.autoDispose
    .family<List<CampusAnnouncementModel>,
        ({String university, String? campus})>((ref, params) async {
  final cleanupService = ref.read(campusCleanupServiceProvider);
  await cleanupService.performCleanupIfNeeded();

  return ref
      .read(campusRepositoryProvider)
      .getAnnouncementsByUniversity(params.university, campus: params.campus);
});

/// Günlük yeni duyuru sayısı
final dailyAnnouncementCheckProvider =
    FutureProvider.autoDispose.family<int, ({String university, String? campus})>(
        (ref, params) async {
  return ref
      .read(campusRepositoryProvider)
      .getRecentAnnouncementCount(
        university: params.university,
        campus: params.campus,
      );
});
