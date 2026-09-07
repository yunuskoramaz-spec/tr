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
    'Akkışla','Bünyan','Develi','Felahiye','Hacılar','İncesu','Kocasinan',
    'Melikgazi','Özvatan','Pınarbaşı','Sarıoğlan','Sarız','Talas','Tomarza',
    'Yahyalı','Yeşilhisar'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bina / Adres Bul')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: district,
            decoration: const InputDecoration(labelText: '1. İlçe'),
            items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() { district = v; neighborhood = null; road = null; }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: neighborhood,
            decoration: const InputDecoration(labelText: '2. Mahalle'),
            items: (district == null ? const <String>[] : const ['Anayurt','Mevlana','YeniDoğan','Çarşı'])
                .map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: district == null ? null : (v) => setState(() { neighborhood = v; road = null; }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: road,
            decoration: const InputDecoration(labelText: '3. Cadde / Sokak'),
            items: (neighborhood == null ? const <String>[] : const ['Anayurt Caddesi','Mehmet Timuçin Caddesi','Çimen Sokak'])
                .map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: neighborhood == null ? null : (v) => setState(() => road = v),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: '4. Bina No veya Bina İsmi',
              hintText: '16, B12, Anaşehir...',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.home_work),
              title: Text(query.isEmpty ? 'Bina sonucu burada gösterilecek' : query),
              subtitle: Text([district, neighborhood, road].whereType<String>().join(' • ')),
            ),
          ),
        ],
      ),
    );
  }
}
