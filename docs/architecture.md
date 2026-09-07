# Kayseri Rehber mimarisi

## Ürün amacı
Kayseri'de yaşayan veya şehre gelen insanların adresleri, binaları ve önemli yerleri kolay bir arayüzle bulabilmesi ve konuma ulaşabilmesi.

Bu uygulama **kurye çağırma veya sipariş uygulaması değildir**.

## Adres çözümleme
`İlçe → Mahalle → Cadde/Sokak → Bina No/Bina İsmi`

Ana arama yaklaşımı:
1. Kullanıcının serbest metin araması
2. Türkçe karakterleri normalize ederek eşleşme
3. Cadde + bina no
4. Bina adı / site / blok
5. Harita sonucu

## Yer kategorileri
- Bina / adres
- Eczane ve nöbetçi eczane
- Noter ve nöbetçi noter
- Hastane
- Taksi durağı
- Cami
- Akaryakıt istasyonu
- Market
- Fırın
- Restoran
- Kafe
- Oto servis
- Site / konut
- Diğer önemli POI'ler

## Veri sınıfları
- `address`: bina ve yol verisi
- `poi`: şehirdeki önemli yerler
- `duty`: tarih bazlı nöbet kayıtları
- `sources`: veri sağlayıcıları ve güncelleme tarihleri

## Harita ve yönlendirme
- OpenStreetMap harita katmanı
- Arama sonuçlarında koordinat
- Seçilen konumu haritada gösterme
- Harici harita uygulamasında yol tarifi açma

## Veri kaynağı yaklaşımı
MVP'de gerçek arama için OpenStreetMap Nominatim kullanılır. Uygulama Kayseri kapsamını sorguya otomatik ekler.

İleride daha yüksek hacim ve veri kalitesi için kendi adres/POI veri tabanı ve düzenli ETL hattı eklenebilir.

## Kapsam dışı
- Kurye çağırma
- Sipariş oluşturma
- Kurye takip
- Belediye ödeme/başvuru servisleri
- Belediye etkinlikleri
- Sosyal hizmetler
- Şehir yönetimi modülleri

## Veri ilkesi
Gerçek veri bulunmayan kayıtlar uydurulmaz. Kaynak ve güncelleme zamanı üretim veri modelinin parçasıdır.
