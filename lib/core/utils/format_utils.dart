/// Para birimi kodunu simgeye çevirir.
/// TL → ₺, USD → $, EUR → €, GBP → £
String currencySymbol(String currency) {
  switch (currency.toUpperCase()) {
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    default:
      return '₺';
  }
}

/// Sayıyı binlik noktalı formata çevirir: 8000 → 8.000
String formatPrice(int price) {
  return price.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
}

/// DateTime'ı Türkçe kısa tarih stringine çevirir: 10 Mar 2026
String formatDateTr(DateTime date) {
  const months = [
    '',
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  return '${date.day} ${months[date.month]} ${date.year}';
}
