class QuestionModel {
  final String questionId;
  final String questionText;
  final String category;
  final String difficulty;

  QuestionModel({
    required this.questionId,
    required this.questionText,
    required this.category,
    required this.difficulty,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'category': category,
      'difficulty': difficulty,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map, String docId) {
    return QuestionModel(
      questionId: docId,
      questionText: map['questionText'] ?? '',
      category: map['category'] ?? '',
      difficulty: map['difficulty'] ?? '',
    );
  }
}
