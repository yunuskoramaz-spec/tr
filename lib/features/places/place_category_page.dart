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
  final service = PlaceSearchService();
  final searchController = TextEditingController();
  List<PlaceResult> results = const [];
  bool loading = false;
  bool mapView = false;
  String? error;

  static const definitions = <String, ({String title, IconData icon, String query})>{
    'eczane': (title:'Eczaneler', icon:Icons.local_pharmacy, query:'eczane'),
    'noter': (title:'Noterler', icon:Icons.description, query:'noter'),
    'hastane': (title:'Hastaneler', icon:Icons.local_hospital, query:'hastane'),
    'taksi': (title:'Taksi Durakları', icon:Icons.local_taxi, query:'taksi durağı'),
    'cami': (title:'Camiler', icon:Icons.mosque, query:'cami'),
    'benzin': (title:'Akaryakıt', icon:Icons.local_gas_station, query:'benzin istasyonu'),
    'market': (title:'Marketler', icon:Icons.shopping_cart, query:'market'),
    'firin': (title:'Fırınlar', icon:Icons.bakery_dining, query:'fırın'),
    'restoran': (title:'Restoranlar', icon:Icons.restaurant, query:'restoran'),
    'kafe': (title:'Kafeler', icon:Icons.local_cafe, query:'kafe'),
    'oto-servis': (title:'Oto Servis', icon:Icons.build, query:'oto servis'),
    'site': (title:'Siteler / Konut', icon:Icons.apartment, query:'site'),
  };

  @override void initState(){super.initState(); WidgetsBinding.instance.addPostFrameCallback((_)=>load());}
  @override void dispose(){searchController.dispose(); super.dispose();}

  Future<void> load() async {
    final definition=definitions[widget.type]; if(definition==null)return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState((){loading=true;error=null;});
    try{
      final suffix=searchController.text.trim();
      final found=await service.search(suffix.isEmpty?definition.query:'${definition.query} $suffix');
      if(mounted)setState(()=>results=found);
    }catch(e){if(mounted)setState(()=>error=e.toString().replaceFirst('Exception: ',''));}
    finally{if(mounted)setState(()=>loading=false);}
  }

  Future<void> directions(PlaceResult place) async {
    final uri=Uri.parse('https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lon}');
    await launchUrl(uri,mode:LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context){
    final definition=definitions[widget.type]??(title:'Yerler',icon:Icons.place,query:'Kayseri');
    return PopScope(
      canPop:true,
      child:Scaffold(
        backgroundColor:const Color(0xFFF7F9FC),
        appBar:AppBar(
          backgroundColor:Colors.white,surfaceTintColor:Colors.transparent,
          title:Text(definition.title,style:const TextStyle(fontWeight:FontWeight.w700)),
          leading:IconButton(icon:const Icon(Icons.arrow_back),onPressed:()=>context.pop()),
          actions:[IconButton(tooltip:'Ana sayfa',icon:const Icon(Icons.home_outlined),onPressed:()=>context.go('/'))],
        ),
        body:Column(children:[
          Padding(padding:const EdgeInsets.fromLTRB(16,10,16,8),child:Row(children:[
            Expanded(child:_TabButton(label:'Liste',icon:Icons.list_alt,active:!mapView,onTap:()=>setState(()=>mapView=false))),
            const SizedBox(width:8),
            Expanded(child:_TabButton(label:'Harita',icon:Icons.map_outlined,active:mapView,onTap:()=>setState(()=>mapView=true))),
          ])),
          Padding(padding:const EdgeInsets.fromLTRB(16,0,16,10),child:TextField(
            controller:searchController,textInputAction:TextInputAction.search,onSubmitted:(_)=>load(),
            decoration:InputDecoration(filled:true,fillColor:Colors.white,prefixIcon:const Icon(Icons.search),suffixIcon:IconButton(onPressed:load,icon:const Icon(Icons.arrow_forward)),hintText:'İlçe veya mahalle ile ara',border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none)),
          )),
          Expanded(child:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Padding(padding:const EdgeInsets.all(24),child:Text(error!,textAlign:TextAlign.center))):mapView?_MapView(results:results,onDirections:directions):RefreshIndicator(
            onRefresh:load,
            child:ListView.builder(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,4,16,28),itemCount:results.isEmpty?1:results.length,itemBuilder:(_,i)=>results.isEmpty?const _EmptyCard():_PlaceCard(place:results[i],definition:definition,onDirections:directions),
          )),
        ]),
      ),
    );
  }
}

