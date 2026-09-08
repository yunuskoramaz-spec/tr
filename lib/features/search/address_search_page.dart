import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/place_search_service.dart';

enum _Step { district, neighborhood, street, building }

class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({super.key});
  @override State<AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  static const bg = Color(0xFF08131C);
  static const panel = Color(0xFF14232D);
  static const red = Color(0xFFFF4650);
  static const teal = Color(0xFF2DBF9E);
  final service = PlaceSearchService();
  final controller = TextEditingController();
  _Step step = _Step.district;
  String? district;
  String? neighborhood;
  String? street;
  PlaceResult? building;
  List<PlaceResult> results = const [];
  bool loading = false;
  String? error;

  static const districts = ['Akkışla','Bünyan','Develi','Felahiye','Hacılar','İncesu','Kocasinan','Melikgazi','Özvatan','Pınarbaşı','Sarıoğlan','Sarız','Talas','Tomarza','Yahyalı','Yeşilhisar'];

  String get title => switch (step) { _Step.district => 'İlçe Seçin', _Step.neighborhood => 'Mahalle Seçin', _Step.street => 'Cadde / Sokak Seçin', _Step.building => 'Bina Seçin' };
  String get hint => switch (step) { _Step.neighborhood => 'Mahalle ara...', _Step.street => 'Cadde veya sokak ara...', _Step.building => 'Bina no veya bina adı ara...', _Step.district => 'İlçe ara...' };

  @override void dispose() { controller.dispose(); super.dispose(); }

  void selectDistrict(String value) { setState(() { district=value; neighborhood=null; street=null; building=null; results=[]; controller.clear(); step=_Step.neighborhood; }); }

  void selectResult(PlaceResult p) {
    setState(() {
      if (step == _Step.neighborhood) { neighborhood=p.name; street=null; building=null; step=_Step.street; }
      else if (step == _Step.street) { street=p.name; building=null; step=_Step.building; }
      else if (step == _Step.building) { building=p; }
      results=[]; controller.clear(); error=null;
    });
  }

  Future<void> search() async {
    final text=controller.text.trim();
    if (text.isEmpty || step == _Step.district) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { loading=true; error=null; });
    final query = switch (step) {
      _Step.neighborhood => '$text mahalle, $district, Kayseri',
      _Step.street => '$text, $neighborhood, $district, Kayseri',
      _Step.building => '$text, $street, $neighborhood, $district, Kayseri',
      _Step.district => text,
    };
    try {
      final data=await service.search(query);
      if (mounted) setState(() => results=data);
    } catch(e) { if (mounted) setState(() => error=e.toString().replaceFirst('Exception: ','')); }
    finally { if (mounted) setState(() => loading=false); }
  }

  void back() {
    if (step==_Step.district) { context.pop(); return; }
    setState(() {
      if (step==_Step.neighborhood) { step=_Step.district; district=null; }
      else if (step==_Step.street) { step=_Step.neighborhood; neighborhood=null; }
      else { step=_Step.street; building=null; }
      controller.clear(); results=[]; error=null;
    });
  }

  Future<void> maps(PlaceResult p) async {
    final uri=Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lon}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:bg,
    appBar:AppBar(backgroundColor:bg,foregroundColor:Colors.white,title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),leading:IconButton(onPressed:back,icon:const Icon(Icons.arrow_back_ios_new_rounded)),actions:[IconButton(onPressed:()=>context.go('/'),icon:const Icon(Icons.home_outlined))]),
    body:ListView(padding:const EdgeInsets.fromLTRB(16,4,16,28),children:[
      _Crumbs(district:district, neighborhood:neighborhood, street:street),
      const SizedBox(height:14),
      if(step==_Step.district) ...[
        const Text('Adresin bulunduğu ilçeyi seçin',style:TextStyle(color:Color(0xFF9FB0BC))),
        const SizedBox(height:12),
        ...districts.map((d)=>_RowTile(text:d,onTap:()=>selectDistrict(d))),
      ] else ...[
        TextField(controller:controller,onSubmitted:(_)=>search(),style:const TextStyle(color:Colors.white),decoration:InputDecoration(hintText:hint,prefixIcon:const Icon(Icons.search_rounded),suffixIcon:IconButton(onPressed:search,icon:const Icon(Icons.arrow_forward_rounded)),filled:true,fillColor:panel,border:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:BorderSide.none))),
        const SizedBox(height:12),
        if(loading) const Padding(padding:EdgeInsets.all(24),child:Center(child:CircularProgressIndicator(color:red))),
        if(error!=null) _Info(icon:Icons.error_outline,text:error!),
        if(!loading&&error==null&&results.isEmpty&&building==null) const _Info(icon:Icons.search_rounded,text:'Arama yaparak bir sonraki adımı açın.'),
        ...results.map((p)=>_ResultTile(place:p,onTap:()=>selectResult(p))),
        if(building!=null) ...[
          const SizedBox(height:8),
          _BuildingCard(place:building!,onDirections:()=>maps(building!)),
        ],
      ],
    ]),
  );
}

