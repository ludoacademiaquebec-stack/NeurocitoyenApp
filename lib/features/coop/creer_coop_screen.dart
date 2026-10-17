import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/coop_service.dart';
import '../../widgets/app_scaffold.dart';

class _C {
  static const nuit2 = Color(0xFF0E3A3D);
  static const nuit3 = Color(0xFF071D20);
  static const or = Color(0xFFE0A82E);
  static const orClair = Color(0xFFF0BD4A);
  static const vert = Color(0xFF1D7A52);
  static const rouge = Color(0xFF8B2E2E);
}


class CreerCoopScreen extends StatefulWidget {
  const CreerCoopScreen({super.key});
  @override
  State<CreerCoopScreen> createState() => _CreerCoopScreenState();
}

class _CreerCoopScreenState extends State<CreerCoopScreen> {
  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _quartierCtrl = TextEditingController();

  Map<String, dynamic>? _departement;
  Map<String, dynamic>? _commune;
  Map<String, dynamic>? _arrondissement;
  Map<String, dynamic>? _quartierExistant;

  List<Map<String, dynamic>> _departements = [];
  List<Map<String, dynamic>> _communes = [];
  List<Map<String, dynamic>> _arrondissements = [];
  List<Map<String, dynamic>> _quartiers = [];

  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadDepartements();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _quartierCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDepartements() async {
    final res = await CoopService.unitesParNiveau(4);
    setState(() {
      _departements = res;
      _loading = false;
    });
  }

  Future<void> _onDepartementChange(Map<String, dynamic>? d) async {
    setState(() {
      _departement = d;
      _commune = null;
      _arrondissement = null;
      _quartierExistant = null;
      _communes = [];
      _arrondissements = [];
      _quartiers = [];
    });
    if (d == null) return;
    final res = await CoopService.unitesEnfants(d['id'] as String);
    setState(() => _communes = res.where((e) => e['niveau'] == 3).toList());
  }

  Future<void> _onCommuneChange(Map<String, dynamic>? c) async {
    setState(() {
      _commune = c;
      _arrondissement = null;
      _quartierExistant = null;
      _arrondissements = [];
      _quartiers = [];
    });
    if (c == null) return;
    final res = await CoopService.unitesEnfants(c['id'] as String);
    setState(() => _arrondissements = res);
  }

  Future<void> _onArrondissementChange(Map<String, dynamic>? a) async {
    setState(() {
      _arrondissement = a;
      _quartierExistant = null;
      _quartiers = [];
    });
    if (a == null) return;
    final res = await CoopService.unitesEnfants(a['id'] as String);
    setState(() => _quartiers = res);
  }

