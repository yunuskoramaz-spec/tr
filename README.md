# Kayseri Kurye

Kayseri içindeki kurye operasyonlarına odaklı, belediye hizmetlerini içermeyen adres/POI uygulaması.

## Kapsam
- Bina ve işletme/adres arama
- Hiyerarşik adres seçimi: İlçe → Mahalle → Cadde/Sokak → Bina No/İsim
- Eczaneler ve gün bazlı nöbetçi eczaneler
- Noterler ve gün bazlı nöbetçi noterler
- Hastaneler
- Taksi durakları
- Camiler
- Benzin istasyonları
- Kurye için yararlı ticari noktalar
- Harita üzerinde konum ve rota altyapısı
- Belediye servisleri/KBS/şehir yönetimi modülleri kapsam dışı

## Referans APK inceleme
Yüklenen `Akıllı Şehir Kayseri_7.0.29.apk` Flutter tabanlıdır. APK içinde eczane, hastane, noter, taksi, yakıt ve adres odaklı görsel varlıklar bulunduğu görüldü. Yeni uygulamada bu yaklaşım kurye kullanımına göre sadeleştirildi.

## Adres deneyimi
Örnek akış:
`Talas → Anayurt Mahallesi → Anayurt Caddesi → 16`
veya bina/site adı:
`Talas → Anayurt Mahallesi → Anayurt Caddesi → B12 / Anaşehir`

## Veri mimarisi
Adres verisi, sabit POI verisi ve tarih bazlı nöbet verisi ayrı tutulur. Nöbet kayıtlarında `duty_date`, `start_at`, `end_at` ve kaynak bilgisi bulunur.

## Önemli not
“Kayseri'deki bütün binalar ve işletmeler” canlı ve eksiksiz bir veri setidir. Bunu kaynak veriler olmadan elle uydurmak doğru değildir. Bu repo, veri sağlayıcılarını içeri alan ETL katmanının bağlanacağı uygulama ve şema temelini içerir. Nöbetçi eczane bilgilerinin Kayseri Eczacı Odası tarafından girildiği resmi belediye sayfasında belirtilmektedir; belediye veri kaynağı uygulamanın içine hizmet modülü olarak alınmaz.
