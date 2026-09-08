import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/place_search_service.dart';

class PlaceCategoryPage extends StatefulWidget {
  const PlaceCategoryPage({super.key, required this.type});
  final String type;

  @override
  State<PlaceCategoryPage> createState() => _PlaceCategoryPageState();
}

class _PlaceCategoryPageState extends State<PlaceCategoryPage> {
  static const _red = Color(0xFFFF4650);
  static const _teal = Color(0xFF2DBF9E);
  final service = PlaceSearchService();
  final searchController = TextEditingController();
  List<PlaceResult> results = const [];
  PlaceResult? selected;
  bool loading = false;
  bool mapView = false;
  String? error;

  static const definitions = <String, ({String title, IconData icon, String query})>{
    'eczane': (title: 'Eczaneler', icon: Icons.local_pharmacy_outlined, query: 'eczane'),
    'noter': (title: 'Noterler', icon: Icons.description_outlined, query: 'noter'),
    'hastane': (title: 'Hastaneler', icon: Icons.local_hospital_outlined, query: 'hastane'),
    'taksi': (title: 'Taksi Durakları', icon: Icons.local_taxi_outlined, query: 'taksi durağı'),
    'cami': (title: 'Camiler', icon: Icons.mosque_outlined, query: 'cami'),
    'benzin': (title: 'Akaryakıt', icon: Icons.local_gas_station_outlined, query: 'benzin istasyonu'),
    'market': (title: 'Marketler', icon: Icons.shopping_cart_outlined, query: 'market'),
    'firin': (title: 'Fırınlar', icon: Icons.bakery_dining_outlined, query: 'fırın'),
    'restoran': (title: 'Restoranlar', icon: Icons.restaurant_outlined, query: 'restoran'),
    'kafe': (title: 'Kafeler', icon: Icons.local_cafe_outlined, query: 'kafe'),
    'oto-servis': (title: 'Oto Servis', icon: Icons.build_outlined, query: 'oto servis'),
    'site': (title: 'Siteler / Konut', icon: Icons.apartment_outlined, query: 'site'),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final definition = definitions[widget.type];
    if (definition == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      loading = true;
      error = null;
      selected = null;
    });

