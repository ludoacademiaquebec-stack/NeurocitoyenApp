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
  static const teal = Color(0xFF2F7D6D);
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

class AdminJournalTab extends StatefulWidget {
  const AdminJournalTab({super.key});
  @override
  State<AdminJournalTab> createState() => _AdminJournalTabState();
}

class _AdminJournalTabState extends State<AdminJournalTab>
    with TickerProviderStateMixin {
  late final TabController _subTabCtrl;
  bool _loading = true;

  List<Map<String, dynamic>> _edits = [];
  List<Map<String, dynamic>> _sessions = [];

  String _search = '';
  String? _filtreTable;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _subTabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _subTabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final edits = await _db
          .from('edit_log')
          .select()
          .order('created_at', ascending: false)
          .limit(200);
      final sessions = await _db
          .from('admin_sessions')
          .select()
          .order('login_at', ascending: false)
          .limit(100);

      setState(() {
        _edits = List<Map<String, dynamic>>.from(edits);
        _sessions = List<Map<String, dynamic>>.from(sessions);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _toast('Erreur : $e', rouge: true);
    }
  }

  List<Map<String, dynamic>> get _editsFiltres {
    var list = _edits;

    if (_filtreTable != null) {
      list = list.where((e) => e['table_name'] == _filtreTable).toList();
    }

    if (_search.isNotEmpty) {
      final s = _search.toLowerCase();
      list = list.where((e) {
        final table = (e['table_name'] ?? '').toString().toLowerCase();
        final email = (e['user_email'] ?? '').toString().toLowerCase();
        final action = (e['action'] ?? '').toString().toLowerCase();
        return table.contains(s) || email.contains(s) || action.contains(s);
      }).toList();
    }

    return list;
  }

  List<String> get _tablesDispo {
    final tables = <String>{};
    for (final e in _edits) {
      final t = e['table_name']?.toString();
      if (t != null && t.isNotEmpty) tables.add(t);
    }
    return tables.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.or));
    }

    return Column(
      children: [
        _header(),
        Container(
          color: _C.nuit3,
          child: TabBar(
            controller: _subTabCtrl,
            indicatorColor: _C.or,
            labelColor: _C.or,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                  text: 'Éditions (${_edits.length})',
                  icon: const Icon(Icons.edit, size: 16)),
              Tab(
                  text: 'Connexions (${_sessions.length})',
                  icon: const Icon(Icons.login, size: 16)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabCtrl,
            children: [
              _journalEdits(),
              _journalSessions(),
            ],
          ),
        ),
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
            child: const Icon(Icons.history, color: _C.or, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Journal d\'édition', style: _serif(18)),
                Text(
                  '${_edits.length} éditions · ${_sessions.length} connexions',
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
        ],
      ),
    );
  }

  // ===========================================================================
  // SOUS-TAB 1 : ÉDITIONS
  // ===========================================================================
  Widget _journalEdits() {
    return Column(
      children: [
        _filtresEdits(),
        Expanded(child: _listeEdits()),
      ],
    );
  }

  Widget _filtresEdits() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: _C.nuit3,
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher par table, email, action...',
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
                _chipTable(null, 'Toutes'),
                for (final t in _tablesDispo) _chipTable(t, t),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipTable(String? table, String label) {
    final sel = _filtreTable == table;
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
        onSelected: (_) =>
            setState(() => _filtreTable = sel ? null : table),
        selectedColor: _C.or,
        backgroundColor: Colors.white10,
        side: BorderSide(color: _C.or.withOpacity(0.3)),
        showCheckmark: false,
      ),
    );
  }

  Widget _listeEdits() {
    final list = _editsFiltres;

    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Aucune édition enregistrée',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (c, i) => _editTile(list[i]),
    );
  }

  Widget _editTile(Map<String, dynamic> e) {
    final table = e['table_name'] ?? '—';
    final action = e['action'] ?? '—';
    final email = e['user_email'] ?? '—';
    final dateStr = e['created_at']?.toString() ?? '';
    final date = dateStr.length >= 19 ? dateStr.substring(0, 19) : dateStr;

    final color = _actionColor(action);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(_actionIcon(action), color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        action.toString().toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        table,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'insert':
        return _C.vert;
      case 'update':
        return _C.or;
      case 'delete':
        return _C.rouge;
      default:
        return Colors.white54;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'insert':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  // ===========================================================================
  // SOUS-TAB 2 : SESSIONS
  // ===========================================================================
  Widget _journalSessions() {
    if (_sessions.isEmpty) {
      return const Center(
        child: Text(
          'Aucune session enregistrée',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _sessions.length,
      itemBuilder: (c, i) => _sessionTile(_sessions[i]),
    );
  }

  Widget _sessionTile(Map<String, dynamic> s) {
    final email = s['email'] ?? '—';
    final statut = s['statut'] ?? 'active';
    final loginStr = s['login_at']?.toString() ?? '';
    final logoutStr = s['logout_at']?.toString();
    final login = loginStr.length >= 19 ? loginStr.substring(0, 19) : loginStr;
    final logout = logoutStr != null && logoutStr.length >= 19
        ? logoutStr.substring(0, 19)
        : null;

    final color = statut == 'active' ? _C.vert : Colors.white54;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statut == 'active' ? Icons.login : Icons.logout,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Connexion : $login',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                if (logout != null)
                  Text(
                    'Déconnexion : $logout',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statut == 'active' ? 'ACTIVE' : 'FERMÉE',
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
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
