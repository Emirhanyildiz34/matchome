import 'package:flutter/foundation.dart';
import 'campus_repository.dart';

/// Campus duyuruları için background cleanup service
/// - Eski inactive duyuruları otomatik siler
/// - Günlük refresh check yapılır
class CampusCleanupService {
  final CampusRepository _repository;
  
  // Cleanup check interval (dönem aralığı)
  static const Duration cleanupInterval = Duration(hours: 6);
  static const Duration softDeleteDuration = Duration(days: 30);
  static const Duration hardDeleteDuration = Duration(days: 7);

  DateTime? _lastCleanupTime;

  CampusCleanupService(this._repository);

  /// Cleanup işlemini gerçekleştir (eğer yeterince zaman geçtiyse)
  Future<void> performCleanupIfNeeded() async {
    final now = DateTime.now();
    final lastCleanup = _lastCleanupTime;

    // Minimum interval kontrolü
    if (lastCleanup != null && now.difference(lastCleanup) < cleanupInterval) {
      return;
    }

    try {
      await performCleanup();
      _lastCleanupTime = now;
    } catch (e) {
      debugPrint('Cleanup hatası: $e');
      // Hata durumunda sessiz başarısız olur (uygulamayı bozmaz)
    }
  }

  /// Cleanup işlemini zorla gerçekleştir
  Future<void> performCleanup() async {
    debugPrint('Campus cleanup başladı...');
    
    // Soft delete edilmiş duyuruları hardDelete süresi geçtikten sonra sil
    await _repository.permanentlyDeleteOldInactiveAnnouncements(
      daysOld: hardDeleteDuration.inDays,
    );
    
    debugPrint('Campus cleanup tamamlandı.');
  }

  /// Son cleanup zamanını döndür
  DateTime? get lastCleanupTime => _lastCleanupTime;

  /// Cleanup zeitgeistini sıfırla (test için)
  void resetCleanupTimer() {
    _lastCleanupTime = null;
  }
}
