import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/response_model.dart';

class ResultsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, List<ResponseModel>> _cachedResponses = {};

  Future<List<ResponseModel>> fetchResponses(String interviewId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedResponses.containsKey(interviewId)) {
      return _cachedResponses[interviewId]!;
    }

    try {
      final snapshot = await _firestore
          .collection('interviews')
          .doc(interviewId)
          .collection('responses')
          .orderBy('createdAt')
          .get();

      final data = snapshot.docs.map((doc) => ResponseModel.fromMap(doc.data())).toList();
      _cachedResponses[interviewId] = data;
      return data;
    } catch (e) {
      throw 'Failed to fetch results: $e';
    }
  }

  int calculateScore(List<ResponseModel> responses) {
    return responses.where((r) => r.userAnswer.trim().isNotEmpty).length;
  }

  int calculateTotalTime(List<ResponseModel> responses) {
    return responses.fold(0, (sum, item) => sum + item.answerTime);
  }
}
