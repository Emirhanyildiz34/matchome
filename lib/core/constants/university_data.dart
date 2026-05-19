/// GeoJSON kaynağından türetilen üniversite/kampüs koordinat verisi.
class CampusData {
  final String name;
  final double latitude;
  final double longitude;

  const CampusData(this.name, this.latitude, this.longitude);
}

class UniversityData {
  /// Üniversite adı -> kampüs listesi.
  static final Map<String, List<CampusData>> universities = {
    '19 Mayıs Üniversitesi': [
      const CampusData('Sağlık Yüksek Okulu', 41.372360, 36.211836),
      const CampusData('Vezirköprü MYO', 41.130004, 35.456326),
    ],
    '29 Mayıs Üniversitesi': [
      const CampusData('Ana Kampüs', 41.032016, 29.098857),
    ],
    '7 Aralık Üniversitesi': [
      const CampusData('Ana Kampüs', 36.731231, 37.102097),
    ],
    'AUZEF İstanbul üniversitesi': [
      const CampusData('Ana Kampüs', 41.012362, 28.961005),
    ],
    'AYDIN ADNAN MENDERES ÜNİVERSİTESİ': [
      const CampusData('SÖKE MYO YENİKENT YERLEŞKESİ', 37.760930, 27.396169),
      const CampusData('SÖKE İŞLETME VE MİMARLIK TASARIM FAKÜLTELERİ YERLEŞKESİ', 37.767466, 27.393216),
    ],
    'Abant İzzet Baysal Üniversitesi': [
      const CampusData('Ana Kampüs', 40.715952, 31.517278),
      const CampusData('Mengen Meslek Yüksekokulu', 40.936363, 32.084357),
      const CampusData('Seben İzzet Baysal Meslek Yüksekokulu', 40.408226, 31.566401),
      const CampusData('Şehir Yerleşkesi', 40.739355, 31.602189),
    ],
    'Abdullah Gül Üniversitesi': [
      const CampusData('Ana Kampüs', 38.681912, 35.609274),
      const CampusData('Sümer Kampüsü', 38.737440, 35.475114),
    ],
    'Acıbadem Üniversitesi': [
      const CampusData('Kerem Aydınlar Yerleşkesi', 40.978472, 29.110239),
    ],
    'Adana Alparslan Türkeş Bilim ve Teknoloji Üniversitesi': [
      const CampusData('Ana Kampüs', 37.044676, 35.389027),
    ],
    'Adana Bilim ve Teknoloji Üniversitesi': [
      const CampusData('Yeşiloba Yerleşkesi', 37.005837, 35.249663),
    ],
    'Adnan Menderes Üniversitesi': [
      const CampusData('Atça Meslek Yüksekokulu', 37.883881, 28.207193),
      const CampusData('Batı Yerleşkesi', 37.830739, 27.795932),
      const CampusData('Bozdoğan Meslek Yüksek Okulu', 37.673746, 28.319985),
      const CampusData('Buharkent Meslek Yüksekokulu', 37.980540, 28.748065),
      const CampusData('Didim Yerleşkesi', 37.408418, 27.378083),
      const CampusData('Ek Yerleşke', 37.854941, 27.263043),
      const CampusData('Güney Yerleşkesi', 37.760503, 27.754592),
      const CampusData('Sultanhisar Meslek Yüksek Okulu', 37.888234, 28.159766),
      const CampusData('Sülayman Pekgüzel Kampüsü', 37.630956, 28.041279),
      const CampusData('İsabeyli Kampüsü', 37.910347, 28.264710),
    ],
    'Adıyaman Üniversitesi': [
      const CampusData('Ana Kampüs', 37.746227, 38.226018),
    ],
    'Afyon Kocatepe Üniversitesi': [
      const CampusData('Ahmet Karahisar Kampüsü', 38.719284, 30.566344),
      const CampusData('Ahmet Necdet Sezer Kampüsü', 38.817396, 30.533785),
    ],
    'Afyonkarahisar Sağlık Bilimleri Üniversitesi': [
      const CampusData('Ana Kampüs', 38.785052, 30.464621),
    ],
    'Akdeniz Üniversitesi': [
      const CampusData('Ana Kampüs', 36.892701, 30.649546),
      const CampusData('Manavgat Meslek Yüksekokulu', 36.789856, 31.471551),
      const CampusData('Mimarlık Fakültesi', 36.890289, 30.644592),
      const CampusData('Serik Gülsün - Süleyman Süral M.Y.O', 36.922113, 31.090205),
      const CampusData('Serik Meslek Yüksekokulu', 36.917235, 31.105035),
      const CampusData('Sosyal Bilimler MYO', 36.903997, 30.679525),
    ],
    'Aksaray Üniversitesi': [
      const CampusData('Ana Kampüs', 38.331624, 33.987204),
      const CampusData('Ortaköy MYO', 38.754557, 34.038236),
    ],
    'Alanya Alaaddin Keykubat Üniversitesi': [
      const CampusData('Ana Kampüs', 36.526580, 32.084054),
      const CampusData('Rektörlüğü', 36.584503, 31.888995),
    ],
    'Alanya Üniversitesi': [
      const CampusData('Merkez Kampüsü', 36.548223, 32.032051),
    ],
    'Altınbaş Üniversitesi': [
      const CampusData('Ana Kampüs', 41.057364, 28.820769),
      const CampusData('Gayrettepe Sosyal Bilimler Yerleşkesi', 41.069974, 29.012855),
    ],
    'Amasya Üniversitesi': [
      const CampusData('Fen-Edebiyat Fakültesi İpekköy Yerleşkesi', 40.607243, 35.813782),
      const CampusData('Hasan Duman Meslek Yüksekokulu', 40.875250, 35.210921),
      const CampusData('Kirazlıdere Yerleşkesi', 40.664871, 35.846913),
      const CampusData('Meslek Yüksek Okulu', 40.649977, 35.790406),
      const CampusData('Yeşilırmak Yerleşkesi', 40.650014, 35.790998),
    ],
    'Anadolu Üniversitesi': [
      const CampusData('Ana Kampüs', 39.792057, 30.500085),
      const CampusData('AÖF Konya Bürosu', 37.868563, 32.485119),
      const CampusData('AÖF Sincan Bürosu', 39.962757, 32.578621),
      const CampusData('AÖF Toros Bürosu', 37.013651, 35.325926),
      const CampusData('Erzincan Bürosu', 39.746967, 39.499585),
    ],
    'Ankara Güzel Sanatlar ve Müzik Üniversitesi': [
      const CampusData('Ana Kampüs', 39.857751, 32.845724),
    ],
    'Ankara Hacı Bayram Veli Üniversitesi': [
      const CampusData('İktisadi ve İdari Bilimler Fakültesi', 39.934540, 32.828021),
      const CampusData('İletişim Fakültesi', 39.919223, 32.814947),
    ],
    'Ankara Sosyal Bilimler Üniversitesi': [
      const CampusData('Ana Kampüs', 39.943303, 32.855590),
    ],
    'Ankara Yıldırım Beyazıt Üniversitesi': [
      const CampusData('Batı Kampüsü', 39.970365, 32.817419),
      const CampusData('Esenboğa Yerleşkesi', 40.133414, 32.949341),
      const CampusData('Etlik Milli İrade Yerleşkesi', 39.972093, 32.824435),
      const CampusData('Tuz Gölü Yerleşkesi', 38.957115, 33.522106),
      const CampusData('Tıp Fakültesi', 39.903538, 32.761617),
    ],
    'Ankara Üniversitesi': [
      const CampusData('50. Yıl Kampüsü', 39.780490, 32.820234),
      const CampusData('Ankara Keçisi ve Tiftik Uygulama ve Araştırma Merkezi', 40.210620, 32.243638),
      const CampusData('Cebeci Yerleşkesi', 39.927907, 32.873388),
      const CampusData('Dışkapı Yerleşkesi', 39.962308, 32.862735),
      const CampusData('Keçiören Yerleşkesi', 39.996316, 32.862126),
      const CampusData('Kök Hücre Enstitüsü', 39.881386, 32.815750),
      const CampusData('Tandoğan Yerleşkesi', 39.937052, 32.828133),
      const CampusData('Tıp Fakültesi Halk Sağlığı Anabilim Dalı', 39.924443, 32.879286),
      const CampusData('Veteriner Fakültesi', 39.957773, 32.862353),
      const CampusData('İlahiyat Fakültesi', 39.933318, 32.824431),
    ],
    'Antalya Belek Üniversitesi': [
      const CampusData('Ana Kampüs', 36.883833, 31.000377),
    ],
    'Antalya Bilim Üniversitesi': [
      const CampusData('Ana Kampüs', 37.052632, 30.622691),
    ],
    'Ardahan Üniversitesi': [
      const CampusData('Yenisey Kampüsü', 41.131604, 42.780828),
    ],
    'Artvin Çoruh Üniversitesi': [
      const CampusData('Ana Kampüs', 41.197267, 41.848275),
      const CampusData('Borçka Yerleşlesi', 41.352315, 41.676055),
      const CampusData('Hopa Yerleşkesi', 41.389940, 41.416895),
      const CampusData('Şehir Yerleşkesi', 41.185038, 41.832824),
    ],
    'Atatürk Üniversitesi': [
      const CampusData('Atatürk Üniv. Veteriner Fakültesi', 39.941728, 41.124829),
      const CampusData('Oltu Yerleşkesi', 40.566909, 42.003108),
    ],
    'Atatürk üniversitesi': [
      const CampusData('Ana Kampüs', 39.896021, 41.233669),
    ],
    'Atılım Üniversitesi': [
      const CampusData('Ana Kampüs', 39.814285, 32.724276),
    ],
    'Avrasya Üniversitesi': [
      const CampusData('Pelitli Yerleşkesi', 40.987825, 39.804821),
      const CampusData('Yomra Yerleşkesi', 40.956546, 39.861696),
      const CampusData('Ömer Yıldız Yerleşkesi', 40.984927, 39.827265),
    ],
    'Aydın Adnan Menderes Üniversitesi': [
      const CampusData('Ana Kampüs', 37.855250, 27.856005),
      const CampusData('Kuşadası Devlet Konservatuvarı', 37.860224, 27.256665),
    ],
    'Ağrı İbrahim Çeçen Üniversitesi': [
      const CampusData('Ana Kampüs', 39.721576, 42.994875),
      const CampusData('Sağlık Hizmetleri Meslek Yüksekokulu', 39.717963, 43.023699),
    ],
    'Bahcesehir University': [
      const CampusData('BAU Beşiktaş', 41.041855, 29.009570),
      const CampusData('BAU Galata', 41.024513, 28.976943),
    ],
    'Bahçeşehir Üniversitesi': [
      const CampusData('Tıp Fakültesi', 40.989479, 29.079531),
    ],
    'Balıkesir Üniversitesi': [
      const CampusData('Ana Kampüs', 39.541804, 28.007415),
      const CampusData('Ayvalık Meslek Yüksekokulu', 39.332836, 26.714210),
      const CampusData('Balıkesir Ünirversitesi Edremit Meslek Yüksekokulu', 39.607712, 27.041517),
      const CampusData('Bigadiç Çağış Kampüsü', 39.539418, 28.005502),
      const CampusData('Havran Meslek Yüksekokulu', 39.558641, 27.084661),
      const CampusData('Sındırgı Meslek Yüksekokulu', 39.232420, 28.178810),
    ],
    'Bandırma 17 Eylül Üniversitesi': [
      const CampusData('İletişim Merkezi', 40.355817, 27.970305),
    ],
    'Bandırma Onyedi Eylül Üniversitesi': [
      const CampusData('Ana Kampüs', 40.335550, 27.940019),
      const CampusData('Bandırma Meslek Yüksekokulu', 40.349056, 27.955211),
      const CampusData('Yabancı Diller Yüksekokulu', 40.341077, 27.960790),
    ],
    'Bartın Üniversitesi': [
      const CampusData('Ana Kampüs', 41.551640, 32.280942),
      const CampusData('Deniz ve Liman İşletmeciliği Kampüsü', 41.845033, 32.720763),
    ],
    'Batman Üniversitesi': [
      const CampusData('Batı Raman Yerleşkesi', 37.786835, 41.063020),
      const CampusData('Hasankeyf Kampüsü', 37.730722, 41.422142),
      const CampusData('Kozluk Meslek Yüksekokulu', 38.175290, 41.503015),
      const CampusData('Merkez Yerleşkesi', 37.904238, 41.129765),
      const CampusData('Sason Meslek Yüksekokulu', 38.336015, 41.409261),
    ],
    'Başkent Üniversitesi': [
      const CampusData('Ana Kampüs', 39.887637, 32.655303),
      const CampusData('Kahramankazan MYO', 40.191202, 32.674457),
    ],
    'Beykent Üniversitesi': [
      const CampusData('Ana Kampüs', 41.018317, 28.626691),
      const CampusData('Ayazağa - Maslak Yerleşkesi', 41.117373, 29.003515),
      const CampusData('Beylikdüzü Yerleşkesi', 41.017266, 28.625792),
      const CampusData('Hadımköy Yerleşkesi', 41.085079, 28.629239),
      const CampusData('Taksim Yerleşkesi', 41.033830, 28.984600),
      const CampusData('Öğrenci Konukevi', 41.018011, 28.626961),
    ],
    'Bezmiâlem Vakıf Üniversitesi': [
      const CampusData('Ana Kampüs', 41.018214, 28.936494),
    ],
    'Bilecik Şeyh Edebali Üniversitesi': [
      const CampusData('Ana Kampüs', 40.190348, 29.967728),
      const CampusData('Söğüt Meslek Yüksekokulu', 40.016218, 30.181367),
    ],
    'Bilgi Üniversitesi': [
      const CampusData('Dolapdere Yerleşkesi', 41.040025, 28.974496),
    ],
    'Bilkent Üniversitesi': [
      const CampusData('Ana Kampüs', 39.872729, 32.753287),
    ],
    'Bingöl Üniversitesi': [
      const CampusData('Ana Kampüs', 38.900432, 40.484473),
      const CampusData('Genç Meslek Yüksekokulu', 38.749155, 40.535918),
    ],
    'Biruni Üniversitesi': [
      const CampusData('Merkez Kampüs', 41.017623, 28.916746),
    ],
    'Boğaziçi Üniversitesi': [
      const CampusData('Anadolu Hisarı Kampüsü', 41.081058, 29.071224),
      const CampusData('Güney Yerleşkesi', 41.083668, 29.050631),
      const CampusData('Hisar Kampüs', 41.089032, 29.050918),
      const CampusData('Kandilli Yerleşkesi', 41.062738, 29.061249),
      const CampusData('Kuzey Yerleşkesi', 41.086769, 29.044173),
      const CampusData('Sarıtepe Yerleşkesi', 41.240901, 29.006218),
      const CampusData('Uçaksavar Yerleşkesi', 41.085429, 29.039853),
    ],
    'Burdur Mehmet Akif Ersoy Üniversitesi': [
      const CampusData('Bucak Hikmet Tolunay Meslek Yüksekokulu', 37.461684, 30.606532),
      const CampusData('Tefenni Meslek Yüksekokulu', 37.316969, 29.779653),
      const CampusData('Çavdır Meslek Yüksekokulu', 37.146889, 29.690753),
    ],
    'Bursa Teknik Üniversitesi': [
      const CampusData('Ana Kampüs', 40.187224, 29.116843),
    ],
    'Bursa Uludağ Üniversitesi': [
      const CampusData('Ana Kampüs', 40.238869, 28.869871),
      const CampusData('Gemlik Yerleşkesi', 40.421684, 29.146038),
      const CampusData('Keles Meslek Yüksekokulu', 39.913312, 29.236263),
    ],
    'Bülent Ecevit Üniversitesi': [
      const CampusData('Rektörlüğü', 41.451429, 31.763158),
      const CampusData('İncirharmanı Kampüsü', 41.434111, 31.757213),
    ],
    'Celal Bayar Üniversitesi': [
      const CampusData('Şehzadeler Yerleşkesi', 38.621728, 27.441517),
    ],
    'Cukurova University': [
      const CampusData('Tarım Makinaları Bölümü', 37.058939, 35.358456),
    ],
    'Dicle Üniversitesi': [
      const CampusData('Ana Kampüs', 37.916279, 40.272361),
      const CampusData('Silvan meslek Yüksekokulu', 38.138225, 41.019059),
      const CampusData('Teknokent', 37.936296, 40.283739),
    ],
    'Dokuz Eylül Üniversitesi': [
      const CampusData('15 Temmuz Sağlık ve Sanat Yerleşkesi', 38.394290, 27.029970),
      const CampusData('Bergama Meslek Yüksekokulu', 39.107685, 27.190150),
      const CampusData('Efes MYO', 37.947343, 27.381346),
      const CampusData('Fevziye Hepkon Sosyal Bilimler Meslek Yüksek Okulu', 38.196625, 26.845961),
      const CampusData('Turizm ve Uygulamalı Bilimler Yerleşkesi', 38.381787, 27.222715),
      const CampusData('Tınaztepe Yerleşkesi', 38.370659, 27.203367),
      const CampusData('Veteriner Fakültesi', 38.307616, 27.692380),
      const CampusData('İktisadi ve İdari Bilimler Fakültesi (Dokuzçeşmeler Yerleşkesi)', 38.385077, 27.181243),
      const CampusData('İlahiyat Fakültesi', 38.395037, 27.097357),
      const CampusData('İİBF YBS Bölümü', 38.385082, 27.180001),
    ],
    'Doğuş Üniversitesi': [
      const CampusData('Ana Kampüs', 41.000140, 29.047408),
      const CampusData('Dudullu Yerleşkesi', 41.001504, 29.176330),
      const CampusData('Çengelköy Yerleşkesi', 41.047574, 29.076915),
    ],
    'Dumlupınar Üniversitesi': [
      const CampusData('Altıntaş Meslek Yüksekokulu', 39.075077, 30.132260),
      const CampusData('Emet Meslek Yüksekokulu', 39.337024, 29.268377),
      const CampusData('Evliya Çelebi Yerleşkesi', 39.480342, 29.897014),
      const CampusData('Gediz Meslek Yüksekokulu', 39.007643, 29.404047),
      const CampusData('Gediz Sağlık Hizmetleri Meslek Yüksekokulu', 39.008325, 29.404101),
      const CampusData('Germiyan Yerleşkesi', 39.392971, 30.039992),
      const CampusData('Simav Kampüsü', 39.112558, 29.016786),
    ],
    'Düzce Üniversitesi': [
      const CampusData('Akçakoca Turizm ve Otelcilik Yüksek Okulu', 41.072802, 31.156441),
      const CampusData('Akçakoca Yerleşkesi', 41.073918, 31.156811),
      const CampusData('Cumayeri Meslek Yüksek Okulu', 40.879262, 30.949920),
      const CampusData('Düzce Meslek Yüksek Okulu', 40.844630, 31.148278),
      const CampusData('Gölyaka Kampüsü', 40.795293, 30.985449),
      const CampusData('Gölyaka Meslek Yüksek Okulu', 40.794981, 30.985321),
      const CampusData('Gümüşova Meslek Yüksek Okulu', 40.845177, 30.938183),
      const CampusData('Kaynaşlı Meslek Yüksek Okulu', 40.773274, 31.315946),
      const CampusData('Konuralp Yerleşkesi', 40.904081, 31.179892),
      const CampusData('Meslek Yüksekokulu', 40.960797, 31.444639),
      const CampusData('Çilimli Meslek Yüksekokulu', 40.895189, 31.048377),
    ],
    'Ege Üniversitesi': [
      const CampusData('Ana Kampüs', 38.519842, 27.147271),
      const CampusData('Eğitim Fakültesi', 38.459221, 27.222941),
      const CampusData('Karşıyaka Suat-Cemile Balcıoğlu Yerleşkesi', 38.473661, 27.106784),
      const CampusData('Merkez Yerleşke', 38.456466, 27.220885),
      const CampusData('Spor Bilimleri Fakültesi', 38.459256, 27.223753),
      const CampusData('Ödemiş Sağlık Yüksekokulu', 38.228622, 27.975801),
      const CampusData('İnkılap Tarihi ve Atatürkçülük Bölümü Başkanlığı', 38.462684, 27.224272),
    ],
    'Erciyes Üniversitesi': [
      const CampusData('Ana Kampüs', 38.709403, 35.539828),
      const CampusData('Bilgi İşlem Daire Başkanlığı', 38.708301, 35.520323),
      const CampusData('Develi Seyrani Kampüsü', 38.381521, 35.453705),
      const CampusData('Kız Öğrenci Yurtları', 38.719488, 35.549195),
      const CampusData('Sosyal Tesisleri', 38.684671, 35.567509),
    ],
    'Eren Üniversitesi': [
      const CampusData('Rahva Yerleşkesi', 38.480334, 42.159917),
    ],
    'Erzincan Binali Yıldırım Üniversitesi': [
      const CampusData('Yalnızbağ Yerleşkesi', 39.805607, 39.375896),
    ],
    'Erzincan Üniversitesi': [
      const CampusData('Hukuk Fakültesi Dekanlığı', 39.728437, 39.472252),
      const CampusData('Meslek Yüksek Okulu', 39.745966, 39.506503),
    ],
    'Erzurum Atatürk Üniversitesi': [
      const CampusData('Ana Kampüs', 39.897333, 41.237804),
    ],
    'Erzurum Teknik Üniversitesi': [
      const CampusData('Ana Kampüs', 39.919752, 41.238242),
    ],
    'Eskişehir Osmangazi Üniversitesi': [
      const CampusData('Meşelik Yerleşkesi', 39.750829, 30.483387),
      const CampusData('OGÜ Sağlık MYO Çifteler Kampüsü', 39.368320, 31.033426),
      const CampusData('Ziraat Fakültesi Ali Numan Kıraç Yerleşkesi', 39.757489, 30.472574),
    ],
    'Eskişehir Teknik Üniversitesi': [
      const CampusData('2 Eylül Kampüsü', 39.815265, 30.534018),
    ],
    'FMV Işık Üniversitesi': [
      const CampusData('Ana Kampüs', 41.169808, 29.562820),
    ],
    'Fatih Belediyesi - Yıldız Teknik Üniversitesi': [
      const CampusData('İstanbul Tarihi Yarımada Uygulama ve Araştırma Merkezi', 40.998917, 28.924394),
    ],
    'Fatih Sultan Mehmet Vakıf Üniversitesi': [
      const CampusData('Topkapı Yerleşkesi', 41.014356, 28.917042),
      const CampusData('Üsküdar Yerleşkesi', 41.018351, 29.022809),
    ],
    'Fenerbahçe Üniversitesi': [
      const CampusData('Ana Kampüs', 40.994666, 29.120566),
    ],
    'Fırat Üniversitesi': [
      const CampusData('Ana Kampüs', 38.682450, 39.189662),
      const CampusData('Keban Meslek Yüksekokulu', 38.795564, 38.728842),
    ],
    'Galatasaray Üniversitesi': [
      const CampusData('Ana Kampüs', 41.046124, 29.020005),
    ],
    'Gazi ve Ankara Hacı Bayram Veli Üniversitesi': [
      const CampusData('Gölbaşı Yerleşkesi', 39.781248, 32.809200),
    ],
    'Gazi Üniversitesi': [
      const CampusData('Ana Kampüs', 39.939645, 32.820527),
      const CampusData('Karayolu Ulaştırması Uygulama Ve Araştırma Merkez', 39.878747, 32.858939),
      const CampusData('Maltepe Yerleşkesi', 39.931397, 32.845584),
      const CampusData('Mimarlık Fakültesi', 39.931666, 32.846179),
      const CampusData('Ostim Yerleşkesi', 39.983052, 32.745440),
      const CampusData('Tusaş Kazan Meslek Yüksekokulu', 40.152056, 32.653317),
      const CampusData('Tıp Fakültesi', 39.933913, 32.823040),
    ],
    'Gaziantep Üniversitesi': [
      const CampusData('Merkez Yerleşkesi', 37.034507, 37.310618),
      const CampusData('İlahiyat Fakültesi', 37.032744, 37.313889),
      const CampusData('İslahiye Kampüsü', 37.046865, 36.612978),
    ],
    'Gaziosmanpaşa Üniversitesi': [
      const CampusData('Ana Kampüs', 40.327313, 36.478381),
      const CampusData('Turhal Meslek Yüksekokulu', 40.374363, 36.100379),
    ],
    'Gebze Teknik Üniversitesi': [
      const CampusData('Ana Kampüs', 40.812052, 29.358341),
    ],
    'Gedik Üniversitesi': [
      const CampusData('Aydınlı Yerleşkesi', 40.873743, 29.332931),
      const CampusData('Pendik Eğitim Kampüsü', 40.902417, 29.276439),
    ],
    'Gelişim Üniversitesi': [
      const CampusData('Ana Kampüs', 40.992335, 28.709844),
    ],
    'Giresun Üniversitesi': [
      const CampusData('Bulancak Kadir Karabaş Uygulamalı Bilimler Yüksekokulu', 40.939312, 38.183961),
      const CampusData('Dereli Meslek Yükeskokulu', 40.739768, 38.449531),
      const CampusData('Güre Yerlekesi', 40.915042, 38.322574),
      const CampusData('Nizamiye Yerleşkesi', 40.913690, 38.389010),
      const CampusData('Sağlık Hizmetleri Meslek Yüksekokulu', 40.914489, 38.327892),
    ],
    'Gümüşhane Üniversitesi': [
      const CampusData('Ana Kampüs', 40.438659, 39.516646),
      const CampusData('Kelkit Aydın Doğan Meslek Yüksekokulu', 40.110528, 39.451244),
      const CampusData('Köse İrfan Can Meslek Yüksekokulu', 40.192874, 39.660922),
    ],
    'Hacettepe University': [
      const CampusData('Vaccine Institute', 39.932852, 32.861880),
    ],
    'Hacettepe Üniversitesi': [
      const CampusData('Beytepe Kampüsü', 39.866350, 32.736288),
      const CampusData('Sıhhiye Kampüsü', 39.931326, 32.862563),
    ],
    'Hacı Bayram Veli Üniversitesi': [
      const CampusData('Ana Kampüs', 39.942261, 32.818687),
    ],
    'Hakkari Üniversitesi': [
      const CampusData('Rektörlüğü', 37.574592, 43.731236),
      const CampusData('Zeynel Bey Yerleşkesi', 37.571889, 43.753231),
    ],
    'Haliç Üniversitesi': [
      const CampusData('Ana Kampüs', 41.088570, 28.951662),
    ],
    'Harran Üniversitesi': [
      const CampusData('Eyyübiye Kampüsü', 37.120000, 38.820760),
      const CampusData('Hilvan Meslek Yüksekokulu', 37.600966, 38.980925),
      const CampusData('Osmanbey Yerleşkesi', 37.171873, 39.000035),
      const CampusData('Siverek Meslek Yüksekokulu', 37.683330, 39.253333),
      const CampusData('Siverek Uygulamalı Bilimler Fakültesi', 37.753460, 39.322168),
      const CampusData('Viranşehir Sağlık Meslek Yüksek Okulu', 37.212168, 39.773152),
    ],
    'Hasan Kalyoncu Üniversitesi': [
      const CampusData('Ana Kampüs', 37.007514, 37.437003),
    ],
    'Hatay Mustafa Kemal Üniversitesi': [
      const CampusData('Dörtyol Meslek Yüksekokulu', 36.909311, 36.227611),
    ],
    'Hiti Üniversitesi': [
      const CampusData('Tıp Fakültesi', 40.566455, 34.933317),
    ],
    'Hitit Üniversitesi': [
      const CampusData('Alaca Avni Çelik Meslek Yüksekokulu', 40.177772, 34.853754),
    ],
    'Isparta Uygulamalı Bilimler Üniversitesi': [
      const CampusData('Ana Kampüs', 37.779234, 30.546710),
    ],
    'Istanbul Kültür Üniversitesi': [
      const CampusData('Ana Kampüs', 40.991337, 28.832200),
    ],
    'Istanbul University': [
      const CampusData('Institute of Marine Sciences and Management', 41.015543, 28.959575),
      const CampusData('iktisad faculty ek Bina 1', 41.015778, 28.960411),
    ],
    'Istanbul Üniversitesi': [
      const CampusData('Su Bilimleri Fakültesi', 41.009889, 28.959768),
    ],
    'Iğdır Üniversitesi': [
      const CampusData('Bülent Yurtseven Yerleşkesi', 39.805179, 44.082233),
      const CampusData('Karaağaç Yerleşkesi', 39.921173, 44.036943),
    ],
    'Işık Üniversitesi': [
      const CampusData('Ana Kampüs', 41.169683, 29.563899),
      const CampusData('Maslak Kampüsü', 41.111016, 29.026055),
    ],
    'KOCAELİ ÜNİVERSİTESİ': [
      const CampusData('KÖRFEZ KAMPÜSÜ', 40.776826, 29.733982),
    ],
    'KTO Karatay Üniversitesi': [
      const CampusData('Ana Kampüs', 37.864259, 32.536767),
    ],
    'Kadir Has Üniversitesi': [
      const CampusData('Ana Kampüs', 41.025400, 28.958522),
    ],
    'Kafkas Üniversitesi': [
      const CampusData('Ana Kampüs', 40.582697, 43.063554),
      const CampusData('Dereiçi Kampüsü', 40.615355, 43.092485),
      const CampusData('Merkez Kampüsü', 40.604492, 43.084994),
    ],
    'Kahramanmaraş Sütçü İmam Üniversitesi': [
      const CampusData('Avşar Kampüsü', 37.587792, 36.824000),
      const CampusData('Bahçelievler Yerleşkesi', 37.576317, 36.928124),
      const CampusData('Karacasu Kampüsü', 37.519401, 36.990166),
    ],
    'Kapadokya Üniversitesi': [
      const CampusData('Fabrika Yerleşkesi', 38.628728, 34.914556),
      const CampusData('Ürgüp Sağlık Yerleşkesi', 38.647151, 34.908132),
    ],
    'Karabük Üniversitesi': [
      const CampusData('Ana Kampüs', 41.209446, 32.655744),
    ],
    'Karadeniz Teknik Üniversitesi': [
      const CampusData('Ana Kampüs', 40.992854, 39.768791),
      const CampusData('KTÜ Sahil Tesisleri', 41.002030, 39.775413),
      const CampusData('Tıp Fakültesi Dekanlığı', 40.993151, 39.770274),
    ],
    'Karamanoğlu Mehmetbey Üniversitesi': [
      const CampusData('Yunus Emre Yerleşkesi', 37.175680, 33.252406),
    ],
    'Karatekin Üniversitesi': [
      const CampusData('Meslek Yüksekokulu', 40.602301, 33.603519),
    ],
    'Kastamonu Üniversitesi': [
      const CampusData('Abana Sabahat Mesut Yılmaz Meslek Yüksekokulu', 41.979052, 33.993791),
      const CampusData('Bozkurt Meslek Yüksekokulu', 41.948508, 34.012778),
      const CampusData('Eğitim Fakültesi', 41.386055, 33.780700),
      const CampusData('Rafet Vergili MYO Yerleşkesi', 41.246711, 33.333392),
    ],
    'Kayseri Üniversitesi': [
      const CampusData('Ana Kampüs', 38.713106, 35.553316),
    ],
    'Kilis 7 Aralık Üniversitesi': [
      const CampusData('Karataş Kampüsü', 36.717972, 37.123673),
    ],
    'Kocaeli Sağlık ve Teknoloji Üniversitesi': [
      const CampusData('Ana Kampüs', 40.699499, 29.883925),
    ],
    'Kocaeli Üniversitesi': [
      const CampusData('Anıtpark Kampüsü', 40.765954, 29.939754),
      const CampusData('Arslanbey Yerleşkesi', 40.710311, 30.028393),
      const CampusData('Atçılık Meslek Yüksekokulu', 40.743996, 30.023453),
      const CampusData('Diş Hekimliği Fakültesi', 40.707544, 29.974848),
      const CampusData('Hereke Asım Kocabıyık Meslek Yüksekokulu', 40.784452, 29.620269),
      const CampusData('Kandıra Meslekyüksek Okulu', 41.064657, 30.166870),
      const CampusData('Kartepe Yerleşkesi', 40.707641, 30.101121),
      const CampusData('Nuh Çimento Prof. Dr. Baki Komşuoğlu Meslek Yüksekokulu', 40.751184, 30.054263),
      const CampusData('Umuttepe Yerleşkesi', 40.817770, 29.917957),
    ],
    'Konya Gıda ve Tarım Üniversitesi': [
      const CampusData('Ana Kampüs', 37.874617, 32.474667),
    ],
    'Konya Teknik Üniversitesi': [
      const CampusData('Ana Kampüs', 38.006594, 32.515417),
      const CampusData('Sürekli Eğitim Uygulama ve Araştırma Merkezi', 37.873227, 32.494559),
    ],
    'Korkut Ata Üniversitesi': [
      const CampusData('Kadirli Yerleşkesi', 37.387313, 36.071784),
    ],
    'Koç Üniversitesi': [
      const CampusData('Ana Kampüs', 41.202329, 29.072619),
      const CampusData('Batı Kampüsü', 41.193654, 29.048909),
    ],
    'Kırklareli Üniversitesi': [
      const CampusData('Ana Kampüs', 41.792425, 27.164469),
      const CampusData('Kayalı Yerleşkesi', 41.793189, 27.168358),
    ],
    'Kırklareli üniversitesi': [
      const CampusData('MYO', 41.720502, 27.192990),
    ],
    'Kırşehir Ahi Evran Üniversitesi': [
      const CampusData('Bağbaşı Yerleşkesi', 39.143937, 34.116020),
      const CampusData('Merkez Yerleşkesi', 39.136605, 34.155066),
    ],
    'MEF Üniversitesi': [
      const CampusData('Ana Kampüs', 41.108276, 29.008603),
    ],
    'Malatya Turgut Özal Üniversitesi': [
      const CampusData('Ana Kampüs', 38.396720, 38.281658),
    ],
    'Manisa Celal Bayar Üniversitesi': [
      const CampusData('Akhisar Meslek Yüksekokulu', 38.904170, 27.806876),
      const CampusData('Muradiye Kampüsü', 38.679344, 27.309116),
      const CampusData('Soma Meslek Yüksekokulu', 39.188193, 27.608275),
      const CampusData('Sürekli Eğitim Merkezi', 38.619025, 27.438910),
      const CampusData('Uncubozköy Kampüsü', 38.610913, 27.378734),
      const CampusData('Yabancı Diller Yüksekokulu', 38.620334, 27.439280),
    ],
    'Manisa Celâl Bayar Üniversitesi': [
      const CampusData('Hasan Ferdi Turgutlu Teknoloji Fakültesi', 38.491616, 27.706534),
    ],
    'Mardin Artuklu Üniversitesi': [
      const CampusData('Midyat Meslek Yüksekokulu', 37.420604, 41.380751),
      const CampusData('Yeni Kampüsü', 37.346293, 40.642386),
    ],
    'Marmara Üniversitesi': [
      const CampusData('Atatürk Eğitim Fakültesi', 40.962245, 29.132577),
      const CampusData('Bahçelievler Kampüsü', 40.997526, 28.867989),
      const CampusData('Bağlarbaşı Yerleşkesi', 41.020432, 29.036442),
      const CampusData('Mehmet Genç Yerleşkesi', 40.905153, 29.155480),
      const CampusData('Mühendislik Fakültesi', 40.956221, 29.132376),
      const CampusData('Recep Tayyip Erdoğan Külliyesi Sağlık Yerleşkesi', 40.951227, 29.138676),
      const CampusData('Recep Tayyip Erdoğan Yerleşkesi', 40.959976, 29.132280),
      const CampusData('Rektörlüğü', 41.004570, 28.974252),
      const CampusData('Siyasal Bilgiler Fakültesi', 40.963670, 29.133969),
      const CampusData('Teknoloji Fakültesi', 40.959025, 29.135431),
      const CampusData('İktisat Fakültesi', 40.962936, 29.135113),
      const CampusData('İşletme Fakültesi', 40.963698, 29.135322),
    ],
    'Medeniyet Üniversitesi': [
      const CampusData('Orhanlı Kampüsü', 40.925786, 29.345645),
    ],
    'Medipol University': [
      const CampusData('Ana Kampüs', 41.022789, 28.953811),
    ],
    'Medipol Üniversitesi': [
      const CampusData('Kavacık Güney Yerleşkesi', 41.087003, 29.088237),
      const CampusData('Kavacık Yerleşkesi', 41.091034, 29.092148),
    ],
    'Mehmet Akif Ersoy Üniversitesi': [
      const CampusData('Bahçelievler Yerleşkesi', 37.715172, 30.272882),
      const CampusData('İstiklal Yerleşkesi', 37.687551, 30.341957),
    ],
    'Mersin Üniversitesi': [
      const CampusData('Erdemli Meslek Yüksekokulu', 36.608773, 34.312443),
      const CampusData('Mut Meslek Yüksekokulu', 36.631741, 33.420316),
      const CampusData('Tece Yerleşkesi', 36.685466, 34.443393),
      const CampusData('Yenişehir Yerleşkesi', 36.765377, 34.556058),
      const CampusData('Çiftlikköy Merkez Kampüsü', 36.784777, 34.530172),
    ],
    'Milas Meslek Yüksekokulu | Muğla Sıtkı Koçman Üniversitesi': [
      const CampusData('Ana Kampüs', 37.283561, 27.779395),
    ],
    'Milli Savunma Üniversitesi': [
      const CampusData('Ana Kampüs', 41.102662, 29.013200),
    ],
    'Mimar Sinan Güzel Sanatlar Üniversitesi': [
      const CampusData('Ana Kampüs', 41.030123, 28.988876),
      const CampusData('Bomonti Kampüsü', 41.057484, 28.980079),
      const CampusData('Dolmabahçe Yerleşkesi', 41.041156, 29.000636),
      const CampusData('MSGSÜ Bomonti Kampüsü', 41.057676, 28.979952),
      const CampusData('SEM (Sürekli Eğitim Merkezi)', 41.041875, 29.008460),
      const CampusData('İstanbul Devlet Konservatuarı', 41.040757, 29.003234),
    ],
    'Mudanya Üniversitesi': [
      const CampusData('Ana Kampüs', 40.300663, 28.947404),
    ],
    'Mustafa Kemal Üniversitesi': [
      const CampusData('Tayfun Sökmen Kampüsü', 36.332763, 36.192979),
    ],
    'Muğla Sıtkı Koçman Üniversitesi': [
      const CampusData('Ana Kampüs', 37.167195, 28.374554),
      const CampusData('Dalaman Meslek Yüksekokulu', 36.798649, 28.809012),
      const CampusData('Güzel Sanatlar Fakültesi', 37.031852, 27.355261),
      const CampusData('Muğla Meslek Yüksekokulu', 37.208583, 28.370563),
    ],
    'Muğla Üniversitesi': [
      const CampusData('Sağlık Hizmetleri MYO', 36.856381, 28.270130),
    ],
    'Muş Alparslan Üniversitesi': [
      const CampusData('Ana Kampüs', 38.772506, 41.422956),
      const CampusData('MAUN İslami İlimler Fakültesi', 38.738366, 41.495168),
    ],
    'Namık Kemal Üniversites': [
      const CampusData('Saray Meslek Yüksek Okulı', 41.424150, 27.919163),
    ],
    'Namık Kemal Üniversitesi': [
      const CampusData('Malkara Yüksekokulu', 40.883631, 26.893765),
      const CampusData('Muratlı Meslek Yüksekokulu', 41.153829, 27.494383),
      const CampusData('Çorlu Meslek Yüksekokulu', 41.143540, 27.856764),
      const CampusData('Çorlu Mühendislik Fakültesi', 41.181013, 27.816808),
    ],
    'Necmettin Erbakan Üniversitesi': [
      const CampusData('Ereğli Yerleşkesi', 37.465788, 34.056668),
      const CampusData('Köyceğiz Yerleşkesi', 37.864890, 32.416597),
      const CampusData('Meram Sağlık Yerleşkesi', 37.876418, 32.431652),
      const CampusData('Seydişehir Yerleşkesi', 37.432843, 31.829092),
    ],
    'Nevşehir Hacıbektaş Veli Üniversitesi': [
      const CampusData('Ana Kampüs', 38.678323, 34.742127),
    ],
    'Nevşehir Üniversitesi': [
      const CampusData('Avanos Yüksek Okulu', 38.706903, 34.843085),
    ],
    'Nişantaşı Üniversitesi': [
      const CampusData('Kampüsü', 41.052109, 28.985065),
    ],
    'Nuh Naci Yazgan Üniversitesi': [
      const CampusData('Ana Kampüs', 38.786062, 35.408941),
    ],
    'ODTÜ Deniz Bilimleri Enstitüsü': [
      const CampusData('Ana Kampüs', 36.566487, 34.255386),
    ],
    'Okan Üniversitesi': [
      const CampusData('Ana Kampüs', 41.010536, 29.196643),
    ],
    'Ondokuz Mayıs Üniversitesi': [
      const CampusData('Ana Kampüs', 41.367736, 36.199356),
    ],
    'Onyedi Eylül Üniversitesi': [
      const CampusData('Sağlık Bilimleri Fakültesi', 40.353102, 27.977819),
    ],
    'Ordu Üniversitesi': [
      const CampusData('Cumhuriyet Yerleşkesi', 40.974552, 37.970154),
      const CampusData('Teknik Bilimler Meslek Yüksek Okulu', 40.983708, 37.916121),
    ],
    'Orta Doğu Teknik Üniversitesi': [
      const CampusData('Ana Kampüs', 39.875322, 32.789998),
    ],
    'Osmangazi Üniversitesi': [
      const CampusData('Bademlik Yerleşkesi', 39.759222, 30.522217),
    ],
    'Osmaniye Korkut Ata Üniversitesi': [
      const CampusData('Karacaoğlan Yerleşkesi', 37.040111, 36.221302),
    ],
    'Ostim Teknik Üniversitesi': [
      const CampusData('Yerleşkesi', 39.968652, 32.742752),
    ],
    'Pamukkale Üniversitesi': [
      const CampusData('Denizli Meslek Yüksekokulu', 37.749003, 29.091693),
      const CampusData('Denizli Teknik Bilimler Meslek Yüksekokulu', 37.749094, 29.090803),
      const CampusData('Kınıklı Yerleşkesi', 37.739669, 29.100650),
      const CampusData('Tavas Yüksekokulu', 37.568702, 29.055337),
      const CampusData('Çal Meslek Yüksekokulu', 38.078452, 29.399891),
    ],
    'Piri Reis Üniversitesi': [
      const CampusData('Deniz Kampüsü', 40.814506, 29.289986),
      const CampusData('Hazırlık Kampüsü', 40.826456, 29.322555),
    ],
    'Recep Tayyip Erdoğan Üniversitesi': [
      const CampusData('Denizcilik Fakültesi Turgut Kıran Yerleşkesi', 41.024115, 40.415472),
      const CampusData('Tıp Fakültesi', 41.037904, 40.566929),
      const CampusData('Zihni Derin Yerleşkesi', 41.037252, 40.493206),
    ],
    'Sabahattin Zaim Üniversitesi': [
      const CampusData('Ana Kampüs', 41.031121, 28.784387),
    ],
    'Sabancı Üniversitesi': [
      const CampusData('Ana Kampüs', 40.893287, 29.378446),
      const CampusData('Yaratıcı Teknolojiler Atölyesi', 39.290386, 26.689941),
    ],
    'Sakarya Uygulamalı Bilimler Üniversitesi': [
      const CampusData('Ana Kampüs', 41.026320, 30.302250),
      const CampusData('Geyve Meslek Yüksekokulu', 40.534389, 30.294235),
      const CampusData('Sakarya Meslek Yüksekokulu', 40.855089, 30.321394),
      const CampusData('Turizm Fakültesi', 40.690843, 30.267767),
    ],
    'Sakarya Üniversitesi': [
      const CampusData('Ana Kampüs', 40.741442, 30.329351),
      const CampusData('Diş Hekimliği Fakültesi', 40.764644, 30.394258),
    ],
    'Samsun Üniversitesi': [
      const CampusData('Ana Kampüs', 41.373158, 36.240323),
      const CampusData('Tıp Fakültesi', 41.270391, 36.299146),
    ],
    'Sanko Üniversitesi': [
      const CampusData('Ana Kampüs', 37.072429, 37.367834),
    ],
    'Sağlık Bilimleri Üniversitesi': [
      const CampusData('Hamidiye Yerleşkesi', 41.003746, 29.019279),
    ],
    'Selçuk Üniversitesi': [
      const CampusData('( SÜ ) Akören Alirıza Ercan Meslek Yüksek Okulu', 37.458607, 32.360877),
      const CampusData('Ana Kampüs', 38.019432, 32.509842),
      const CampusData('Beyşehir Ali Akkanat Kampüsü', 37.653959, 31.702685),
      const CampusData('Cihanbeyli Meslek Yüksekokulu', 38.645209, 32.923667),
      const CampusData('Karapınar Aydoğanlar Meslek Yüksekokulu', 37.710481, 33.540895),
    ],
    'Siirt Üniversitesi': [
      const CampusData('Ana Kampüs', 37.935933, 41.940466),
      const CampusData('Kezer Yerleşkesi', 37.965953, 41.849202),
    ],
    'Sinop Üniversitesi': [
      const CampusData('Ayancık Meslek Yüksekokulu', 41.941985, 34.590326),
      const CampusData('Boyabat Meslek Yüksekokulu', 41.461345, 34.797296),
      const CampusData('Su Ürünleri Fakültesi', 42.041516, 35.042268),
    ],
    'Sivas Bilim ve Teknoloji Üniversitesi': [
      const CampusData('Ana Kampüs', 39.725601, 36.988630),
    ],
    'Sivas Cumhuriyet University': [
      const CampusData('Uluslararası İlişkiler Ofisi, Araştırma Merkezleri, Güvenlik Merkezi', 39.705592, 37.028361),
    ],
    'Sivas Cumhuriyet Üniversitesi': [
      const CampusData('Ana Kampüs', 39.707245, 37.032163),
      const CampusData('Zara Kampüsü', 39.885121, 37.735429),
    ],
    'Su Altı Arkeoleji Enstitüsü': [
      const CampusData('Ana Kampüs', 37.043018, 27.425719),
    ],
    'Süleyman Demirel Üniversitesi': [
      const CampusData('Batı Yerleşkesi', 37.827921, 30.521902),
      const CampusData('Doğu Yerleşkesi', 37.840403, 30.540379),
    ],
    'T. C. İstanbul Arel Üniversitesi': [
      const CampusData('Cevizlibağ Sağlık Yerleşkesi', 41.017195, 28.913736),
    ],
    'T.C. Balıkesir Üniversitesi': [
      const CampusData('Burhaniye Meslek Yüksekokulu', 39.538664, 26.953842),
    ],
    'T.C. Bayburt Üniversitesi': [
      const CampusData('Bâbertî Külliyesi', 40.250430, 40.187597),
      const CampusData('Dede Korkut Kampüsü', 40.250413, 40.231094),
    ],
    'T.C. Kırklareli Üniversitesi': [
      const CampusData('Vize Meslek Yüksek Okulu', 41.564899, 27.770971),
    ],
    'T.C. Maltepe Üniversitesi': [
      const CampusData('Ana Kampüs', 40.959115, 29.185397),
    ],
    'T.C. Mehmet Akif Ersoy Üniversitesi': [
      const CampusData(': Ağlasun Meslek Yüksekok', 37.650003, 30.532601),
    ],
    'T.C. Sakarya Üniversitesi': [
      const CampusData('Hendek Eğitim Fakültesi', 40.796142, 30.741155),
    ],
    'TED Üniversitesi': [
      const CampusData('Kolej Kampüsü', 39.923731, 32.861503),
    ],
    'TOBB Ekonomi ve Teknoloji Üniversitesi': [
      const CampusData('Ana Kampüs', 39.920151, 32.800328),
    ],
    'Tarsus Üniversitesi': [
      const CampusData('Ana Kampüs', 36.953545, 34.848825),
    ],
    'Tekirdağ Namık Kemal Üniversitesi': [
      const CampusData('Ana Kampüs', 40.995382, 27.588801),
      const CampusData('Tıp Fakültesi', 40.995571, 27.587250),
      const CampusData('Çerkezköy Meslek Yüksek Okulu', 41.256623, 27.936363),
    ],
    'Toros Üniversitesi': [
      const CampusData('45 Evler Kampüsü', 36.791857, 34.595055),
      const CampusData('Bahçelievler Kampüsü', 36.795151, 34.591425),
      const CampusData('Uray Kampüsü', 36.801376, 34.633972),
    ],
    'Trabzon Üniversitesi': [
      const CampusData('Fatih Eğitim Kampüsü', 41.009901, 39.608283),
      const CampusData('İlahiyat Fakültesi', 40.985134, 39.812690),
    ],
    'Trakya Üniversitesi': [
      const CampusData('Ana Kampüs', 41.679275, 26.560192),
      const CampusData('Ayşekadın Yerleşkesi', 41.669444, 26.575614),
      const CampusData('Balkan Yerleşkesi', 41.643406, 26.616084),
      const CampusData('Keşan Hakkı Yörük Sağlık Yüksekokulu', 40.835270, 26.660081),
      const CampusData('Keşan MYO', 40.861704, 26.632291),
      const CampusData('Kosova Yerleşkesi (İsmail Hakkı Tonguç Yerleşkesi)', 41.672018, 26.574294),
      const CampusData('Makedonya Yerleşkesi', 41.680723, 26.560172),
      const CampusData('Prof. Dr. Ahmet Karadeniz Yerleşkesi', 41.634152, 26.623710),
      const CampusData('Sarayiçi Yerleşkesi', 41.695706, 26.552815),
      const CampusData('Uzunköprü Uygulamalı Bilimler Yüksekokulu', 41.250878, 26.684833),
    ],
    'Tunceli - Munzur Üniversitesi': [
      const CampusData('Ana Kampüs', 39.046019, 39.515388),
    ],
    'Türk Hava Kurumu Üniversitesi': [
      const CampusData('Ana Kampüs', 39.945681, 32.690068),
      const CampusData('İzmir MYO', 37.948851, 27.369880),
    ],
    'Türk-Alman Üniversitesi': [
      const CampusData('Ana Kampüs', 41.143593, 29.101093),
    ],
    'Türk-Japon Üniversitesi': [
      const CampusData('Ana Kampüs', 40.921019, 29.319202),
    ],
    'Tınaztepe Üniversitesi': [
      const CampusData('Ana Kampüs', 38.405900, 27.195099),
    ],
    'Ufuk Üniversitesi': [
      const CampusData('İncek Kampüsü', 39.826207, 32.729928),
    ],
    'Uludağ Üniversitesi': [
      const CampusData('Ali Osman Sönmez Kampüsü', 40.258604, 29.060119),
      const CampusData('Karacabey Yerleşkesi', 40.219199, 28.375122),
      const CampusData('Yenişehir İbrahim Orhan Meslek Yüksekokulu', 40.283781, 29.656536),
      const CampusData('Ziraat Fakültesi', 40.225881, 28.862357),
      const CampusData('İlahiyat Fakültesi', 40.229883, 28.975994),
      const CampusData('İnegöl Yerleşkesi', 40.076910, 29.491476),
    ],
    'Uygulamalı Matematik Enstitüsü': [
      const CampusData('Ana Kampüs', 39.894271, 32.782660),
    ],
    'Uşak Üniversitesi': [
      const CampusData('1 Eylül Yerleşkesi', 38.674095, 29.330370),
      const CampusData('Diş Hekimliği Fakültesi', 38.669649, 29.404874),
      const CampusData('Karahallı Meslek Yüksel Okulu', 38.332744, 29.556026),
    ],
    'Yalova Üniversitesi': [
      const CampusData('Armutlu Meslek Yüksekokulu', 40.519815, 28.806452),
      const CampusData('Merkez Yerleşkesi', 40.652204, 29.219251),
      const CampusData('Safran Yerleşkesi', 40.644447, 29.264488),
    ],
    'Yaşar Üniversitesi': [
      const CampusData('Ana Kampüs', 38.454079, 27.202598),
    ],
    'Yeditepe Üniversitesi': [
      const CampusData('Ana Kampüs', 40.971700, 29.151187),
    ],
    'Yozgat Bozok Üniversitesi': [
      const CampusData('Erdoğan Akdağ Yerleşkesi', 39.775103, 34.794536),
    ],
    'Yüzüncü Yıl Üniversitesi': [
      const CampusData('Zeve Yerleşkesi', 38.566467, 43.283804),
    ],
    'Yıldırım Beyazıt Üniversitesi': [
      const CampusData('Cinnah Yerleşkesi', 39.899263, 32.858194),
    ],
    'Yıldız Teknik Üniversitesi': [
      const CampusData('Ana Kampüs', 41.051751, 29.010864),
      const CampusData('Davutpaşa Yerleşkesi', 41.024676, 28.892314),
    ],
    'Zonguldak Bülent Ecevit Üniversitesi': [
      const CampusData('Merkez Kampüsü', 41.451221, 31.762137),
      const CampusData('İbni Sina Kampüsü Girişi', 41.416304, 31.701484),
    ],
    'Çanakkale 18 Mart Üniversitesi': [
      const CampusData('Anafartalar Yerleşkesi', 40.154767, 26.413548),
      const CampusData('Bayramiç Meslek Yüksekokulu', 39.809109, 26.600316),
    ],
    'Çanakkale Onsekiz Mart Üniversitesi': [
      const CampusData('Ana Kampüs', 40.109153, 26.422348),
      const CampusData('Biga İktisadi ve İdari Bilimler Fakültesi Prof. Dr. Ramazan AYDIN Yerleşkesi', 40.285007, 27.151781),
    ],
    'Çanakkale Onsekiz Mart Üniversitesi Astrofizik Araştırma Merkezi': [
      const CampusData('Ulupınar Gözlemevi', 40.099693, 26.474270),
    ],
    'Çankaya Üniversitesi': [
      const CampusData('Ana Kampüs', 39.820640, 32.562393),
      const CampusData('Balgat Kampüsü', 39.902243, 32.795094),
      const CampusData('Lojman', 39.822842, 32.556118),
    ],
    'Çankırı Karatekin Üniversitesi': [
      const CampusData('Ana Kampüs', 40.622726, 33.618727),
      const CampusData('Ballıca Meslek Kampüsü', 40.527176, 33.609424),
    ],
    'Çorum Hitit Üniversitesi': [
      const CampusData('Ana Kampüs', 40.571550, 34.982464),
    ],
    'Çukurova Üniversitesi': [
      const CampusData('Adana Meslek Yüksek Okulu', 37.027271, 35.323389),
      const CampusData('Ana Kampüs', 37.052973, 35.348139),
      const CampusData('Karaisalı Meslek Yüksek Okulu', 37.254122, 35.068001),
      const CampusData('Kozan Meslek Yüksekokulu', 37.466390, 35.801879),
      const CampusData('İlahiyat Fakültesi', 37.061431, 35.366278),
    ],
    'Ömer Halisdemir Üniversitesi': [
      const CampusData('Ana Kampüs', 37.937928, 34.626345),
    ],
    'Üsküdar University': [
      const CampusData('South Campus', 41.022628, 29.040397),
    ],
    'Üsküdar Üniversitesi': [
      const CampusData('Güney Yerleşkesi', 41.021734, 29.040152),
    ],
    'İbn Haldun Üniversitesi': [
      const CampusData('Ana Kampüs', 41.137558, 28.799028),
    ],
    'İnönü Üniversitesi': [
      const CampusData('Ana Kampüs', 38.336167, 38.437407),
      const CampusData('Arapgir Meslek Yüksek Okulu Yerleşkesi', 39.016501, 38.488099),
      const CampusData('Kale Meslek Yüksekokulu', 38.417629, 38.756254),
    ],
    'İskenderun Teknik Üniversitesi': [
      const CampusData('Ana Kampüs', 36.577927, 36.153508),
    ],
    'İslam Bilim ve Teknoloji Üniversitesi': [
      const CampusData('Ana Kampüs', 36.978388, 37.300106),
    ],
    'İstanbul Arel Üniversitesi': [
      const CampusData('Tepekent Kemal Gözükara Yerleşkesi', 41.054914, 28.500441),
    ],
    'İstanbul Atlas Üniversitesi': [
      const CampusData('Ana Kampüs', 41.097973, 28.979072),
    ],
    'İstanbul Aydın Üniversitesi': [
      const CampusData('Ana Kampüs', 41.006264, 28.689574),
      const CampusData('Hazırlık Okulu Bahçelievler Kampüsü', 41.000142, 28.859759),
    ],
    'İstanbul Ayvansaray Üniversitesi': [
      const CampusData('Ana Kampüs', 41.038035, 28.944757),
    ],
    'İstanbul Bilgi Üniversitesi': [
      const CampusData('santralistanbul Kampüsü', 41.066136, 28.945722),
    ],
    'İstanbul Esenyurt Üniversitesi': [
      const CampusData('Ana Kampüs', 41.020384, 28.687336),
    ],
    'İstanbul Gedik Üniversitesi': [
      const CampusData('Kartal Kampüsü', 40.902014, 29.219673),
    ],
    'İstanbul Kent Üniversitesi': [
      const CampusData('Ana Kampüs', 41.032932, 28.984320),
    ],
    'İstanbul Kültür Üniversitesi': [
      const CampusData('İncirli Yerleşkesi', 40.995262, 28.867456),
    ],
    'İstanbul Medeniyet Üniversitesi': [
      const CampusData('Ana Kampüs', 40.951680, 29.119494),
      const CampusData('Güney Yerleşkesi', 40.995834, 29.061554),
      const CampusData('Kuzey Yerleşkesi', 40.996686, 29.065027),
    ],
    'İstanbul Rumeli Üniversitesi': [
      const CampusData('Silivri Mehmet Balcı Yerleşkesi', 41.078510, 28.269660),
    ],
    'İstanbul Sabahattin Zaim Üniversitesi': [
      const CampusData('Altunizade Yerleşkesi', 41.023110, 29.046502),
    ],
    'İstanbul Teknik Üniversitesi': [
      const CampusData('Ana Kampüs', 41.104629, 29.028331),
      const CampusData('İTÜ Mimarlık Fakültesi', 41.040559, 28.990791),
    ],
    'İstanbul Ticaret Üniversitesi': [
      const CampusData('Ana Kampüs', 41.005279, 29.035332),
    ],
    'İstanbul Yeni Yüzyıl Üniversitesi': [
      const CampusData('Ana Kampüs', 41.016040, 28.906787),
    ],
    'İstanbul Üniversitesi': [
      const CampusData('Adalet Meslek Yüksekokulu', 41.012572, 28.960306),
      const CampusData('Ana Kampüs', 41.010289, 28.955778),
      const CampusData('Cerrahpaşa Avcılar Yerleşkesi', 40.989018, 28.725908),
      const CampusData('Cerrahpaşa Bahçeköy Yerleşkesi', 41.175455, 28.991628),
      const CampusData('Cerrahpaşa Büyükçekmece Yerleşkesi', 41.090908, 28.620249),
      const CampusData('Cerrahpaşa Florence Nightingale Hemşirelik Fakültesi', 41.070192, 28.985232),
      const CampusData('Cerrahpaşa Orman Fakültesi', 41.175892, 28.991038),
      const CampusData('Cerrahpaşa Sosyal Bilimler Fakültesi', 41.100274, 28.875273),
      const CampusData('Edebiyat Fakültesi', 41.010320, 28.960506),
      const CampusData('Fen Fakültesi', 41.011772, 28.959646),
      const CampusData('Hasan Ali Yücel Eğitim Fakültesi', 41.011875, 28.961568),
      const CampusData('Hukuk Fakültesi', 41.013938, 28.963679),
      const CampusData('Kariyer Geliştirme Merkezi', 41.012679, 28.961061),
      const CampusData('Merkez Kütüphanesi', 41.009874, 28.962224),
      const CampusData('Mimarlık Fakültesi', 41.012081, 28.962413),
      const CampusData('Rektörlüğü Güzel Sanatlar…', 41.012897, 28.961098),
      const CampusData('Rektörlüğü Kütüphane Ve Dokümantasyon Daire Başkanlığı', 41.013005, 28.962484),
      const CampusData('Siyasal Bilgiler Fakültesi', 41.012561, 28.971609),
      const CampusData('Su Bölümeri Fakültesi', 41.012022, 28.960631),
      const CampusData('İktisat Fakültesi Ek Bina 2', 41.012959, 28.960527),
      const CampusData('İktisat fakültesi Ek Bina 2', 41.012759, 28.961652),
      const CampusData('İletişim Fakültesi', 41.012945, 28.961915),
    ],
    'İstanbul üniversitesi': [
      const CampusData('Ana Kampüs', 41.012152, 28.960422),
      const CampusData('fen bilimleri enstitüsü', 41.011781, 28.961285),
      const CampusData('hasan ali yücel eğitim fakültesi A block', 41.012359, 28.962393),
      const CampusData('iletişim fakültesi', 41.012632, 28.961922),
      const CampusData('sağlık kültür ve spor daire başkanlığı', 41.014255, 28.962058),
      const CampusData('sosyal bilimler meslek yüksek okulu', 41.011772, 28.962438),
      const CampusData('uzaktan eğitim merkezi', 41.011570, 28.961277),
    ],
    'İstiklal Üniversitesi': [
      const CampusData('Ana Kampüs', 37.594883, 36.849003),
    ],
    'İstinye Üniversitesi': [
      const CampusData('Topkapı Kampüsü', 41.014945, 28.904972),
    ],
    'İzmir Bakırçay Üniversitesi': [
      const CampusData('Ana Kampüs', 38.581313, 26.963498),
    ],
    'İzmir Demokrasi Üniversitesi': [
      const CampusData('Güzelyalı Sağlık Yerleşkesi', 38.396509, 27.077148),
      const CampusData('Ulucak Yerleşkesi', 38.479786, 27.358535),
      const CampusData('Uzundere Yerleşkesi', 38.347125, 27.087511),
      const CampusData('Üçkuyular Ana Yerleşkesi', 38.393487, 27.073835),
    ],
    'İzmir Ekonomi Üniversitesi': [
      const CampusData('Ana Kampüs', 38.388865, 27.044463),
      const CampusData('Güzelbahçe Kampüsü', 38.367193, 26.909601),
    ],
    'İzmir Kâtip Çelebi Üniversitesi': [
      const CampusData('Ana Kampüs', 38.515135, 27.031164),
      const CampusData('Aydınlıkevler Yerleşkesi', 38.489855, 27.077929),
      const CampusData('Mithatpaşa Yerleşkesi', 38.407418, 27.108476),
    ],
    'İzmir Yüksek Teknoloji Enstitüsü': [
      const CampusData('Ana Kampüs', 38.321757, 26.638506),
    ],
    'Şebinkarahisar Üniversite Yerleşkesi': [
      const CampusData('Ana Kampüs', 40.283257, 38.389386),
    ],
    'Şırnak Üniversitesi': [
      const CampusData('Ana Kampüs', 37.503583, 42.427340),
      const CampusData('Ziraat Fakültesi', 37.339699, 41.898150),
      const CampusData('İdil Kampüsü', 37.339365, 41.898332),
      const CampusData('İdil Meslek Yüksekokulu', 37.339528, 41.897957),
    ],
  };

