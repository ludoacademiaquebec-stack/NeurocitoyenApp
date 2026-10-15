import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IAGuideGlobal extends StatefulWidget {
  const IAGuideGlobal({super.key});
  @override
  State<IAGuideGlobal> createState()=> _IAGuideGlobalState();
}

class _IAGuideGlobalState extends State<IAGuideGlobal> {
  List<Map<String,String>> chat=[
    {'role':'ia','text':'Bienvenue dans la Ligue Panafricaine des Neurocitoyens 🌍\n\nJe suis ton **Guide IA LIVE**.\n\n**Je maîtrise :**\n• **Charte 47 articles** : valeurs, droits, gouvernance\n• **Modèle Eco 295M FCFA** + 3 fonds (Ligue 8% | Solidarité 5% | Initiatives 4%)\n• **Parcours 5 modules** : QCM 85% + Université\n\nPose ta question, je te réponds comme Coach Baobab.'},
  ];
  final ctrl=TextEditingController();
  final scrollCtrl=ScrollController();
  bool loading=false;

  final suggestions = ["C'est quoi la Charte?", "Explique le Modèle Eco 295M", "Comment marche le Parcours?", "Les 3 fonds 17%"];

  Future<void> send(String t) async {
    if(t.trim().isEmpty || loading) return;
    setState((){ chat.add({'role':'user','text':t}); loading=true; });
    ctrl.clear();
    scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent+300, duration: const Duration(milliseconds:300), curve: Curves.easeOut);
    try {
      final res = await Supabase.instance.client.functions.invoke('ia-chat', body: {'message': t, 'ia_type': 'GUIDE', 'prompt': t});
      String text='Pas de réponse';
      if(res.data is Map) text=(res.data['response']??res.data['reponse']??'').toString();
      setState(()=> chat.add({'role':'ia','text': text}));
    } catch (e) { setState(()=> chat.add({'role':'ia','text': '⚠️ $e'})); }
    finally { setState(()=> loading=false); Future.delayed(const Duration(milliseconds:200), ()=> scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds:400), curve: Curves.easeOut)); }
  }

  Widget _inlineRich(String txt, bool isUser){
    List<InlineSpan> spans=[]; final regex=RegExp(r'\*\*(.*?)\*\*'); int last=0;
    for(final m in regex.allMatches(txt)){
      if(m.start>last) spans.add(TextSpan(text: txt.substring(last,m.start)));
      spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      last=m.end;
    }
    if(last<txt.length) spans.add(TextSpan(text: txt.substring(last)));
    return RichText(text: TextSpan(style: TextStyle(fontSize:12.8, height:1.5, color: isUser? Colors.black.withOpacity(0.9): Colors.white.withOpacity(0.92)), children: spans.isEmpty?[TextSpan(text: txt)]:spans));
  }

  Widget _buildRich(String raw, bool isUser){
    final lines=raw.split('\n'); List<Widget> w=[];
    for(var line in lines){
      if(line.trim().isEmpty){ w.add(const SizedBox(height:8)); continue; }
      if(line.startsWith('### ')||line.startsWith('## ')||line.startsWith('# ')){
        var t=line.replaceAll(RegExp(r'^#+\s*'), '');
        w.add(Padding(padding: const EdgeInsets.only(top:12,bottom:4), child: Text(t, style: TextStyle(fontWeight: FontWeight.w800, fontSize: isUser?14:13, color: isUser? Colors.black: const Color(0xFFFFC400)))));
      } else if(line.trim().startsWith('- ')||line.trim().startsWith('• ')){
        var t=line.trim().substring(2);
        w.add(Padding(padding: const EdgeInsets.only(left:8,bottom:6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[Text('• ', style: TextStyle(color: isUser? Colors.black54: const Color(0xFFFFC400), fontWeight: FontWeight.bold)), Expanded(child: _inlineRich(t, isUser))]))));
      } else {
        w.add(Padding(padding: const EdgeInsets.only(bottom:6), child: _inlineRich(line, isUser)));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: w);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFF070A1A),
      appBar: AppBar(backgroundColor: const Color(0xFF070A1A), elevation:0, leading: IconButton(icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_back, color: Colors.white, size:18)), onPressed: ()=>context.go('/')), title: Row(children:[Container(width:36,height:36,decoration: BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFFFFC400), Color(0xFFFF8C00)]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.auto_awesome, color: Colors.black, size:20)), const SizedBox(width:10), const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text('IA Guide • LIVE', style: TextStyle(fontSize:13, fontWeight: FontWeight.w800, color: Colors.white)), Text('Groq Llama 3.3 70B • Charte 47', style: TextStyle(fontSize:9, color: Colors.white54))])]), actions:[Container(margin: const EdgeInsets.only(right:12), padding: const EdgeInsets.symmetric(horizontal:10,vertical:5), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3))), child: Row(children:[Container(width:6,height:6,decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)), const SizedBox(width:6), const Text('En ligne', style: TextStyle(fontSize:9, color: Color(0xFF10B981), fontWeight: FontWeight.w700))])),
      ),
      body: Column(children:[
        SizedBox(height:44, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal:12), scrollDirection: Axis.horizontal, itemCount: suggestions.length, separatorBuilder: (_,__)=> const SizedBox(width:8), itemBuilder: (c,i)=> ActionChip(label: Text(suggestions[i], style: const TextStyle(fontSize:10, fontWeight: FontWeight.w600)), backgroundColor: Colors.white.withOpacity(0.06), side: BorderSide(color: Colors.white.withOpacity(0.1)), labelStyle: const TextStyle(color: Colors.white70), onPressed: ()=>send(suggestions[i])))),
        const Divider(color: Colors.white10, height:1),
        Expanded(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors:[Color(0xFF070A1A), Color(0xFF0E1430)])), child: ListView.builder(controller: scrollCtrl, padding: const EdgeInsets.fromLTRB(14,16,14,16), itemCount: chat.length, itemBuilder: (c,i){
          var m=chat[i]; bool isUser=m['role']=='user';
          return Align(alignment: isUser? Alignment.centerRight: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom:14), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.86), decoration: BoxDecoration(color: isUser? const Color(0xFFFFC400): const Color(0xFF151C3A), borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isUser?18:4), bottomRight: Radius.circular(isUser?4:18)), border: isUser? null: Border.all(color: Colors.white.withOpacity(0.06)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius:12, offset: const Offset(0,4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            if(!isUser) Padding(padding: const EdgeInsets.fromLTRB(14,10,14,0), child: Row(children:[Container(width:22,height:22,decoration: BoxDecoration(color: const Color(0xFFFFC400).withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.psychology, size:12, color: Color(0xFFFFC400))), const SizedBox(width:6), const Text('Guide Ligue', style: TextStyle(fontSize:9, fontWeight: FontWeight.w800, color: Color(0xFFFFC400), letterSpacing:0.5))])),
            Padding(padding: const EdgeInsets.all(14), child: _buildRich(m['text']!, isUser)),
          ])));
        }))),
        if(loading) Padding(padding: const EdgeInsets.symmetric(horizontal:14, vertical:6), child: Row(children:[Container(width:32,height:32,decoration: BoxDecoration(color: const Color(0xFF151C3A), borderRadius: BorderRadius.circular(10)), child: const Center(child: SizedBox(width:14,height:14, child: CircularProgressIndicator(strokeWidth:2, color: Color(0xFFFFC400))))), const SizedBox(width:10), const Text('Le Guide réfléchit...', style: TextStyle(color: Colors.white54, fontSize:11, fontStyle: FontStyle.italic))])),
        Container(padding: const EdgeInsets.fromLTRB(12,10,12,12), decoration: BoxDecoration(color: const Color(0xFF0A0E25), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06)))), child: Row(children:[
          Expanded(child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.08))), child: TextField(controller: ctrl, onSubmitted: send, minLines:1, maxLines:4, style: const TextStyle(color: Colors.white, fontSize:13), decoration: const InputDecoration(hintText: 'Pose ta question à la Ligue...', hintStyle: TextStyle(color: Colors.white38, fontSize:12), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal:16, vertical:12))))),
          const SizedBox(width:10),
          Container(decoration: BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFFFFC400), Color(0xFFFF9A00)]), borderRadius: BorderRadius.circular(14)), child: IconButton(onPressed: ()=>send(ctrl.text), icon: const Icon(Icons.send_rounded, size:18), color: Colors.black, padding: const EdgeInsets.all(12))),
        ]),
      ]),
    );
  }
}
