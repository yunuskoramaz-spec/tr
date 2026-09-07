import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const categories = [
    ('Adres / Bina', Icons.location_on, '/adres'),
    ('Eczaneler', Icons.local_pharmacy, '/kategori/eczane'),
    ('Nöbetçi Eczane', Icons.emergency, '/nobet'),
    ('Noterler', Icons.description, '/kategori/noter'),
    ('Hastaneler', Icons.local_hospital, '/kategori/hastane'),
    ('Taksi Durakları', Icons.local_taxi, '/kategori/taksi'),
    ('Akaryakıt', Icons.local_gas_station, '/kategori/benzin'),
    ('Marketler', Icons.shopping_cart, '/kategori/market'),
    ('Fırınlar', Icons.bakery_dining, '/kategori/firin'),
    ('Restoranlar', Icons.restaurant, '/kategori/restoran'),
    ('Kafeler', Icons.local_cafe, '/kategori/kafe'),
    ('Camiler', Icons.mosque, '/kategori/cami'),
    ('Oto Servis', Icons.build, '/kategori/oto-servis'),
    ('Siteler / Konut', Icons.apartment, '/kategori/site'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayseri Rehber'), actions: [
        IconButton(tooltip: 'Nöbetçi hizmetler', onPressed: () => context.go('/nobet'), icon: const Icon(Icons.calendar_month)),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Kayseri’de yerini kolay bul', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Adres, bina, işletme ve önemli noktaları tek ekrandan bul.'),
          const SizedBox(height: 14),
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go('/adres'),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Row(children: [
                  Icon(Icons.search, size: 32), SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Adres veya yer ara', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4), Text('Bina, site, cadde, mahalle veya işletme adı'),
                  ])),
                  Icon(Icons.chevron_right),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text('Kategoriler', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.42),
            itemBuilder: (_, i) {
              final c = categories[i];
              return Card(child: InkWell(onTap: () => context.go(c.$3), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(c.$2, size: 30), const SizedBox(height: 8), Text(c.$1, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
              ])));
            },
          ),
        ],
      ),
    );
  }
}