  static final ({
    Map<String, List<CampusData>> canonicalUniversities,
    Map<String, String> aliases,
  }) _canonicalData = _buildCanonicalData();

  static final Map<String, String> _preferredCanonicalNamesByKey = {
    'namik kemal uni': 'Tekirdağ Namık Kemal Üniversitesi',
  };

  static String _normalize(String text) {
    const tr = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'i': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };
    final lower = text.toLowerCase().trim();
    final sb = StringBuffer();
    for (final ch in lower.split('')) {
      sb.write(tr[ch] ?? ch);
    }
    return sb.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _simplifyUniversityKey(String text) {
    var s = _normalize(text);
    s = s
        .replaceAll(RegExp(r'\buniversitesi\b'), 'uni')
        .replaceAll(RegExp(r'\buniversites\b'), 'uni')
        .replaceAll(RegExp(r'\buniversity\b'), 'uni')
        .replaceAll(RegExp(r'\buniversite\b'), 'uni')
        .replaceAll(RegExp(r'\benstitusu\b'), 'uni');

    final tokens = s.split(' ').where((t) => t.isNotEmpty).toList();

    // Sehir + universite adi formundaki tekrarli kayitlari birlestir.
    // Ornek: "tekirdag namik kemal uni" -> "namik kemal uni"
    if (tokens.length >= 4 && tokens.last == 'uni') {
      s = tokens.sublist(1).join(' ');
    } else {
      s = tokens.join(' ');
    }

    return s;
  }

