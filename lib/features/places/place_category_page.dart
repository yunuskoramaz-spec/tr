import 'package:flutter/material.dart';

class PlaceCategoryPage extends StatelessWidget {
  const PlaceCategoryPage({super.key, required this.type});
  final String type;

  static const definitions = <String, ({String title, IconData icon, List<String> samples})>{
    'eczane': (title: 'Eczaneler', icon: Icons.local_pharmacy, samples: ['Eczane kayıtları veri kaynağından yüklenecek']),
    'noter': (title: 'Noterler', icon: Icons.description, samples: ['Noter kayıtları veri kaynağından yüklenecek']),
    'hastane': (title: 'Hastaneler', icon: Icons.local_hospital, samples: ['Hastane kayıtları veri kaynağından yüklenecek']),
    'taksi': (title: 'Taksi Durakları', icon: Icons.local_taxi, samples: ['Taksi durağı kayıtları veri kaynağından yüklenecek']),
    'cami': (title: 'Camiler', icon: Icons.mosque, samples: ['Cami kayıtları veri kaynağından yüklenecek']),
    'benzin': (title: 'Benzin İstasyonları', icon: Icons.local_gas_station, samples: ['Benzin istasyonu kayıtları veri kaynağından yüklenecek']),
    'market': (title: 'Marketler', icon: Icons.shopping_cart, samples: ['Market kayıtları veri kaynağından yüklenecek']),
    'firin': (title: 'Fırınlar', icon: Icons.bakery_dining, samples: ['Fırın kayıtları veri kaynağından yüklenecek']),
    'restoran': (title: 'Restoranlar', icon: Icons.restaurant, samples: ['Restoran kayıtları veri kaynağından yüklenecek']),
    'kafe': (title: 'Kafeler', icon: Icons.local_cafe, samples: ['Kafe kayıtları veri kaynağından yüklenecek']),
    'oto-servis': (title: 'Oto Servis', icon: Icons.build, samples: ['Oto servis kayıtları veri kaynağından yüklenecek']),
    'site': (title: 'Siteler / Konut', icon: Icons.apartment, samples: ['Site ve konut kayıtları veri kaynağından yüklenecek']),
    'diger': (title: 'Diğer Yerler', icon: Icons.more_horiz, samples: ['Kurye, şehir ve günlük yaşam için gerekli diğer POI kayıtları burada listelenecek']),
  };

  @override
  Widget build(BuildContext context) {
    final definition = definitions[type] ?? definitions['diger']!;
    return Scaffold(
      appBar: AppBar(title: Text(definition.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: '${definition.title} içinde ara',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(definition.icon, size: 32),
              title: Text(definition.title),
              subtitle: const Text('İlçe, mahalle, cadde/sokak ve bina bilgileriyle filtrelenebilir.'),
            ),
          ),
          const SizedBox(height: 8),
          ...definition.samples.map((sample) => Card(
            child: ListTile(
              leading: Icon(definition.icon),
              title: Text(sample),
              subtitle: const Text('Gerçek veri içe aktarıldığında adres ve konum ayrıntıları gösterilecek.'),
            ),
          )),
        ],
      ),
    );
  }
}
