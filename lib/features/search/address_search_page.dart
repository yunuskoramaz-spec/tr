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

  String get title => switch (step) { _Step.district => 'İlçe Seçin', _Step.neighborhood => 'Mahalle Seçin', _Step.street => 'Cadde / Sokak Seçin', _Step.building => 'Bina / İşletme Seçin' };
  String get hint => switch (step) { _Step.neighborhood => 'Mahalle ara...', _Step.street => 'Cadde veya sokak ara...', _Step.building => 'Bina no, bina adı veya dükkan ara...', _Step.district => 'İlçe ara...' };

  List<PlaceResult> get visibleResults {
    final q = _normalize(controller.text);
    if (q.isEmpty) return results;
    return results.where((p) => _normalize('${p.name} ${p.address}').contains(q)).toList(growable: false);
  }

  @override void dispose() { controller.dispose(); super.dispose(); }

  Future<void> selectDistrict(String value) async {
    setState(() { district=value; neighborhood=null; street=null; building=null; results=[]; controller.clear(); step=_Step.neighborhood; error=null; loading=true; });
    try {
      final data = await service.searchNeighborhoods(value);
      if (mounted) setState(() { results=data; loading=false; });
    } catch (e) { if (mounted) setState(() { error=_cleanError(e); loading=false; }); }
  }

  Future<void> selectNeighborhood(PlaceResult p) async {
    setState(() { neighborhood=p.name; street=null; building=null; results=[]; controller.clear(); step=_Step.street; error=null; loading=true; });
    try {
      final data = await service.searchStreets(district!, p.name);
      if (mounted) setState(() { results=data; loading=false; });
    } catch (e) { if (mounted) setState(() { error=_cleanError(e); loading=false; }); }
  }

  Future<void> selectStreet(PlaceResult p) async {
    setState(() { street=p.name; building=null; results=[]; controller.clear(); step=_Step.building; error=null; loading=true; });
    try {
      final data = await service.searchStreetPlaces(district!, neighborhood!, p.name);
      if (mounted) setState(() { results=data; loading=false; });
    } catch (e) { if (mounted) setState(() { error=_cleanError(e); loading=false; }); }
  }

  void selectBuilding(PlaceResult p) => setState(() { building=p; controller.clear(); error=null; });

  Future<void> retry() async {
    if (step == _Step.neighborhood && district != null) return selectDistrict(district!);
    if (step == _Step.street && district != null && neighborhood != null) return selectNeighborhood(PlaceResult(name: neighborhood!, address: '', lat: 0, lon: 0));
    if (step == _Step.building && district != null && neighborhood != null && street != null) return selectStreet(PlaceResult(name: street!, address: '', lat: 0, lon: 0));
  }

  void back() {
    if (step==_Step.district) { context.pop(); return; }
    setState(() {
      if (step==_Step.neighborhood) { step=_Step.district; district=null; }
      else if (step==_Step.street) { step=_Step.neighborhood; neighborhood=null; }
      else { step=_Step.street; street=null; building=null; }
      controller.clear(); results=[]; error=null;
    });
  }

  Future<void> maps(PlaceResult p) async {
    final uri=Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lon}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override Widget build(BuildContext context) {
    final list = visibleResults;
    return Scaffold(
      backgroundColor:bg,
      appBar:AppBar(backgroundColor:bg,foregroundColor:Colors.white,title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),leading:IconButton(onPressed:back,icon:const Icon(Icons.arrow_back_ios_new_rounded)),actions:[IconButton(onPressed:()=>context.go('/'),icon:const Icon(Icons.home_outlined))]),
      body:ListView(padding:const EdgeInsets.fromLTRB(16,4,16,28),children:[
        _Crumbs(district:district, neighborhood:neighborhood, street:street),
        const SizedBox(height:14),
        if(step==_Step.district) ...[
          const Text('Kayseri ilçelerinden birini seçin',style:TextStyle(color:Color(0xFF9FB0BC))),
          const SizedBox(height:12),
          ...districts.map((d)=>_RowTile(text:d,onTap:()=>selectDistrict(d))),
        ] else ...[
          TextField(
            controller:controller,
            onChanged:(_)=>setState((){}),
            onSubmitted:(_)=>setState((){}),
            style:const TextStyle(color:Colors.white),
            decoration:InputDecoration(hintText:hint,prefixIcon:const Icon(Icons.search_rounded),suffixIcon:controller.text.isEmpty?const Icon(Icons.tune_rounded):IconButton(onPressed:()=>setState(controller.clear),icon:const Icon(Icons.close_rounded)),filled:true,fillColor:panel,border:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:BorderSide.none)),
          ),
          const SizedBox(height:12),
          if(loading) const Padding(padding:EdgeInsets.all(28),child:Center(child:CircularProgressIndicator(color:red))),
          if(!loading&&error!=null) _ErrorBox(text:error!,onRetry:retry),
          if(!loading&&error==null&&results.isNotEmpty) _CountBox(count:list.length,total:results.length,label:switch(step){_Step.neighborhood=>'mahalle',_Step.street=>'cadde / sokak',_Step.building=>'bina / işletme',_Step.district=>'ilçe'}),
          if(!loading&&error==null&&results.isEmpty) const _Info(icon:Icons.search_off_rounded,text:'Bu bölüm için henüz veri bulunamadı. Veri kaynağına bağlı olarak bazı adresler OpenStreetMap\'te kayıtlı olmayabilir.'),
          ...list.map((p)=>_ResultTile(place:p,step:step,onTap:()=>step==_Step.neighborhood?selectNeighborhood(p):step==_Step.street?selectStreet(p):selectBuilding(p))),
          if(building!=null) ...[
            const SizedBox(height:8),
            _BuildingCard(place:building!,onDirections:()=>maps(building!)),
          ],
        ],
      ]),
    );
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
  String _normalize(String v) => v.toLowerCase().replaceAll('ı','i').replaceAll('ş','s').replaceAll('ğ','g').replaceAll('ü','u').replaceAll('ö','o').replaceAll('ç','c').trim();
}

