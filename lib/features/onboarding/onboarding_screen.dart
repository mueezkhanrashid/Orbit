import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _i=0;
  final _pages = const [
    {'t':'Your Pakistan, in one place','s':'News • Jobs • Scholarships • Weather','icon': Icons.public},
    {'t':'Live Space & Markets','s':'ISS • KSE 100 • BTC — live','icon': Icons.rocket_launch},
    {'t':'Faith','s':'Quran • Namaz • Zikar • Qibla','icon': Icons.mosque},
  ];
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitTheme.bg,
      body: SafeArea(child: Column(children: [
        Expanded(child: PageView.builder(
          controller: _page, onPageChanged: (i)=> setState(()=> _i=i), itemCount: _pages.length,
          itemBuilder: (_,i){
            final p=_pages[i];
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 88, height: 88, decoration: BoxDecoration(color: OrbitTheme.accent, borderRadius: BorderRadius.circular(12)), child: Icon(p['icon'] as IconData, color: Colors.white, size: 36)),
                const SizedBox(height: 24),
                Text(p['t'] as String, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 22, height: 1.2)),
                const SizedBox(height: 8),
                Text(p['s'] as String, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 13)),
              ]),
            );
          },
        )),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_pages.length, (i)=> Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: _i==i?20:6, height: 6, decoration: BoxDecoration(color: _i==i?OrbitTheme.primary:OrbitTheme.outline, borderRadius: BorderRadius.circular(999))))),
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: SizedBox(width: double.infinity, child: FilledButton(
          onPressed: (){
            if (_i < _pages.length-1) {
              _page.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
            } else {
              Navigator.of(context).pop();
            }
          },
          style: FilledButton.styleFrom(backgroundColor: OrbitTheme.ink, padding: const EdgeInsets.symmetric(vertical: 14)),
          child: Text(_i==_pages.length-1 ? 'Enter ORBIT' : 'Continue'),
        ))),
        TextButton(onPressed: ()=> Navigator.of(context).pop(), child: const Text('Skip', style: TextStyle(color: OrbitTheme.muted))),
        const SizedBox(height: 12),
      ])),
    );
  }
}
