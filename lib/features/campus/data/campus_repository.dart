import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/university_data.dart';
import 'models/campus_announcement_model.dart';
import 'models/scraped_announcement_model.dart';

class CampusRepository {
  final SupabaseClient _supabase;

  CampusRepository(this._supabase);

  // ─── Resmi (Scraped) Duyurular ───

  /// Scraper botunun kazıdığı resmi üniversite duyurularını getirir
  Future<List<ScrapedAnnouncementModel>> getScrapedAnnouncements(
    String university,
  ) async {
    final candidates = _buildUniversityCandidates(university);

    final response = await _supabase
        .from('scraped_announcements')
        .select('*')
        .inFilter('university', candidates)
        .eq('is_active', true)
        .order('published_at', ascending: false)
        .limit(50);

    final direct = (response as List)
        .map((json) => ScrapedAnnouncementModel.fromJson(json))
        .toList();

    if (direct.isNotEmpty) {
      return direct;
    }

    // Eski/kirli verilerde ad farklari olabilir; normalize ederek tekrar filtrele.
    final fallback = await _supabase
        .from('scraped_announcements')
        .select('*')
        .eq('is_active', true)
        .order('published_at', ascending: false)
        .limit(400);

    final candidateKeys = candidates
        .map(_normalizeUniversityKey)
        .where((k) => k.isNotEmpty)
        .toSet();

    return (fallback as List)
        .where((json) {
          final rowUni = (json['university'] as String? ?? '').trim();
          return candidateKeys.contains(_normalizeUniversityKey(rowUni));
        })
        .map((json) => ScrapedAnnouncementModel.fromJson(json))
        .take(50)
        .toList();
  }

  List<String> _buildUniversityCandidates(String university) {
    final raw = university.trim();
    final resolved = UniversityData.resolveUniversityName(raw);

    final set = <String>{
      raw,
      if (resolved != null && resolved.isNotEmpty) resolved,
    };

    final extra = <String>[];
    for (final name in set.toList()) {
      // Türkçe ↔ İngilizce "Üniversitesi" dönüşümü
      extra.add(name.replaceAll('Üniversitesi', 'Universitesi'));
      extra.add(name.replaceAll('Universitesi', 'Üniversitesi'));
      extra.add(name.replaceAll('University', 'Üniversitesi'));
      extra.add(name.replaceAll('Üniversitesi', 'University'));

      // Tüm Türkçe karakterleri ASCII'ye çevir
      final ascii = name
          .replaceAll('İ', 'I')
          .replaceAll('ı', 'i')
          .replaceAll('Ş', 'S')
          .replaceAll('ş', 's')
          .replaceAll('Ğ', 'G')
          .replaceAll('ğ', 'g')
          .replaceAll('Ü', 'U')
          .replaceAll('ü', 'u')
          .replaceAll('Ö', 'O')
          .replaceAll('ö', 'o')
          .replaceAll('Ç', 'C')
          .replaceAll('ç', 'c');
      extra.add(ascii);

      // ASCII + Universitesi dönüşümü
      extra.add(ascii.replaceAll('Universitesi', 'Üniversitesi'));
      extra.add(ascii.replaceAll('University', 'Universitesi'));
    }
    set.addAll(extra.map((e) => e.trim()).where((e) => e.isNotEmpty));

    return set.toList();
  }

  String _normalizeUniversityKey(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .replaceAll(RegExp(r'\buniversitesi\b'), 'uni')
        .replaceAll(RegExp(r'\buniversity\b'), 'uni')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ─── Kullanıcı (Topluluk) Duyuruları ───

  /// Üniversite ve kampüse göre duyuruları getir
  /// [campus] null ise, tüm kampüsün duyuruları getirilir
  /// Eski inactive duyuruları otomatik siler
  Future<List<CampusAnnouncementModel>> getAnnouncementsByUniversity(
    String university, {
    String? campus,
  }) async {
    // Önce eski duyuruları sil
    await _cleanupOldAnnouncements();

    try {
      // profiles join ile dene (FK düzgünse çalışır)
      return await _fetchAnnouncements(
        university: university,
        campus: campus,
        selectQuery:
            '*, profiles!fk_campus_ann_profiles(full_name, avatar_url)',
      );
    } catch (_) {
      // FK henüz yoksa veya join hatası varsa, profil bilgisi olmadan getir
      return await _fetchAnnouncements(
        university: university,
        campus: campus,
        selectQuery: '*',
      );
    }
  }

  Future<List<CampusAnnouncementModel>> _fetchAnnouncements({
    required String university,
    String? campus,
    required String selectQuery,
  }) async {
    var query = _supabase
        .from('campus_announcements')
        .select(selectQuery)
        .eq('university', university)
        .eq('is_active', true);

    if (campus != null && campus.isNotEmpty) {
      // Üniversite geneli duyurular VEYA bu kampüse özel duyurular
      query = query.or(
        'visibility_scope.eq.university,and(visibility_scope.eq.campus,campus.eq.$campus)',
      );
    }
    // campus bilinmiyorsa visibility_scope filtresi uygulanmaz;
    // üniversitenin TÜM duyuruları gösterilir

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => CampusAnnouncementModel.fromJson(json))
        .toList();
  }

