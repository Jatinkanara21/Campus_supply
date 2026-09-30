import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});
  @override State<ProductDetailScreen> createState()=>_ProductDetailScreenState();
}
class _ProductDetailScreenState extends State<ProductDetailScreen>{
  static const cream=Color(0xFFFAF8F3), ink=Color(0xFF172033), blue=Color(0xFF2563EB), yellow=Color(0xFFFACC15), coral=Color(0xFFF97368);
  int quantity=1;
  int selectedColor=0;
  @override Widget build(BuildContext context){
    const colors=[Color(0xFF172033),blue,coral,Color(0xFF8A7B68)];
    return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('Product Details'),actions:[IconButton(onPressed:()=>Navigator.pushNamed(context,'/wishlist'),icon:const Icon(Icons.favorite_border_rounded))]),body:ListView(padding:const EdgeInsets.fromLTRB(18,4,18,30),children:[
      Container(height:300,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(26),border:Border.all(color:const Color(0xFFE7E2D9))),child:Stack(children:[
        Center(child:Icon(Icons.menu_book_rounded,size:150,color:blue.withValues(alpha:.18))),
        const Center(child:Icon(Icons.menu_book_rounded,size:110,color:blue)),
        Positioned(top:14,left:14,child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:yellow,borderRadius:BorderRadius.circular(10)),child:const Text('Popular',style:TextStyle(color:ink,fontSize:10,fontWeight:FontWeight.w900)))),
      ])),
      const SizedBox(height:20),
      const Text('A5 Premium Sketchbook',style:TextStyle(color:ink,fontSize:27,fontWeight:FontWeight.w900,letterSpacing:-.7)),
      const SizedBox(height:7),
      const Row(children:[Icon(Icons.star_rounded,color:Color(0xFFF4B400),size:19),SizedBox(width:4),Text('4.9  •  184 reviews',style:TextStyle(color:Color(0xFF707681),fontWeight:FontWeight.w600))]),
      const SizedBox(height:12),
      const Text('₹349',style:TextStyle(color:blue,fontSize:25,fontWeight:FontWeight.w900)),
      const SizedBox(height:22),
      const Text('Choose a cover color',style:TextStyle(color:ink,fontSize:16,fontWeight:FontWeight.w900)),
      const SizedBox(height:10),
      Row(children:List.generate(colors.length,(i)=>GestureDetector(onTap:()=>setState(()=>selectedColor=i),child:Container(width:40,height:40,margin:const EdgeInsets.only(right:12),decoration:BoxDecoration(color:colors[i],shape:BoxShape.circle,border:Border.all(color:selectedColor==i?blue:Colors.white,width:selectedColor==i?3:1)))))),
      const SizedBox(height:22),
      const Text('About this product',style:TextStyle(color:ink,fontSize:16,fontWeight:FontWeight.w900)),
      const SizedBox(height:7),
      const Text('A smooth, premium sketchbook for lecture notes, concept sketches and design work. Compact enough for campus, roomy enough for your next big idea.',style:TextStyle(color:Color(0xFF707681),height:1.5)),
      const SizedBox(height:20),
      Row(children:[const Text('Quantity',style:TextStyle(color:ink,fontWeight:FontWeight.w800)),const Spacer(),IconButton(onPressed:()=>setState(()=>quantity=quantity>1?quantity-1:1),icon:const Icon(Icons.remove_circle_outline)),Text(quantity.toString(),style:const TextStyle(color:ink,fontWeight:FontWeight.w900)),IconButton(onPressed:()=>setState(()=>quantity++),icon:const Icon(Icons.add_circle_outline))]),
      const SizedBox(height:10),
      SizedBox(height:54,child:ElevatedButton.icon(onPressed:()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Added to cart'))),icon:const Icon(Icons.shopping_cart_outlined),label:const Text('Add to Cart'))),
    ]));
  }
}
