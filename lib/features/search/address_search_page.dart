import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/place_search_service.dart';

class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({super.key});

  @override
  State<AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  final controller = TextEditingController();
  final service = PlaceSearchService();
  List<PlaceResult> results = const [];
  bool loading = false;
  String? error;
  PlaceResult? selected;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> search() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { loading = true; error = null; selected = null; });
    try {
      final found = await service.search(controller.text);
      if (!mounted) return;
      setState(() => results = found);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openMaps(PlaceResult place) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lon}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adres ve Yer Bul')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Kayseri’de nereye gideceksiniz?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Bina, site, cadde, sokak, mahalle veya işletme adını yazın.'),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => search(),
            decoration: InputDecoration(
              hintText: 'Örn. Anaşehir, Talas, Sivas Caddesi 16',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: search),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (loading) const Center(child: CircularProgressIndicator()),
          if (error != null) _MessageCard(icon: Icons.error_outline, text: error!),
          if (!loading && error == null && results.isEmpty)
            const _MessageCard(icon: Icons.location_city, text: 'Arama yapınca gerçek harita sonuçları burada listelenecek.'),
          if (selected != null) _MapCard(place: selected!, onDirections: () => openMaps(selected!)),
          ...results.map((place) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.location_on)),
              title: Text(place.name),
              subtitle: Text(place.address, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => selected = place),
            ),
          )),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.place, required this.onDirections});
  final PlaceResult place;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(place.lat, place.lon);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        SizedBox(
          height: 220,
          child: FlutterMap(
            options: MapOptions(initialCenter: point, initialZoom: 16),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.kayserirehber.app'),
              MarkerLayer(markers: [Marker(point: point, width: 48, height: 48, child: const Icon(Icons.location_pin, size: 48))]),
            ],
          ),
        ),
        ListTile(
          title: Text(place.name),
          subtitle: Text(place.address, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: FilledButton.icon(onPressed: onDirections, icon: const Icon(Icons.directions), label: const Text('Yol Tarifi')),
        ),
      ]),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon), const SizedBox(width: 12), Expanded(child: Text(text)),
      ]),
    ),
  );
}
