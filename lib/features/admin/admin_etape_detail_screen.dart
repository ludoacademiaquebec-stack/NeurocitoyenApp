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
}

class AdminEtapeDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? etape;
  const AdminEtapeDetailScreen({super.key, this.etape});
  @override
  State<AdminEtapeDetailScreen> createState() => _AdminEtapeDetailScreenState();
}

class _AdminEtapeDetailScreenState extends State<AdminEtapeDetailScreen> {
  SupabaseClient get _db => Supabase.instance.client;
  bool _loading = false;

  bool get _isNew => widget.etape == null;

  late TextEditingController _titreCtrl;
  late TextEditingController _sousTitreCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _dureeCtrl;
  late TextEditingController _prerequisCtrl;
  late TextEditingController _prerequisDescCtrl;
  late TextEditingController _iconeCtrl;
  late TextEditingController _couleurCtrl;
  late TextEditingController _prixCtrl;
  bool _gratuit = true;
  bool _obligatoire = true;

  @override
  void initState() {
    super.initState();
    final e = widget.etape ?? {};
    _titreCtrl = TextEditingController(text: e['titre'] ?? '');
    _sousTitreCtrl = TextEditingController(text: e['sous_titre'] ?? '');
    _descCtrl = TextEditingController(text: e['description'] ?? '');
    _dureeCtrl = TextEditingController(text: '${e['duree_semaines'] ?? 4}');
    _prerequisCtrl = TextEditingController(text: '${e['prerequis'] ?? ''}');
    _prerequisDescCtrl =
        TextEditingController(text: e['prerequis_description'] ?? '');
    _iconeCtrl = TextEditingController(text: e['icone'] ?? 'self_improvement');
    _couleurCtrl = TextEditingController(text: e['couleur'] ?? '#C4952B');
    _prixCtrl = TextEditingController(text: '${e['prix_fcfa'] ?? 0}');
    _gratuit = e['gratuit'] ?? true;
    _obligatoire = e['obligatoire'] ?? true;
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _sousTitreCtrl.dispose();
    _descCtrl.dispose();
    _dureeCtrl.dispose();
    _prerequisCtrl.dispose();
    _prerequisDescCtrl.dispose();
    _iconeCtrl.dispose();
    _couleurCtrl.dispose();
    _prixCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titreCtrl.text.trim().isEmpty) {
      _toast('Le titre est obligatoire', rouge: true);
      return;
    }
    setState(() => _loading = true);

    final data = {
      'titre': _titreCtrl.text.trim(),
      'sous_titre': _sousTitreCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'duree_semaines': int.tryParse(_dureeCtrl.text) ?? 4,
      'prerequis': _prerequisCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_prerequisCtrl.text),
      'prerequis_description': _prerequisDescCtrl.text.trim(),
      'icone': _iconeCtrl.text.trim(),
      'couleur': _couleurCtrl.text.trim(),
      'prix_fcfa': int.tryParse(_prixCtrl.text) ?? 0,
      'gratuit': _gratuit,
      'obligatoire': _obligatoire,
    };

    try {
      if (_isNew) {
        final maxNum = await _db
            .from('etapes_parcours')
            .select('numero')
            .order('numero', ascending: false)
            .limit(1)
            .maybeSingle();
        final nextNum = ((maxNum?['numero'] as int?) ?? 0) + 1;
        data['numero'] = nextNum;
        await _db.from('etapes_parcours').insert(data);
      } else {
        await _db
            .from('etapes_parcours')
            .update(data)
            .eq('numero', widget.etape!['numero']);
      }

      try {
        await _db.from('edit_log').insert({
          'table_name': 'etapes_parcours',
          'row_id': null,
          'action': _isNew ? 'insert' : 'update',
          'new_data': data,
        });
      } catch (_) {}

      if (mounted) {
        _toast(_isNew ? 'Étape créée' : 'Étape mise à jour');
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _loading = false);
      _toast('Erreur : $e', rouge: true);
    }
  }

  Future<void> _delete() async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: const Text('Supprimer cette étape ?',
            style: TextStyle(color: Colors.white)),
        content: Text(
            'L\'étape "${widget.etape!['titre']}" sera supprimée définitivement.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white70))),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _C.rouge),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (conf != true) return;

    setState(() => _loading = true);
    try {
      await _db
          .from('etapes_parcours')
          .delete()
          .eq('numero', widget.etape!['numero']);

      try {
        await _db.from('edit_log').insert({
          'table_name': 'etapes_parcours',
          'row_id': null,
          'action': 'delete',
          'old_data': widget.etape,
        });
      } catch (_) {}

      if (mounted) {
        _toast('Étape supprimée');
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _loading = false);
      _toast('Erreur : $e', rouge: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.nuit,
      appBar: AppBar(
        backgroundColor: _C.nuit,
        foregroundColor: Colors.white,
        title: Text(_isNew ? 'Nouvelle étape' : 'Étape ${widget.etape!['numero']}'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete, color: _C.rouge),
              onPressed: _loading ? null : _delete,
              tooltip: 'Supprimer',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _label('Titre *'),
                _field(_titreCtrl, 'Ex : Le Mur Invisible'),
                _label('Sous-titre'),
                _field(_sousTitreCtrl, 'Ex : Éveil critique et transformation intérieure'),
                _label('Description'),
                _field(_descCtrl, 'Décris cette étape...', maxLines: 4),
                _label('Durée (semaines)'),
                _field(_dureeCtrl, '4', keyboardType: TextInputType.number),
                _label('Prérequis (numéro de l\'étape précédente, vide = aucun)'),
                _field(_prerequisCtrl, 'Ex : 1', keyboardType: TextInputType.number),
                _label('Description du prérequis'),
                _field(_prerequisDescCtrl, 'Ex : Étape 1 validée'),
                _row(
                  _switchTile('Gratuit', _gratuit, (v) => setState(() => _gratuit = v)),
                  _switchTile('Obligatoire', _obligatoire,
                      (v) => setState(() => _obligatoire = v)),
                ),
                if (!_gratuit) ...[
                  _label('Prix (FCFA)'),
                  _field(_prixCtrl, '5000', keyboardType: TextInputType.number),
                ],
                _label('Icône (nom Material)'),
                _field(_iconeCtrl, 'self_improvement'),
                _label('Couleur (hex)'),
                _field(_couleurCtrl, '#C4952B'),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.or,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _loading ? null : _save,
                  icon: const Icon(Icons.check_circle, color: Colors.black),
                  label: Text(_isNew ? 'Créer l\'étape' : 'Enregistrer',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler',
                      style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
    );
  }

  Widget _label(String txt) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 12),
        child: Text(txt,
            style: const TextStyle(
                color: _C.orClair,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      );

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: _C.nuit3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.or),
        ),
      ),
    );
  }

  Widget _row(Widget a, Widget b) {
    return Row(
      children: [
        Expanded(child: a),
        Expanded(child: b),
      ],
    );
  }

  Widget _switchTile(String label, bool val, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 13)),
      value: val,
      onChanged: onChanged,
      activeThumbColor: _C.or,
      contentPadding: EdgeInsets.zero,
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
