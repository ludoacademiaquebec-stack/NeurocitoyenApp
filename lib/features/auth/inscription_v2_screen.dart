import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/db.dart';
import '../../core/ligue_data.dart';
import '../../widgets/app_scaffold.dart';

class InscriptionScreen extends StatefulWidget {
  final String paysId;
  const InscriptionScreen({super.key, required this.paysId});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  int step = 0;
  bool _loading = false;
  String? _error;

  // Step 0 : Identité
  String pseudo = '';
  String nom = '';
  String prenoms = '';
  String email = '';

  // Step 1 : Territoire
  String departement = '';
  String commune = '';
  String quartier = '';

  // Step 2 : Pôles
  List<int> polesChoisis = [];
  List<String> interetsElargis = [];

  // Step 3 : Parrain
  String codeParrain = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final qp = GoRouterState.of(context).uri.queryParameters;
      setState(() => codeParrain = qp['parrain'] ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cite = LigueData.getCite(widget.paysId);
    return AppScaffold(
      title: '${cite.flag} ${cite.nom} - Inscription',
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (step + 1) / 4,
                color: const Color(0xFFFFC400),
                backgroundColor: Colors.white10,
              ),
              const SizedBox(height: 12),
              Text(
                'Étape ${step + 1}/4 — ${['Identité', 'Territoire', 'Pôles', 'Récap'][step]}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              Expanded(child: SingleChildScrollView(child: _step(cite))),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC400),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _loading ? null : () => _next(cite),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : Text(step < 3
                          ? 'Continuer'
                          : 'Créer mon compte & Dashboard'),
                ),
              ),
              if (step > 0)
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _error = null;
                            step--;
                          }),
                  child: const Text('← Retour',
                      style: TextStyle(color: Colors.white54)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _next(Cite cite) async {
    setState(() => _error = null);

    // Validations
    if (step == 0) {
      if (pseudo.trim().length < 3) {
        setState(() => _error = 'Pseudo : 3 caractères minimum');
        return;
      }
      if (nom.trim().isEmpty || prenoms.trim().isEmpty) {
        setState(() => _error = 'Nom et prénoms obligatoires');
        return;
      }
      if (!email.contains('@') || !email.contains('.')) {
        setState(() => _error = 'Email invalide');
        return;
      }
      setState(() => step++);
      return;
    }

    if (step == 1) {
      if (departement.trim().isEmpty) {
        setState(() => _error = 'Département obligatoire');
        return;
      }
      if (commune.trim().isEmpty) {
        setState(() => _error = 'Commune obligatoire');
        return;
      }
      setState(() => step++);
      return;
    }

    if (step == 2) {
      if (polesChoisis.isEmpty) {
        setState(() => _error = 'Choisis au moins 1 pôle');
        return;
      }
      setState(() => step++);
      return;
    }

    // Step 3 : Insertion Supabase
    setState(() => _loading = true);
    try {
      final codeCooptation = _genererCodeCooptation(cite.id);
      final user = await Db.createUser(
        pseudo: pseudo.trim(),
        nom: nom.trim(),
        prenoms: prenoms.trim(),
        email: email.trim().toLowerCase(),
        paysId: cite.id,
        codeCooptation: codeCooptation,
        codeParrain: codeParrain.isNotEmpty ? codeParrain : null,
        departement: departement.trim(),
        commune: commune.trim(),
        villageQuartier: quartier.trim(),
        domainesInteret: [
          ...polesChoisis.map((e) => 'pole_$e'),
          ...interetsElargis,
        ],
      );

      // Sauvegarde locale pour session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user['id'] as String);
      await prefs.setString('pseudo', user['pseudo'] as String);
      await prefs.setString('code_parrain', codeCooptation);
      await prefs.setString('pays_id', cite.id);

      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _genererCodeCooptation(String paysId) {
    final rnd = Random();
    final lettres = String.fromCharCodes(
        List.generate(4, (i) => rnd.nextInt(26) + 65));
    final chiffres = rnd.nextInt(9000) + 1000;
    return '$paysId-$lettres-$chiffres';
  }

  Widget _step(Cite cite) {
    if (step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (codeParrain.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                'Parrain : $codeParrain',
                style: const TextStyle(color: Colors.green, fontSize: 11),
              ),
            ),
          const Text('Identité',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 12),
          _f('Pseudo (unique)', (v) => pseudo = v),
          _f('Prénoms', (v) => prenoms = v),
          _f('Nom', (v) => nom = v),
          _f('Email', (v) => email = v),
        ],
      );
    }

    if (step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Territoire',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 12),
          _f('Département', (v) => departement = v),
          _f('Commune', (v) => commune = v),
          _f('Quartier / Village', (v) => quartier = v),
        ],
      );
    }

    if (step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pôles d\'intérêt (max 2)',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: LigueData.poles.map((p) {
              final sel = polesChoisis.contains(p.numero);
              return FilterChip(
                label: Text('${p.numero}. ${p.nom}',
                    style: TextStyle(
                        color: sel ? Colors.black : Colors.white70,
                        fontSize: 9)),
                selected: sel,
                selectedColor: const Color(0xFFFFC400),
                backgroundColor: Colors.white.withOpacity(0.06),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      if (polesChoisis.length < 2) polesChoisis.add(p.numero);
                    } else {
                      polesChoisis.remove(p.numero);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 11),
            decoration: InputDecoration(
              hintText: 'Autres intérêts (séparés par virgule)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 10),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
            ),
            onChanged: (v) => interetsElargis = v
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Récapitulatif',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 12),
        Text(
          'Pseudo : $pseudo\n'
          'Nom complet : $prenoms $nom\n'
          'Email : $email\n'
          'Cité : ${cite.nom}\n'
          'Département : $departement\n'
          'Commune : $commune\n'
          'Quartier : $quartier\n'
          'Pôles : ${polesChoisis.join(', ')}',
          style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.6),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC400).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Un code de cooptation unique + 100 neuro-dollars de bienvenue '
            'seront attribués automatiquement à la création.',
            style: TextStyle(color: Color(0xFFFFC400), fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _f(String label, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}