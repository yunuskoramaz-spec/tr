import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const categories = [
    ('Bina / Adres', Icons.location_on, '/adres'),
    ('Eczaneler', Icons.local_pharmacy, '/kategori/eczane'),
    ('Nöbetçi Eczane', Icons.emergency, '/nobet'),
    ('Noterler', Icons.description, '/kategori/noter'),
    ('Nöbetçi Noter', Icons.event_available, '/nobet'),
    ('Hastaneler', Icons.local_hospital, '/kategori/hastane'),
    ('Taksi Durakları', Icons.local_taxi, '/kategori/taksi'),
    ('Camiler', Icons.mosque, '/kategori/cami'),
    ('Benzin İstasyonları', Icons.local_gas_station, '/kategori/benzin'),
    ('Marketler', Icons.shopping_cart, '/kategori/market'),
    ('Fırınlar', Icons.bakery_dining, '/kategori/firin'),
    ('Restoranlar', Icons.restaurant, '/kategori/restoran'),
    ('Kafeler', Icons.local_cafe, '/kategori/kafe'),
    ('Oto Servis', Icons.build, '/kategori/oto-servis'),
    ('Siteler / Konut', Icons.apartment, '/kategori/site'),
    ('Diğer Yerler', Icons.more_horiz, '/kategori/diger'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayseri Kurye'),
        actions: [
          IconButton(
            tooltip: 'Nöbetçi hizmetler',
            onPressed: () => context.go('/nobet'),
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Kayseri’de yerini kolay bul', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Bina, işletme ve önemli noktaları hızlıca bul.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go('/adres'),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Row(children: [
                  Icon(Icons.search, size: 30),
                  SizedBox(width: 12),
                  Expanded(child: Text('Adres ara\nİlçe → Mahalle → Cadde/Sokak → Bina No veya Bina İsmi')),
                  Icon(Icons.chevron_right),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Kategoriler', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.42,
            ),
            itemBuilder: (_, i) {
              final c = categories[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.go(c.$3),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(c.$2, size: 30),
                        const SizedBox(height: 8),
                        Text(c.$1, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Haritada keşfet'),
              subtitle: const Text('Kayseri’deki adres ve yerleri harita üzerinde incele.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/kategori/diger'),
            ),
          ),
        ],
      ),
    );
  }
}
