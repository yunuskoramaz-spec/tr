import 'dart:async';
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

/// Kayseri adres ve POI verilerini canlı, ücretsiz açık harita kaynaklarından getirir.
/// Ağ sorunlarında tek bir sunucuya bağımlı kalmamak için Overpass yedekleri kullanılır.
class PlaceSearchService {
  static const _nominatim = 'https://nominatim.openstreetmap.org/search';
  static const _overpassEndpoints = <String>[
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  static const _south = 38.25;
  static const _west = 35.05;
  static const _north = 39.05;
  static const _east = 36.20;

  static const _headers = <String, String>{
    'User-Agent': 'KayseriRehber/1.0 (Kayseri city guide)',
    'Accept-Language': 'tr-TR,tr;q=0.9,en;q=0.5',
  };

  static final Map<String, List<PlaceResult>> _cache = <String, List<PlaceResult>>{};

  Future<List<PlaceResult>> search(String query, {String? category}) async {
    final text = query.trim();
    if (category == null && text.length < 2) return const [];

    final cacheKey = '${category ?? 'address'}|${_normalize(text)}';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final result = category == null
        ? await _searchAddress(text)
        : await _searchPoi(text, category);
    _cache[cacheKey] = result;
    return result;
  }

  Future<List<PlaceResult>> _searchPoi(String text, String category) async {
    try {
      final results = await _searchOverpass(text, category);
      if (results.isNotEmpty) return results;
    } catch (_) {}

    final fallback = text.isEmpty
        ? '${_categoryLabel(category)}, Kayseri, Türkiye'
        : '$text, ${_categoryLabel(category)}, Kayseri, Türkiye';
    return _searchNominatim(fallback);
  }

  Future<List<PlaceResult>> _searchOverpass(String text, String category) async {
    final filter = _categoryFilter(category);
    if (filter.isEmpty) return const [];

    final midLat = (_south + _north) / 2;
    final midLon = (_west + _east) / 2;
    final boxes = <List<double>>[
      [_south, _west, midLat, midLon],
      [_south, midLon, midLat, _east],
      [midLat, _west, _north, midLon],
      [midLat, midLon, _north, _east],
    ];

    // Dört bölgeyi paralel sorgulamak, önceki sürümdeki 4 x 70 saniyeye varabilen
    // seri beklemeyi ortadan kaldırır. İlk başarılı endpoint kullanılır.
    final endpoint = await _findWorkingOverpassEndpoint();
    if (endpoint == null) throw Exception('Harita veri sunucularına ulaşılamadı.');

    final futures = boxes.map((box) => _queryBox(endpoint, box, filter));
    final chunks = await Future.wait(futures);
    final seen = <String>{};
    final results = <PlaceResult>[];

    for (final chunk in chunks) {
      for (final place in chunk) {
        if (text.isNotEmpty && !_matchesText(text, place)) continue;
        final key = '${_normalize(place.name)}|${place.lat.toStringAsFixed(5)}|${place.lon.toStringAsFixed(5)}';
        if (seen.add(key)) results.add(place);
      }
    }

    results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return results.take(250).toList(growable: false);
  }

  Future<String?> _findWorkingOverpassEndpoint() async {
    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {..._headers, 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
              body: const {'data': '[out:json][timeout:5];node(38.72,35.48,38.73,35.50);out 1;'},
            )
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) return endpoint;
      } catch (_) {}
    }
    return null;
  }

  Future<List<PlaceResult>> _queryBox(String endpoint, List<double> box, String filter) async {
    final boxText = box.map((v) => v.toStringAsFixed(6)).join(',');
    final query = '''
[out:json][timeout:25];
(
  node($boxText)$filter;
  way($boxText)$filter;
  relation($boxText)$filter;
);
out center tags;
''';

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {..._headers, 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 32));
      if (response.statusCode != 200) return const [];
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = decoded['elements'] as List<dynamic>? ?? const [];
      return elements.map(_parseOverpass).whereType<PlaceResult>().toList();
    } catch (_) {
      return const [];
    }
  }

  PlaceResult? _parseOverpass(dynamic raw) {
    final item = raw as Map<String, dynamic>;
    final tags = (item['tags'] as Map<String, dynamic>?) ?? const {};
    final center = item['center'] as Map<String, dynamic>?;
    final lat = (item['lat'] as num?)?.toDouble() ?? (center?['lat'] as num?)?.toDouble();
    final lon = (item['lon'] as num?)?.toDouble() ?? (center?['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final name = _firstNonEmpty([tags['name:tr'], tags['name'], tags['official_name']]);
    if (name == null) return null;

    return PlaceResult(
      name: name,
      address: _addressFromTags(tags, name),
      lat: lat,
      lon: lon,
      type: _firstNonEmpty([tags['amenity'], tags['shop'], tags['office'], tags['craft']]),
      phone: _firstNonEmpty([tags['contact:phone'], tags['phone']]),
    );
  }

  String _categoryFilter(String category) {
    switch (category) {
      case 'benzin':
        return '["amenity"="fuel"]';
      case 'market':
        return '[("shop"~"^(supermarket|convenience|department_store|mall)$",i)]';
      case 'noter':
        return '[("office"="notary")["name"~"noter",i]]';
      case 'eczane':
        return '["amenity"="pharmacy"]';
      case 'hastane':
        return '["amenity"="hospital"]';
      case 'taksi':
        return '[("amenity"="taxi")["name"]]';
      case 'cami':
        return '["amenity"="place_of_worship"]["religion"="muslim"]';
      case 'firin':
        return '["shop"="bakery"]';
      case 'restoran':
        return '["amenity"~"^(restaurant|fast_food)$",i]';
      case 'kafe':
        return '["amenity"~"^(cafe|coffee_shop)$",i]';
      case 'oto-servis':
        return '["shop"="car_repair"]';
      case 'site':
        return '["building"]["name"]';
      default:
        return '';
    }
  }

  bool _matchesText(String text, PlaceResult place) {
    final needle = _normalize(text);
    final searchable = _normalize('${place.name} ${place.address}');
    return searchable.contains(needle);
  }

  Future<List<PlaceResult>> _searchAddress(String text) async {
    final queries = <String>[
      '$text, Kayseri, Türkiye',
      '$text, Kayseri, Turkey',
    ];
    final seen = <String>{};
    final all = <PlaceResult>[];

    for (final query in queries) {
      try {
        final found = await _searchNominatim(query);
        for (final place in found) {
          final key = '${_normalize(place.name)}|${place.lat.toStringAsFixed(6)}|${place.lon.toStringAsFixed(6)}';
          if (seen.add(key)) all.add(place);
        }
      } catch (_) {}
    }
    return all.take(50).toList(growable: false);
  }

  Future<List<PlaceResult>> _searchNominatim(String query) async {
    final uri = Uri.parse(_nominatim).replace(queryParameters: {
      'q': query,
      'format': 'jsonv2',
      'limit': '50',
      'addressdetails': '1',
      'countrycodes': 'tr',
      'accept-language': 'tr',
    });

    final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw Exception('Adres servisi yanıt vermedi (${response.statusCode}).');

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
        ]) ?? 'Kayseri';
  }

  String _addressFromTags(Map<String, dynamic> tags, String fallback) {
    final street = tags['addr:street']?.toString();
    final number = tags['addr:housenumber']?.toString();
    final neighborhood = _firstNonEmpty([tags['addr:neighbourhood'], tags['addr:suburb'], tags['addr:district']]);
    final parts = <String>[];
    if (street != null && street.isNotEmpty) parts.add(number == null || number.isEmpty ? street : '$street No: $number');
    if (neighborhood != null) parts.add(neighborhood);
    return parts.isEmpty ? fallback : '${parts.join(', ')}, Kayseri';
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ı', 'i').replaceAll('ş', 's').replaceAll('ğ', 'g')
      .replaceAll('ü', 'u').replaceAll('ö', 'o').replaceAll('ç', 'c')
      .replaceAll('İ', 'i').replaceAll('Ş', 's').replaceAll('Ğ', 'g')
      .replaceAll('Ü', 'u').replaceAll('Ö', 'o').replaceAll('Ç', 'c')
      .trim();

  String _categoryLabel(String category) {
    const labels = {
      'benzin': 'benzin istasyonu', 'market': 'market', 'noter': 'noter',
      'eczane': 'eczane', 'hastane': 'hastane', 'taksi': 'taksi durağı',
      'cami': 'cami', 'firin': 'fırın', 'restoran': 'restoran', 'kafe': 'kafe',
      'oto-servis': 'oto servis', 'site': 'site',
    };
    return labels[category] ?? category;
  }

  String? _firstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
