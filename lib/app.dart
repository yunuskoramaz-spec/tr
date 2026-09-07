import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/home/home_page.dart';
import 'features/search/address_search_page.dart';
import 'features/duty/duty_page.dart';
import 'features/places/place_category_page.dart';

class KayseriKuryeApp extends StatelessWidget {
  const KayseriKuryeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(path: '/adres', builder: (_, __) => const AddressSearchPage()),
        GoRoute(path: '/nobet', builder: (_, __) => const DutyPage()),
        GoRoute(
          path: '/kategori/:type',
          builder: (_, state) => PlaceCategoryPage(type: state.pathParameters['type']!),
        ),
      ],
    );
    return MaterialApp.router(
      title: 'Kayseri Kurye',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepOrange,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      ),
      routerConfig: router,
    );
  }
}
