// ─── FILE: lib/models/user_stats.dart ───────────────────────
class UserStats {
  final int totalInterviews;
  final double averageScore;
  final int currentStreak;
  final String bestCategory;

  const UserStats({
    this.totalInterviews = 0,
    this.averageScore = 0,
    this.currentStreak = 0,
    this.bestCategory = '—',
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalInterviews: (map['totalInterviews'] as num?)?.toInt() ?? 0,
      averageScore: (map['averageScore'] as num?)?.toDouble() ?? 0.0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      bestCategory: map['bestCategory'] as String? ?? '—',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalInterviews': totalInterviews,
      'averageScore': averageScore,
      'currentStreak': currentStreak,
      'bestCategory': bestCategory,
    };
  }

  UserStats copyWith({
    int? totalInterviews,
    double? averageScore,
    int? currentStreak,
    String? bestCategory,
  }) {
    return UserStats(
      totalInterviews: totalInterviews ?? this.totalInterviews,
      averageScore: averageScore ?? this.averageScore,
      currentStreak: currentStreak ?? this.currentStreak,
      bestCategory: bestCategory ?? this.bestCategory,
    );
  }
}
