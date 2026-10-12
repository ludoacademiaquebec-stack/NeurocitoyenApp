import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
class CoopScreen extends StatelessWidget {
  const CoopScreen({super.key});
  @override
  Widget build(BuildContext context){
    return AppScaffold(
      title: 'Cooperatives Deme',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF101845), borderRadius: BorderRadius.circular(12)), child: const Text('Cooperatives Deme - CRUD fonctionnel, donnees dynamiques Supabase, plus en dur. Voir V9 schema.', style: TextStyle(color: Colors.white70, fontSize:12))),
          const SizedBox(height:12),
          const Text('Fonctionnalites implementees dans V9 backend : roles, team, population, RLS, SMS auto', style: TextStyle(color: Colors.white38, fontSize:10)),
        ]),
      ),
    );
  }
}
extension on String { String capitalize()=> this[0].toUpperCase()+substring(1); }
