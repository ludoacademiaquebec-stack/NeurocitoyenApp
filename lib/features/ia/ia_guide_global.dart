import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _C {
  static const bg = Color(0xFF070B1F);
  static const surface = Color(0xFF101737);
  static const field = Color(0xFF1C2452);
  static const gold = Color(0xFFFFC400);
  static const card = Color(0xFFF8FAFF); // carte IA claire
  static const ink = Color(0xFF0E1533);
  static const muted = Color(0xFF66708F);
  static const line = Color(0xFFE2E8F8);
}

enum _Kind { user, ai, error, result }
class _Msg { final _Kind kind; final String text; const _Msg(this.kind, this.text); }

class IAGuideGlobal extends StatefulWidget {
  const IAGuideGlobal({super.key, this.iaType='GUIDE', this.moduleId, this.title='Guide IA', this.subtitle='République des Neurocitoyens'});
  final String iaType; final String? moduleId; final String title; final String subtitle;
  @override
  State<IAGuideGlobal> createState()=> _IAGuideGlobalState();
}

class _IAGuideGlobalState extends State<IAGuideGlobal> {
  late List<_Msg> _msgs;
  final _ctrl=TextEditingController();
  final _scroll=ScrollController();
  bool _loading=false;
  String _last='';

  @override
  void initState(){
    super.initState();
    _msgs=[const _Msg(_Kind.ai,'Bienvenue dans la Ligue Panafricaine des Neurocitoyens 🌍\n\nJe suis ton **Guide IA LIVE**.\n\n**Mes domaines :**\n• Charte 47 articles\n• Modèle Eco 295M + 3 fonds 17%\n• Parcours 5 modules QCM 85%\n\nPose ta question, Coach Baobab te répond.')];
  }
  @override
  void dispose(){ _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  void _toEnd(){ WidgetsBinding.instance.addPostFrameCallback((_) { if(_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds:280), curve: Curves.easeOut); }); }

  Future<void> _send(String raw,{bool retry=false}) async {
    final t=raw.trim(); if(t.isEmpty||_loading) return;
    setState((){ if(retry && _msgs.isNotEmpty && _msgs.last.kind==_Kind.error) _msgs.removeLast(); else _msgs.add(_Msg(_Kind.user,t)); _loading=true; });
    _last=t; if(!retry) _ctrl.clear(); _toEnd();
    try{
      final res=await Supabase.instance.client.functions.invoke('ia-chat', body:{'message':t,'ia_type':widget.iaType,'prompt':t, if(widget.moduleId!=null) 'module_id':widget.moduleId});
      String ans='';
      if(res.data is Map) ans=(res.data['response']??res.data['reponse']??'').toString();
      if(ans.trim().isEmpty) ans="Je n'ai pas pu formuler de réponse. Reformule?";
      if(!mounted) return;
      setState(()=> _msgs.add(_Msg(_Kind.ai, ans)));
    }catch(e){
      if(mounted) setState(()=> _msgs.add(_Msg(_Kind.error, 'Connexion impossible. Réessaie.')));
    }finally{
      if(mounted) setState(()=> _loading=false); _toEnd();
    }
  }

  @override
  Widget build(BuildContext context){
    final maxW=math.min(MediaQuery.of(context).size.width, 820)*0.86;
    final showChips=_msgs.length==1 &&!_loading;
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(backgroundColor: _C.surface, foregroundColor: Colors.white, elevation:0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: ()=> context.canPop()?context.pop():context.go('/')), title: Row(children:[Container(width:34,height:34,decoration: const BoxDecoration(gradient: LinearGradient(colors:[_C.gold, Color(0xFFFF8A00)]), shape: BoxShape.circle), child: const Icon(Icons.psychology_alt_rounded, color: _C.ink, size:20)), const SizedBox(width:10), Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(widget.title, style: const TextStyle(fontSize:15, fontWeight: FontWeight.w800)), Text(widget.subtitle, style: const TextStyle(fontSize:10, color: Colors.white54))])]), bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height:1, color: _C.gold.withOpacity(0.3)))),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth:820), child: Column(children:[
        Expanded(child: ListView.builder(controller: _scroll, padding: const EdgeInsets.fromLTRB(14,18,14,8), itemCount: _msgs.length+(_loading?1:0), itemBuilder: (c,i){
          if(i==_msgs.length) return const _Typing();
          final m=_msgs[i];
          if(m.kind==_Kind.user) return _User(text:m.text, maxW:maxW);
          if(m.kind==_Kind.error) return _Error(text:m.text, onRetry:()=>_send(_last, retry:true));
          return _AI(text:m.text, maxW:maxW);
        })),
        if(showChips) Padding(padding: const EdgeInsets.fromLTRB(12,0,12,10), child: Wrap(spacing:8, runSpacing:8, children:[
          for(final s in ["C'est quoi la Charte?","Modèle Eco 295M","Parcours 5 modules","Les 3 fonds 17%"])
            ActionChip(label: Text(s, style: const TextStyle(color: Colors.white, fontSize:12.5, fontWeight: FontWeight.w600)), backgroundColor: _C.field, side: BorderSide(color: _C.gold.withOpacity(0.5)), onPressed: ()=>_send(s))
        ])),
        Container(decoration: const BoxDecoration(color: _C.surface, border: Border(top: BorderSide(color: Color(0x1AFFFFFF)))), padding: const EdgeInsets.fromLTRB(12,10,12,12), child: Row(children:[
          Expanded(child: Container(decoration: BoxDecoration(color: _C.field, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.08))), child: TextField(controller: _ctrl, minLines:1, maxLines:4, style: const TextStyle(color: Colors.white, fontSize:14.5), decoration: const InputDecoration(hintText:'Pose ta question à la Ligue...', hintStyle: TextStyle(color: Colors.white38, fontSize:13), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal:18, vertical:12)), onSubmitted: (v)=>_send(v)))),
          const SizedBox(width:10),
          Container(decoration: BoxDecoration(gradient: const LinearGradient(colors:[_C.gold, Color(0xFFFF9A00)]), borderRadius: BorderRadius.circular(14)), child: IconButton.filled(onPressed: _loading?null:()=>_send(_ctrl.text), icon: const Icon(Icons.send_rounded, size:18), style: IconButton.styleFrom(backgroundColor: _C.gold, foregroundColor: _C.ink, minimumSize: const Size(48,48)))),
        ])),
      ]))),
    );
  }
}