  static ({
    Map<String, List<CampusData>> canonicalUniversities,
    Map<String, String> aliases,
  }) _buildCanonicalData() {
    final buckets = <String, List<String>>{};

    for (final universityName in universities.keys) {
      final key = _simplifyUniversityKey(universityName);
      buckets.putIfAbsent(key, () => <String>[]).add(universityName);
    }

    final canonicalUniversities = <String, List<CampusData>>{};
    final aliases = <String, String>{};

    for (final bucketEntry in buckets.entries) {
      final members = bucketEntry.value;
      String canonicalName = members.first;
      int maxCampusCount = universities[canonicalName]?.length ?? 0;

      for (final candidate in members.skip(1)) {
        final candidateCount = universities[candidate]?.length ?? 0;
        if (candidateCount > maxCampusCount ||
            (candidateCount == maxCampusCount &&
                candidate.length < canonicalName.length)) {
          canonicalName = candidate;
          maxCampusCount = candidateCount;
        }
      }

      final preferredDisplayName =
          _preferredCanonicalNamesByKey[bucketEntry.key];
      if (preferredDisplayName != null) {
        final preferred = members.where((m) =>
            _normalize(m) == _normalize(preferredDisplayName));
        if (preferred.isNotEmpty) {
          canonicalName = preferred.first;
        }
      }

      final mergedCampuses = <String, List<CampusData>>{};
      for (final member in members) {
        final campuses = universities[member] ?? const <CampusData>[];
        for (final campus in campuses) {
          final campusKey = _normalize(campus.name);
          mergedCampuses.putIfAbsent(campusKey, () => <CampusData>[]).add(campus);
        }
      }

      final canonicalCampusList = <CampusData>[];
      for (final grouped in mergedCampuses.values) {
        final displayName = grouped
            .map((c) => c.name)
            .reduce((a, b) => a.length <= b.length ? a : b);
        final avgLat =
            grouped.map((c) => c.latitude).reduce((a, b) => a + b) / grouped.length;
        final avgLon = grouped
                .map((c) => c.longitude)
                .reduce((a, b) => a + b) /
            grouped.length;
        canonicalCampusList.add(CampusData(displayName, avgLat, avgLon));
      }

      canonicalCampusList.sort((a, b) => a.name.compareTo(b.name));
      canonicalUniversities[canonicalName] = canonicalCampusList;

      aliases[canonicalName] = canonicalName;
      for (final member in members) {
        aliases[member] = canonicalName;
      }
    }

    return (
      canonicalUniversities: canonicalUniversities,
      aliases: aliases,
    );
  }

