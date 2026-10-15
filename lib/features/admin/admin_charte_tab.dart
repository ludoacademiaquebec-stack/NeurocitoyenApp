import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _C {
  static const nuit = Color(0xFF060A1F);
  static const nuit2 = Color(0xFF121845);
  static const nuit3 = Color(0xFF0B102E);
  static const or = Color(0xFFC4952B);
  static const orClair = Color(0xFFF0D9A0);
  static const vert = Color(0xFF0F7A3D);
  static const rouge = Color(0xFFE53935);
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

class AdminCharteTab extends StatefulWidget {
  const AdminCharteTab({super.key});
  @override
  State<AdminCharteTab> createState() => _AdminCharteTabState();
}

class _AdminCharteTabState extends State<AdminCharteTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _titres = [];
  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _annexes = [];

  String _search = '';
  String? _filtreTitreId;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final titres = await _db
          .from('charte_titres')
          .select()
          .order('numero_ordre');
      final articles = await _db
          .from('charte_articles')
          .select()
          .order('numero');
      final annexes = await _db
          .from('charte_annexes')
          .select()
          .order('lettre');

      setState(() {
        _titres = List<Map<String, dynamic>>.from(titres);
        _articles = List<Map<String, dynamic>>.from(articles);
        _annexes = List<Map<String, dynamic>>.from(annexes);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _toast('Erreur de chargement : $e', rouge: true);
    }
  }

  List<Map<String, dynamic>> get _articlesFiltres {
    var list = _articles.where((a) => a['actif'] == true).toList();

    if (_filtreTitreId != null) {
      list = list.where((a) => a['titre_id'] == _filtreTitreId).toList();
    }

    if (_search.isNotEmpty) {
      final s = _search.toLowerCase();
      list = list.where((a) {
        final contenu = (a['contenu'] ?? '').toString().toLowerCase();
        final num = (a['numero'] ?? '').toString();
        return contenu.contains(s) || num.contains(s);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AdminCharteTab build: loading=$_loading, titres=${_titres.length}, articles=${_articles.length}');

    if (_loading) {
      return Container(
        color: Colors.red,  // ROUGE VIF pour test
        child: const Center(
          child: Text(
            'CHARGEMENT CHARTE...',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Column(
      children: [
        _header(),
        _filtres(),
        Expanded(child: _liste()),
      ],
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _C.nuit2,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.or.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu_book, color: _C.or, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gestion de la Charte',
                    style: _serif(18)),
                Text(
                  '${_titres.length} titres · ${_articles.where((a) => a['actif'] == true).length} articles · ${_annexes.length} annexes',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _C.or),
            onPressed: _load,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: _C.vert),
            onPressed: () => _showEditDialog(null),
            tooltip: 'Nouvel article',
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
          // Recherche
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher un article...',
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

          // Filtres par titre
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chipTitre(null, 'Tous'),
                for (final t in _titres)
                  if (t['actif'] == true)
                    _chipTitre(
                      t['id'],
                      '${t['numero_romain']} · ${t['titre']}',
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipTitre(String? id, String label) {
    final sel = _filtreTitreId == id;
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
        onSelected: (_) => setState(() => _filtreTitreId = sel ? null : id),
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
    final list = _articlesFiltres;

    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Aucun article trouvé',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (c, i) => _articleTile(list[i]),
    );
  }

  Widget _articleTile(Map<String, dynamic> a) {
    final numero = a['numero'];
    final contenu = (a['contenu'] ?? '').toString();
    final actif = a['actif'] == true;

    // Trouver le titre parent
    final titre = _titres.firstWhere(
      (t) => t['id'] == a['titre_id'],
      orElse: () => <String, dynamic>{},
    );
    final titreLabel = titre.isNotEmpty
        ? 'Titre ${titre['numero_romain']} · ${titre['titre']}'
        : 'Orphelin';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: actif ? _C.or.withOpacity(0.3) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.or.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Art. $numero',
                  style: const TextStyle(
                    color: _C.or,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titreLabel,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!actif)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _C.rouge.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'INACTIF',
                    style: TextStyle(
                      color: _C.rouge,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contenu.length > 180
                ? '${contenu.substring(0, 180)}...'
                : contenu,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _actionBtn(Icons.edit, 'Éditer', _C.or, () => _showEditDialog(a)),
              const SizedBox(width: 8),
              _actionBtn(
                actif ? Icons.visibility_off : Icons.visibility,
                actif ? 'Désactiver' : 'Activer',
                Colors.white70,
                () => _toggleActif(a),
              ),
              const Spacer(),
              _actionBtn(
                Icons.delete_forever,
                'Supprimer',
                _C.rouge,
                () => _confirmDelete(a),
              ),
            ],
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
  // TOGGLE ACTIF
  // ===========================================================================
  Future<void> _toggleActif(Map<String, dynamic> a) async {
    try {
      final newValue = a['actif'] != true;
      await _db.from('charte_articles').update({
        'actif': newValue,
        'modifie_le': DateTime.now().toIso8601String(),
      }).eq('id', a['id']);

      await _logEdit('charte_articles', a['id'], 'update', a,
          {'actif': newValue});

      await _load();
      _toast(newValue ? 'Article activé' : 'Article désactivé');
    } catch (e) {
      _toast('Erreur : $e', rouge: true);
    }
  }

  // ===========================================================================
  // DIALOG ÉDITION / CRÉATION
  // ===========================================================================
  void _showEditDialog(Map<String, dynamic>? article) {
    final isNew = article == null;
    final numCtrl = TextEditingController(
        text: isNew ? '' : (article['numero'] ?? '').toString());
    final contenuCtrl = TextEditingController(
        text: isNew ? '' : (article['contenu'] ?? '').toString());
    String? titreId =
        isNew ? (_filtreTitreId ?? _titres.first['id']) : article['titre_id'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _C.nuit2,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.all(20),
          title: Row(
            children: [
              Icon(
                isNew ? Icons.add_circle : Icons.edit,
                color: _C.or,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                isNew ? 'Nouvel article' : 'Éditer l\'article ${article['numero']}',
                style: _serif(16, color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre parent
                  const Text('Titre parent',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: titreId,
                    dropdownColor: _C.nuit3,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _C.nuit3,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: _titres
                        .where((t) => t['actif'] == true)
                        .map((t) => DropdownMenuItem(
                              value: t['id'] as String,
                              child: Text(
                                '${t['numero_romain']} · ${t['titre']}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setS(() => titreId = v),
                  ),
                  const SizedBox(height: 14),

                  // Numéro
                  const Text('Numéro',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: numCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ex: 12',
                      hintStyle: const TextStyle(
                          color: Colors.white38, fontSize: 12),
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
                  const SizedBox(height: 14),

                  // Contenu
                  const Text('Contenu (texte complet)',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: contenuCtrl,
                    maxLines: 8,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, height: 1.5),
                    decoration: InputDecoration(
                      hintText:
                          'TitreCourt. Contenu complet de l\'article...',
                      hintStyle: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: _C.nuit3,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
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
                final num = int.tryParse(numCtrl.text.trim());
                final contenu = contenuCtrl.text.trim();

                if (num == null || contenu.isEmpty || titreId == null) {
                  setS(() {});
                  _toast('Numéro et contenu requis', rouge: true);
                  return;
                }

                Navigator.pop(ctx);

                if (isNew) {
                  await _createArticle(num, titreId!, contenu);
                } else {
                  await _updateArticle(article['id'], num, titreId!, contenu);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.or,
                foregroundColor: Colors.black,
              ),
              child: Text(isNew ? 'Créer' : 'Enregistrer',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createArticle(
      int numero, String titreId, String contenu) async {
    try {
      await _db.from('charte_articles').insert({
        'titre_id': titreId,
        'numero': numero,
        'numero_affiche': 'Article $numero',
        'contenu': contenu,
        'version': '2.0',
        'actif': true,
        'ordre': numero,
      });

      await _logEdit('charte_articles', null, 'insert', null,
          {'numero': numero, 'titre_id': titreId});

      await _load();
      _toast('Article $numero créé ✅');
    } catch (e) {
      _toast('Erreur création : $e', rouge: true);
    }
  }

  Future<void> _updateArticle(
      dynamic id, int numero, String titreId, String contenu) async {
    try {
      await _db.from('charte_articles').update({
        'numero': numero,
        'numero_affiche': 'Article $numero',
        'contenu': contenu,
        'titre_id': titreId,
        'modifie_le': DateTime.now().toIso8601String(),
      }).eq('id', id);

      await _logEdit('charte_articles', id, 'update', null,
          {'numero': numero});

      await _load();
      _toast('Article $numero mis à jour ✅');
    } catch (e) {
      _toast('Erreur mise à jour : $e', rouge: true);
    }
  }

  // ===========================================================================
  // SUPPRESSION
  // ===========================================================================
  void _confirmDelete(Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: Text('Supprimer l\'article ${a['numero']} ?',
            style: _serif(16, color: Colors.white)),
        content: const Text(
          'L\'article sera désactivé (soft delete). Tu pourras le réactiver plus tard.',
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
              await _toggleActif({'id': a['id'], 'actif': true});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.rouge,
              foregroundColor: Colors.white,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOG
  // ===========================================================================
  Future<void> _logEdit(
    String table,
    dynamic rowId,
    String action,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  ) async {
    try {
      await _db.from('edit_log').insert({
        'table_name': table,
        'row_id': rowId,
        'user_id': _db.auth.currentUser?.id,
        'action': action,
        'old_data': oldData,
        'new_data': newData,
        'user_email': _db.auth.currentUser?.email,
      });
    } catch (_) {}
  }

  // ===========================================================================
  // TOAST
  // ===========================================================================
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