class _Crumbs extends StatelessWidget { const _Crumbs({this.district,this.neighborhood,this.street}); final String? district,neighborhood,street; @override Widget build(BuildContext c)=>Wrap(spacing:6,runSpacing:6,children:[const Icon(Icons.location_city_outlined,color:Color(0xFF9FB0BC),size:18),if(district!=null)_Chip(district!),if(neighborhood!=null)_Chip(neighborhood!),if(street!=null)_Chip(street!),const _Chip('Bina / İşletme')]); }
class _Chip extends StatelessWidget { const _Chip(this.text); final String text; @override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:const Color(0xFF14232D),borderRadius:BorderRadius.circular(20)),child:Text(text,style:const TextStyle(color:Color(0xFFCBD5DB),fontSize:12,fontWeight:FontWeight.w700))); }
class _RowTile extends StatelessWidget { const _RowTile({required this.text,required this.onTap}); final String text; final VoidCallback onTap; @override Widget build(BuildContext c)=>Card(color:const Color(0xFF14232D),margin:const EdgeInsets.only(bottom:7),elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),child:ListTile(onTap:onTap,leading:const Icon(Icons.folder_open_rounded,color:Color(0xFF2DBF9E)),title:Text(text,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700)),trailing:const Icon(Icons.chevron_right_rounded,color:Color(0xFF718491)))); }
class _ResultTile extends StatelessWidget { const _ResultTile({required this.place,required this.step,required this.onTap}); final PlaceResult place; final _Step step; final VoidCallback onTap; @override Widget build(BuildContext c){final icon=step==_Step.neighborhood?Icons.location_city_rounded:step==_Step.street?Icons.route_rounded:Icons.storefront_rounded;return Card(color:const Color(0xFF14232D),margin:const EdgeInsets.only(bottom:7),elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),child:ListTile(onTap:onTap,leading:Icon(icon,color:const Color(0xFF2DBF9E)),title:Text(place.name,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700)),subtitle:place.address.isEmpty?null:Text(place.address,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Color(0xFF9FB0BC))),trailing:const Icon(Icons.chevron_right_rounded,color:Color(0xFF718491))));} }
class _CountBox extends StatelessWidget { const _CountBox({required this.count,required this.total,required this.label}); final int count,total; final String label; @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Text(count==total?'$total $label bulundu':'$count / $total $label gösteriliyor',style:const TextStyle(color:Color(0xFF9FB0BC),fontSize:13,fontWeight:FontWeight.w600))); }
class _ErrorBox extends StatelessWidget { const _ErrorBox({required this.text,required this.onRetry}); final String text; final VoidCallback onRetry; @override Widget build(BuildContext c)=>Card(color:const Color(0xFF14232D),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Icon(Icons.error_outline,color:Color(0xFFFF4650)),const SizedBox(width:10),Expanded(child:Text(text,style:const TextStyle(color:Color(0xFFCBD5DB))))]),const SizedBox(height:10),OutlinedButton.icon(onPressed:onRetry,icon:const Icon(Icons.refresh),label:const Text('Tekrar Dene'))]))); }
class _BuildingCard extends StatelessWidget { const _BuildingCard({required this.place,required this.onDirections}); final PlaceResult place; final VoidCallback onDirections; @override Widget build(BuildContext c){final p=LatLng(place.lat,place.lon);return Card(color:const Color(0xFF14232D),clipBehavior:Clip.antiAlias,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(height:210,child:FlutterMap(options:MapOptions(initialCenter:p,initialZoom:17),children:[TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'com.kayserirehber.app'),MarkerLayer(markers:[Marker(point:p,width:48,height:48,child:const Icon(Icons.location_pin,color:Color(0xFFFF4650),size:48))])])),Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(place.name,style:const TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w800)),const SizedBox(height:6),Text(place.address,style:const TextStyle(color:Color(0xFF9FB0BC),height:1.3)),if(place.phone!=null)...[const SizedBox(height:6),Text(place.phone!,style:const TextStyle(color:Color(0xFF9FB0BC)) )],const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:onDirections,icon:const Icon(Icons.navigation_rounded),label:const Text('Yol Tarifi'),style:FilledButton.styleFrom(backgroundColor:const Color(0xFFFF4650))))]))]));}}
class _Info extends StatelessWidget { const _Info({required this.icon,required this.text}); final IconData icon; final String text; @override Widget build(BuildContext c)=>Card(color:const Color(0xFF14232D),child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Icon(icon,color:const Color(0xFF9FB0BC)),const SizedBox(width:10),Expanded(child:Text(text,style:const TextStyle(color:Color(0xFFCBD5DB))))]))); }
