import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/place_search_service.dart';

class PlaceCategoryPage extends StatefulWidget {
  const PlaceCategoryPage({super.key, required this.type});
  final String type;
  @override State<PlaceCategoryPage> createState() => _PlaceCategoryPageState();
}

class _PlaceCategoryPageState extends State<PlaceCategoryPage> {
  static const red = Color(0xFFFF4650);
  static const bg = Color(0xFF08131C);
  static const panel = Color(0xFF14232D);
  static const teal = Color(0xFF2DBF9E);
  final service = PlaceSearchService();
  final search = TextEditingController();
  List<PlaceResult> results = const [];
  bool loading = false;
  bool map = false;
  String? error;

  static const defs = <String, ({String title, IconData icon})>{
    'eczane': (title: 'Eczaneler', icon: Icons.local_pharmacy_outlined),
    'noter': (title: 'Noterler', icon: Icons.description_outlined),
    'hastane': (title: 'Hastaneler', icon: Icons.local_hospital_outlined),
    'taksi': (title: 'Taksi Durakları', icon: Icons.local_taxi_outlined),
    'cami': (title: 'Camiler', icon: Icons.mosque_outlined),
    'benzin': (title: 'Akaryakıt', icon: Icons.local_gas_station_outlined),
    'market': (title: 'Marketler', icon: Icons.shopping_cart_outlined),
    'firin': (title: 'Fırınlar', icon: Icons.bakery_dining_outlined),
    'restoran': (title: 'Restoranlar', icon: Icons.restaurant_outlined),
    'kafe': (title: 'Kafeler', icon: Icons.local_cafe_outlined),
    'oto-servis': (title: 'Oto Servis', icon: Icons.build_outlined),
    'site': (title: 'Siteler / Konut', icon: Icons.apartment_outlined),
  };

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => load()); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> load() async {
    if (!mounted) return;
    setState(() { loading = true; error = null; });
    try {
      final data = await service.search(search.text.trim(), category: widget.type);
      if (mounted) setState(() => results = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> directions(PlaceResult p) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lon}&travelmode=driving');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> call(PlaceResult p) async {
    if (p.phone == null) return;
    final phone = p.phone!.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isNotEmpty) await launchUrl(Uri.parse('tel:$phone'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final d = defs[widget.type] ?? (title: 'Yerler', icon: Icons.place_outlined);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: TextField(
            controller: search,
            onSubmitted: (_) => load(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'İlçe, mahalle veya isim ara',
              hintStyle: const TextStyle(color: Color(0xFF8EA0AC)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9FB0BC)),
              suffixIcon: IconButton(onPressed: load, icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white)),
              filled: true, fillColor: panel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: _Mode(active: !map, text: 'Liste', icon: Icons.list_alt_rounded, onTap: () => setState(() => map = false))),
            const SizedBox(width: 8),
            Expanded(child: _Mode(active: map, text: 'Harita', icon: Icons.map_outlined, onTap: () => setState(() => map = true))),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator(color: red)) : error != null ? _Error(message: error!, retry: load) : map ? _Map(results: results, icon: d.icon, onDirections: directions) : results.isEmpty ? _Empty(retry: load) : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 6, 16, 30), itemCount: results.length, itemBuilder: (_, i) => _Card(place: results[i], icon: d.icon, onDirections: () => directions(results[i]), onCall: () => call(results[i])))),
      ]),
    );
  }
}

class _Mode extends StatelessWidget {
  const _Mode({required this.active, required this.text, required this.icon, required this.onTap});
  final bool active; final String text; final IconData icon; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Material(color: active ? const Color(0xFFFF4650) : const Color(0xFF14232D), borderRadius: BorderRadius.circular(14), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: active ? Colors.white : const Color(0xFF9FB0BC), size: 20), const SizedBox(width: 7), Text(text, style: TextStyle(color: active ? Colors.white : const Color(0xFF9FB0BC), fontWeight: FontWeight.w800))]))));
}

class _Card extends StatelessWidget {
  const _Card({required this.place, required this.icon, required this.onDirections, required this.onCall});
  final PlaceResult place; final IconData icon; final VoidCallback onDirections; final VoidCallback onCall;
  @override Widget build(BuildContext context) => Card(color: const Color(0xFF14232D), margin: const EdgeInsets.only(bottom: 10), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFF21343F), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: const Color(0xFF2DBF9E))), const SizedBox(width: 11), Expanded(child: Text(place.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)))]), const SizedBox(height: 11), Text(place.address, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9FB0BC), height: 1.3)), if (place.phone != null) ...[const SizedBox(height: 7), Text(place.phone!, style: const TextStyle(color: Color(0xFF9FB0BC)))], const SizedBox(height: 12), Row(children: [if (place.phone != null) Expanded(child: FilledButton.icon(onPressed: onCall, icon: const Icon(Icons.call, size: 18), label: const Text('Ara'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2DBF9E)))), if (place.phone != null) const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: onDirections, icon: const Icon(Icons.directions_outlined, size: 18), label: const Text('Yol Tarifi'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0xFF516572)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))))]))));
}

class _Map extends StatelessWidget {
  const _Map({required this.results, required this.icon, required this.onDirections});
  final List<PlaceResult> results; final IconData icon; final Future<void> Function(PlaceResult) onDirections;
  @override Widget build(BuildContext context) {
    final center = results.isEmpty ? const LatLng(38.7225, 35.4875) : LatLng(results.first.lat, results.first.lon);
    return FlutterMap(options: MapOptions(initialCenter: center, initialZoom: results.isEmpty ? 11 : 13), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.kayserirehber.app'), MarkerLayer(markers: results.map((p) => Marker(point: LatLng(p.lat, p.lon), width: 46, height: 46, child: GestureDetector(onTap: () => onDirections(p), child: Container(decoration: BoxDecoration(color: const Color(0xFFFF4650), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: Icon(icon, color: Colors.white, size: 22))))).toList())]);
  }
}

class _Empty extends StatelessWidget { const _Empty({required this.retry}); final VoidCallback retry; @override Widget build(BuildContext c) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.search_off_rounded, color: Color(0xFF8093A0), size: 46), const SizedBox(height: 10), const Text('Sonuç bulunamadı.', style: TextStyle(color: Colors.white)), const SizedBox(height: 12), OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Tekrar dene'))])); }
class _Error extends StatelessWidget { const _Error({required this.message, required this.retry}); final String message; final VoidCallback retry; @override Widget build(BuildContext c) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 46), const SizedBox(height: 10), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)), const SizedBox(height: 12), FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Tekrar dene'))]))); }
