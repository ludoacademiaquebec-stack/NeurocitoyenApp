import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
class PolesScreen extends StatelessWidget {
  const PolesScreen({super.key});
  @override Widget build(BuildContext context) {
    final poles = ['Éducation', 'Santé', 'Agriculture', 'Tech', 'Économie', 'Culture', 'Gouvernance'];
    return AppScaffold(title: 'Pôles - 21 Pôles', child: GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: poles.length, itemBuilder: (c,i)=> Container(decoration: BoxDecoration(color: const Color(0xFF0E3A3D), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE0A82E).withOpacity(0.5))), child: Center(child: Text(poles[i], style: const TextStyle(color: Color(0xFFE0A82E), fontWeight: FontWeight.bold))))));
  }
}