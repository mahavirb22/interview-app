// ─── FILE: lib/models/interview_question.dart ───────────────────────
class InterviewQuestion {
  final String id;
  final String question;
  final String hint;
  final List<String> expectedKeyPoints;

  const InterviewQuestion({
    required this.id,
    required this.question,
    required this.hint,
    required this.expectedKeyPoints,
  });

  factory InterviewQuestion.fromMap(Map<String, dynamic> map, {String? id}) {
    return InterviewQuestion(
      id: id ?? map['id'] as String? ?? '',
      question: map['question'] as String? ?? '',
      hint: map['hint'] as String? ?? '',
      expectedKeyPoints: (map['expectedKeyPoints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'hint': hint,
      'expectedKeyPoints': expectedKeyPoints,
    };
  }

  InterviewQuestion copyWith({
    String? id,
    String? question,
    String? hint,
    List<String>? expectedKeyPoints,
  }) {
    return InterviewQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      hint: hint ?? this.hint,
      expectedKeyPoints: expectedKeyPoints ?? this.expectedKeyPoints,
    );
  }
}
