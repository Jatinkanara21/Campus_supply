import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class BundlesScreen extends StatelessWidget {
  const BundlesScreen({super.key});
  static const cream=Color(0xFFFAF8F3), ink=Color(0xFF172033), blue=Color(0xFF2563EB), coral=Color(0xFFF97368), muted=Color(0xFF707681);

  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:cream,
    appBar:AppBar(title:const Text('Student Bundles',style:TextStyle(fontWeight:FontWeight.w900))),
    body:StreamBuilder<List<Map<String,dynamic>>>(
      stream:FirestoreDatabase.instance.watchBundles(),
      builder:(context,snapshot){
        if(snapshot.hasError)return const Center(child:Text('Unable to load bundles.'));
        if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
        final bundles=snapshot.data!;
        if(bundles.isEmpty)return ListView(padding:const EdgeInsets.all(18),children:[
          const Text('Built for busy students.',style:TextStyle(color:ink,fontSize:28,fontWeight:FontWeight.w900,letterSpacing:-.8)),
          const SizedBox(height:6),const Text('No bundles have been added yet. Admins can create them from the catalog manager.',style:TextStyle(color:muted,height:1.4))
        ]);
        return ListView(padding:const EdgeInsets.all(18),children:[
          const Text('Built for busy students.',style:TextStyle(color:ink,fontSize:28,fontWeight:FontWeight.w900,letterSpacing:-.8)),
          const SizedBox(height:6),const Text('Curated kits that save time, money, and a last-minute campus run.',style:TextStyle(color:muted,height:1.4)),
          const SizedBox(height:20),
          ...bundles.map((b)=>Container(margin:const EdgeInsets.only(bottom:14),padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFE7E2D9))),child:Row(children:[
            Container(width:90,height:100,decoration:BoxDecoration(color:const Color(0xFFEAF2FF),borderRadius:BorderRadius.circular(18)),child:const Icon(Icons.auto_awesome_rounded,color:blue,size:48)),
            const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:coral,borderRadius:BorderRadius.circular(9)),child:Text((b['badge']??'Student bundle').toString(),style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900))),
              const SizedBox(height:7),Text((b['name']??b['title']??'Bundle').toString(),style:const TextStyle(color:ink,fontSize:16,fontWeight:FontWeight.w900)),
              const SizedBox(height:4),Text((b['description']??'Curated campus essentials.').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted,fontSize:11.5,height:1.3)),
              if(b['price']!=null) ...[const SizedBox(height:6),Text('₹${b['price']}',style:const TextStyle(color:blue,fontSize:17,fontWeight:FontWeight.w900))]
            ]))
          ]))
        ]);
      },
    ),
  );
}
