import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/place_search_service.dart';

class PlaceCategoryPage extends StatefulWidget {
  const PlaceCategoryPage({super.key, required this.type});
  final String type;
  @override State<PlaceCategoryPage> createState() => _PlaceCategoryPageState();
}

class _PlaceCategoryPageState extends State<PlaceCategoryPage> {
  final service=PlaceSearchService();
  final searchController=TextEditingController();
  List<PlaceResult> results=const [];
  bool loading=false;
  String? error;

  static const definitions=<String,({String title,IconData icon,String query})>{
    'eczane':(title:'Eczaneler',icon:Icons.local_pharmacy,query:'eczane'),
    'noter':(title:'Noterler',icon:Icons.description,query:'noter'),
    'hastane':(title:'Hastaneler',icon:Icons.local_hospital,query:'hastane'),
    'taksi':(title:'Taksi Durakları',icon:Icons.local_taxi,query:'taksi durağı'),
    'cami':(title:'Camiler',icon:Icons.mosque,query:'cami'),
    'benzin':(title:'Benzin İstasyonları',icon:Icons.local_gas_station,query:'benzin istasyonu'),
    'market':(title:'Marketler',icon:Icons.shopping_cart,query:'market'),
    'firin':(title:'Fırınlar',icon:Icons.bakery_dining,query:'fırın'),
    'restoran':(title:'Restoranlar',icon:Icons.restaurant,query:'restoran'),
    'kafe':(title:'Kafeler',icon:Icons.local_cafe,query:'kafe'),
    'oto-servis':(title:'Oto Servis',icon:Icons.build,query:'oto servis'),
    'site':(title:'Siteler / Konut',icon:Icons.apartment,query:'site'),
  };

  @override void initState(){super.initState();WidgetsBinding.instance.addPostFrameCallback((_)=>load());}
  @override void dispose(){searchController.dispose();super.dispose();}

  Future<void> load() async {
    final definition=definitions[widget.type]; if(definition==null)return;
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
    final definition=definitions[widget.type]??(title:'Diğer Yerler',icon:Icons.more_horiz,query:'Kayseri');
    return Scaffold(
      backgroundColor:Colors.white,
      appBar:AppBar(
        backgroundColor:Colors.white,surfaceTintColor:Colors.transparent,title:Text(definition.title),
        leading:IconButton(icon:const Icon(Icons.arrow_back),onPressed:()=>context.pop()),
        actions:[IconButton(tooltip:'Ana sayfa',icon:const Icon(Icons.home_outlined),onPressed:()=>context.go('/'))],
      ),
      body:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,24),children:[
        TextField(
          controller:searchController,textInputAction:TextInputAction.search,onSubmitted:(_)=>load(),
          decoration:InputDecoration(
            filled:true,fillColor:const Color(0xFFF6F7F9),prefixIcon:const Icon(Icons.search),
            suffixIcon:IconButton(onPressed:load,icon:const Icon(Icons.arrow_forward)),hintText:'İlçe veya mahalle ile filtrele',
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none),
          ),
        ),
        const SizedBox(height:12),
        if(loading)const Padding(padding:EdgeInsets.all(24),child:Center(child:CircularProgressIndicator())),
        if(error!=null)Card(elevation:0,child:Padding(padding:const EdgeInsets.all(16),child:Text(error!))),
        if(!loading&&error==null&&results.isEmpty)const Card(elevation:0,child:Padding(padding:const EdgeInsets.all(16),child:Text('Bu kategori için sonuç bulunamadı.'))),
        ...results.map((place)=>Card(elevation:0,margin:const EdgeInsets.only(bottom:8),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14),side:BorderSide(color:Colors.grey.shade200)),child:ListTile(
          leading:CircleAvatar(child:Icon(definition.icon)),title:Text(place.name,style:const TextStyle(fontWeight:FontWeight.w600)),
          subtitle:Text(place.address,maxLines:2,overflow:TextOverflow.ellipsis),
          trailing:IconButton(tooltip:'Yol tarifi',onPressed:()=>directions(place),icon:const Icon(Icons.directions)),
        ))),
      ]),
    );
  }
}
