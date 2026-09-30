import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firestore_database.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  static const cream=Color(0xFFFAF8F3), ink=Color(0xFF172033), blue=Color(0xFF2563EB), muted=Color(0xFF707681), border=Color(0xFFE7E2D9);

  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _authScaffold(context);
    }
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.w900))),
      body: StreamBuilder<List<Map<String,dynamic>>>(
        stream: FirestoreDatabase.instance.watchCart(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Unable to load your cart.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final cart = snapshot.data!;
          if (cart.isEmpty) return _empty(context);
          return StreamBuilder<List<Map<String,dynamic>>>(
            stream: FirestoreDatabase.instance.watchProducts(),
            builder: (context, productsSnap) {
              if (!productsSnap.hasData) return const Center(child: CircularProgressIndicator());
              final byId = {for (final p in productsSnap.data!) p['id'].toString(): p};
              double total=0;
              for(final item in cart){ final p=byId[item['productId']?.toString()]; total += ((p?['price'] as num?)?.toDouble() ?? 0) * ((item['quantity'] as num?)?.toInt() ?? 1); }
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  ...cart.map((item) => _item(context, uid, item, byId[item['productId']?.toString()])),
                  const SizedBox(height: 14),
                  Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(20),border: Border.all(color:border)), child: Column(children: [
                    _row('Subtotal','₹${total.toStringAsFixed(0)}'),
                    _row('Delivery','Free'),
                    const Divider(height:24),
                    _row('Total','₹${total.toStringAsFixed(0)}',bold:true),
                  ])),
                  const SizedBox(height:18),
                  SizedBox(height:54,child:ElevatedButton(onPressed:()=>Navigator.pushNamed(context,'/checkout',arguments:{'total':total}),child:const Text('Checkout →'))),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _item(BuildContext context,String uid,Map<String,dynamic> item,Map<String,dynamic>? p){
    final qty=(item['quantity'] as num?)?.toInt()??1;
    final name=(p?['name']??'Product').toString();
    final price=(p?['price'] as num?)?.toDouble()??0;
    return Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:border)),child:Row(children:[
      Container(width:72,height:72,decoration:BoxDecoration(color:const Color(0xFFF5F3EE),borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.inventory_2_rounded,color:blue,size:34)),
      const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,style:const TextStyle(color:ink,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text('₹${price.toStringAsFixed(0)}',style:const TextStyle(color:blue,fontWeight:FontWeight.w900))])),
      IconButton(onPressed:()=>FirestoreDatabase.instance.updateCartQuantity(uid:uid,productId:item['productId'].toString(),quantity:qty-1),icon:const Icon(Icons.remove_circle_outline)),
      Text('$qty',style:const TextStyle(fontWeight:FontWeight.w800)),
      IconButton(onPressed:()=>FirestoreDatabase.instance.updateCartQuantity(uid:uid,productId:item['productId'].toString(),quantity:qty+1),icon:const Icon(Icons.add_circle_outline)),
    ]));
  }

  Widget _empty(BuildContext context)=>Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.shopping_bag_outlined,size:64,color:blue),const SizedBox(height:14),const Text('Your cart is empty',style:TextStyle(color:ink,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:8),const Text('Add something from the shop to get started.',textAlign:TextAlign.center,style:TextStyle(color:muted)),const SizedBox(height:18),FilledButton(onPressed:()=>Navigator.pushNamed(context,'/shop'),child:const Text('Browse shop'))]));

  Widget _authScaffold(BuildContext context)=>Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('Your Cart')),body:Center(child:FilledButton(onPressed:()=>Navigator.pushNamed(context,'/login'),child:const Text('Sign in to view cart'))));

  Widget _row(String a,String b,{bool bold=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Expanded(child:Text(a,style:TextStyle(color:muted,fontWeight:bold?FontWeight.w900:FontWeight.w500))),Text(b,style:TextStyle(color:ink,fontWeight:bold?FontWeight.w900:FontWeight.w700,fontSize:bold?18:14))]));
}
