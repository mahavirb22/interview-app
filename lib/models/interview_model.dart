import 'package:cloud_firestore/cloud_firestore.dart';

class InterviewModel {
  final String interviewId;
  final String userId;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String status;

  InterviewModel({
    required this.interviewId,
    required this.userId,
    this.startedAt,
    this.completedAt,
    this.status = 'in_progress',
  });

  Map<String, dynamic> toMap() {
    return {
      'interviewId': interviewId,
      'userId': userId,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status,
    };
  }

  factory InterviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return InterviewModel(
      interviewId: docId,
      userId: map['userId'] ?? '',
      startedAt: map['startedAt'] != null ? (map['startedAt'] as Timestamp).toDate() : null,
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      status: map['status'] ?? 'in_progress',
    );
  }
}
