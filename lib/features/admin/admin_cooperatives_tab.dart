import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _C {
  static const nuit = Color(0xFF060A1F);
  static const nuit2 = Color(0xFF121845);
  static const nuit3 = Color(0xFF0B102E);
  static const or = Color(0xFFC4952B);
  static const orClair = Color(0xFFF0D9A0);
  static const vert = Color(0xFF0F7A3D);
  static const rouge = Color(0xFFB4473A);
  static const teal = Color(0xFF2F7D6D);
  static const violet = Color(0xFF7A4E8C);
}

TextStyle _serif(double size,
    {Color color = Colors.white, FontWeight weight = FontWeight.w700}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'serif'],
    fontSize: size,
    color: color,
    fontWeight: weight,
  );
}

class AdminCooperativesTab extends StatefulWidget {
  const AdminCooperativesTab({super.key});
  @override
  State<AdminCooperativesTab> createState() => _AdminCooperativesTabState();
}

class _AdminCooperativesTabState extends State<AdminCooperativesTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _coops = [];
  List<Map<String, dynamic>> _unites = [];
  String _filtreStatut = 'tous';

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final coops = await _db.from('cooperatives').select().order('created_at', ascending: false);
      final unites = await _db
          .from('unites_territoriales')
          .select()
          .eq('pays_code', 'BJ')
          .eq('actif', true)
          .order('nom');
      setState(() {
        _coops = List<Map<String, dynamic>>.from(coops);
        _unites = List<Map<String, dynamic>>.from(unites);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _toast('Erreur de chargement : $e', rouge: true);
    }
  }

  List<Map<String, dynamic>> get _coopsFiltrees {
    if (_filtreStatut == 'tous') return _coops;
    return _coops.where((c) => c['statut'] == _filtreStatut).toList();
  }

  Future<void> _saveCoop(Map<String, dynamic>? existing, Map<String, dynamic> data) async {
    try {
      if (existing == null) {
        await _db.from('cooperatives').insert(data);
      } else {
        await _db.from('cooperatives').update(data).eq('id', existing['id']);
      }
      await _load();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _toast('Erreur : $e', rouge: true);
    }
  }

  Future<void> _deleteCoop(Map<String, dynamic> coop) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: const Text('Supprimer cette coopérative ?', style: TextStyle(color: Colors.white)),
        content: Text('La coopérative "${coop['nom']}" sera définitivement supprimée.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler', style: TextStyle(color: Colors.white70))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.rouge),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (conf != true) return;
    try {
      await _db.from('cooperatives').delete().eq('id', coop['id']);
      await _load();
    } catch (e) {
      _toast('Erreur : $e', rouge: true);
    }
  }

  void _showForm({Map<String, dynamic>? coop}) {
    final isNew = coop == null;
    final nomCtrl = TextEditingController(text: coop?['nom'] ?? '');
    final codeCtrl = TextEditingController(text: coop?['code'] ?? '');
    String? statut = coop?['statut'] ?? 'projet';
    String? niveau = (coop?['niveau'] ?? 1).toString();
    String? uniteId = coop?['unite_territoriale_id'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _C.nuit2,
          title: Text(isNew ? 'Nouvelle coopérative' : 'Éditer la coopérative', style: _serif(18, color: _C.orClair)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(nomCtrl, 'Nom de la coopérative'),
                  const SizedBox(height: 8),
                  _field(codeCtrl, 'Code (ex: COOP-001)'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: niveau,
                    decoration: _inputDeco('Niveau'),
                    dropdownColor: _C.nuit2,
                    style: const TextStyle(color: Colors.white),
                    items: ['1', '2', '3', '4', '5'].map((n) => DropdownMenuItem(value: n, child: Text('Niveau $n'))).toList(),
                    onChanged: (v) => setDialogState(() => niveau = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: statut,
                    decoration: _inputDeco('Statut'),
                    dropdownColor: _C.nuit2,
                    style: const TextStyle(color: Colors.white),
                    items: ['projet', 'comite', 'operationnelle', 'archive'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                    onChanged: (v) => setDialogState(() => statut = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: uniteId,
                    decoration: _inputDeco('Unité territoriale (Quartier / Commune)'),
                    dropdownColor: _C.nuit2,
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: _unites
                        .where((u) => u['niveau'] == 1 || u['niveau'] == 3)
                        .map((u) => DropdownMenuItem(value: u['id'] as String, child: Text('${u['nom']} (Niv. ${u['niveau']})', overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => uniteId = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: Colors.white54))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _C.or),
              onPressed: () {
                final data = {
                  'nom': nomCtrl.text.trim(),
                  'code': codeCtrl.text.trim(),
                  'niveau': int.tryParse(niveau ?? '1') ?? 1,
                  'statut': statut,
                  'unite_territoriale_id': uniteId,
                  'pays_code': 'BJ',
                };
                _saveCoop(coop, data);
              },
              child: Text(isNew ? 'Créer' : 'Enregistrer', style: const TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _C.or));

    return Column(
      children: [
        _header(),
        _filtres(),
        Expanded(child: _liste()),
      ],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _C.nuit2,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _C.teal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.handshake, color: _C.teal, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coopératives', style: _serif(20, color: _C.orClair)),
                Text('${_coops.length} coopérative(s) enregistrée(s)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _C.or, foregroundColor: Colors.black),
            onPressed: () => _showForm(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvelle', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _filtres() {
    final statuts = ['tous', 'projet', 'comite', 'operationnelle', 'archive'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _C.nuit3,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuts.map((s) {
            final sel = _filtreStatut == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(s == 'tous' ? 'Tous' : s.toUpperCase()),
                selected: sel,
                onSelected: (_) => setState(() => _filtreStatut = s),
                selectedColor: _C.or,
                backgroundColor: Colors.white10,
                labelStyle: TextStyle(color: sel ? Colors.black : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _liste() {
    final list = _coopsFiltrees;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handshake_outlined, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('Aucune coopérative pour ce filtre', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => _showForm(), child: const Text('Créer la première coopérative', style: TextStyle(color: _C.or))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (c, i) {
        final coop = list[i];
        final statut = coop['statut'] as String? ?? 'projet';
        final nb = coop['nombre_membres'] ?? 0;
        final unite = _unites.firstWhere(
          (u) => u['id'] == coop['unite_territoriale_id'],
          orElse: () => {},
        );
        final colorStatut = statut == 'operationnelle' ? _C.vert : (statut == 'comite' ? _C.or : (statut == 'archive' ? Colors.white24 : _C.violet));

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.nuit2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorStatut.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.handshake, color: colorStatut, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${coop['nom']}', style: _serif(16, color: _C.orClair)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: colorStatut.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text(statut.toUpperCase(), style: TextStyle(color: colorStatut, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('Code: ${coop['code'] ?? '—'}', style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
                  const SizedBox(width: 16),
                  Text('Niv. ${coop['niveau']}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  if (unite.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, size: 12, color: _C.teal),
                    const SizedBox(width: 2),
                    Text('${unite['nom']}', style: const TextStyle(color: _C.teal, fontSize: 10)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.people, size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text('$nb membre(s)', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  const Spacer(),
                  _actionBtn(Icons.edit, 'Éditer', _C.or, () => _showForm(coop: coop)),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.delete, 'Suppr.', _C.rouge, () => _deleteCoop(coop)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDeco(hint),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      filled: true,
      fillColor: _C.nuit3,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _C.or)),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _toast(String msg, {bool rouge = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: rouge ? _C.rouge : _C.vert,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      duration: const Duration(seconds: 2),
    ));
  }
}
