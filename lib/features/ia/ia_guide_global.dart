import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';

class _C {
  static const bg = Color(0xFF070B1F);
  static const surface = Color(0xFF101737);
  static const field = Color(0xFF1C2452);
  static const gold = Color(0xFFE0A82E);
  static const card = Color(0xFFF8FAFF);
  static const ink = Color(0xFF0E1533);
  static const line = Color(0xFFE2E8F8);
}

enum _Kind { user, ai, error }
class _Msg { final _Kind kind; final String text; const _Msg(this.kind, this.text); }

class IAGuideGlobal extends StatefulWidget {
  const IAGuideGlobal({super.key, this.iaType='GUIDE', this.moduleId, this.title='Guide IA', this.subtitle='République des Neurocitoyens'});
  final String iaType; final String? moduleId; final String title; final String subtitle;
  @override
  State<IAGuideGlobal> createState()=> _IAGuideGlobalState();
}

class _IAGuideGlobalState extends State<IAGuideGlobal> {
  List<_Msg> _msgs=[const _Msg(_Kind.ai,'Bienvenue 🌍\n\nJe suis ton **Guide IA LIVE**.\n\n• Charte 47 articles\n• Modèle Eco 295M + 3 fonds\n• Parcours 5 modules\n\nParle ou écris, je t\'écoute.')];
  final _ctrl=TextEditingController();
  final _scroll=ScrollController();
  bool _loading=false;
  String _last='';
  final SpeechToText _speech=SpeechToText();
  bool _isListening=false;

  @override
  void initState(){ super.initState(); _initSpeech(); }
  Future<void> _initSpeech() async { await _speech.initialize(); }

