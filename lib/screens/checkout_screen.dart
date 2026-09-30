import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override State<CheckoutScreen> createState()=>_CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>{
  static const cream=Color(0xFFFAF8F3), ink=Color(0xFF172033), blue=Color(0xFF2563EB), muted=Color(0xFF707681), border=Color(0xFFE7E2D9);
  bool loading=false;
  final name=TextEditingController(), phone=TextEditingController(), address=TextEditingController(), city=TextEditingController(), pin=TextEditingController();

  @override void dispose(){name.dispose();phone.dispose();address.dispose();city.dispose();pin.dispose();super.dispose();}

  Future<void> _placeOrder(double total,List<Map<String,dynamic>> cart,Map<String,Map<String,dynamic>> byId) async{
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null){if(mounted)Navigator.pushNamed(context,'/login');return;}
    if(name.text.trim().isEmpty||address.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please enter your name and address.')));return;}
    setState(()=>loading=true);
    final items=cart.map((item){
      final p=byId[item['productId']?.toString()];
      return {'productId':item['productId'],'name':p?['name']??'Product','price':p?['price']??0,'quantity':item['quantity']??1};
    }).toList();
    try{
      await FirestoreDatabase.instance.createOrder(uid:uid,items:items,total:total,status:'pending');
      await FirestoreDatabase.instance.clearCart(uid);
      if(!mounted)return;
      Navigator.pushNamedAndRemoveUntil(context,'/orders',(_)=>false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Order placed successfully.')));
    }finally{if(mounted)setState(()=>loading=false);}
  }

  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('Checkout')),body:Center(child:FilledButton(onPressed:()=>Navigator.pushNamed(context,'/login'),child:const Text('Sign in to checkout'))));
    return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('Checkout',style:TextStyle(fontWeight:FontWeight.w900))),body:StreamBuilder<List<Map<String,dynamic>>>(
      stream:FirestoreDatabase.instance.watchCart(uid),
      builder:(context,cartSnap){
        if(!cartSnap.hasData)return const Center(child:CircularProgressIndicator());
        final cart=cartSnap.data!;
        return StreamBuilder<List<Map<String,dynamic>>>(
          stream:FirestoreDatabase.instance.watchProducts(),
          builder:(context,productSnap){
            if(!productSnap.hasData)return const Center(child:CircularProgressIndicator());
            final byId={for(final p in productSnap.data!)p['id'].toString():p};
            double total=0; for(final i in cart){final p=byId[i['productId']?.toString()];total+=((p?['price'] as num?)?.toDouble()??0)*((i['quantity'] as num?)?.toInt()??1);}
            return ListView(padding:const EdgeInsets.fromLTRB(18,8,18,30),children:[
              _section('Delivery details',[TextField(controller:name,decoration:const InputDecoration(labelText:'Full name')),const SizedBox(height:12),TextField(controller:phone,decoration:const InputDecoration(labelText:'Phone number')),const SizedBox(height:12),TextField(controller:address,decoration:const InputDecoration(labelText:'Address'),maxLines:3),const SizedBox(height:12),Row(children:[Expanded(child:TextField(controller:city,decoration:const InputDecoration(labelText:'City'))),const SizedBox(width:10),Expanded(child:TextField(controller:pin,decoration:const InputDecoration(labelText:'PIN code')))])]),
              const SizedBox(height:14),
              _section('Order summary',[_row('Items','${cart.length}'),_row('Delivery','Free'),const Divider(height:22),_row('Total','₹${total.toStringAsFixed(0)}',bold:true)]),
              const SizedBox(height:16),
              SizedBox(height:54,child:ElevatedButton(onPressed:loading?null:()=>_placeOrder(total,cart,byId),child:loading?const CircularProgressIndicator(color:Colors.white):const Text('Place order'))),
            ]);
          },
        );
      },
    ));
  }

  Widget _section(String title,List<Widget> children)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:ink,fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:12),...children]));
  Widget _row(String a,String b,{bool bold=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:Text(a,style:const TextStyle(color:muted))),Text(b,style:TextStyle(color:ink,fontWeight:bold?FontWeight.w900:FontWeight.w700,fontSize:bold?18:14))]));
}
