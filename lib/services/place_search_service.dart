import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceResult {
  const PlaceResult({
    required this.name,
    required this.address,
    required this.lat,
    required this.lon,
    this.type,
  });

  final String name;
  final String address;
  final double lat;
  final double lon;
  final String? type;
}

class PlaceSearchService {
  static const _base = 'https://nominatim.openstreetmap.org/search';

  Future<List<PlaceResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final uri = Uri.parse(_base).replace(queryParameters: {
      'q': '$trimmed, Kayseri, Türkiye',
      'format': 'jsonv2',
      'limit': '12',
      'addressdetails': '1',
      'accept-language': 'tr',
    });

    final response = await http.get(uri, headers: {
      'User-Agent': 'KayseriRehber/0.2 (mobile app)',
    });

    if (response.statusCode != 200) {
      throw Exception('Adres servisine ulaşılamadı (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((item) {
      final data = item as Map<String, dynamic>;
      return PlaceResult(
        name: _nameOf(data),
        address: (data['display_name'] as String?) ?? 'Kayseri',
        lat: double.parse(data['lat'] as String),
        lon: double.parse(data['lon'] as String),
        type: data['type'] as String?,
      );
    }).toList();
  }

  String _nameOf(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    return (address?['building'] ??
            address?['amenity'] ??
            address?['shop'] ??
            address?['road'] ??
            data['name'] ??
            'Kayseri')
        .toString();
  }
}
