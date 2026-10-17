import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  const ResponsiveScaffold({super.key, required this.child, required this.title});

  @override Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: Text(title), backgroundColor: const Color(0xFF0B2B2F)),
      body: SafeArea(bottom: false, child: Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80), child: child)),
      bottomNavigationBar: SafeArea(
        child: Container(height: 70 + MediaQuery.of(context).padding.bottom, padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(color: Color(0xFF0E3A3D), border: Border(top: BorderSide(color: Colors.white12))),
          child: BottomNavigationBar(backgroundColor: Colors.transparent, elevation: 0, selectedItemColor: const Color(0xFFE0A82E), unselectedItemColor: Colors.white54, selectedFontSize: 10, unselectedFontSize: 9, iconSize: 22, type: BottomNavigationBarType.fixed,
            onTap: (i) => context.go(['/', '/carte', '/dashboard', '/modules', '/profil'][i]),
            items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'), BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Cités'), BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Board'), BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Modules'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil')],
          ),
        ),
      ),
      floatingActionButton: Padding(padding: EdgeInsets.only(bottom: 90 + MediaQuery.of(context).padding.bottom), child: FloatingActionButton.extended(onPressed: () => context.go('/ia-guide'), backgroundColor: const Color(0xFFE0A82E), icon: const Icon(Icons.smart_toy, color: Colors.black, size: 18), label: const Text('IA Guide', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)))),
    );
  }
}