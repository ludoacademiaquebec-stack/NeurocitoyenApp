import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _C {
  static const nuit = Color(0xFF0B2B2F);
  static const nuit2 = Color(0xFF0E3A3D);
  static const nuit3 = Color(0xFF071D20);
  static const or = Color(0xFFE0A82E);
  static const orClair = Color(0xFFF0BD4A);
  static const vert = Color(0xFF1D7A52);
  static const rouge = Color(0xFFB4473A);
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

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});
  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _gradesDispo = [];

  String _search = '';
  String _filtreRole = 'tous';

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await _db
          .from('users')
          .select()
          .order('created_at', ascending: false);
      final grades = await _db
          .from('institutions_grades')
          .select()
          .eq('actif', true)
          .order('numero');

      setState(() {
        _users = List<Map<String, dynamic>>.from(users);
        _gradesDispo = List<Map<String, dynamic>>.from(grades);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _toast('Erreur : $e', rouge: true);
    }
  }

  List<Map<String, dynamic>> get _usersFiltres {
    var list = _users;

    if (_filtreRole != 'tous') {
      list = list.where((u) => u['role_systeme'] == _filtreRole).toList();
    }

    if (_search.isNotEmpty) {
      final s = _search.toLowerCase();
      list = list.where((u) {
        final pseudo = (u['pseudo'] ?? '').toString().toLowerCase();
        final nom = (u['nom'] ?? '').toString().toLowerCase();
        final prenoms = (u['prenoms'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final code = (u['mon_code_cooptation'] ?? '').toString().toLowerCase();
        return pseudo.contains(s) ||
            nom.contains(s) ||
            prenoms.contains(s) ||
            email.contains(s) ||
            code.contains(s);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.or));
    }

    return Scaffold(
      backgroundColor: _C.nuit,
      body: Column(
        children: [
          _header(),
          _filtres(),
          Expanded(child: _liste()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _C.or,
        foregroundColor: Colors.black,
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Nouvel utilisateur',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================
  Widget _header() {
    final total = _users.length;
    final admins = _users.where((u) => u['role_systeme'] == 'super_admin').length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: _C.nuit2,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.rouge.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people, color: _C.rouge, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gestion des utilisateurs', style: _serif(18)),
                Text(
                  '$total utilisateurs · $admins superadmin(s)',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _C.rouge),
            onPressed: _load,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FILTRES
  // ===========================================================================
  Widget _filtres() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: _C.nuit3,
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher pseudo, nom, email, code...',
              hintStyle: const TextStyle(
                  color: Colors.white38, fontSize: 12),
              prefixIcon: const Icon(Icons.search,
                  color: Colors.white38, size: 18),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chipRole('tous', 'Tous'),
                _chipRole('membre', 'Membres'),
                _chipRole('super_admin', 'SuperAdmins'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipRole(String code, String label) {
    final sel = _filtreRole == code;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: sel ? Colors.black : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: sel,
        onSelected: (_) => setState(() => _filtreRole = code),
        selectedColor: _C.or,
        backgroundColor: Colors.white10,
        side: BorderSide(color: _C.or.withOpacity(0.3)),
        showCheckmark: false,
      ),
    );
  }

  // ===========================================================================
  // LISTE
  // ===========================================================================
  Widget _liste() {
    final list = _usersFiltres;

    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Aucun utilisateur trouvé',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (c, i) => _userCard(list[i]),
    );
  }

  Widget _userCard(Map<String, dynamic> u) {
    final isAdmin = u['role_systeme'] == 'super_admin';
    final pseudo = u['pseudo'] ?? '—';
    final nomComplet = '${u['prenoms'] ?? ''} ${u['nom'] ?? ''}'.trim();
    final email = u['email'] ?? '—';
    final grade = u['grade'] ?? 'Aspirant';
    final paysId = u['pays_id'] ?? 'BJ';
    final code = u['mon_code_cooptation'] ?? '—';
    final nd = u['neuro_dollars'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAdmin ? _C.or.withOpacity(0.6) : Colors.white12,
          width: isAdmin ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isAdmin ? _C.or : _C.violet.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    pseudo.isNotEmpty ? pseudo[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isAdmin ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pseudo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _C.or,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (nomComplet.isNotEmpty)
                      Text(
                        nomComplet,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _pill(Icons.school, grade, _C.vert),
              _pill(Icons.public, 'Cité $paysId', _C.violet),
              _pill(Icons.attach_money, '$nd ND', _C.or),
              _pill(Icons.qr_code, code, Colors.white54),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionBtn(Icons.edit, 'Éditer', _C.or, () => _editUser(u)),
              const SizedBox(width: 8),
              _actionBtn(
                Icons.military_tech,
                'Grade',
                _C.vert,
                () => _editGrade(u),
              ),
              const SizedBox(width: 8),
              _actionBtn(
                Icons.attach_money,
                'ND',
                _C.violet,
                () => _editNd(u),
              ),
              const Spacer(),
              _actionBtn(
                Icons.delete_forever,
                'Bannir',
                _C.rouge,
                () => _confirmDelete(u),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ÉDITER USER (nom, prenoms, pseudo, email)
  // ===========================================================================
  void _editUser(Map<String, dynamic> u) {
    final pseudoCtrl = TextEditingController(text: '${u['pseudo'] ?? ''}');
    final nomCtrl = TextEditingController(text: '${u['nom'] ?? ''}');
    final prenomsCtrl = TextEditingController(text: '${u['prenoms'] ?? ''}');
    final emailCtrl = TextEditingController(text: '${u['email'] ?? ''}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: Text('Éditer ${u['pseudo']}',
            style: _serif(16, color: Colors.white)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _formField('Pseudo', pseudoCtrl),
                _formField('Nom', nomCtrl),
                _formField('Prénoms', prenomsCtrl),
                _formField('Email', emailCtrl,
                    keyboardType: TextInputType.emailAddress),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveUser(u['id'], {
                'pseudo': pseudoCtrl.text.trim(),
                'nom': nomCtrl.text.trim(),
                'prenoms': prenomsCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.or,
              foregroundColor: Colors.black,
            ),
            child: const Text('Enregistrer',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ÉDITER GRADE
  // ===========================================================================
  void _editGrade(Map<String, dynamic> u) {
    String? gradeSel = u['grade'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _C.nuit2,
          title: Text('Grade de ${u['pseudo']}',
              style: _serif(16, color: Colors.white)),
          content: SizedBox(
            width: 400,
            child: DropdownButtonFormField<String>(
              value: _gradesDispo.any((g) => g['grade'] == gradeSel)
                  ? gradeSel
                  : null,
              dropdownColor: _C.nuit3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: _C.nuit3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _gradesDispo
                  .map((g) => DropdownMenuItem(
                        value: g['grade'] as String,
                        child: Text(
                          '${g['numero']}. ${g['grade']}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setS(() => gradeSel = v),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (gradeSel != null) {
                  await _saveUser(u['id'], {'grade': gradeSel});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.vert,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enregistrer',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ÉDITER NEURO-DOLLARS
  // ===========================================================================
  void _editNd(Map<String, dynamic> u) {
    final ctrl = TextEditingController(text: '${u['neuro_dollars'] ?? 0}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: Text('Neuro-dollars de ${u['pseudo']}',
            style: _serif(16, color: Colors.white)),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              filled: true,
              fillColor: _C.nuit3,
              suffixText: 'ND',
              suffixStyle: const TextStyle(color: _C.or, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final v = int.tryParse(ctrl.text) ?? 0;
              await _saveUser(u['id'], {'neuro_dollars': v});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.violet,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CONFIRM DELETE
  // ===========================================================================
  void _confirmDelete(Map<String, dynamic> u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: Text('Bannir ${u['pseudo']} ?',
            style: _serif(16, color: Colors.white)),
        content: const Text(
          'L\'utilisateur sera désactivé (statut = banni). Tu pourras le réactiver plus tard.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteUser(u['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.rouge,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bannir'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================
  Future<void> _saveUser(dynamic id, Map<String, dynamic> data) async {
    try {
      await _db.from('users').update(data).eq('id', id);
      await _logEdit('users', id, 'update', data);
      await _load();
      _toast('Utilisateur mis à jour ✅');
    } catch (e) {
      _toast('Erreur : $e', rouge: true);
    }
  }

  Future<void> _deleteUser(dynamic id) async {
    try {
      await _db.from('users').update({
        'statut': 'banni',
      }).eq('id', id);
      await _logEdit('users', id, 'delete', {});
      await _load();
      _toast('Utilisateur banni');
    } catch (e) {
      // Fallback : si la colonne statut n'existe pas, on ne fait rien de destructif
      _toast('Fonctionnalité bannissement bientôt disponible', rouge: true);
    }
  }

  Widget _formField(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: _C.nuit3,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logEdit(
      String table, dynamic rowId, String action, Map<String, dynamic> data) async {
    try {
      await _db.from('edit_log').insert({
        'table_name': table,
        'row_id': rowId,
        'user_id': _db.auth.currentUser?.id,
        'action': action,
        'new_data': data,
        'user_email': _db.auth.currentUser?.email,
      });
    } catch (_) {}
  }

  void _showCreateUserDialog() {
    final emailCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    final pseudoCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final prenomsCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    String pays = 'BJ';
    String role = 'membre';
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _C.nuit2,
          title: Text('Nouvel utilisateur', style: _serif(18, color: _C.orClair)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _fieldCtrl(emailCtrl, 'Email *', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 8),
                  _fieldCtrl(pwdCtrl, 'Mot de passe * (min 6 caractères)',
                      obscure: true),
                  const SizedBox(height: 8),
                  _fieldCtrl(pseudoCtrl, 'Pseudo *'),
                  const SizedBox(height: 8),
                  _fieldCtrl(nomCtrl, 'Nom *'),
                  const SizedBox(height: 8),
                  _fieldCtrl(prenomsCtrl, 'Prénoms *'),
                  const SizedBox(height: 8),
                  _fieldCtrl(codeCtrl, 'Code de cooptation (auto si vide)'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: pays,
                    decoration: _inputDeco('Pays'),
                    dropdownColor: _C.nuit2,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'BJ', child: Text('Bénin')),
                      DropdownMenuItem(value: 'TG', child: Text('Togo')),
                      DropdownMenuItem(value: 'CI', child: Text('Côte d\'Ivoire')),
                      DropdownMenuItem(value: 'SN', child: Text('Sénégal')),
                      DropdownMenuItem(value: 'CD', child: Text('RD Congo')),
                      DropdownMenuItem(value: 'CM', child: Text('Cameroun')),
                      DropdownMenuItem(value: 'CA', child: Text('Canada')),
                    ],
                    onChanged: (v) => setDialogState(() => pays = v ?? 'BJ'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: _inputDeco('Rôle'),
                    dropdownColor: _C.nuit2,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'membre', child: Text('Membre')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                    ],
                    onChanged: (v) => setDialogState(() => role = v ?? 'membre'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _C.or),
              onPressed: loading
                  ? null
                  : () async {
                      if (emailCtrl.text.isEmpty ||
                          pwdCtrl.text.length < 6 ||
                          pseudoCtrl.text.isEmpty ||
                          nomCtrl.text.isEmpty ||
                          prenomsCtrl.text.isEmpty) {
                        _toast('Champs obligatoires manquants ou mot de passe trop court', rouge: true);
                        return;
                      }
                      setDialogState(() => loading = true);
                      try {
                        final code = codeCtrl.text.trim().isEmpty
                            ? '${pays}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
                            : codeCtrl.text.trim();

                        // 1. Créer dans auth.users
                        final authRes = await _db.auth.signUp(
                          email: emailCtrl.text.trim(),
                          password: pwdCtrl.text,
                        );
                        final newUserId = authRes.user?.id;
                        if (newUserId == null) {
                          throw Exception('Échec création auth');
                        }

                        // 2. Créer dans public.users
                        await _db.from('users').insert({
                          'id': newUserId,
                          'email': emailCtrl.text.trim(),
                          'pseudo': pseudoCtrl.text.trim(),
                          'nom': nomCtrl.text.trim(),
                          'prenoms': prenomsCtrl.text.trim(),
                          'pays_id': pays,
                          'role_systeme': role,
                          'mon_code_cooptation': code,
                          'grade': 'Aspirant',
                        });

                        if (mounted) {
                          Navigator.pop(ctx);
                          _toast('Utilisateur créé avec succès');
                          _load();
                        }
                      } catch (e) {
                        setDialogState(() => loading = false);
                        _toast('Erreur : $e', rouge: true);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Créer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldCtrl(TextEditingController ctrl, String hint,
      {bool obscure = false, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
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

  void _toast(String msg, {bool rouge = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: rouge ? _C.rouge : _C.nuit2,
      content: Text(msg,
          style: TextStyle(
              color: rouge ? Colors.white : _C.or, fontSize: 12)),
      duration: const Duration(seconds: 2),
    ));
  }
}
