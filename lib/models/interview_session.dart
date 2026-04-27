// ─── FILE: lib/models/interview_session.dart ───────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'interview_question.dart';

class InterviewSession {
  final String id;
  final String categoryId;
  final String categoryTitle;
  final List<InterviewQuestion> questions;
  final List<String> answers;
  final double score;
  final String feedback;
  final int duration; // seconds
  final DateTime? timestamp;
  final int questionCount;

  const InterviewSession({
    required this.id,
    required this.categoryId,
    required this.categoryTitle,
    this.questions = const [],
    this.answers = const [],
    this.score = 0,
    this.feedback = '',
    this.duration = 0,
    this.timestamp,
    this.questionCount = 0,
  });

  factory InterviewSession.fromMap(Map<String, dynamic> map, String docId) {
    return InterviewSession(
      id: docId,
      categoryId: map['categoryId'] as String? ?? '',
      categoryTitle: map['categoryTitle'] as String? ?? 'Unknown',
      questions: (map['questions'] as List<dynamic>?)
              ?.map((q) =>
                  InterviewQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
              .toList() ??
          [],
      answers: (map['answers'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [],
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      feedback: map['feedback'] as String? ?? '',
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
      questionCount: (map['questionCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryTitle': categoryTitle,
      'questions': questions.map((q) => q.toMap()).toList(),
      'answers': answers,
      'score': score,
      'feedback': feedback,
      'duration': duration,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
      'questionCount': questionCount,
    };
  }

  InterviewSession copyWith({
    String? id,
    String? categoryId,
    String? categoryTitle,
    List<InterviewQuestion>? questions,
    List<String>? answers,
    double? score,
    String? feedback,
    int? duration,
    DateTime? timestamp,
    int? questionCount,
  }) {
    return InterviewSession(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      questionCount: questionCount ?? this.questionCount,
    );
  }
}
