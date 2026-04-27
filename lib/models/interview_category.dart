// ─── FILE: lib/models/interview_category.dart ───────────────────────
class InterviewCategory {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String colorHex;
  final String difficulty;
  final int totalQuestions;
  final int estimatedMinutes;

  const InterviewCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.colorHex,
    required this.difficulty,
    required this.totalQuestions,
    required this.estimatedMinutes,
  });

  factory InterviewCategory.fromMap(Map<String, dynamic> map, String docId) {
    return InterviewCategory(
      id: docId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconName: map['icon'] as String? ?? map['iconName'] as String? ?? 'code',
      colorHex:
          map['color'] as String? ?? map['colorHex'] as String? ?? '#4F46E5',
      difficulty: map['difficulty'] as String? ?? 'Intermediate',
      totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 5,
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': iconName,
      'color': colorHex,
      'difficulty': difficulty,
      'totalQuestions': totalQuestions,
      'estimatedMinutes': estimatedMinutes,
    };
  }

  InterviewCategory copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    String? colorHex,
    String? difficulty,
    int? totalQuestions,
    int? estimatedMinutes,
  }) {
    return InterviewCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      difficulty: difficulty ?? this.difficulty,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }
}
