# 🏠 MatchHome - Ev Arkadaşı & Kiralık Ev Bulma Uygulaması

**MatchHome**, üniversite öğrencilerinin ve ev arayan bireylerin ev arkadaşı bulmasını, kiralık ev ilanları vermesini/incelemesini ve kampüs içi dinamikleri takip etmesini kolaylaştıran modern bir mobil uygulamadır.

---

## 🚀 Özellikler (Features)

*   **Ev & Ev Arkadaşı İlanları:** Kullanıcılar oda veya ev ilanları oluşturabilir, kriterlerine uygun ev arkadaşı adaylarını listeleyebilir ve filtreleyebilir.
*   **İkinci El Eşya Pazarı:** Öğrencilerin kampüs içinde veya yakınında eşya alıp satabileceği entegre bir pazar yeri.
*   **Kampüs Duyuruları:** Üniversite web sitelerinden otomatik kazınan (scraped) duyurular ve kullanıcılar tarafından eklenen kampüs içi etkinlikler/kayıp ilanları.
*   **Gerçek Zamanlı Sohbet (Realtime Chat):** Supabase Realtime altyapısı sayesinde kullanıcılar ilan sahipleriyle anlık olarak mesajlaşabilir.
*   **Akıllı Arama & Filtreleme:** Şehir, mahalle, üniversite ve fiyat filtreleri ile nokta atışı arama yapabilme.
*   **Favoriler:** Beğenilen ilanları kaydedip daha sonra hızlıca erişebilme.

---

## 🛠 Teknoloji Yığını (Tech Stack)

### Mobil Uygulama (Frontend)
*   **Çerçeve (Framework):** [Flutter](https://flutter.dev/) & Dart
*   **Durum Yönetimi (State Management):** Riverpod (`flutter_riverpod`)
*   **Yönlendirme (Routing):** GoRouter (`go_router`)
*   **Harita/Konum:** Geolocator (Yakındaki ilanları ve üniversiteleri listelemek için)

### Bulut Servisleri & Veritabanı (Backend)
*   **Altyapı:** [Supabase](https://supabase.com/)
    *   **Veritabanı:** PostgreSQL (ilişkisel veri modeli)
    *   **Kimlik Doğrulama (Auth):** E-posta/şifre ve sosyal giriş (Google Sign-In) entegrasyonu
    *   **Depolama (Storage):** İlan fotoğrafları ve profil resimleri için S3 uyumlu dosya depolama
    *   **Gerçek Zamanlılık (Realtime):** Anlık mesajlaşma ve bildirimler için websocket bağlantısı
    *   **Edge Functions:** Sunucusuz JavaScript/TypeScript fonksiyonları (Örn. Otomatik duyuru kazıma tetikleyicileri)

### Veri Kazıcı (Scraper)
*   **Dil:** Python
*   **Kütüphaneler:** BeautifulSoup, Requests, Supabase Python Client
*   **İşlev:** Üniversite duyuru sayfalarını periyodik olarak tarayıp veritabanına kaydeder.

---

## 📂 Proje Klasör Yapısı

```text
├── Ev_arkadasim-main/
│   ├── lib/                  # Flutter uygulama kodları
│   │   ├── core/             # Ortak kullanılan sabitler, araçlar ve servisler
│   │   └── features/         # Özellik bazlı modüller (Auth, Listings, Chat, Campus, Second Hand)
│   │       ├── data/         # Repository'ler ve veri modelleri
│   │       └── presentation/ # UI ekranları, widget'lar ve Riverpod sağlayıcıları (providers)
│   ├── scraper/              # Python veri kazıma scriptleri
│   ├── supabase/             # Supabase fonksiyonları ve yapılandırması
│   ├── supabase_*.sql        # Veritabanı tablolarını ve şemalarını kuran göç (migration) dosyaları
│   └── pubspec.yaml          # Flutter bağımlılıkları ve ayarları
```

---

## ⚙️ Kurulum ve Çalıştırma

### 1. Ön Gereksinimler
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (sürüm `>=3.0.0`)
*   [Python 3.x](https://www.python.org/downloads/) (veri kazıcıyı çalıştırmak için)
*   Aktif bir [Supabase Hesabı](https://supabase.com/)

### 2. Veritabanı Kurulumu (Supabase)
Supabase panelinizde **SQL Editor** kısmına gidin ve kök dizindeki aşağıdaki SQL dosyalarını sırasıyla çalıştırarak tabloları, ilişkileri ve tetikleyicileri (triggers) oluşturun:
1.  `supabase_schema.sql` (Temel veritabanı şeması ve tablolar)
2.  `supabase_profile_migration.sql`
3.  `supabase_chat_setup.sql` & `supabase_conversations_migration.sql`
4.  `supabase_second_hand_setup.sql`
5.  `supabase_campus_migration.sql` ve diğer kampüs SQL dosyaları

### 3. Mobil Uygulamayı Çalıştırma
1.  Bağımlılıkları yükleyin:
    ```bash
    flutter pub get
    ```
2.  Uygulamayı bir emülatör veya gerçek cihazda başlatın:
    ```bash
    flutter run
    ```

### 4. Veri Kazıcıyı (Scraper) Çalıştırma
1.  `scraper` klasörüne gidin:
    ```bash
    cd scraper
    ```
2.  Gerekli Python paketlerini kurun:
    ```bash
    pip install -r requirements.txt
    ```
3.  `.env.example` dosyasının adını `.env` olarak değiştirin ve kendi Supabase bilgilerinizi ekleyin:
    ```env
    SUPABASE_URL=https://<proje-id>.supabase.co
    SUPABASE_SERVICE_KEY=<gizli-service-role-key>
    ```
4.  Kazıcıyı çalıştırın:
    ```bash
    python main.py
    ```

---

## 🔒 Güvenlik Notu
`.env` gibi hassas kimlik bilgileri ve API anahtarları barındıran dosyalar `.gitignore` ile korunmaktadır ve asla GitHub'a push edilmemelidir.