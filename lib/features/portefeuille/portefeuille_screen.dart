import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/app_scaffold.dart';

class _C {
  static const nuit = Color(0xFF0B2B2F);
  static const nuit2 = Color(0xFF0E3A3D);
  static const nuit3 = Color(0xFF071D20);
  static const or = Color(0xFFE0A82E);
  static const orClair = Color(0xFFF0BD4A);
}

TextStyle _serif(double size, {Color color = Colors.white, FontWeight weight = FontWeight.w700}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'serif'],
    fontSize: size,
    color: color,
    fontWeight: weight,
  );
}

class PortefeuilleScreen extends StatefulWidget {
  const PortefeuilleScreen({super.key});
  @override
  State<PortefeuilleScreen> createState() => _PortefeuilleScreenState();
}

class _PortefeuilleScreenState extends State<PortefeuilleScreen> {
  bool _loading = true;
  int _solde = 100;
  List<Map<String, dynamic>> _transactions = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');
      if (_userId == null) {
        setState(() => _loading = false);
        return;
      }

      final user = await Supabase.instance.client
          .from('users')
          .select('neuro_dollars')
          .eq('id', _userId!)
          .maybeSingle();
      if (user != null) {
        _solde = (user['neuro_dollars'] as num?)?.toInt() ?? 100;
      }

      try {
        final res = await Supabase.instance.client
            .from('portefeuille_transactions')
            .select()
            .eq('user_id', _userId!)
            .order('created_at', ascending: false)
            .limit(50);
        _transactions = List<Map<String, dynamic>>.from(res);
      } catch (_) {}
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mon Portefeuille',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _soldeCard(),
                const SizedBox(height: 16),
                _actionsRapides(),
                const SizedBox(height: 20),
                _historiqueTitle(),
                const SizedBox(height: 10),
                if (_transactions.isEmpty)
                  _emptyState()
                else
                  ..._transactions.map(_transactionTile),
              ],
            ),
    );
  }

  Widget _soldeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.or, Color(0xFF8B6914)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _C.or.withOpacity(0.3), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SOLDE ACTUEL',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$_solde',
                  style: _serif(48, color: Colors.black, weight: FontWeight.w900)),
              const SizedBox(width: 8),
              const Text('ND',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Neuro-Dollars',
              style: TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Utilise tes ND dans la Centrale d\'achat et les coopératives',
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionsRapides() {
    return Row(
      children: [
        Expanded(child: _actionBtn(Icons.add_circle, 'Déposer', () => _comingSoon('Dépôt'))),
        const SizedBox(width: 10),
        Expanded(child: _actionBtn(Icons.remove_circle, 'Retirer', () => _comingSoon('Retrait'))),
        const SizedBox(width: 10),
        Expanded(child: _actionBtn(Icons.swap_horiz, 'Transférer', () => _comingSoon('Transfert'))),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _C.nuit3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.or.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _C.or, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _historiqueTitle() {
    return Row(
      children: [
        const Icon(Icons.history, color: _C.or, size: 18),
        const SizedBox(width: 8),
        Text('Historique', style: _serif(18)),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long, color: Colors.white38, size: 40),
          SizedBox(height: 10),
          Text('Aucune transaction pour l\'instant',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          SizedBox(height: 4),
          Text('Tes gains apparaîtront ici',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _transactionTile(Map<String, dynamic> tx) {
    final montant = (tx['montant'] as num?)?.toInt() ?? 0;
    final isPositive = montant >= 0;
    final date = tx['created_at']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['description'] ?? 'Transaction',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  date.length >= 10 ? date.substring(0, 10) : date,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}$montant ND',
            style: TextStyle(
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _comingSoon(String action) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _C.nuit2,
      content: Text('$action bientôt disponible',
          style: const TextStyle(color: _C.or)),
    ));
  }
}