// ===================== UI =====================

class _User extends StatelessWidget{
  const _User({required this.text, required this.maxW}); final String text; final double maxW;
  @override
  Widget build(BuildContext context)=> Align(alignment: Alignment.centerRight, child: Container(margin: const EdgeInsets.only(bottom:16), padding: const EdgeInsets.symmetric(horizontal:16, vertical:11), constraints: BoxConstraints(maxWidth: maxW), decoration: const BoxDecoration(color: _C.gold, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(4))), child: Text(text, style: const TextStyle(color: _C.ink, fontSize:14.5, height:1.4, fontWeight: FontWeight.w600))));
}

class _AI extends StatelessWidget{
  const _AI({required this.text, required this.maxW}); final String text; final double maxW;
  List<Widget> _parse(String raw){
    final lines=raw.split('\n'); List<Widget> out=[];
    for(var l in lines){
      final t=l.trim();
      if(t.isEmpty){ out.add(const SizedBox(height:8)); continue; }
      if(t.startsWith('### ')||t.startsWith('## ')||t.startsWith('# ')){
        final title=t.replaceAll(RegExp(r'^#+\s*'), '');
        out.add(Padding(padding: const EdgeInsets.only(top:14,bottom:6), child: Row(children:[Container(width:4,height:18,decoration: BoxDecoration(color: _C.gold, borderRadius: BorderRadius.circular(2))), const SizedBox(width:8), Expanded(child: Text(title, style: const TextStyle(fontSize:15.5, fontWeight: FontWeight.w800, color: _C.ink)))])));
      } else if(t.startsWith('- ')||t.startsWith('• ')){
        final content=t.substring(2);
        out.add(Container(margin: const EdgeInsets.only(bottom:8), padding: const EdgeInsets.symmetric(horizontal:12, vertical:8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.line)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[Container(margin: const EdgeInsets.only(top:6), width:6,height:6,decoration: const BoxDecoration(color: _C.gold, shape: BoxShape.circle)), const SizedBox(width:10), Expanded(child: _rich(content))])));
      } else {
        out.add(Padding(padding: const EdgeInsets.only(bottom:8), child: _rich(l)));
      }
    }
    return out;
  }

  static Widget _rich(String s){
    final parts=s.split(RegExp(r'\*\*')); // simple bold
    List<InlineSpan> spans=[];
    for(int i=0;i<parts.length;i++){
      final isBold=i%2==1;
      spans.add(TextSpan(text: parts[i], style: TextStyle(fontWeight: isBold?FontWeight.w800:FontWeight.w500)));
    }
    return RichText(text: TextSpan(style: const TextStyle(fontSize:14, height:1.55, color: _C.ink), children: spans));
  }

  @override
  Widget build(BuildContext context){
    return Padding(padding: const EdgeInsets.only(bottom:16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Container(width:32,height:32,decoration: const BoxDecoration(color: _C.gold, shape: BoxShape.circle), child: const Icon(Icons.psychology_alt_rounded, size:18, color: _C.ink)),
      const SizedBox(width:10),
      Flexible(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxW), child: Container(padding: const EdgeInsets.fromLTRB(16,14,16,14), decoration: BoxDecoration(color: _C.card, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)), border: Border.all(color: _C.line), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius:16, offset: const Offset(0,4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _parse(text))))),
    ]));
  }
}

class _Error extends StatelessWidget{
  const _Error({required this.text, required this.onRetry}); final String text; final VoidCallback onRetry;
  @override
  Widget build(BuildContext context)=> Padding(padding: const EdgeInsets.only(bottom:16), child: Row(children:[Container(width:32,height:32,decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.error_outline, size:18, color: Color(0xFFB42318))), const SizedBox(width:10), Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF4B0B0))), child: Row(children:[Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF7A1F1F), fontSize:13))), TextButton(onPressed: onRetry, child: const Text('Réessayer'))])))]));
}

class _Typing extends StatefulWidget{ const _Typing(); @override State<_Typing> createState()=> _TypingState(); }
class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin{
  late final _c=AnimationController(vsync:this, duration: const Duration(milliseconds:1200))..repeat();
  @override void dispose(){ _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context)=> Padding(padding: const EdgeInsets.only(bottom:16), child: Row(children:[Container(width:32,height:32,decoration: const BoxDecoration(color: _C.gold, shape: BoxShape.circle), child: const Icon(Icons.psychology_alt_rounded, size:18, color: _C.ink)), const SizedBox(width:10), Container(padding: const EdgeInsets.symmetric(horizontal:16, vertical:14), decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.line)), child: Row(children:[for(int i=0;i<3;i++) AnimatedBuilder(animation: _c, builder: (_,__) { final t=(_c.value-i*0.2)%1.0; final o=0.3+0.7*(t<0.5?t*2:(1-t)*2); return Container(margin: const EdgeInsets.symmetric(horizontal:3), width:8,height:8, decoration: BoxDecoration(color: _C.ink.withOpacity(o), shape: BoxShape.circle)); })]))]));
}
