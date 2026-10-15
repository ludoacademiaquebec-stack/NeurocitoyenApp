import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/app_scaffold.dart';

class CursusDetailUserScreen extends StatefulWidget {
  final Map<String, dynamic> cursus;
  const CursusDetailUserScreen({super.key, required this.cursus});
  @override
  State<CursusDetailUserScreen> createState() => _CursusDetailUserScreenState();
}

class _CursusDetailUserScreenState extends State<CursusDetailUserScreen> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _modules = [];
  bool _loading = true;

  @override
  void initState(){ super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final raw = await _db.from('cursus_modules').select().eq('cursus_id', widget.cursus['id']).eq('actif', true).order('numero', ascending: true);
      final sorted = List<Map<String, dynamic>>.from(raw)..sort((a,b)=> (a['numero'] as int? ?? 0).compareTo(b['numero'] as int? ?? 0));
      setState(()=> _modules = sorted);
    } catch(e){ debugPrint('load error $e'); }
    setState(()=> _loading=false);
  }

  @override
  Widget build(BuildContext context){
    return AppScaffold(
      title: widget.cursus['titre'] ?? widget.cursus['nom'] ?? 'Cursus',
      child: _loading ? const Center(child: CircularProgressIndicator()) :
      ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _modules.length,
        itemBuilder: (c,i){
          final m=_modules[i];
          return Card(
            color: const Color(0xFF101845),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: const Color(0xFFFFC400), child: Text('${m['numero']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
              title: Text(m['titre'] ?? 'Module ${m['numero']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Module ${m['numero']} / ${_modules.length}', style: const TextStyle(color: Colors.white54, fontSize:11)),
            ),
          );
        },
      ),
    );
  }
}
