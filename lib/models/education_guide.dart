class EducationTip {
  const EducationTip({
    required this.title,
    required this.body,
    required this.actionHint,
  });

  final String title;
  final String body;
  final String actionHint;

  factory EducationTip.fromJson(Map<String, dynamic> json) {
    return EducationTip(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Tips bisnis',
      body: (json['body'] as String?)?.trim() ?? '',
      actionHint: (json['action_hint'] as String?)?.trim() ?? '',
    );
  }
}

class EducationGuide {
  const EducationGuide({
    required this.headline,
    required this.tips,
    required this.generatedAt,
  });

  final String headline;
  final List<EducationTip> tips;
  final DateTime generatedAt;

  bool get isEmpty => tips.isEmpty;
}
