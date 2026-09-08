import 'dart:convert';

import 'package:http/http.dart' as http;

class PlaceResult {
  const PlaceResult({
    required this.name,
    required this.address,
    required this.lat,
    required this.lon,
    this.type,
    this.phone,
  });

  final String name;
  final String address;
  final double lat;
  final double lon;
  final String? type;
  final String? phone;
}

/// Kayseri'deki POI ve adres verilerini canlı kaynaklardan getirir.
///
/// POI: OpenStreetMap Overpass. Kategori sorguları artık sabit 60 kayıtla
/// kesilmez. Kullanıcı araması isim yanında adres/mahalle/ilçe alanlarında da
/// eşleşir. Adres: Nominatim, ardından Overpass fallback.
class PlaceSearchService {
  static const _nominatim = 'https://nominatim.openstreetmap.org/search';
  static const _overpass = 'https://overpass-api.de/api/interpreter';
  static const _kayseriBbox = '38.25,35.05,39.05,36.20';

  static const _headers = {
    'User-Agent': 'KayseriRehber/1.0 (mobile app)',
    'Accept-Language': 'tr-TR,tr;q=0.9',
  };

  Future<List<PlaceResult>> search(String query, {String? category}) async {
    final trimmed = query.trim();
    if (category == null && trimmed.length < 2) return const [];
    if (category != null) return _searchPoi(trimmed, category);
    return _searchAddress(trimmed);
  }

  Future<List<PlaceResult>> _searchPoi(String text, String category) async {
    try {
      final results = await _searchOverpass(text, category);
      if (results.isNotEmpty) return results;
    } catch (_) {
      // Nominatim fallback below.
    }

    final fallbackQuery = text.isEmpty
        ? '${_categoryLabel(category)}, Kayseri, Türkiye'
        : '$text, Kayseri, Türkiye';
    return _searchNominatim(fallbackQuery);
  }

  Future<List<PlaceResult>> _searchOverpass(
    String text,
    String category,
  ) async {
    final escaped = RegExp.escape(text);
    final categoryFilter = _categoryFilter(category);

    // Arama metni varsa isim, sokak, mahalle, ilçe ve şehir alanlarında ara.
    // Metin boşsa kategorideki tüm kayıtları getir.
    final locationFilters = text.isEmpty
        ? ''
        : '''
      ["name"~"$escaped",i]
''';

    final query = text.isEmpty
        ? '''
[out:json][timeout:60];
(
  node($_kayseriBbox)$categoryFilter;
  way($_kayseriBbox)$categoryFilter;
  relation($_kayseriBbox)$categoryFilter;
);
out center tags;
'''
        : '''
[out:json][timeout:60];
(
  node($_kayseriBbox)$categoryFilter$locationFilters;
  way($_kayseriBbox)$categoryFilter$locationFilters;
  relation($_kayseriBbox)$categoryFilter$locationFilters;
);
out center tags;
''';

    final response = await http
        .post(
          Uri.parse(_overpass),
          headers: {
            ..._headers,
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          },
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 70));

