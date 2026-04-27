import 'package:cloud_firestore/cloud_firestore.dart';

class ResponseModel {
  final String questionId;
  final String questionText;
  final String userAnswer; 
  final int answerTime;
  final DateTime? createdAt;
  
  // AI Metrics
  final int? confidenceScore;
  final int? clarityScore;
  final int? relevanceScore;
  final int? fluencyScore;
  final List<String>? strengths;
  final List<String>? weaknesses;
  final String? improvement;
  final String? idealAnswer;

  ResponseModel({
    required this.questionId,
    required this.questionText,
    required this.userAnswer,
    required this.answerTime,
    this.createdAt,
    this.confidenceScore,
    this.clarityScore,
    this.relevanceScore,
    this.fluencyScore,
    this.strengths,
    this.weaknesses,
    this.improvement,
    this.idealAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'userAnswer': userAnswer,
      'answerTime': answerTime,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'confidenceScore': confidenceScore,
      'clarityScore': clarityScore,
      'relevanceScore': relevanceScore,
      'fluencyScore': fluencyScore,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'improvement': improvement,
      'idealAnswer': idealAnswer,
    };
  }

  factory ResponseModel.fromMap(Map<String, dynamic> map) {
    return ResponseModel(
      questionId: map['questionId'] ?? '',
      questionText: map['questionText'] ?? '',
      userAnswer: map['userAnswer'] ?? map['transcript'] ?? '',
      answerTime: map['answerTime']?.toInt() ?? 0,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      confidenceScore: map['confidenceScore']?.toInt(),
      clarityScore: map['clarityScore']?.toInt(),
      relevanceScore: map['relevanceScore']?.toInt(),
      fluencyScore: map['fluencyScore']?.toInt(),
      strengths: List<String>.from(map['strengths'] ?? []),
      weaknesses: List<String>.from(map['weaknesses'] ?? []),
      improvement: map['improvement'],
      idealAnswer: map['idealAnswer'],
    );
  }
}
