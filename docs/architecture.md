# Kayseri Kurye mimarisi

## Ürün amacı
Kayseri'de adres ve yer bilgisine hızlı, anlaşılır ve sade şekilde ulaşmak.

Uygulama bir kurye çağırma veya sipariş uygulaması değildir.

## Adres çözümleme
`İlçe → Mahalle → Cadde/Sokak → Bina No/Bina İsmi`

Arama önceliği:
1. Tam eşleşme
2. Türkçe karakterleri normalize ederek eşleşme
3. Cadde + bina no
4. Bina adı / site / blok
5. Harita yakınlığı

## Yer kategorileri
- Bina / adres
- Eczane
- Nöbetçi eczane
- Noter
- Nöbetçi noter
- Hastane
- Taksi durağı
- Cami
- Benzin istasyonu
- Market
- Fırın
- Restoran
- Kafe
- Oto servis
- Site / konut
- Diğer önemli POI'ler

## Veri sınıfları
- `address`: bina ve yol verisi
- `poi`: eczane, noter, hastane, taksi durağı, cami, istasyon ve diğer yerler
- `duty`: tarih bazlı nöbet kayıtları
- `sources`: veri sağlayıcıları ve güncelleme tarihleri

## Kapsam dışı
- Kurye çağırma
- Sipariş oluşturma
- Kurye takip
- Belediye kurumları ve belediye hizmet modülleri
- Belediye ödeme/başvuru işlemleri
- Şehir yönetimi modülleri

## Veri ilkesi
Gerçek bina ve işletme verisi kaynaklardan ETL ile alınır. Eksik veri tahmin edilmez. Her kayıt için kaynak ve güncelleme zamanı tutulur.