  /// Eski duyuruları temizle (30 gün önceki inactive duyurular)
  Future<void> _cleanupOldAnnouncements() async {
    try {
      final nowIso = DateTime.now().toIso8601String();

      // Bitiş tarihi geçen aktif duyuruları otomatik pasife al.
      await _supabase
          .from('campus_announcements')
          .update({'is_active': false})
          .eq('is_active', true)
          .not('end_date', 'is', null)
          .lt('end_date', nowIso);

      // 30 gün önceki inactive duyuruları sil
      await _supabase
          .from('campus_announcements')
          .delete()
          .eq('is_active', false)
          .lt(
              'created_at',
              DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String());
    } catch (e) {
      // Cleanup başarısız olsa da işleme devam et
      // print('Cleanup hatası: $e');
    }
  }

  /// Bugünden 7 gün önceki tüm inactive duyuruları kalıcı olarak sil
  Future<void> permanentlyDeleteOldInactiveAnnouncements({
    int daysOld = 7,
  }) async {
    await _supabase
        .from('campus_announcements')
        .delete()
        .eq('is_active', false)
        .lt('created_at',
            DateTime.now().subtract(Duration(days: daysOld)).toIso8601String());
  }

  Future<void> createAnnouncement(CampusAnnouncementModel announcement) async {
    await _supabase.from('campus_announcements').insert(announcement.toJson());
  }

  Future<void> updateAnnouncement(CampusAnnouncementModel announcement) async {
    final id = announcement.id;
    if (id == null) {
      throw ArgumentError('Güncellenecek duyurunun id alanı zorunludur.');
    }

    final payload = announcement.toJson()..remove('id');
    await _supabase.from('campus_announcements').update(payload).eq('id', id);
  }

  /// Duyuruyu pasife al (soft delete)
  Future<void> deactivateAnnouncement(String id) async {
    await _supabase
        .from('campus_announcements')
        .update({'is_active': false}).eq('id', id);
  }

  /// Duyuruyu/İlanı tamamlandı veya bulundu olarak işaretle
  Future<void> markAsResolved(String id) async {
    await _supabase
        .from('campus_announcements')
        .update({'is_resolved': true}).eq('id', id);
  }

  /// Etkinliğe katılmak/başvurmak için form doldur
  Future<void> applyToEvent({
    required String announcementId,
    required String contactInfo,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

    await _supabase.from('campus_announcement_applications').insert({
      'announcement_id': announcementId,
      'applicant_id': userId,
      'contact_info': contactInfo,
    });
  }

  /// Son kaç saatte yayınlanan duyuruları getir (refresh kontrol için)
  Future<int> getRecentAnnouncementCount({
    required String university,
    String? campus,
    Duration? since,
  }) async {
    since ??= const Duration(hours: 24);
    final sinceTime = DateTime.now().subtract(since).toIso8601String();

    var query = _supabase
        .from('campus_announcements')
        .select('id')
        .eq('university', university)
        .eq('is_active', true)
        .gte('created_at', sinceTime);

    if (campus != null && campus.isNotEmpty) {
      query = query.or(
        'visibility_scope.eq.university,and(visibility_scope.eq.campus,campus.eq.$campus)',
      );
    } else {
      query = query.eq('visibility_scope', 'university');
    }

    final result = await query;
    return (result as List).length;
  }
}
