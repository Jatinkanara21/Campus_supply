import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override State<CartScreen> createState() => _CartScreenState();
}
class _CartScreenState extends State<CartScreen> {
  static const cream=Color(0xFFFAF8F3), ink=Color(0xFF172033), blue=Color(0xFF2563EB);
  final items=[
    ['Smooth Gel Pens','₹149',Icons.edit_rounded,2,blue],
    ['A5 Premium Sketchbook','₹349',Icons.menu_book_rounded,1,Color(0xFF7C4DFF)],
    ['Campus Drafting Set','₹499',Icons.straighten_rounded,1,Color(0xFFF97368)],
  ];
  @override Widget build(BuildContext context){
    return Scaffold(backgroundColor:cream,appBar:AppBar(title:const Text('Your Cart')),body:ListView(padding:const EdgeInsets.all(18),children:[
      ...items.asMap().entries.map((e)=>_item(e.key,e.value)),
      const SizedBox(height:16),
      TextField(decoration:InputDecoration(hintText:'Promo code',suffixIcon:TextButton(onPressed:(){},child:const Text('Apply')))),
      const SizedBox(height:20),
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFE7E2D9))),child:Column(children:[
        _row('Subtotal','₹1,146'),_row('Student savings','-₹100',color:const Color(0xFF198754)),_row('Delivery','Free'),const Divider(height:24),_row('Total','₹1,046',bold:true),
      ])),
      const SizedBox(height:18),
      SizedBox(height:54,child:ElevatedButton(onPressed:(){},child:const Text('Checkout →'))),
    ]));
  }
  Widget _item(int index,List item)=>Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFE7E2D9))),child:Row(children:[
    Container(width:72,height:72,decoration:BoxDecoration(color:const Color(0xFFF5F3EE),borderRadius:BorderRadius.circular(16)),child:Icon(item[2] as IconData,color:item[4] as Color,size:34)),
    const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item[0] as String,style:const TextStyle(color:ink,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(item[1] as String,style:const TextStyle(color:blue,fontWeight:FontWeight.w900))])),
    IconButton(onPressed:(){setState(()=>item[3]=((item[3] as int)-1).clamp(1,99));},icon:const Icon(Icons.remove_circle_outline)),Text(item[3].toString(),style:const TextStyle(fontWeight:FontWeight.w800)),IconButton(onPressed:(){setState(()=>item[3]=(item[3] as int)+1);},icon:const Icon(Icons.add_circle_outline)),
  ]));
  Widget _row(String a,String b,{bool bold=false,Color? color})=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Expanded(child:Text(a,style:TextStyle(color:color??const Color(0xFF707681),fontWeight:bold?FontWeight.w900:FontWeight.w500))),Text(b,style:TextStyle(color:color??ink,fontWeight:bold?FontWeight.w900:FontWeight.w700,fontSize:bold?18:14))]));
}
