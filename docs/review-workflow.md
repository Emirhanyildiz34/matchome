# Code Review Workflow

> Yazdığın son kodları review et. Farklı bir yer bozulmamalı veya hata olmamalı.
> Edge case ve runtime hata odaklı kontrol et.
> Yeni eklenen özelliklerin test dosyası eksikse yaz ve test et.

> **⏱️ KOMUT BEKLEME KURALI:** Tüm `run_command` / `command_status` çağrılarında bekleme süresi **maksimum 10 saniye**. Uzun komutlar için background'a gönder ve 10'ar saniyelik aralıklarla kontrol et.

---

## 1. Static Analysis (pyflakes)

- Değişen her Python dosyası için çalıştır:

  ```powershell
  # turbo
  .\.venv\Scripts\python.exe -m pyflakes değişen_dosya.py
  ```

- **Yakala:** Undefined name, unused import, tanımsız değişken, unreachable code
- Hata varsa önce düzelt, sonra diğer adımlara geç

---

## 2. Dependency Check (try-import)

- Değişen dosyalardaki **tüm import satırlarını** tara (hem top-level hem fonksiyon-içi)
- Her 3rd-party import için kurulu olduğunu doğrula:

  ```powershell
  # turbo
  .\.venv\Scripts\python.exe -c "import modul_adi; print('OK')"
  ```

- **Özellikle kontrol et:** try bloğu içindeki lazy import'lar (bunlar pyflakes'tan kaçar)
- Kurulu değilse: `pip install paket_adi` ile kur

---

## 3. Runtime & Edge Case Review

- Tüm try/except bloklarında değişken scope kontrolü (except bloğunda tanımsız değişken var mı?)
- Fonksiyon parametrelerinin çağırıldığı yerdeki adıyla eşleştiğini doğrula
- None/null kontrolü yapılmamış dereference var mı?
- Dosya tipi veya format bağımlı kodlarda tüm varyantlar ele alınmış mı? (PDF/DOCX/PPTX vb.)

---

## 4. Cross-Module Flow Analysis (Akış Tutarlılığı)

- Değişen endpoint'leri kullanan **frontend fonksiyonlarını** grep ile bul
- Kullanıcı akışını uçtan uca takip et:
  - Endpoint başarılı → frontend ne yapıyor? (refresh, buton durumu, modal kapanma)
  - Endpoint hata → frontend hata gösteriyor mu? Butonlar eski haline dönüyor mu?
- Bir endpoint'in sonucu başka bir endpoint'i etkiliyor mu? (ör: upload → cleanup → download artık 404)
- State temizliği sonrası UI güncel mi? (session siliyor ama buton hâlâ aktif mi?)

---

## 5. Regresyon Kontrolü

- Değişen dosyaları kullanan diğer modülleri grep ile bul
- Bu modüllerin çalışmasını bozacak bir değişiklik var mı kontrol et
- Mevcut testleri çalıştır:

  ```powershell
  pytest tests/ -m "not integration" --tb=short -q
  ```

---

## 6. Eksik Test Kontrolü

- Yeni eklenen fonksiyon/endpoint için test var mı?
- Yoksa yaz ve çalıştır

---

## 🌐 Tarayıcı Testleri (Tüm projelerde)

| Alan      | Değer                          |
| --------- | ------------------------------ |
| Login     | `emirhanyildiz135@gmail.com`   |
| Şifre     | `admin123456`                  |
