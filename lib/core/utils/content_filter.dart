/// Türkçe argo ve küfür filtresi
class ContentFilter {
  ContentFilter._();

  static const List<String> _blockedWords = [
    // Türkçe küfürler
    'orospu', 'orosbu', 'orsp',
    'sik', 'sikerim', 'sikeyim', 'sikmek', 'sikik', 'sikiş', 'sikilmiş',
    'amk', 'amq', 'amo', 'amına', 'amını',
    'osuruk', 'osurmak',
    'bok', 'boktan',
    'göt', 'götün', 'götü',
    'kaltak',
    'pezevenk',
    'ibne', 'obn',
    'oç', 'oğlum', 'orospu çocuğu',
    'piç', 'piçlik',
    'kahpe', 'kahpelik',
    'serefsiz', 'şerefsiz', 'şerefsizlik',
    'nankör',
    'bok çukuru',
    'orospu çocuğu',
    // İnternet argosu
    'aq', 'mk', 'mq', 'skm', 'skrm',
    'oç', 'ocn',
    'yavşak',
    'sürtük',
    'fahişe',
    'oğlancı',
    'dallama',
    'mal', // argo bağlamda
    'gerizekalı', 'gerzek',
    'salak', 'aptal', // hakaret içerikli
    'ahmak',
    'dangalak',
    'beyinsiz',
    'haysiyetsiz',
  ];

  /// [text] içinde argo veya küfür var mı kontrol eder.
  /// Eşleşen kelimeleri döndürür (boş liste = temiz içerik).
  static List<String> findBlockedWords(String text) {
    final lower = text.toLowerCase();
    final found = <String>[];
    for (final blocked in _blockedWords) {
      // False positive önlemek için substring match yerine word boundary match
      var pattern = RegExp(
        r'(?:^|[\s\W])' + RegExp.escape(blocked) + r'(?:[\s\W]|$)',
      );
      if (pattern.hasMatch(lower)) {
        found.add(blocked);
      }
    }
    return found;
  }

  static bool hasBlockedContent(String text) =>
      findBlockedWords(text).isNotEmpty;
}
