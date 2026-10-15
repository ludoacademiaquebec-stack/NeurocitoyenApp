import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/app_scaffold.dart';

class _C {
  static const nuit = Color(0xFF060A1F);
  static const nuit2 = Color(0xFF121845);
  static const nuit3 = Color(0xFF0B102E);
  static const or = Color(0xFFC4952B);
  static const orClair = Color(0xFFF0D9A0);
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

class AgoraScreen extends StatefulWidget {
  const AgoraScreen({super.key});
  @override
  State<AgoraScreen> createState() => _AgoraScreenState();
}

class _AgoraScreenState extends State<AgoraScreen> {
  String _paysId = 'BJ';
  String _paysNom = 'Bénin';
  bool _loading = true;
  List<Map<String, dynamic>> _posts = [];

  static const _agoraExterneUrl = 'https://2asinternational.org/agora/';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _paysId = prefs.getString('pays_id') ?? 'BJ';
      _paysNom = _paysId;
    });

    try {
      final country = await Supabase.instance.client
          .from('countries')
          .select('nom')
          .eq('id', _paysId)
          .maybeSingle();
      if (country != null) {
        setState(() => _paysNom = country['nom'] as String? ?? _paysId);
      }

      try {
        final res = await Supabase.instance.client
            .from('agora_posts')
            .select()
            .eq('pays_id', _paysId)
            .order('created_at', ascending: false)
            .limit(30);
        _posts = List<Map<String, dynamic>>.from(res);
      } catch (_) {}
    } catch (_) {}

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mon Agora',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(),
                const SizedBox(height: 16),
                if (_paysId == 'BJ') _agoraExterneCard(),
                if (_paysId != 'BJ') _agoraACreerCard(),
                const SizedBox(height: 20),
                _postsTitle(),
                const SizedBox(height: 10),
                if (_posts.isEmpty)
                  _emptyPosts()
                else
                  ..._posts.map(_postTile),
              ],
            ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.or, Color(0xFF8B6914)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AGORA',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text('Agora de $_paysNom',
              style: _serif(24, color: Colors.black, weight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'L\'Agora est la place publique de ta Cité. Ici, tu échanges avec les autres Neurocitoyens de ton pays.',
            style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _agoraExterneCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.or.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.open_in_new, color: _C.or, size: 20),
              const SizedBox(width: 8),
              Text('Agora Bénin (plateforme active)',
                  style: _serif(16)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'La plateforme Agora du Bénin est déjà active sur 2asinternational.org. Ouvre-la pour rejoindre les échanges.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(_agoraExterneUrl);
                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: _C.nuit2,
                          content: Text('Impossible d\'ouvrir le lien',
                              style: TextStyle(color: _C.or)),
                        ),
                      );
                    }
                  }
                } catch (_) {}
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('OUVRIR L\'AGORA BÉNIN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.or,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _agoraACreerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.construction, color: _C.or, size: 20),
              const SizedBox(width: 8),
              Text('Agora $_paysNom en préparation',
                  style: _serif(16)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'L\'Agora de ton pays est en cours de création. Nous cherchons des ambassadeurs pour la lancer. '
            'Contacte-nous si tu veux être le premier Agoranome de ta Cité.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _postsTitle() {
    return Row(
      children: [
        const Icon(Icons.forum, color: _C.or, size: 18),
        const SizedBox(width: 8),
        Text('Discussions locales', style: _serif(18)),
      ],
    );
  }

  Widget _emptyPosts() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Icon(Icons.chat_bubble_outline, color: Colors.white38, size: 40),
          const SizedBox(height: 10),
          Text(
            'Aucune discussion dans l\'Agora de $_paysNom',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text('Sois le premier à publier !',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _postTile(Map<String, dynamic> p) {
    final date = p['created_at']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p['titre'] ?? 'Sans titre',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(p['contenu'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              date.length >= 10 ? date.substring(0, 10) : date,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
