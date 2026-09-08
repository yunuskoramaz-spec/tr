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

/// Real address and POI data for Kayseri.
/// POIs use Overpass/OpenStreetMap, addresses use Nominatim with an Overpass fallback.
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
      // Nominatim fallback is used below.
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
    final filters = _filtersFor(category, escaped);
    final query = '''
[out:json][timeout:20];
(
  node($_kayseriBbox)$filters;
  way($_kayseriBbox)$filters;
  relation($_kayseriBbox)$filters;
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
        .timeout(const Duration(seconds: 25));

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

      final key = '${name.toLowerCase()}|$lat|$lon';
      if (!seen.add(key)) continue;

      results.add(
        PlaceResult(
          name: name,
          address: _addressFromTags(tags, name),
          lat: lat,
          lon: lon,
          type: tags['amenity']?.toString() ?? tags['shop']?.toString(),
          phone: _firstNonEmpty([tags['contact:phone'], tags['phone']]),
        ),
      );
    }

    return results.take(60).toList();
  }

  String _filtersFor(String category, String escaped) {
    final nameFilter = escaped.isEmpty ? '' : '["name"~"$escaped",i]';
    switch (category) {
      case 'benzin':
        return '["amenity"="fuel"]$nameFilter';
      case 'market':
        return '["shop"~"^(supermarket|convenience|department_store|mall)"]$nameFilter';
      case 'noter':
        return '["name"~"noter",i]$nameFilter';
      case 'eczane':
        return '["amenity"="pharmacy"]$nameFilter';
      case 'hastane':
        return '["amenity"="hospital"]$nameFilter';
      case 'taksi':
        return '["amenity"="taxi"]$nameFilter';
      case 'cami':
        return '["amenity"="place_of_worship"]["religion"="muslim"]$nameFilter';
      case 'firin':
        return '["shop"="bakery"]$nameFilter';
      case 'restoran':
        return '["amenity"="restaurant"]$nameFilter';
      case 'kafe':
        return '["amenity"="cafe"]$nameFilter';
      case 'oto-servis':
        return '["shop"="car_repair"]$nameFilter';
      case 'site':
        return '["building"]["name"]$nameFilter';
      default:
        return '["name"~"$escaped",i]';
    }
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
          final key = '${item.name.toLowerCase()}|${item.lat}|${item.lon}';
          if (seen.add(key)) all.add(item);
        }
      } catch (_) {
        // Try the second variant and then Overpass below.
      }
      if (all.length >= 20) break;
    }

    if (all.isEmpty) {
      try {
        return await _searchOverpass(text, 'address');
      } catch (_) {
        return const [];
      }
    }

    return all.take(20).toList();
  }

  Future<List<PlaceResult>> _searchNominatim(String query) async {
    final uri = Uri.parse(_nominatim).replace(
      queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'limit': '20',
        'addressdetails': '1',
        'countrycodes': 'tr',
        'accept-language': 'tr',
      },
    );

    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

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
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
