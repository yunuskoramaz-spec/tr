import 'dart:convert';

import 'package:http/http.dart' as http;

class DutyPharmacy {
  const DutyPharmacy({
    required this.name,
    required this.district,
    required this.neighborhood,
    required this.type,
    required this.phone,
    required this.address,
  });

  final String name;
  final String district;
  final String neighborhood;
  final String type;
  final String phone;
  final String address;
}

class DutyPharmacyService {
  static final Uri _official = Uri.parse(
    'https://www.kayseri.bel.tr/nobetci-eczane',
  );
  static final Uri _cbs = Uri.parse(
    'https://cbs.kayseri.bel.tr/kayseri-nobetci-eczaneler',
  );

  static const _headers = {
    'User-Agent': 'KayseriRehber/1.0 (mobile app)',
    'Accept-Language': 'tr-TR,tr;q=0.9',
  };

  Future<List<DutyPharmacy>> fetch() async {
    Object? lastError;

    for (final source in [_official, _cbs]) {
      try {
        final response = await http
            .get(source, headers: _headers)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          throw Exception('Kayseri eczane servisi ${response.statusCode} döndürdü.');
        }

        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        final items = _parseTable(body);
        if (items.isNotEmpty) return items;
        lastError = Exception('Nöbetçi eczane tablosu boş döndü.');
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(
      lastError?.toString().replaceFirst('Exception: ', '') ??
          'Nöbetçi eczane verisi alınamadı.',
    );
  }

  List<DutyPharmacy> _parseTable(String html) {
    final rows = RegExp(
      r'<tr\b[^>]*>(.*?)</tr>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);

    final items = <DutyPharmacy>[];
    final seen = <String>{};

    for (final row in rows) {
      final cells = RegExp(
        r'<t[dh]\b[^>]*>(.*?)</t[dh]>',
        caseSensitive: false,
        dotAll: true,
      )
          .allMatches(row.group(1) ?? '')
          .map((m) => _clean(m.group(1) ?? ''))
          .where((x) => x.isNotEmpty)
          .toList();

      if (cells.length < 5) continue;

      final nameIndex = cells.indexWhere(
        (x) => x.toLowerCase().contains('eczane') &&
            !x.toLowerCase().contains('eczane adı'),
      );
      if (nameIndex < 0 || nameIndex + 4 >= cells.length) continue;

      final name = cells[nameIndex];
      if (name.toLowerCase().contains('eczane adı')) continue;

      final district = _at(cells, nameIndex + 1);
      final neighborhood = _at(cells, nameIndex + 2);
      final type = _at(cells, nameIndex + 3);
      final phone = _at(cells, nameIndex + 4);
      final address = _at(cells, nameIndex + 5);

      if (district.isEmpty || neighborhood.isEmpty || address.isEmpty) continue;

      final key = '${name.toLowerCase()}|$district|$address';
      if (!seen.add(key)) continue;

      items.add(
        DutyPharmacy(
          name: name,
          district: district,
          neighborhood: neighborhood,
          type: type.isEmpty ? 'Nöbetçi' : type,
          phone: phone,
          address: address,
        ),
      );
    }

    return items;
  }

  String _at(List<String> cells, int index) =>
      index >= 0 && index < cells.length ? cells[index] : '';

  String _clean(String value) {
    var text = value
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    text = _decodeNumericEntities(text);
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _decodeNumericEntities(String value) {
    return value.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.tryParse(match.group(1)!);
      return code == null ? match.group(0)! : String.fromCharCode(code);
    });
  }
}