    if (response.statusCode != 200) {
      throw Exception('Yer servisi ${response.statusCode} döndürdü.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = decoded['elements'] as List<dynamic>? ?? const [];
    final seen = <String>{};
    final results = <PlaceResult>[];

    for (final raw in elements) {
      final item = raw as Map<String, dynamic>;
      final tags = (item['tags'] as Map<String, dynamic>?) ?? const {};
      final center = item['center'] as Map<String, dynamic>?;
      final lat = (item['lat'] as num?)?.toDouble() ??
          (center?['lat'] as num?)?.toDouble();
      final lon = (item['lon'] as num?)?.toDouble() ??
          (center?['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;

      final name = _firstNonEmpty([
        tags['name:tr'],
        tags['name'],
        tags['official_name'],
      ]);
      if (name == null) continue;

      final address = _addressFromTags(tags, name);
      if (text.isNotEmpty && !_matchesText(text, name, address, tags)) {
        continue;
      }

      final key = '${name.toLowerCase()}|${lat.toStringAsFixed(6)}|${lon.toStringAsFixed(6)}';
      if (!seen.add(key)) continue;

      results.add(
        PlaceResult(
          name: name,
          address: address,
          lat: lat,
          lon: lon,
          type: tags['amenity']?.toString() ?? tags['shop']?.toString(),
          phone: _firstNonEmpty([tags['contact:phone'], tags['phone']]),
        ),
      );
    }

    // Burada artık take(60) gibi yapay bir kesme yok. Overpass'ın döndürdüğü
    // bütün isimli kayıtlar uygulamaya aktarılır.
    return results;
  }

  String _categoryFilter(String category) {
    switch (category) {
      case 'benzin':
        return '["amenity"="fuel"]';
      case 'market':
        return '["shop"~"^(supermarket|convenience|department_store|mall)$"]';
      case 'noter':
        return '["name"~"noter",i]';
      case 'eczane':
        return '["amenity"="pharmacy"]';
      case 'hastane':
        return '["amenity"="hospital"]';
      case 'taksi':
        return '["amenity"="taxi"]';
      case 'cami':
        return '["amenity"="place_of_worship"]["religion"="muslim"]';
      case 'firin':
        return '["shop"="bakery"]';
      case 'restoran':
        return '["amenity"="restaurant"]';
      case 'kafe':
        return '["amenity"="cafe"]';
      case 'oto-servis':
        return '["shop"="car_repair"]';
      case 'site':
        return '["building"]["name"]';
      default:
        return '';
    }
  }

  bool _matchesText(
    String text,
    String name,
    String address,
    Map<String, dynamic> tags,
  ) {
    final needle = text.toLowerCase();
    final searchable = <String>[
      name,
      address,
      tags['addr:street']?.toString() ?? '',
      tags['addr:neighbourhood']?.toString() ?? '',
      tags['addr:suburb']?.toString() ?? '',
      tags['addr:district']?.toString() ?? '',
      tags['addr:city']?.toString() ?? '',
    ].join(' ').toLowerCase();
    return searchable.contains(needle);
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'benzin': return 'benzin istasyonu';
      case 'market': return 'market';
      case 'noter': return 'noter';
      case 'eczane': return 'eczane';
      case 'hastane': return 'hastane';
      case 'taksi': return 'taksi durağı';
      case 'cami': return 'cami';
      case 'firin': return 'fırın';
      case 'restoran': return 'restoran';
      case 'kafe': return 'kafe';
      case 'oto-servis': return 'oto servis';
      case 'site': return 'site';
      default: return category;
    }
  }

  Future<List<PlaceResult>> _searchAddress(String text) async {
    final variants = <String>[
      '$text, Kayseri, Türkiye',
      '$text, Kayseri, Turkey',
    ];
    final seen = <String>{};
    final all = <PlaceResult>[];

    for (final query in variants) {
      try {
        final found = await _searchNominatim(query);
        for (final item in found) {
          final key = '${item.name.toLowerCase()}|${item.lat.toStringAsFixed(6)}|${item.lon.toStringAsFixed(6)}';
          if (seen.add(key)) all.add(item);
        }
      } catch (_) {
        // Try next variant, then Overpass fallback.
      }
    }

    if (all.isEmpty) {
      try {
        return await _searchOverpass(text, 'address');
      } catch (_) {
        return const [];
      }
    }

    return all;
  }

  Future<List<PlaceResult>> _searchNominatim(String query) async {
    final uri = Uri.parse(_nominatim).replace(
      queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'limit': '50',
        'addressdetails': '1',
        'countrycodes': 'tr',
        'accept-language': 'tr',
      },
    );

    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Adres servisine ulaşılamadı (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((raw) {
      final data = raw as Map<String, dynamic>;
      return PlaceResult(
        name: _nameOf(data),
        address: (data['display_name'] as String?) ?? 'Kayseri',
        lat: double.tryParse(data['lat']?.toString() ?? '') ?? 0,
        lon: double.tryParse(data['lon']?.toString() ?? '') ?? 0,
        type: data['type']?.toString(),
      );
    }).where((p) => p.lat != 0 && p.lon != 0).toList();
  }

  String _nameOf(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    return _firstNonEmpty([
          data['name'],
          address?['building'],
          address?['house_number'],
          address?['road'],
          address?['neighbourhood'],
          address?['suburb'],
        ]) ??
        'Kayseri';
  }

  String _addressFromTags(Map<String, dynamic> tags, String fallback) {
    final street = tags['addr:street']?.toString();
    final number = tags['addr:housenumber']?.toString();
    final neighborhood = _firstNonEmpty([
      tags['addr:neighbourhood'],
      tags['addr:suburb'],
      tags['addr:district'],
    ]);

    final parts = <String>[];
    if (street != null && street.isNotEmpty) {
      parts.add(number == null || number.isEmpty ? street : '$street No: $number');
    }
    if (neighborhood != null) parts.add(neighborhood);
    if (parts.isEmpty) return fallback;
    return '${parts.join(', ')}, Kayseri';
  }

  String? _firstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      final valueText = value?.toString().trim();
      if (valueText != null && valueText.isNotEmpty) return valueText;
    }
    return null;
  }
}
