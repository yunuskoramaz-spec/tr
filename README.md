# Kayseri Kurye

Kayseri'yi kolay keşfetmek ve adres/yer bilgilerine hızlı ulaşmak için geliştirilen, sade bir Kayseri şehir rehberi ve adres dizini.

> **Ürün amacı:** Kurye çağırmak veya sipariş oluşturmak değil; insanların Kayseri'deki adreslere, binalara ve önemli noktalara kolayca ulaşmasını sağlamaktır.

## Kapsam
- Bina ve adres arama
- Hiyerarşik adres seçimi: İlçe → Mahalle → Cadde/Sokak → Bina No / Bina İsmi
- Eczaneler
- Gün ve tarihe göre nöbetçi eczaneler
- Noterler
- Gün ve tarihe göre nöbetçi noterler
- Hastaneler
- Taksi durakları
- Camiler
- Benzin istasyonları
- Marketler, fırınlar, restoranlar, kafeler
- Oto servisleri
- Siteler / konut alanları
- Diğer yararlı POI'ler
- Harita ve konum altyapısı
- Favoriler ve arama geçmişi için altyapı

## Kesinlikle olmayacaklar
- "Bu binaya kurye çağır"
- Kurye çağırma / sipariş oluşturma
- Kurye takip sistemi
- Belediye hizmetleri
- Belediye başvuru/ödeme işlemleri
- Belediye etkinlikleri veya şehir yönetimi modülleri

## Adres deneyimi
Örnek:
`Talas → Anayurt Mahallesi → Anayurt Caddesi → Bina No 16`

veya:
`Talas → Anayurt Mahallesi → Anayurt Caddesi → B12 / Anaşehir`

Kullanıcı ayrıca kategori üzerinden yer arayabilecek ve uygun olduğunda adresi harita üzerinde inceleyebilecek.

## Veri mimarisi
Adres verisi, POI verisi ve tarih bazlı nöbet verisi birbirinden ayrıdır. Nöbet kayıtlarında `duty_date`, `start_at`, `end_at` ve kaynak bilgisi bulunur.

Tüm Kayseri bina/işletme verisi kaynaklardan ETL ile alınmalıdır. Veri yokken isim veya koordinat uydurulmaz.

## Referans APK
Yüklenen `Akıllı Şehir Kayseri_7.0.29.apk` incelendi. Referans uygulamadaki kategori yaklaşımı korunurken, Kayseri Kurye'de yalnızca adres, bina, işletme, önemli nokta ve nöbet bilgilerine odaklanılır.