class _Crumbs extends StatelessWidget { const _Crumbs({this.district,this.neighborhood,this.street}); final String? district,neighborhood,street; @override Widget build(BuildContext c)=>Wrap(spacing:6,runSpacing:6,children:[const Icon(Icons.location_city_outlined,color:Color(0xFF9FB0BC),size:18),if(district!=null)_Chip(district!),if(neighborhood!=null)_Chip(neighborhood!),if(street!=null)_Chip(street!),const _Chip('Bina')]); }
class _Chip extends StatelessWidget { const _Chip(this.text); final String text; @override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:const Color(0xFF14232D),borderRadius:BorderRadius.circular(20)),child:Text(text,style:const TextStyle(color:Color(0xFFCBD5DB),fontSize:12,fontWeight:FontWeight.w700))); }
class _RowTile extends StatelessWidget { const _RowTile({required this.text,required this.onTap}); final String text; final VoidCallback onTap; @override Widget build(BuildContext c)=>Card(color:const Color(0xFF14232D),margin:const EdgeInsets.only(bottom:7),elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),child:ListTile(onTap:onTap,leading:const Icon(Icons.folder_open_rounded,color:Color(0xFF2DBF9E)),title:Text(text,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700)),trailing:const Icon(Icons.chevron_right_rounded,color:Color(0xFF718491)))); }
class _ResultTile extends StatelessWidget { const _ResultTile({required this.place,required this.onTap}); final PlaceResult place; final VoidCallback onTap; @override Widget build(BuildContext c)=>Card(color:const Color(0xFF14232D),margin:const EdgeInsets.only(bottom:7),elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),child:ListTile(onTap:onTap,leading:const Icon(Icons.folder_outlined,color:Color(0xFF2DBF9E)),title:Text(place.name,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700)),subtitle:Text(place.address,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Color(0xFF9FB0BC))),trailing:const Icon(Icons.chevron_right_rounded,color:Color(0xFF718491)))); }
class _BuildingCard extends StatelessWidget { const _BuildingCard({required this.place,required this.onDirections}); final PlaceResult place; final VoidCallback onDirections; @override Widget build(BuildContext c){final p=LatLng(place.lat,place.lon);return Card(color:const Color(0xFF14232D),clipBehavior:Clip.antiAlias,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(height:210,child:FlutterMap(options:MapOptions(initialCenter:p,initialZoom:16),children:[TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'com.kayserirehber.app'),MarkerLayer(markers:[Marker(point:p,width:48,height:48,child:const Icon(Icons.location_pin,color:Color(0xFFFF4650),size:48))])])),Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(place.name,style:const TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w800)),const SizedBox(height:6),Text(place.address,style:const TextStyle(color:Color(0xFF9FB0BC),height:1.3)),const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:onDirections,icon:const Icon(Icons.navigation_rounded),label:const Text('Yol Tarifi'),style:FilledButton.styleFrom(backgroundColor:const Color(0xFFFF4650))))]))]));}}
class _Info extends StatelessWidget { const _Info({required this.icon,required this.text}); final IconData icon; final String text; @override Widget build(BuildContext c)=>Card(color:const Color(0xFF14232D),child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Icon(icon,color:const Color(0xFF9FB0BC)),const SizedBox(width:10),Expanded(child:Text(text,style:const TextStyle(color:Color(0xFFCBD5DB))))]))); }