  Future<void> _submit() async {
    // Validations
    if (_nomCtrl.text.trim().isEmpty) {
      return _toast('Donne un nom à ta coopérative', _C.rouge);
    }
    if (_arrondissement == null) {
      return _toast('Sélectionne un arrondissement', _C.rouge);
    }

    String? quartierId = _quartierExistant?['id'] as String?;
    if (quartierId == null) {
      final nomQuartier = _quartierCtrl.text.trim();
      if (nomQuartier.isEmpty) {
        return _toast('Indique le nom de ton quartier', _C.rouge);
      }
      // Créer le quartier à la volée
      setState(() => _submitting = true);
      try {
        quartierId = await CoopService.creerQuartierALaVolee(
          nom: nomQuartier,
          arrondissementId: _arrondissement!['id'] as String,
        );
      } catch (e) {
        setState(() => _submitting = false);
        return _toast('Erreur création quartier : $e', _C.rouge);
      }
    }

    setState(() => _submitting = true);
    try {
      await CoopService.creerProjet(
        nom: _nomCtrl.text.trim(),
        uniteTerritorialeId: quartierId,
        paysCode: 'BJ',
        description: _descCtrl.text.trim(),
      );

      if (!mounted) return;
      _toast('Coopérative créée !', _C.vert);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _toast(e.toString(), _C.rouge);
      }
    }
  }

  void _toast(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: bg, content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Créer une coopérative',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _intro(),
                const SizedBox(height: 20),
                _label('Nom de la coopérative'),
                _field(_nomCtrl, 'Ex : Coopérative des femmes de Godomey'),
                const SizedBox(height: 16),
                _label('Description (optionnel)'),
                _field(_descCtrl, 'Que fera votre coopérative ?',
                    maxLines: 3),
                const SizedBox(height: 24),
                _label('Localisation'),
                const SizedBox(height: 8),
                _dropdown(
                  hint: 'Département',
                  value: _departement,
                  items: _departements,
                  onChanged: _onDepartementChange,
                ),
                const SizedBox(height: 10),
                _dropdown(
                  hint: 'Commune',
                  value: _commune,
                  items: _communes,
                  onChanged: _onCommuneChange,
                  disabled: _departement == null,
                ),
                const SizedBox(height: 10),
                _dropdown(
                  hint: 'Arrondissement',
                  value: _arrondissement,
                  items: _arrondissements,
                  onChanged: _onArrondissementChange,
                  disabled: _commune == null,
                ),
                const SizedBox(height: 10),
                if (_arrondissement != null) ...[
                  if (_quartiers.isNotEmpty) ...[
                    const Text(
                      'Quartier existant (optionnel)',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    _dropdown(
                      hint: 'Sélectionner un quartier existant',
                      value: _quartierExistant,
                      items: _quartiers,
                      onChanged: (q) => setState(() => _quartierExistant = q),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_quartierExistant == null) ...[
                    const Text(
                      'Ou crée ton quartier',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    _field(_quartierCtrl,
                        'Ex : Djègan-Kpèvi, Agla, Fidjrossè...'),
                    const SizedBox(height: 6),
                    const Text(
                      '⚠️ Ce quartier sera activé après validation par la Cité.',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                _regles(),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.or,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.check_circle, color: Colors.black),
                  label: Text(
                    _submitting ? 'Création...' : 'Créer la coopérative',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Annuler',
                      style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
    );
  }

  Widget _intro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.or.withValues(alpha: 0.4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: _C.or, size: 20),
              SizedBox(width: 8),
              Text('Comment ça marche ?',
                  style: TextStyle(
                      color: _C.orClair,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '1. Tu deviens fondateur initiateur.\n'
            '2. Tu invites 4 autres Neurocitoyens certifiés.\n'
            '3. À 5 membres, la coopérative devient "comité".\n'
            '4. Vous démarrez la phase pré-commerce (marketing, AGORA).\n'
            '5. Après validation, vous démarrez le commerce.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
          ),
          SizedBox(height: 8),
          Text(
            '⚠️ Tu as 30 jours pour réunir les 5 membres.',
            style: TextStyle(
                color: _C.or, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _regles() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Règles essentielles',
              style: TextStyle(
                  color: _C.orClair,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            '• Tous les membres doivent être certifiés Neurocitoyens.\n'
            '• Les non-certifiés doivent finir leur parcours avant de rejoindre.\n'
            '• La part sociale est de 5 000 FCFA.\n'
            '• Un membre, une voix.\n'
            '• Pas de rémunération liée au recrutement.',
            style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _label(String txt) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(txt,
            style: const TextStyle(
                color: _C.orClair,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      );

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
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

  Widget _dropdown({
    required String hint,
    required Map<String, dynamic>? value,
    required List<Map<String, dynamic>> items,
    required Function(Map<String, dynamic>?) onChanged,
    bool disabled = false,
  }) {
    return DropdownButtonFormField<Map<String, dynamic>>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: _C.nuit2,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: disabled ? _C.nuit3.withValues(alpha: 0.5) : _C.nuit3,
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
      items: items
          .map((e) => DropdownMenuItem<Map<String, dynamic>>(
                value: e,
                child: Text(e['nom'] as String? ?? '—',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ))
          .toList(),
      onChanged: disabled ? null : onChanged,
    );
  }
}
