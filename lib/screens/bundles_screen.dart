import 'package:flutter/material.dart';

class BundlesScreen extends StatelessWidget {
  const BundlesScreen({super.key});
  static const cream=Color(0xFFFAF8F3), ink=Color(0xFF172033), blue=Color(0xFF2563EB), coral=Color(0xFFF97368);
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('Student Bundles')),body:ListView(padding:const EdgeInsets.all(18),children:[
    const Text('Built for busy students.',style:TextStyle(color:ink,fontSize:28,fontWeight:FontWeight.w900,letterSpacing:-.8)),
    const SizedBox(height:6),const Text('Curated kits that save time, money, and a last-minute campus run.',style:TextStyle(color:Color(0xFF707681),height:1.4)),
    const SizedBox(height:20),
    _card('Architecture Starter Kit','Sketchbook + pencils + ruler + drafting essentials','₹2,499','Save 15%',Icons.architecture_rounded,blue),
    _card('First-Year Essentials','Notebooks + pens + planner + everyday study tools','₹999','Save 15%',Icons.auto_stories_rounded,coral),
    _card('Design Student Kit','Markers + grid pad + sketching essentials','₹1,499','Save 15%',Icons.palette_rounded,Color(0xFF7C4DFF)),
    _card('Exam Survival Kit','Highlighters + sticky notes + notebooks + pens','₹699','Save 15%',Icons.school_rounded,Color(0xFF198754)),
  ]));
  static Widget _card(String title,String sub,String price,String badge,IconData icon,Color accent)=>Container(margin:const EdgeInsets.only(bottom:14),padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFE7E2D9))),child:Row(children:[
    Container(width:90,height:100,decoration:BoxDecoration(color:Color.alphaBlend(accent.withValues(alpha:.10),Colors.white),borderRadius:BorderRadius.circular(18)),child:Icon(icon,color:accent,size:48)),
    const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:coral,borderRadius:BorderRadius.circular(9)),child:Text(badge,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900))),const SizedBox(height:7),Text(title,style:const TextStyle(color:ink,fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(sub,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Color(0xFF707681),fontSize:11.5,height:1.3)),const SizedBox(height:6),Text(price,style:const TextStyle(color:blue,fontSize:17,fontWeight:FontWeight.w900))])),
  ]));
}
