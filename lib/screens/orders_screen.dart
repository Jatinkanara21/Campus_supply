import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  static const cream=Color(0xFFF5F7FB), ink=Color(0xFF172554), blue=Color(0xFF3157D5), green=Color(0xFF198754), muted=Color(0xFF64748B), border=Color(0xFFE2E8F0);

  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('Orders')),body:Center(child:FilledButton(onPressed:()=>Navigator.pushNamed(context,'/login'),child:const Text('Sign in to view orders'))));
    return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('My orders',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:()=>Navigator.pushNamed(context,'/shop'),icon:const Icon(Icons.add_shopping_cart_rounded))]),body:StreamBuilder<List<Map<String,dynamic>>>(
      stream:FirestoreDatabase.instance.watchOrders(uid),
      builder:(context,snapshot){
        if(snapshot.hasError)return const Center(child:Text('Unable to load orders.'));
        if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
        final orders=snapshot.data!;
        if(orders.isEmpty)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.receipt_long_outlined,size:64,color:blue),const SizedBox(height:14),const Text('No orders yet',style:TextStyle(color:ink,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:8),const Text('Your completed purchases will appear here.',style:TextStyle(color:muted)),const SizedBox(height:18),FilledButton(onPressed:()=>Navigator.pushNamed(context,'/shop'),child:const Text('Start shopping'))]));
        return ListView.separated(padding:const EdgeInsets.all(18),itemCount:orders.length,separatorBuilder:(_,__)=>const SizedBox(height:12),itemBuilder:(_,i){
          final o=orders[i];final status=(o['status']??'pending').toString();final done=status=='delivered';final color=done?green:blue;
          return Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Expanded(child:Text('#${o['id']}',style:const TextStyle(color:ink,fontWeight:FontWeight.w900))),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:color.withValues(alpha:.12),borderRadius:BorderRadius.circular(10)),child:Text(status.toUpperCase(),style:TextStyle(color:color,fontSize:10,fontWeight:FontWeight.w900)))]),
            const SizedBox(height:12),Text('₹${((o['total'] as num?)?.toDouble()??0).toStringAsFixed(0)}',style:const TextStyle(color:blue,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text('${(o['items'] as List?)?.length??0} item line(s)',style:const TextStyle(color:muted)),
            const SizedBox(height:16),LinearProgressIndicator(value:done?1:.5,minHeight:7,borderRadius:BorderRadius.circular(8),backgroundColor:const Color(0xFFE8EEFF),color:color),
          ]));
        });
      },
    ));
  }
}
