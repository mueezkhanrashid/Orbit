import '../location/location_service.dart';
import 'profile_store.dart';
import '../services/jobs_service.dart';
import '../services/scholarship_service.dart';
import '../services/news_service.dart';

// SMART ENGINE — on-device, no paid AI, instant, private.
// Scores every item 0-100 and explains WHY. Learns from your taps/saves/searches (history).

class SmartLead {
  final String id, title, org, location, type, url, source;
  final String category; // job, internship, scholarship, news, market
  final int match; // 0-100
  final List<String> reasons; // why this lead for you
  final String due; // deadline or postedAt
  final bool isHot; // >85 or expiring soon
  const SmartLead({required this.id, required this.title, required this.org, required this.location, required this.type, required this.url, required this.source, required this.category, required this.match, required this.reasons, required this.due, this.isHot=false});
}

class SmartEngine {
  final ProfileStore _profileStore;
  SmartEngine({ProfileStore? store}) : _profileStore = store ?? ProfileStore();

  // Score jobs/internships
  List<SmartLead> scoreJobs(List<Job> jobs, OrbitLocation loc){
    final profile = _profileStore.load();
    final learned = _profileStore.learnedKeywords();
    return jobs.map((j){
      int score=30; // baseline
      final reasons=<String>[];
      final titleLc=j.title.toLowerCase();
      final locLc=j.location.toLowerCase();
      final cityLc=loc.city.toLowerCase();
      final countryLc=loc.country.toLowerCase();

      // Location — strongest signal
      if(locLc.contains(cityLc)){ score+=25; reasons.add('Near ${loc.city}'); }
      else if(locLc.contains(countryLc)){ score+=12; reasons.add(' ${loc.country}'); }
      else if(j.remote){ score+=8; reasons.add('🌍 Remote'); }

      // Skills / field match
      for(final s in profile.skills){
        if(titleLc.contains(s.toLowerCase())){ score+=12; reasons.add(' Skill: $s'); break; }
      }
      for(final kw in learned){
        if(titleLc.contains(kw)){ score+=6; reasons.add(' Learned: $kw'); break; }
      }
      if(profile.field!='All' && titleLc.contains(profile.field.toLowerCase())){ score+=8; reasons.add('📚 Field: ${profile.field}'); }

      // Remote pref
      if(profile.remoteOnly && j.remote){ score+=6; reasons.add('🏠 Remote pref'); }

      // Source trust (Arbeitnow/Remotive free, no spam)
      if(j.source=='Arbeitnow' || j.source=='Remotive') score+=2;

      score = score.clamp(0, 98);
      return SmartLead(
        id: j.id, title: j.title, org: j.org, location: j.location, type: j.type, url: j.url, source: j.source,
        category: j.type.toLowerCase().contains('intern')? 'internship':'job',
        match: score, reasons: reasons.take(3).toList(), due: j.postedAt, isHot: score>=82,
      );
    }).toList()..sort((a,b)=> b.match.compareTo(a.match));
  }

  List<SmartLead> scoreScholarships(List<Scholarship> items, OrbitLocation loc){
    final profile = _profileStore.load();
    final learned = _profileStore.learnedKeywords();
    return items.map((s){
      int score=28;
      final reasons=<String>[];
      final titleLc=s.title.toLowerCase();
      // For Pakistani?
      if(s.forPakistani){ score+=14; reasons.add('For Pakistani'); }
      // Level match
      if(s.level.toLowerCase().contains(profile.level.toLowerCase()) || profile.level=='All'){ score+=10; reasons.add('🎓 ${profile.level} match'); }
      // Funding pref
      if(s.funding.toLowerCase().contains(profile.fundingPref.toLowerCase().split(' ').first) || profile.fundingPref=='Any'){ score+=8; reasons.add('💰 ${s.funding}'); }
      // Field
      for(final skill in profile.skills){ if(titleLc.contains(skill.toLowerCase())){ score+=10; reasons.add(' $skill'); break; } }
      for(final kw in learned){ if(titleLc.contains(kw)){ score+=5; reasons.add(' $kw'); break; } }
      // Country vibe — if location is PK, boost PK-friendly
      if(loc.countryCode=='PK' && s.forPakistani) score+=4;
      // Deadline urgency — Rolling is low urgency, soon is high
      if(s.deadline=='Rolling'){ score+=1; } else { score+=3; reasons.add('Due ${s.deadline}'); }
      score = score.clamp(0, 97);
      return SmartLead(id:s.id, title:s.title, org:s.org, location:s.location, type:s.level, url:s.url, source:s.org, category:'scholarship', match:score, reasons:reasons.take(3).toList(), due:s.deadline, isHot: score>=80 || s.deadline.contains('2026-11'));
    }).toList()..sort((a,b)=> b.match.compareTo(a.match));
  }

  List<SmartLead> scoreNews(List<NewsArticle> news, OrbitLocation loc){
    final profile = _profileStore.load();
    final learned = _profileStore.learnedKeywords();
    return news.map((n){
      int score=30;
      final reasons=<String>[];
      final isPK = loc.countryCode=='PK';
      final titleLc=n.title.toLowerCase();
      if(isPK && (n.source=='Dawn'||n.source=='Geo')){ score+=16; reasons.add(' Local'); }
      if(n.trending){ score+=10; reasons.add('Trending'); }
      for(final s in profile.skills){ if(titleLc.contains(s)){ score+=8; reasons.add(' $s'); break; } }
      for(final kw in learned){ if(titleLc.contains(kw)){ score+=5; reasons.add(' $kw'); break; } }
      return SmartLead(id:n.url.isEmpty? n.title : n.url, title:n.title, org:n.source, location: isPK? 'Pakistan':'World', type:n.category, url:n.url, source:n.source, category:'news', match: score.clamp(0,92), reasons:reasons.take(2).toList(), due:n.timeAgo, isHot: n.trending);
    }).toList()..sort((a,b)=> b.match.compareTo(a.match));
  }

  // Weekly digest text — smart summary
  String digestText(OrbitLocation loc, {required int jobs, required int scholarships, required int internships}){
    final profile = _profileStore.load();
    return 'Smart for ${loc.city} • ${profile.field} • ${profile.skills.take(2).join(', ')}  $jobs jobs near you, $scholarships scholarships for Pakistani, $internships interns. Tap Leads to see Top 10.';
  }
}
