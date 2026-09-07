# Kayseri Kurye mimarisi

## Adres çözümleme
`İlçe → Mahalle → Cadde/Sokak → Bina No/Bina İsmi`

Arama sırası:
1. Tam eşleşme
2. Türkçe karakterleri normalize ederek eşleşme
3. Cadde + bina no
4. Bina adı / site / blok
5. Harita yakınlığı

## Veri sınıfları
- `address`: bina ve yol verisi
- `poi`: eczane, noter, hastane, taksi durağı, cami, istasyon vb.
- `duty`: nöbetçi kayıtları
- `sources`: veri sağlayıcıları ve güncelleme tarihleri

## Kapsam dışı
Belediye kurumları, belediye ödeme/başvuru servisleri, belediye etkinlikleri, sosyal hizmetler ve diğer şehir yönetimi modülleri.

## Kurye odaklı alanlar
- bina giriş notu
- blok/kapı bilgisi
- site adı
- kat/asansör notu
- teslimat erişim notu
- doğrulanmış koordinat
