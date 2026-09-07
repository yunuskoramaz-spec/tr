import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const categories = [
    ('Bina / Adres', Icons.location_on, '/adres'),
    ('Eczaneler', Icons.local_pharmacy, '/nobet'),
    ('Nöbetçi Eczane', Icons.emergency, '/nobet'),
    ('Noterler', Icons.description, '/nobet'),
    ('Nöbetçi Noter', Icons.event_available, '/nobet'),
    ('Hastaneler', Icons.local_hospital, '/nobet'),
    ('Taksi Durakları', Icons.local_taxi, '/nobet'),
    ('Camiler', Icons.mosque, '/nobet'),
    ('Benzin İstasyonları', Icons.local_gas_station, '/nobet'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayseri Kurye')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Kurye için hızlı adres bul', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Card(
            child: InkWell(
              onTap: () => context.go('/adres'),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Row(children: [
                  Icon(Icons.search, size: 30),
                  SizedBox(width: 12),
                  Expanded(child: Text('İlçe → Mahalle → Cadde/Sokak → Bina No / Bina İsmi')),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (_, i) {
              final c = categories[i];
              return Card(
                child: InkWell(
                  onTap: () => context.go(c.$3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(c.$2, size: 30),
                      const SizedBox(height: 8),
                      Text(c.$1, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
