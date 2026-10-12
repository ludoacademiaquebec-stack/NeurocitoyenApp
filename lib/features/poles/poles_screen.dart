import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';

class PolesScreen extends StatelessWidget {
  const PolesScreen({super.key});
  @override Widget build(BuildContext context){
    final poles = [
      {'name':'Éducation & Neuro','icon':'🧠'},
      {'name':'Tech & IA','icon':'🤖'},
      {'name':'Économie & BCN','icon':'💰'},
      {'name':'Santé','icon':'🏥'},
      {'name':'Culture','icon':'🎭'},
      {'name':'Agriculture','icon':'🌾'},
      {'name':'Énergie','icon':'⚡'},
      {'name':'Gouvernance','icon':'⚖️'},
      {'name':'Diaspora','icon':'🌍'},
    ];
    return AppScaffold(
      title: 'Les 9 Pôles',
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, childAspectRatio:1.2, crossAxisSpacing:12, mainAxisSpacing:12),
        itemCount: poles.length,
        itemBuilder: (c,i)=> Container(
          decoration: BoxDecoration(color: const Color(0xFF101845), borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
            Text(poles[i]['icon']!, style: const TextStyle(fontSize:36)),
            const SizedBox(height:8),
            Text(poles[i]['name']!, textAlign:TextAlign.center, style: const TextStyle(color:Colors.white, fontWeight:FontWeight.bold, fontSize:12))
          ])
        ),
      ),
    );
  }
}