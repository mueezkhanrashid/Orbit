import '../storage/hive_boxes.dart';

// Profile — on-device, private, no server. Powers SMART LEADS.
// User sets once, then SMART engine auto-tunes from taps/saves/searches (local learning).

class OrbitProfile {
  final String field; // e.g., Computer Science, Business, Engineering
  final String level; // BS, Masters, PhD, All
  final List<String> skills; // flutter, python, data, marketing
  final String preferredLocation; // Lahore, Remote, Any
  final String fundingPref; // Fully funded, Any
  final bool remoteOnly;
  const OrbitProfile({
    this.field='All',
    this.level='Masters',
    this.skills=const ['flutter','python'],
    this.preferredLocation='Any',
    this.fundingPref='Fully funded',
    this.remoteOnly=false,
  });
  Map<String,dynamic> toJson()=> {'field':field,'level':level,'skills':skills,'preferredLocation':preferredLocation,'fundingPref':fundingPref,'remoteOnly':remoteOnly};
  factory OrbitProfile.fromJson(Map<String,dynamic> j)=> OrbitProfile(
    field: j['field']??'All',
    level: j['level']??'Masters',
    skills: List<String>.from(j['skills']??['flutter']),
    preferredLocation: j['preferredLocation']??'Any',
    fundingPref: j['fundingPref']??'Fully funded',
    remoteOnly: j['remoteOnly']??false,
  );
}

class ProfileStore {
  static const _key='orbit_profile_v2';
  static const _historyKey='orbit_smart_history_v2'; // taps, saves, searches

  OrbitProfile load(){
    final v = OrbitBoxes.box(OrbitBoxes.prefs).get(_key);
    if(v is Map) return OrbitProfile.fromJson(Map<String,dynamic>.from(v));
    return const OrbitProfile();
  }
  Future<void> save(OrbitProfile p) async {
    OrbitBoxes.box(OrbitBoxes.prefs).put(_key, p.toJson());
  }

  // Smart history — local learning (no server)
  List<String> history(){
    final v = OrbitBoxes.box(OrbitBoxes.prefs).get(_historyKey);
    if(v is List) return List<String>.from(v);
    return [];
  }
  void addHistory(String event){
    // event: "tap:job:flutter backend" or "search:scholarship erasmus" or "save:daad"
    final h = history();
    h.insert(0, event);
    if(h.length>80) h.removeRange(80, h.length);
    OrbitBoxes.box(OrbitBoxes.prefs).put(_historyKey, h);
  }
  // Learned keywords from history
  Set<String> learnedKeywords(){
    final kws=<String>{};
    for(final e in history()){
      final parts = e.split(':');
      if(parts.length>=2){
        final kw = parts.sublist(1).join(':').toLowerCase();
        for(final w in kw.split(RegExp(r'[^a-z0-9]+'))){
          if(w.length>=3) kws.add(w);
        }
      }
    }
    return kws;
  }
}