  void _toEnd(){ WidgetsBinding.instance.addPostFrameCallback((_) { if(_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds:280), curve: Curves.easeOut); }); }

  Future<void> _toggleMic() async {
    if(_isListening){
      await _speech.stop(); setState(()=>_isListening=false); return;
    }
    bool available = await _speech.initialize();
    if(!available) return;
    setState(()=>_isListening=true);
    await _speech.listen(localeId:'fr_FR', onResult:(res){
      _ctrl.text=res.recognizedWords;
      if(res.finalResult){ setState(()=>_isListening=false); _send(_ctrl.text); }
    });
  }

  Future<void> _send(String raw,{bool retry=false}) async {
    final t=raw.trim(); if(t.isEmpty||_loading) return;
    setState((){ if(retry && _msgs.isNotEmpty && _msgs.last.kind==_Kind.error) _msgs.removeLast(); else _msgs.add(_Msg(_Kind.user,t)); _loading=true; });
    _last=t; if(!retry) _ctrl.clear(); _toEnd();
    try{
      final res=await Supabase.instance.client.functions.invoke('ia-chat', body:{'message':t,'ia_type':widget.iaType,'prompt':t, if(widget.moduleId!=null) 'module_id':widget.moduleId});
      String ans=''; if(res.data is Map) ans=(res.data['response']??res.data['reponse']??'').toString();
      if(ans.trim().isEmpty) ans="Je n'ai pas pu répondre. Reformule?";
      setState(()=>_msgs.add(_Msg(_Kind.ai,ans)));
    }catch(e){ setState(()=>_msgs.add(_Msg(_Kind.error,'Connexion impossible. Réessaie.'))); }
    finally{ setState(()=>_loading=false); _toEnd(); }
  }

  Widget _rich(String s){
    final parts=s.split(RegExp(r'\*\*')); List<InlineSpan> spans=[];
    for(int i=0;i<parts.length;i++){ spans.add(TextSpan(text: parts[i], style: TextStyle(fontWeight: i%2==1?FontWeight.w800:FontWeight.w500))); }
    return RichText(text: TextSpan(style: const TextStyle(fontSize:14, height:1.55, color: _C.ink), children: spans));
  }

  List<Widget> _parse(String raw){
    final lines=raw.split('\n'); List<Widget> out=[];
    for(var l in lines){
      final t=l.trim(); if(t.isEmpty){ out.add(const SizedBox(height:8)); continue; }
      if(t.startsWith('#')){ final title=t.replaceAll(RegExp(r'^#+\s*'), ''); out.add(Padding(padding: const EdgeInsets.only(top:14,bottom:6), child: Row(children:[Container(width:4,height:18,decoration: BoxDecoration(color: _C.gold, borderRadius: BorderRadius.circular(2))), const SizedBox(width:8), Expanded(child: Text(title, style: const TextStyle(fontSize:15.5, fontWeight: FontWeight.w800, color: _C.ink)))]))); }
      else if(t.startsWith('- ')||t.startsWith('• ')){ final c=t.substring(2); out.add(Container(margin: const EdgeInsets.only(bottom:8), padding: const EdgeInsets.symmetric(horizontal:12, vertical:8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.line)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[Container(margin: const EdgeInsets.only(top:6), width:6,height:6,decoration: const BoxDecoration(color: _C.gold, shape: BoxShape.circle)), const SizedBox(width:10), Expanded(child: _rich(c))]))); }
      else { out.add(Padding(padding: const EdgeInsets.only(bottom:8), child: _rich(l))); }
    }
    return out;
  }

  @override
  Widget build(BuildContext context){
    final maxW=math.min(MediaQuery.of(context).size.width, 820)*0.86;
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(backgroundColor: _C.surface, foregroundColor: Colors.white, elevation:0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: ()=> context.canPop()?context.pop():context.go('/')), title: Row(children:[Container(width:34,height:34,decoration: const BoxDecoration(gradient: LinearGradient(colors:[_C.gold, Color(0xFFFF8A00)]), shape: BoxShape.circle), child: const Icon(Icons.psychology_alt_rounded, color: _C.ink, size:20)), const SizedBox(width:10), Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(widget.title, style: const TextStyle(fontSize:15, fontWeight: FontWeight.w800)), Text(widget.subtitle, style: const TextStyle(fontSize:10, color: Colors.white54))])]), bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height:1, color: _C.gold.withOpacity(0.3)))),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth:820), child: Column(children:[
        Expanded(child: ListView.builder(controller: _scroll, padding: const EdgeInsets.fromLTRB(14,18,14,8), itemCount: _msgs.length+(_loading?1:0), itemBuilder: (c,i){
          if(i==_msgs.length) return Padding(padding: const EdgeInsets.only(bottom:16), child: Row(children:[Container(width:32,height:32,decoration: const BoxDecoration(color: _C.gold, shape: BoxShape.circle), child: const Icon(Icons.psychology_alt_rounded, size:18, color: _C.ink)), const SizedBox(width:10), Container(padding: const EdgeInsets.symmetric(horizontal:16, vertical:14), decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.line)), child: const SizedBox(width:24,height:8, child: LinearProgressIndicator(color: _C.gold, backgroundColor: _C.line)))]));
          final m=_msgs[i]; if(m.kind==_Kind.user) return Align(alignment: Alignment.centerRight, child: Container(margin: const EdgeInsets.only(bottom:16), padding: const EdgeInsets.symmetric(horizontal:16, vertical:11), constraints: BoxConstraints(maxWidth: maxW), decoration: const BoxDecoration(color: _C.gold, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(4))), child: Text(m.text, style: const TextStyle(color: _C.ink, fontSize:14.5, fontWeight: FontWeight.w600))));
          if(m.kind==_Kind.error) return Padding(padding: const EdgeInsets.only(bottom:16), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)), child: Row(children:[Expanded(child: Text(m.text, style: const TextStyle(color: Color(0xFF7A1F1F), fontSize:13))), TextButton(onPressed: ()=>_send(_last, retry:true), child: const Text('Réessayer'))])));
          return Padding(padding: const EdgeInsets.only(bottom:16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[Container(width:32,height:32,decoration: const BoxDecoration(color: _C.gold, shape: BoxShape.circle), child: const Icon(Icons.psychology_alt_rounded, size:18, color: _C.ink)), const SizedBox(width:10), Flexible(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxW), child: Container(padding: const EdgeInsets.fromLTRB(16,14,16,14), decoration: BoxDecoration(color: _C.card, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)), border: Border.all(color: _C.line), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius:16)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _parse(m.text)))))]));
        })),
        Padding(padding: const EdgeInsets.fromLTRB(12,0,12,10), child: Wrap(spacing:8, runSpacing:8, children:[for(final s in ["Charte?","Modèle 295M","Parcours?","3 fonds"]) ActionChip(label: Text(s, style: const TextStyle(color: Colors.white, fontSize:12, fontWeight: FontWeight.w600)), backgroundColor: _C.field, side: BorderSide(color: _C.gold.withOpacity(0.5)), onPressed: ()=>_send(s))])),
        Container(decoration: const BoxDecoration(color: _C.surface, border: Border(top: BorderSide(color: Color(0x1AFFFFFF)))), padding: const EdgeInsets.fromLTRB(10,10,10,12), child: Row(children:[
          Container(decoration: BoxDecoration(color: _isListening? Colors.red.withOpacity(0.15): Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: _isListening? Colors.red.withOpacity(0.5): Colors.white.withOpacity(0.1))), child: IconButton(onPressed: _toggleMic, icon: Icon(_isListening? Icons.mic: Icons.mic_none_rounded, color: _isListening? Colors.red: Colors.white70), tooltip: 'Parler')),
          const SizedBox(width:8),
          Expanded(child: Container(decoration: BoxDecoration(color: _C.field, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.08))), child: TextField(controller: _ctrl, minLines:1, maxLines:4, style: const TextStyle(color: Colors.white, fontSize:14.5), decoration: const InputDecoration(hintText:'Écris ou parle...', hintStyle: TextStyle(color: Colors.white38, fontSize:13), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal:18, vertical:12)), onSubmitted: (v)=>_send(v)))),
          const SizedBox(width:8),
          Container(decoration: BoxDecoration(gradient: const LinearGradient(colors:[_C.gold, Color(0xFFFF9A00)]), borderRadius: BorderRadius.circular(14)), child: IconButton.filled(onPressed: _loading?null:()=>_send(_ctrl.text), icon: const Icon(Icons.send_rounded, size:18), style: IconButton.styleFrom(backgroundColor: _C.gold, foregroundColor: _C.ink, minimumSize: const Size(48,48)))),
        ])),
      ]))),
    );
  }
}
