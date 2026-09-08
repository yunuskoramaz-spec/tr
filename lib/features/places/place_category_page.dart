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
  final service = PlaceSearchService();
  final searchController = TextEditingController();
  final mapController = MapController();
  List<PlaceResult> results = const [];
  bool loading = false;
  bool mapView = false;
  String? error;

  static const definitions = <String, ({String title, IconData icon, String query})>{
    'eczane': (title: 'Eczaneler', icon: Icons.local_pharmacy, query: 'eczane'),
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
    mapController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final definition = definitions[widget.type];
    if (definition == null) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final text = searchController.text.trim();
      // Kategori ve arama terimi artık ayrı parametreler olarak servise gider.
      // Böylece "opet" araması "benzin istasyonu opet" gibi kırılgan bir
      // serbest metin sorgusuna dönüşmez.
      final found = await service.search(text, category: widget.type);
      if (mounted) {
        setState(() => results = found);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> directions(PlaceResult place) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lon}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final definition = definitions[widget.type] ??
        (title: 'Diğer Yerler', icon: Icons.place_outlined, query: 'Kayseri');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            definition.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: () => context.go('/'),
          ),
          actions: [
            IconButton(
              tooltip: 'Ana sayfa',
              icon: const Icon(Icons.home_outlined),
              onPressed: () => context.go('/'),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      active: !mapView,
                      icon: Icons.list_alt,
                      label: 'Liste',
                      onTap: () => setState(() => mapView = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeButton(
                      active: mapView,
                      icon: Icons.map_outlined,
                      label: 'Harita',
                      onTap: () => setState(() => mapView = true),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => load(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: load,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                  hintText: 'İlçe, mahalle veya isim ile ara',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? _ErrorState(message: error!, onRetry: load)
                      : mapView
                          ? _MapResults(
                              results: results,
                              icon: definition.icon,
                              mapController: mapController,
                              onDirections: directions,
                            )
                          : results.isEmpty
                              ? _EmptyState(onRetry: load)
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                                  itemCount: results.length,
                                  itemBuilder: (_, i) => _PlaceCard(
                                    place: results[i],
                                    icon: definition.icon,
                                    onDirections: () => directions(results[i]),
                                  ),
                                ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active ? const Color(0xFF2DBF9E) : const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: active ? Colors.white : const Color(0xFF5D748A)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : const Color(0xFF5D748A),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.icon, required this.onDirections});

  final PlaceResult place;
  final IconData icon;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F8F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: const Color(0xFF2DBF9E), size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      place.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 22, color: Color(0xFF647A8F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place.address,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF536B80), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (place.phone != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF647A8F)),
                    const SizedBox(width: 8),
                    Text(place.phone!, style: const TextStyle(color: Color(0xFF536B80))),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Yol Tarifi'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    side: const BorderSide(color: Color(0xFF2F73D9)),
                    foregroundColor: const Color(0xFF2F73D9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _MapResults extends StatelessWidget {
  const _MapResults({required this.results, required this.icon, required this.mapController, required this.onDirections});

  final List<PlaceResult> results;
  final IconData icon;
  final MapController mapController;
  final Future<void> Function(PlaceResult) onDirections;

  @override
  Widget build(BuildContext context) {
    final center = results.isNotEmpty
        ? LatLng(results.first.lat, results.first.lon)
        : const LatLng(38.7225, 35.4875);

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(initialCenter: center, initialZoom: results.isNotEmpty ? 13 : 11),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.kayserirehber.app',
            ),
            MarkerLayer(
              markers: results
                  .map(
                    (p) => Marker(
                      point: LatLng(p.lat, p.lon),
                      width: 52,
                      height: 52,
                      child: GestureDetector(
                        onTap: () => onDirections(p),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2DBF9E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Icon(icon, color: Colors.white, size: 25),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        if (results.isEmpty)
          const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Bu kategori için sonuç bulunamadı.'),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 44, color: Color(0xFF647A8F)),
            const SizedBox(height: 10),
            const Text('Sonuç bulunamadı.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 44),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
}
