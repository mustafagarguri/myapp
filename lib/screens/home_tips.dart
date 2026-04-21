enum HomeTipCategory { preDonation, postDonation, activeCall }

class HomeTip {
  const HomeTip({
    required this.title,
    required this.body,
    required this.category,
  });

  final String title;
  final String body;
  final HomeTipCategory category;
}

const List<HomeTip> _homeTips = [
  HomeTip(
    title: 'اشرب الماء جيداً',
    body:
        'اشرب كوبين إلى ثلاثة أكواب ماء قبل التبرع ليساعد جسمك على الحفاظ على توازنه.',
    category: HomeTipCategory.preDonation,
  ),
  HomeTip(
    title: 'نم جيداً قبل التبرع',
    body:
        'النوم الكافي في الليلة السابقة يساعدك على التبرع براحة ويقلل الشعور بالإرهاق.',
    category: HomeTipCategory.preDonation,
  ),
  HomeTip(
    title: 'تناول وجبة خفيفة',
    body:
        'يفضل تناول وجبة خفيفة متوازنة قبل التبرع وتجنب الحضور على معدة فارغة.',
    category: HomeTipCategory.preDonation,
  ),
  HomeTip(
    title: 'خفف المجهود بعد التبرع',
    body:
        'بعد التبرع تجنب التمارين الشديدة لباقي اليوم وامنح جسمك وقتاً للراحة.',
    category: HomeTipCategory.postDonation,
  ),
  HomeTip(
    title: 'ركز على الحديد',
    body:
        'الأطعمة الغنية بالحديد مثل اللحوم والبقوليات والخضار الورقية تساعد على التعافي بعد التبرع.',
    category: HomeTipCategory.postDonation,
  ),
  HomeTip(
    title: 'لا تؤجل شرب السوائل',
    body:
        'بعد التبرع استمر في شرب الماء والعصائر خلال الساعات التالية لتجنب الدوخة.',
    category: HomeTipCategory.postDonation,
  ),
  HomeTip(
    title: 'جهز نفسك قبل التحرك',
    body:
        'إذا وصلك نداء تبرع، احرص على شرب الماء وأخذ وجبة خفيفة قبل الذهاب للمستشفى.',
    category: HomeTipCategory.activeCall,
  ),
  HomeTip(
    title: 'احتفظ بهدوئك أثناء الطريق',
    body:
        'الوصول بهدوء وبدون مجهود زائد يساعدك على التبرع بشكل أفضل عند وصولك للمستشفى.',
    category: HomeTipCategory.activeCall,
  ),
];

HomeTip selectHomeTip({
  required DateTime now,
  required bool isEligible,
  required bool hasActiveCall,
}) {
  final category = hasActiveCall
      ? HomeTipCategory.activeCall
      : (isEligible
            ? HomeTipCategory.preDonation
            : HomeTipCategory.postDonation);

  final matchingTips = _homeTips
      .where((tip) => tip.category == category)
      .toList();
  final indexSeed = now.year + now.month + now.day;
  return matchingTips[indexSeed % matchingTips.length];
}