class _TabButton extends StatelessWidget{
  const _TabButton({required this.label,required this.icon,required this.active,required this.onTap});
  final String label; final IconData icon; final bool active; final VoidCallback onTap;
  @override Widget build(BuildContext context)=>Material(color:active?Colors.deepOrangeAccent:const Color(0xFFEFF3F8),borderRadius:BorderRadius.circular(16),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(16),child:Padding(padding:const EdgeInsets.symmetric(vertical:14),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,color:active?Colors.white:const Color(0xFF60758D)),const SizedBox(width:7),Text(label,style:TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:active?Colors.white:const Color(0xFF60758D)))]))));
}

class _PlaceCard extends StatelessWidget{
  const _PlaceCard({required this.place,required this.definition,required this.onDirections});
  final PlaceResult place; final ({String title,IconData icon,String query}) definition; final Future<void> Function(PlaceResult) onDirections;
  @override Widget build(BuildContext context)=>Card(color:Colors.white,elevation:0,margin:const EdgeInsets.only(bottom:12),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20),side:BorderSide(color:Colors.grey.shade200)),child:Padding(padding:const EdgeInsets.fromLTRB(16,16,16,14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0xFFE6F8F3),borderRadius:BorderRadius.circular(15)),child:Icon(definition.icon,color:const Color(0xFF2DBD9B),size:27)),const SizedBox(width:12),Expanded(child:Text(place.name,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800)))]),
    const SizedBox(height:14),
    Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.location_on_outlined,size:21,color:Color(0xFF687D94)),const SizedBox(width:8),Expanded(child:Text(place.address,style:const TextStyle(fontSize:15,height:1.35,color:Color(0xFF536B84),fontWeight:FontWeight.w600)))]),
    const SizedBox(height:14),
    SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:()=>onDirections(place),icon:const Icon(Icons.directions_outlined),label:const Text('Yol Tarifi'),style:OutlinedButton.styleFrom(foregroundColor:Colors.deepOrangeAccent,side:const BorderSide(color:Colors.deepOrangeAccent),padding:const EdgeInsets.symmetric(vertical:13)))),
  ])));
}

class _MapView extends StatelessWidget{
  const _MapView({required this.results,required this.onDirections}); final List<PlaceResult> results; final Future<void> Function(PlaceResult) onDirections;
  @override Widget build(BuildContext context){final center=results.isNotEmpty?LatLng(results.first.lat,results.first.lon):const LatLng(38.7225,35.4875);return FlutterMap(options:MapOptions(initialCenter:center,initialZoom:12),children:[TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'com.kayserirehber.app'),MarkerLayer(markers:results.map((p)=>Marker(point:LatLng(p.lat,p.lon),width:48,height:48,child:GestureDetector(onTap:()=>onDirections(p),child:const Icon(Icons.location_pin,size:46,color:Colors.deepOrangeAccent)))).toList())]);}
}

class _EmptyCard extends StatelessWidget{const _EmptyCard();@override Widget build(BuildContext context)=>const Card(color:Colors.white,elevation:0,child:Padding(padding:EdgeInsets.all(24),child:Column(children:[Icon(Icons.search_off,size:42),SizedBox(height:10),Text('Sonuç bulunamadı.',style:TextStyle(fontSize:17,fontWeight:FontWeight.w700)),SizedBox(height:4),Text('İlçe veya mahalle adıyla tekrar arayın.',textAlign:TextAlign.center)])));}
