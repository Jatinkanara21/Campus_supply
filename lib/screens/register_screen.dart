import 'package:flutter/material.dart';
import '../widgets/campus_logo.dart';

class RegisterScreen extends StatefulWidget { const RegisterScreen({super.key}); @override State<RegisterScreen> createState()=>_RegisterScreenState(); }
class _RegisterScreenState extends State<RegisterScreen> {
  bool hidePassword=true;
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:460),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const CampusLogo(size:58,showWordmark:true),const SizedBox(height:42),
    const Text('Join CampusSupply',style:TextStyle(fontSize:34,fontWeight:FontWeight.w800,letterSpacing:-1.1,color:Color(0xFF17172B))),
    const SizedBox(height:8),const Text('Create one account for your books, bags and campus essentials.',style:TextStyle(color:Color(0xFF77778A),fontSize:15)),const SizedBox(height:30),
    const TextField(decoration:InputDecoration(labelText:'Full name',hintText:'Your name',prefixIcon:Icon(Icons.person_outline_rounded))),const SizedBox(height:16),
    const TextField(keyboardType:TextInputType.emailAddress,decoration:InputDecoration(labelText:'Email address',hintText:'you@example.com',prefixIcon:Icon(Icons.mail_outline_rounded))),const SizedBox(height:16),
    TextField(obscureText:hidePassword,decoration:InputDecoration(labelText:'Password',hintText:'Create a password',prefixIcon:const Icon(Icons.lock_outline_rounded),suffixIcon:IconButton(onPressed:()=>setState(()=>hidePassword=!hidePassword),icon:Icon(hidePassword?Icons.visibility_outlined:Icons.visibility_off_outlined)))),const SizedBox(height:24),
    SizedBox(width:double.infinity,height:56,child:ElevatedButton(onPressed:()=>Navigator.pushReplacementNamed(context,'/home'),style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFF6D4AFF),foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),child:const Text('Create account',style:TextStyle(fontSize:16,fontWeight:FontWeight.w700)))),const SizedBox(height:22),
    Center(child:TextButton(onPressed:()=>Navigator.pushNamed(context,'/login'),child:const Text('Already have an account? Sign in'))),
  ]))))));
}
}
