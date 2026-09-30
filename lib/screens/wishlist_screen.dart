import 'package:flutter/material.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  static const cream=Color(0xFFFAF8F3), ink=Color(0xFF172033), blue=Color(0xFF2563EB), coral=Color(0xFFF97368);
  @override Widget build(BuildContext context){
    final products=[['Smooth Gel Pens','₹149',Icons.edit_rounded,blue],['A5 Premium Sketchbook','₹349',Icons.menu_book_rounded,Color(0xFF7C4DFF)],['Campus Drafting Set','₹499',Icons.straighten_rounded,coral],['Studio Marker Pack','₹599',Icons.palette_rounded,Color(0xFF198754)]];
    return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('Wishlist')),body:ListView.separated(padding:const EdgeInsets.all(18),itemCount:products.length,separatorBuilder:(_,__)=>const SizedBox(height:12),itemBuilder:(_,i){final p=products[i];return Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFE7E2D9))),child:Row(children:[
      Container(width:72,height:72,decoration:BoxDecoration(color:const Color(0xFFF5F3EE),borderRadius:BorderRadius.circular(16)),child:Icon(p[2] as IconData,color:p[3] as Color,size:35)),
      const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p[0] as String,style:const TextStyle(color:ink,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(p[1] as String,style:const TextStyle(color:blue,fontWeight:FontWeight.w900))])),
      IconButton(onPressed:(){},icon:const Icon(Icons.favorite_rounded,color:coral)),IconButton(onPressed:()=>Navigator.pushNamed(context,'/cart'),icon:const Icon(Icons.shopping_cart_outlined,color:blue)),
    ]);}));
  }
}
