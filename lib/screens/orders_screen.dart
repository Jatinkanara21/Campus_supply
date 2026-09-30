import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  static const cream=Color(0xFFFAF8F3), ink=Color(0xFF172033), blue=Color(0xFF2563EB), green=Color(0xFF198754), muted=Color(0xFF707681);

  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null) return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('My Orders')),body:Center(child:FilledButton(onPressed:()=>Navigator.pushNamed(context,'/login'),child:const Text('Sign in to view orders'))));
    return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('My Orders',style:TextStyle(fontWeight:FontWeight.w900))),body:StreamBuilder<List<Map<String,dynamic>>>(
      stream:FirestoreDatabase.instance.watchOrders(uid),
      builder:(context,snapshot){
        if(snapshot.hasError) return const Center(child:Text('Unable to load orders.'));
        if(!snapshot.hasData) return const Center(child:CircularProgressIndicator());
        final orders=snapshot.data!;
        if(orders.isEmpty) return const Center(child:Text('No orders yet.'));
        return ListView.separated(padding:const EdgeInsets.all(18),itemCount:orders.length,separatorBuilder:(_,__)=>const SizedBox(height:12),itemBuilder:(_,i){
          final o=orders[i]; final status=(o['status']??'pending').toString(); final color=status=='delivered'?green:blue;
          return Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFE7E2D9))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Expanded(child:Text('#${o['id']}',style:const TextStyle(color:ink,fontWeight:FontWeight.w900))),Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:color.withValues(alpha:.12),borderRadius:BorderRadius.circular(10)),child:Text(status,style:TextStyle(color:color,fontSize:11,fontWeight:FontWeight.w900)))]),
            const SizedBox(height:8),Text('Total: ₹${((o['total'] as num?)?.toDouble()??0).toStringAsFixed(0)}',style:const TextStyle(color:blue,fontSize:18,fontWeight:FontWeight.w900)),
            const SizedBox(height:8),Text('${(o['items'] as List?)?.length??0} item line(s)',style:const TextStyle(color:muted)),
          ]));
        });
      },
    ));
  }
}
