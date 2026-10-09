import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/app_image.dart';
import '../database/firestore_database.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  static const cream=Color(0xFFF5F7FB), ink=Color(0xFF172554), blue=Color(0xFF3157D5), coral=Color(0xFFFF8066), muted=Color(0xFF64748B), border=Color(0xFFE2E8F0);

  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('Wishlist')),body:Center(child:FilledButton(onPressed:()=>Navigator.pushNamed(context,'/login'),child:const Text('Sign in to view wishlist'))));
    return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('Wishlist',style:TextStyle(fontWeight:FontWeight.w900))),body:StreamBuilder<List<Map<String,dynamic>>>(
      stream:FirestoreDatabase.instance.watchWishlist(uid),
      builder:(context,snapshot){
        if(snapshot.hasError)return const Center(child:Text('Unable to load wishlist.'));
        if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
        final wishes=snapshot.data!;
        if(wishes.isEmpty)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.favorite_border_rounded,size:64,color:coral),const SizedBox(height:14),const Text('Nothing saved yet',style:TextStyle(color:ink,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:8),const Text('Tap the heart on products you want to keep.',style:TextStyle(color:muted)),const SizedBox(height:18),FilledButton(onPressed:()=>Navigator.pushNamed(context,'/shop'),child:const Text('Explore products'))]));
        return StreamBuilder<List<Map<String,dynamic>>>(stream:FirestoreDatabase.instance.watchProducts(),builder:(context,products){
          if(!products.hasData)return const Center(child:CircularProgressIndicator());
          final byId={for(final p in products.data!)p['id'].toString():p};
          return LayoutBuilder(builder:(context,constraints){
            final columns=constraints.maxWidth>=1000?3:constraints.maxWidth>=650?2:1;
            return GridView.builder(padding:const EdgeInsets.all(18),itemCount:wishes.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,crossAxisSpacing:14,mainAxisSpacing:14,childAspectRatio:1.35),itemBuilder:(_,i){
              final id=wishes[i]['productId']?.toString();final p=byId[id];final image=(p?['imageUrl']??'').toString();
              return Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:border)),child:Row(children:[
                Container(width:90,height:110,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:const Color(0xFFF4F2ED),borderRadius:BorderRadius.circular(16)),child: AppImage(
                  source: image,
                  fit: BoxFit.cover,
                  fallback: const Icon(
                    Icons.inventory_2_rounded,
                    color: blue,
                    size: 35,
                  ),
                )),
                const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((p?['name']??'Product').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:ink,fontWeight:FontWeight.w900)),const Spacer(),Text('₹${((p?['price'] as num?)?.toDouble()??0).toStringAsFixed(0)}',style:const TextStyle(color:blue,fontSize:18,fontWeight:FontWeight.w900)),Row(children:[IconButton(onPressed:id==null?null:()=>FirestoreDatabase.instance.toggleWishlist(uid:uid,productId:id),icon:const Icon(Icons.favorite_rounded,color:coral)),IconButton(onPressed:id==null?null:()=>FirestoreDatabase.instance.addToCart(uid:uid,productId:id),icon:const Icon(Icons.shopping_bag_outlined,color:blue))])]))]));
            });
          });
        });
      },
    ));
  }
}
