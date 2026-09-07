import 'package:flutter/material.dart';

class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({super.key});
  @override
  State<AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  String? district;
  String? neighborhood;
  String? road;
  String query = '';

  final districts = const [
    'Akkışla', 'Bünyan', 'Develi', 'Felahiye', 'Hacılar', 'İncesu',
    'Kocasinan', 'Melikgazi', 'Özvatan', 'Pınarbaşı', 'Sarıoğlan', 'Sarız',
    'Talas', 'Tomarza', 'Yahyalı', 'Yeşilhisar',
  ];

  List<String> get neighborhoods {
    if (district == null) return const [];
    if (district == 'Talas') return const ['Anayurt', 'Bahçelievler', 'Harman', 'Mevlana', 'Toki', 'Yenidoğan', 'Kiçiköy', 'Endürlük'];
    if (district == 'Melikgazi') return const ['Alpaslan', 'Bahçelievler', 'Çaybağları', 'Esentepe', 'Gesi', 'Mimarsinan', 'Yıldırım Beyazıt'];
    if (district == 'Kocasinan') return const ['Argıncık', 'Erkilet', 'Fevzi Çakmak', 'Kocasinan', 'Sahabiye', 'Zümrüt'];
    return const ['Merkez Mahallesi', 'Yeni Mahalle', 'Çarşı Mahallesi'];
  }

  List<String> get roads {
    if (neighborhood == null) return const [];
    return const ['Anayurt Caddesi', 'Mehmet Timuçin Caddesi', 'Atatürk Caddesi', 'İstiklal Caddesi', 'Fatih Sultan Mehmet Caddesi', 'Çimen Sokak', 'Zafer Sokak'];
  }

  @override
  Widget build(BuildContext context) {
    final path = [district, neighborhood, road].whereType<String>().join(' › ');
    return Scaffold(
      appBar: AppBar(title: const Text('Bina / Adres Bul')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Adres seç', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Önce ilçe, sonra mahalle ve cadde/sokak seç. Son adımda bina numarası veya bina adını ara.'),
          const SizedBox(height: 18),
          _stepTitle('1', 'İlçe'),
          DropdownButtonFormField<String>(
            value: district,
            isExpanded: true,
            decoration: const InputDecoration(hintText: 'İlçe seçin', border: OutlineInputBorder()),
            items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() { district = v; neighborhood = null; road = null; }),
          ),
          const SizedBox(height: 16),
          _stepTitle('2', 'Mahalle'),
          DropdownButtonFormField<String>(
            value: neighborhood,
            isExpanded: true,
            decoration: const InputDecoration(hintText: 'Mahalle seçin', border: OutlineInputBorder()),
            items: neighborhoods.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
            onChanged: district == null ? null : (v) => setState(() { neighborhood = v; road = null; }),
          ),
          const SizedBox(height: 16),
          _stepTitle('3', 'Cadde / Sokak'),
          DropdownButtonFormField<String>(
            value: road,
            isExpanded: true,
            decoration: const InputDecoration(hintText: 'Cadde veya sokak seçin', border: OutlineInputBorder()),
            items: roads.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: neighborhood == null ? null : (v) => setState(() => road = v),
          ),
          const SizedBox(height: 16),
          _stepTitle('4', 'Bina'),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Bina No veya Bina İsmi',
              hintText: '16, B12, Anaşehir...',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.home_work, size: 32),
              title: Text(query.isEmpty ? 'Bina sonucu' : query),
              subtitle: Text(path.isEmpty ? 'Adres seçimi bekleniyor' : path),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          if (query.isNotEmpty && path.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Haritada göster'),
                subtitle: const Text('Koordinat verisi bağlandığında bu adres haritada açılacak.'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepTitle(String number, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      CircleAvatar(radius: 13, child: Text(number, style: const TextStyle(fontSize: 12))),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    ]),
  );
}
