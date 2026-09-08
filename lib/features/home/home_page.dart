import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _red = Color(0xFFFF4650);
  static const _teal = Color(0xFF2DBF9E);
  static const _navy = Color(0xFF08131C);

  static const categories = <({String title, IconData icon, String route})>[
    (title: 'Bina / Adres', icon: Icons.location_on_outlined, route: '/adres'),
    (title: 'Eczaneler', icon: Icons.local_pharmacy_outlined, route: '/kategori/eczane'),
    (title: 'Nöbetçi Eczane', icon: Icons.nightlight_round, route: '/nobet'),
    (title: 'Noterler', icon: Icons.description_outlined, route: '/kategori/noter'),
    (title: 'Hastaneler', icon: Icons.local_hospital_outlined, route: '/kategori/hastane'),
    (title: 'Taksi Durakları', icon: Icons.local_taxi_outlined, route: '/kategori/taksi'),
    (title: 'Camiler', icon: Icons.mosque_outlined, route: '/kategori/cami'),
    (title: 'Akaryakıt', icon: Icons.local_gas_station_outlined, route: '/kategori/benzin'),
    (title: 'Marketler', icon: Icons.shopping_cart_outlined, route: '/kategori/market'),
    (title: 'Fırınlar', icon: Icons.bakery_dining_outlined, route: '/kategori/firin'),
    (title: 'Restoranlar', icon: Icons.restaurant_outlined, route: '/kategori/restoran'),
    (title: 'Kafeler', icon: Icons.local_cafe_outlined, route: '/kategori/kafe'),
    (title: 'Oto Servis', icon: Icons.build_outlined, route: '/kategori/oto-servis'),
    (title: 'Siteler / Konut', icon: Icons.apartment_outlined, route: '/kategori/site'),
  ];

  void _open(BuildContext context, String route) => context.push(route);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              sliver: SliverToBoxAdapter(child: _Header()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
              sliver: SliverToBoxAdapter(
                child: _SearchHero(onTap: () => _open(context, '/adres')),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Expanded(child: Text('Hızlı erişim', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800))),
                    Text('${categories.length} kategori', style: const TextStyle(color: Color(0xFF9FB0BC), fontSize: 13)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = categories[index];
                    return _CategoryTile(item: item, onTap: () => _open(context, item.route));
                  },
                  childCount: categories.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 9,
                  mainAxisSpacing: 9,
                  childAspectRatio: .91,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: HomePage._red, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 27),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KAYSERİ REHBER', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: .5)),
                SizedBox(height: 2),
                Text('Şehirde aradığın yere bir adım yakın', style: TextStyle(color: Color(0xFF9FB0BC), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/nobet'),
            tooltip: 'Nöbetçi eczaneler',
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          ),
        ],
      );
}

class _SearchHero extends StatelessWidget {
  const _SearchHero({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF14232D),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: HomePage._teal.withValues(alpha: .16), borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.search_rounded, color: HomePage._teal, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ne aramak istiyorsun?', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text('Bina, mahalle, cadde veya işletme ara', style: TextStyle(color: Color(0xFF9FB0BC), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item, required this.onTap});
  final ({String title, IconData icon, String route}) item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF14232D),
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.route == '/nobet' ? HomePage._red.withValues(alpha: .15) : HomePage._teal.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(item.icon, color: item.route == '/nobet' ? HomePage._red : HomePage._teal, size: 23),
                ),
                const SizedBox(height: 8),
                Text(item.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}
