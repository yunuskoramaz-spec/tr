import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/home/home_page.dart';
import 'features/search/address_search_page.dart';
import 'features/duty/duty_page.dart';
import 'features/places/place_category_page.dart';

class KayseriRehberApp extends StatelessWidget {
  const KayseriRehberApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router=GoRouter(routes:[
      GoRoute(path:'/',builder:(_,__)=>const HomePage()),
      GoRoute(path:'/adres',builder:(_,__)=>const AddressSearchPage()),
      GoRoute(path:'/nobet',builder:(_,__)=>const DutyPage()),
      GoRoute(path:'/kategori/:type',builder:(_,state)=>PlaceCategoryPage(type:state.pathParameters['type']!)),
    ]);
    return MaterialApp.router(
      title:'Kayseri Rehber',debugShowCheckedModeBanner:false,routerConfig:router,
      theme:ThemeData(
        useMaterial3:true,
        colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF1565C0),brightness:Brightness.light),
        scaffoldBackgroundColor:Colors.white,
        appBarTheme:const AppBarTheme(backgroundColor:Colors.white,surfaceTintColor:Colors.transparent,elevation:0),
        cardTheme:const CardThemeData(color:Colors.white,surfaceTintColor:Colors.transparent),
      ),
    );
  }
}