  static List<String> get universityNames {
    final names = _canonicalData.canonicalUniversities.keys.toList()..sort();
    return names;
  }

  static List<String> searchUniversities(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return universityNames;
    return universityNames.where((u) => _normalize(u).contains(q)).toList();
  }

  static String? resolveUniversityName(String university) {
    if (university.trim().isEmpty) return null;
    if (_canonicalData.canonicalUniversities.containsKey(university)) {
      return university;
    }

    final aliasExact = _canonicalData.aliases[university];
    if (aliasExact != null) return aliasExact;

    final normalized = _normalize(university);
    for (final entry in _canonicalData.aliases.entries) {
      if (_normalize(entry.key) == normalized) {
        return entry.value;
      }
    }

    for (final entry in _canonicalData.aliases.entries) {
      final keyNormalized = _normalize(entry.key);
      if (keyNormalized.contains(normalized) ||
          normalized.contains(keyNormalized)) {
        return entry.value;
      }
    }

    return null;
  }

  static List<String> getCampusNames(String university) {
    final resolvedUniversity = resolveUniversityName(university);
    if (resolvedUniversity == null) return [];
    return _canonicalData.canonicalUniversities[resolvedUniversity]
            ?.map((c) => c.name)
            .toList() ??
        [];
  }

  static CampusData? getCampusData(String university, String? campus) {
    final resolvedUniversity = resolveUniversityName(university);
    if (resolvedUniversity == null) return null;
    final list = _canonicalData.canonicalUniversities[resolvedUniversity];
    if (list == null || list.isEmpty) return null;
    if (campus == null || campus.trim().isEmpty) return list.first;

    final normalizedCampus = _normalize(campus);

    for (final c in list) {
      if (_normalize(c.name) == normalizedCampus) {
        return c;
      }
    }

    for (final c in list) {
      final cn = _normalize(c.name);
      if (cn.contains(normalizedCampus) || normalizedCampus.contains(cn)) {
        return c;
      }
    }

    return list.first;
  }
}