    try {
      final found = await service.search(searchController.text.trim(), category: widget.type);
      if (!mounted) return;
      setState(() => results = found);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> directions(PlaceResult place) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lon}&travelmode=driving');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> call(PlaceResult place) async {
    final phone = place.phone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final definition = definitions[widget.type] ?? (title: 'Yerler', icon: Icons.place_outlined, query: '');
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Text(definition.title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w500)),
          leading: IconButton(icon: const Icon(Icons.arrow_back, size: 27), onPressed: () => context.pop()),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 13),
              child: Row(
                children: [
                  Expanded(child: _TabButton(active: !mapView, icon: Icons.list_alt_rounded, label: 'Listede Göster', onTap: () => setState(() => mapView = false))),
                  const SizedBox(width: 8),
                  Expanded(child: _TabButton(active: mapView, icon: Icons.map_outlined, label: 'Haritada Göster', onTap: () => setState(() => mapView = true))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 5),
              child: TextField(
                controller: searchController,
                onSubmitted: (_) => load(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'İlçe, mahalle veya isim ile ara',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchController.text.isEmpty ? null : IconButton(onPressed: () { searchController.clear(); load(); }, icon: const Icon(Icons.close_rounded)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: _red))
                  : error != null
                      ? _ErrorState(message: error!, onRetry: load)
                      : mapView
                          ? _MapResults(results: results, selected: selected, icon: definition.icon, onSelect: (p) => setState(() => selected = p), onDirections: directions)
                          : results.isEmpty
                              ? _EmptyState(onRetry: load)
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 7, 16, 30),
                                  itemCount: results.length,
                                  itemBuilder: (_, i) => _PlaceCard(place: results[i], icon: definition.icon, onDirections: () => directions(results[i]), onCall: () => call(results[i])),
                                ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.active, required this.icon, required this.label, required this.onTap});
  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active ? const Color(0xFFFF4650) : const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(16),
        elevation: active ? 2 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: active ? Colors.white : const Color(0xFF5D748A)),
              const SizedBox(width: 7),
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: active ? Colors.white : const Color(0xFF5D748A)))),
            ]),
          ),
        ),
      );
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.icon, required this.onDirections, required this.onCall});
  final PlaceResult place;
  final IconData icon;
  final VoidCallback onDirections;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE6EBF0))),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFFE4F8F2), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: const Color(0xFF2DBF9E), size: 27)),
              const SizedBox(width: 12),
              Expanded(child: Text(place.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 13),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.location_on_outlined, size: 21, color: Color(0xFF657B90)),
              const SizedBox(width: 8),
              Expanded(child: Text(place.address, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, height: 1.3, color: Color(0xFF526A80), fontWeight: FontWeight.w600))),
            ]),
            if (place.phone != null) ...[
              const SizedBox(height: 7),
              Row(children: [const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF657B90)), const SizedBox(width: 8), Text(place.phone!, style: const TextStyle(color: Color(0xFF526A80), fontWeight: FontWeight.w600))]),
            ],
            const SizedBox(height: 13),
            Row(children: [
              if (place.phone != null) ...[
                Expanded(child: FilledButton.icon(onPressed: onCall, icon: const Icon(Icons.call, size: 19), label: const Text('Ara'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2DBF9E), minimumSize: const Size.fromHeight(45)))),
                const SizedBox(width: 9),
              ],
              Expanded(child: OutlinedButton.icon(onPressed: onDirections, icon: const Icon(Icons.directions_outlined, size: 20), label: const Text('Yol Tarifi'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2F73D9), minimumSize: const Size.fromHeight(45), side: const BorderSide(color: Color(0xFF2F73D9)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
            ]),
          ]),
        ),
      );
}

class _MapResults extends StatelessWidget {
  const _MapResults({required this.results, required this.selected, required this.icon, required this.onSelect, required this.onDirections});
  final List<PlaceResult> results;
  final PlaceResult? selected;
  final IconData icon;
  final ValueChanged<PlaceResult> onSelect;
  final Future<void> Function(PlaceResult) onDirections;

  @override
  Widget build(BuildContext context) {
    final center = selected != null ? LatLng(selected!.lat, selected!.lon) : (results.isNotEmpty ? LatLng(results.first.lat, results.first.lon) : const LatLng(38.7225, 35.4875));
    return Stack(children: [
      FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: results.isNotEmpty ? 12.5 : 11),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.kayserirehber.app'),
          MarkerLayer(markers: results.map((p) => Marker(point: LatLng(p.lat, p.lon), width: 48, height: 48, child: GestureDetector(onTap: () => onSelect(p), child: Container(decoration: BoxDecoration(color: p == selected ? const Color(0xFFFF4650) : const Color(0xFF2DBF9E), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: Icon(icon, color: Colors.white, size: 23))))).toList()),
        ],
      ),
      if (selected != null)
        Positioned(left: 12, right: 12, bottom: 14, child: Material(elevation: 8, borderRadius: BorderRadius.circular(20), color: Colors.white, child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE4F8F2), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: const Color(0xFF2DBF9E))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(selected!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), Text(selected!.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF60768A)))])), const SizedBox(width: 8), IconButton(onPressed: () => onDirections(selected!), icon: const Icon(Icons.directions, color: Color(0xFF2F73D9)))]))))),
      if (results.isEmpty) const Center(child: Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Bu kategori için sonuç bulunamadı.')))),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF728699)), const SizedBox(height: 10), const Text('Sonuç bulunamadı.'), const SizedBox(height: 12), OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tekrar dene'))]));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, size: 48), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tekrar dene'))])));
}
