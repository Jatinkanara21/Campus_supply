import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState()=>_ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen>{
  static const cream=Color(0xFFFAF8F3), ink=Color(0xFF172033), blue=Color(0xFF2563EB), yellow=Color(0xFFFACC15);
  String name='Student';
  @override void initState(){super.initState();_load();}
  Future<void> _load() async{final n=await AuthService.userName();if(mounted)setState(()=>name=n);}
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('My Profile')),body:ListView(padding:const EdgeInsets.all(18),children:[
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:blue,borderRadius:BorderRadius.circular(24)),child:Row(children:[
      Container(width:64,height:64,decoration:const BoxDecoration(color:yellow,shape:BoxShape.circle),child:const Icon(Icons.person_rounded,color:ink,size:34)),
      const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:4),const Text('Student account',style:TextStyle(color:Color(0xFFDDE8FF)))])),
    ])),
    const SizedBox(height:16),
    Row(children:[_stat('12','Orders'),_stat('5','Wishlist'),_stat('320','Points')]),
    const SizedBox(height:18),
    ...[
      (Icons.receipt_long_outlined,'My Orders','Track your purchases'),
      (Icons.favorite_border_rounded,'Wishlist','Your saved essentials'),
      (Icons.location_on_outlined,'Addresses','Manage delivery details'),
      (Icons.help_outline_rounded,'Help & Support','Questions? We can help'),
      (Icons.settings_outlined,'Settings','App preferences'),
    ].map((x)=>Container(margin:const EdgeInsets.only(bottom:9),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFE7E2D9))),child:ListTile(leading:Icon(x.$1,color:blue),title:Text(x.$2,style:const TextStyle(color:ink,fontWeight:FontWeight.w800)),subtitle:Text(x.$3,style:const TextStyle(color:Color(0xFF707681),fontSize:12)),trailing:const Icon(Icons.chevron_right_rounded,color:Color(0xFF9AA0AA))))),
  ]));
  Widget _stat(String n,String label)=>Expanded(child:Container(margin:const EdgeInsets.only(right:8),padding:const EdgeInsets.symmetric(vertical:15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFFE7E2D9))),child:Column(children:[Text(n,style:const TextStyle(color:ink,fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(label,style:const TextStyle(color:Color(0xFF707681),fontSize:11))])));
}
