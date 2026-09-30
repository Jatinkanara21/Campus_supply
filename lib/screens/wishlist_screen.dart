import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  static const cream=Color(0xFFFAF8F3), ink=Color(0xFF172033), blue=Color(0xFF2563EB), coral=Color(0xFFF97368), muted=Color(0xFF707681);

  @override Widget build(BuildContext context) {
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null) return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('Wishlist')),body:Center(child:FilledButton(onPressed:()=>Navigator.pushNamed(context,'/login'),child:const Text('Sign in to view wishlist'))));
    return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('Wishlist',style:TextStyle(fontWeight:FontWeight.w900))),body:StreamBuilder<List<Map<String,dynamic>>>(
      stream:FirestoreDatabase.instance.watchWishlist(uid),
      builder:(context,snapshot){
        if(snapshot.hasError) return const Center(child:Text('Unable to load wishlist.'));
        if(!snapshot.hasData) return const Center(child:CircularProgressIndicator());
        final wishes=snapshot.data!;
        if(wishes.isEmpty) return const Center(child:Text('Your wishlist is empty.'));
        return StreamBuilder<List<Map<String,dynamic>>>(
          stream:FirestoreDatabase.instance.watchProducts(),
          builder:(context,products){
            if(!products.hasData) return const Center(child:CircularProgressIndicator());
            final byId={for(final p in products.data!) p['id'].toString():p};
            return ListView.separated(padding:const EdgeInsets.all(18),itemCount:wishes.length,separatorBuilder:(_,__)=>const SizedBox(height:12),itemBuilder:(_,i){
              final w=wishes[i]; final p=byId[w['productId']?.toString()]; final id=w['productId']?.toString();
              return Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFE7E2D9))),child:Row(children:[
                Container(width:72,height:72,decoration:BoxDecoration(color:const Color(0xFFF5F3EE),borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.inventory_2_rounded,color:blue,size:35)),
                const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((p?['name']??'Product').toString(),style:const TextStyle(color:ink,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text('₹${((p?['price'] as num?)?.toDouble()??0).toStringAsFixed(0)}',style:const TextStyle(color:blue,fontWeight:FontWeight.w900))])),
                IconButton(onPressed:id==null?null:()=>FirestoreDatabase.instance.toggleWishlist(uid:uid,productId:id),icon:const Icon(Icons.favorite_rounded,color:coral)),
                IconButton(onPressed:id==null?null:()=>FirestoreDatabase.instance.addToCart(uid:uid,productId:id),icon:const Icon(Icons.shopping_cart_outlined,color:blue)),
              ]));
            });
          },
        );
      },
    ));
  }
}
