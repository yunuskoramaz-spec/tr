import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/home/home_page.dart';
import 'features/search/address_search_page.dart';
import 'features/duty/duty_page.dart';
import 'features/places/place_category_page.dart';

class KayseriRehberApp extends StatelessWidget {
  const KayseriRehberApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/adres', builder: (_, __) => const AddressSearchPage()),
      GoRoute(path: '/nobet', builder: (_, __) => const DutyPage()),
      GoRoute(path: '/kategori/:type', builder: (_, state) => PlaceCategoryPage(type: state.pathParameters['type']!)),
    ],
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Kayseri Rehber',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF08131C),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF4650), brightness: Brightness.dark),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF08131C), foregroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent),
          cardTheme: const CardThemeData(color: Color(0xFF14232D), surfaceTintColor: Colors.transparent, elevation: 0),
          inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Color(0xFF14232D), hintStyle: TextStyle(color: Color(0xFF8EA0AC)), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15)), borderSide: BorderSide.none)),
        ),
      );
}
