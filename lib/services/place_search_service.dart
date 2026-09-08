import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceResult {
  const PlaceResult({required this.name, required this.address, required this.lat, required this.lon, this.type, this.phone});
  final String name;
  final String address;
  final double lat;
  final double lon;
  final String? type;
  final String? phone;
}

class PlaceSearchService {
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org/search';
  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const _backupOverpassUrl = 'https://overpass.kumi.systems/api/interpreter';
  static const _headers = {'User-Agent': 'KayseriRehber/1.0', 'Accept-Language': 'tr-TR,tr;q=0.9'};
  static const _bbox = '38.25,35.05,39.05,36.20';
  static final Map<String, List<PlaceResult>> _cache = {};

  Future<List<PlaceResult>> search(String query, {String? category}) async {
    final text = query.trim();
    if (category == null && text.length < 2) return const [];
    final key = '${category ?? 'address'}|${_normalize(text)}';
    final cached = _cache[key];
    if (cached != null) return cached;
    final result = category == null ? await _searchAddress(text) : await _searchPoi(text, category);
    _cache[key] = result;
    return result;
  }

  Future<List<PlaceResult>> _searchPoi(String text, String category) async {
    final filter = _filter(category);
    if (filter.isEmpty) return const [];
    for (final endpoint in [_overpassUrl, _backupOverpassUrl]) {
      try {
        final q = '[out:json][timeout:35];(node($_bbox)$filter;way($_bbox)$filter;relation($_bbox)$filter;);out center tags;';
        final response = await http.post(Uri.parse(endpoint), headers: {..._headers, 'Content-Type': 'application/x-www-form-urlencoded'}, body: {'data': q}).timeout(const Duration(seconds: 40));
        if (response.statusCode != 200) continue;
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = decoded['elements'] as List<dynamic>? ?? const [];
        final seen = <String>{};
        final results = <PlaceResult>[];
        for (final raw in elements) {
          final p = _parse(raw);
          if (p == null) continue;
          if (text.isNotEmpty && !_normalize('${p.name} ${p.address}').contains(_normalize(text))) continue;
          final id = '${_normalize(p.name)}|${p.lat.toStringAsFixed(5)}|${p.lon.toStringAsFixed(5)}';
          if (seen.add(id)) results.add(p);
        }
        results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        if (results.isNotEmpty) return results.take(250).toList(growable: false);
      } catch (_) {}
    }
    try { return await _searchNominatim('${text.isEmpty ? _label(category) : text}, Kayseri, Türkiye'); } catch (_) { return const []; }
  }

  String _filter(String category) {
    switch (category) {
      case 'eczane': return '["amenity"="pharmacy"]';
      case 'hastane': return '["amenity"="hospital"]';
      case 'taksi': return '["amenity"="taxi"]';
      case 'cami': return '["amenity"="place_of_worship"]["religion"="muslim"]';
      case 'benzin': return '["amenity"="fuel"]';
      case 'market': return '["shop"~"supermarket|convenience|department_store|mall",i]';
      case 'firin': return '["shop"="bakery"]';
      case 'restoran': return '["amenity"~"restaurant|fast_food",i]';
      case 'kafe': return '["amenity"~"cafe|coffee_shop",i]';
      case 'oto-servis': return '["shop"="car_repair"]';
      case 'site': return '["building"]["name"]';
      case 'noter': return '["office"="notary"]';
      default: return '';
    }
  }

  PlaceResult? _parse(dynamic raw) {
    final item = raw as Map<String, dynamic>;
    final tags = (item['tags'] as Map<String, dynamic>?) ?? const {};
    final center = item['center'] as Map<String, dynamic>?;
    final lat = (item['lat'] as num?)?.toDouble() ?? (center?['lat'] as num?)?.toDouble();
    final lon = (item['lon'] as num?)?.toDouble() ?? (center?['lon'] as num?)?.toDouble();
    final name = _first([tags['name:tr'], tags['name'], tags['official_name']]);
    if (lat == null || lon == null || name == null) return null;
    return PlaceResult(name: name, address: _address(tags, name), lat: lat, lon: lon, type: _first([tags['amenity'], tags['shop'], tags['office'], tags['craft']]), phone: _first([tags['contact:phone'], tags['phone']]));
  }

  Future<List<PlaceResult>> _searchAddress(String text) async {
    final out = <PlaceResult>[];
    final seen = <String>{};
    for (final query in ['$text, Kayseri, Türkiye', '$text, Kayseri, Turkey']) {
      try {
        for (final p in await _searchNominatim(query)) {
          final id = '${_normalize(p.name)}|${p.lat.toStringAsFixed(6)}|${p.lon.toStringAsFixed(6)}';
          if (seen.add(id)) out.add(p);
        }
      } catch (_) {}
    }
    return out.take(50).toList(growable: false);
  }

  Future<List<PlaceResult>> _searchNominatim(String query) async {
    final uri = Uri.parse(_nominatimUrl).replace(queryParameters: {'q': query, 'format': 'jsonv2', 'limit': '50', 'addressdetails': '1', 'countrycodes': 'tr', 'accept-language': 'tr'});
    final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Adres servisi yanıt vermedi (${response.statusCode}).');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((raw) {
      final d = raw as Map<String, dynamic>;
      final a = d['address'] as Map<String, dynamic>?;
      return PlaceResult(name: _first([d['name'], a?['building'], a?['house_number'], a?['road'], a?['neighbourhood'], a?['suburb']]) ?? 'Kayseri', address: d['display_name']?.toString() ?? 'Kayseri', lat: double.tryParse(d['lat']?.toString() ?? '') ?? 0, lon: double.tryParse(d['lon']?.toString() ?? '') ?? 0, type: d['type']?.toString());
    }).where((p) => p.lat != 0 && p.lon != 0).toList();
  }

  String _address(Map<String, dynamic> tags, String fallback) {
    final street = tags['addr:street']?.toString();
    final number = tags['addr:housenumber']?.toString();
    final hood = _first([tags['addr:neighbourhood'], tags['addr:suburb'], tags['addr:district']]);
    final parts = <String>[];
    if (street != null && street.isNotEmpty) parts.add(number == null || number.isEmpty ? street : '$street No: $number');
    if (hood != null) parts.add(hood);
    return parts.isEmpty ? fallback : '${parts.join(', ')}, Kayseri';
  }

  String _normalize(String v) => v.toLowerCase().replaceAll('ı','i').replaceAll('ş','s').replaceAll('ğ','g').replaceAll('ü','u').replaceAll('ö','o').replaceAll('ç','c').replaceAll('İ','i').replaceAll('Ş','s').replaceAll('Ğ','g').replaceAll('Ü','u').replaceAll('Ö','o').replaceAll('Ç','c').trim();
  String _label(String c) => const {'eczane':'eczane','hastane':'hastane','taksi':'taksi durağı','cami':'cami','benzin':'benzin istasyonu','market':'market','firin':'fırın','restoran':'restoran','kafe':'kafe','oto-servis':'oto servis','site':'site','noter':'noter'}[c] ?? c;
  String? _first(Iterable<dynamic> values) { for (final v in values) { final s = v?.toString().trim(); if (s != null && s.isNotEmpty) return s; } return null; }
}
