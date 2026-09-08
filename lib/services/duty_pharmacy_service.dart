import 'dart:convert';
import 'package:http/http.dart' as http;

class DutyPharmacy {
  const DutyPharmacy({required this.name, required this.district, required this.neighborhood, required this.type, required this.phone, required this.address});
  final String name, district, neighborhood, type, phone, address;
}

class DutyPharmacyService {
  static final Uri source = Uri.parse('https://cbs.kayseri.bel.tr/NobetciEczaneler.aspx');

  Future<List<DutyPharmacy>> fetch() async {
    final response = await http.get(source, headers: {'User-Agent': 'KayseriRehber/0.2 (mobile app)', 'Accept-Language': 'tr-TR,tr;q=0.9'}).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Nöbetçi eczane verisi alınamadı.');
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    final rows = RegExp(r'<tr[^>]*>(.*?)</tr>', caseSensitive: false, dotAll: true).allMatches(body);
    final items = <DutyPharmacy>[];
    for (final row in rows) {
      final cells = RegExp(r'<t[dh][^>]*>(.*?)</t[dh]>', caseSensitive: false, dotAll: true).allMatches(row.group(1) ?? '').map((m) => _clean(m.group(1)!)).where((x) => x.isNotEmpty).toList();
      if (cells.length < 6) continue;
      final name = cells[1];
      if (name.toLowerCase().contains('adı') || !name.toLowerCase().contains('eczane')) continue;
      items.add(DutyPharmacy(name: name, district: cells[2], neighborhood: cells[3], type: cells[4], phone: cells[5], address: cells.length > 6 ? cells[6] : ''));
    }
    if (items.isEmpty) throw Exception('Nöbetçi eczane listesi boş döndü.');
    return items;
  }

  String _clean(String value) => value.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&').replaceAll(RegExp(r'\s+'), ' ').trim();
}
