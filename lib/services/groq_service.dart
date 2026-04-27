// ─── FILE: lib/services/groq_service.dart ───────────────────────
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/interview_question.dart';
import '../models/response_model.dart';

class GroqService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';

  Future<List<InterviewQuestion>> generateQuestions({
    required String categoryTitle,
    required String difficulty,
    int count = 5,
  }) async {
    final prompt = '''
You are an expert technical interviewer. Generate exactly $count interview questions for the category: $categoryTitle.
Difficulty: $difficulty.
Return ONLY a valid JSON array of objects with fields:
"question" (string), "hint" (string), "expectedKeyPoints" (list of strings).
No extra text, no markdown, no code fences. Just a raw JSON array.
''';

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 2048,
      }),
    );

    if (response.statusCode != 200) {
      throw 'Groq API error ${response.statusCode}: ${response.body}';
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['choices'][0]['message']['content'] as String;

    // Strip possible markdown code fences if model adds them anyway
    final cleaned = content
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final List<dynamic> rawList = jsonDecode(cleaned) as List<dynamic>;
    return rawList.asMap().entries.map((entry) {
      final map = Map<String, dynamic>.from(entry.value as Map);
      return InterviewQuestion.fromMap(map, id: 'q_${entry.key}');
    }).toList();
  }

  Future<List<ResponseModel>> evaluateAnswers({
    required List<InterviewQuestion> questions,
    required List<String> userAnswers,
  }) async {
    List<ResponseModel> responses = [];
    
    for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final ans = i < userAnswers.length ? userAnswers[i] : '';
        
        if (ans.trim().isEmpty) {
          responses.add(ResponseModel(
            questionId: q.id,
            questionText: q.question,
            userAnswer: '',
            confidenceScore: 0,
            clarityScore: 0,
            relevanceScore: 0,
            fluencyScore: 0,
            strengths: [],
            weaknesses: ['No answer provided.'],
            improvement: 'Try to answer the question next time.',
            idealAnswer: q.expectedKeyPoints.join(', '),
            answerTime: 0,
            createdAt: DateTime.now(),
          ));
          continue;
        }

        final prompt = '''
You are an expert AI interview coach. This contains the user's answer to the question: "${q.question}".
Expected key points: ${q.expectedKeyPoints.join(', ')}.
User Answer: "$ans"
Please analyze it and provide feedback in valid JSON format ONLY with the following structure:
{
  "confidenceScore": 85,
  "clarityScore": 90,
  "relevanceScore": 80,
  "fluencyScore": 85,
  "strengths": ["...", "..."],
  "weaknesses": ["...", "..."],
  "improvement": "...",
  "idealAnswer": "..."
}
Do not return any markdown formatting outside of the JSON block. Just a pure JSON object.
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode != 200) continue;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rawText = decoded['choices'][0]['message']['content'] as String;
      final cleanJsonString = rawText.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*'), '').trim();
      
      try {
         final aiRes = jsonDecode(cleanJsonString);
         responses.add(ResponseModel(
            questionId: q.id,
            questionText: q.question,
            userAnswer: ans,
            confidenceScore: aiRes['confidenceScore'] as int? ?? 0,
            clarityScore: aiRes['clarityScore'] as int? ?? 0,
            relevanceScore: aiRes['relevanceScore'] as int? ?? 0,
            fluencyScore: aiRes['fluencyScore'] as int? ?? 0,
            strengths: List<String>.from(aiRes['strengths'] ?? []),
            weaknesses: List<String>.from(aiRes['weaknesses'] ?? []),
            improvement: aiRes['improvement'] as String? ?? '',
            idealAnswer: aiRes['idealAnswer'] as String? ?? q.expectedKeyPoints.join(', '),
            answerTime: 30, // Default estimate
            createdAt: DateTime.now(),
         ));
      } catch (e) {
         // Fallback if parsing fails
      }
    }
    
    return responses;
  }
}
