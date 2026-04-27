import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/components.dart';
import '../theme/typography.dart';
import '../models/response_model.dart';
import '../services/results_service.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/interview_session.dart';
import '../services/groq_service.dart';

class AnalysisScreen extends StatefulWidget {
  final String interviewId;

  const AnalysisScreen({super.key, required this.interviewId});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _resultsService = ResultsService();
  final _firestoreService = FirestoreService();
  final _groqService = GroqService();
  bool _isLoading = true;
  List<ResponseModel> _responses = [];
  int _avgConfidence = 0;
  int _totalTime = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    try {
      if (widget.interviewId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      final uid = FirebaseAuth.instance.currentUser?.uid;

      _responses = await _resultsService.fetchResponses(widget.interviewId);

      if (_responses.isEmpty && uid != null) {
        // Attempt to evaluate responses via Groq
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('interviews')
            .doc(widget.interviewId)
            .get();
        if (doc.exists && doc.data() != null) {
          final session = InterviewSession.fromMap(doc.data()!, doc.id);
          if (session.answers.isNotEmpty) {
            _responses = await _groqService.evaluateAnswers(
                questions: session.questions, userAnswers: session.answers);
            // Save responses so they don't have to be regenerated
            final batch = FirebaseFirestore.instance.batch();
            final collRef = FirebaseFirestore.instance
                .collection('interviews')
                .doc(widget.interviewId)
                .collection('responses');
            for (var i = 0; i < _responses.length; i++) {
              batch.set(collRef.doc('resp_$i'), _responses[i].toMap());
            }
            await batch.commit();
          }
        }
      }

      _totalTime = _resultsService.calculateTotalTime(_responses);

      if (_responses.isNotEmpty) {
        int confSum = 0;
        for (var r in _responses) {
          confSum += (r.confidenceScore ?? 0);
        }
        _avgConfidence = (confSum / _responses.length).round();
      } else {
        _avgConfidence = 0;
      }
      if (uid != null) {
        await _firestoreService.updateInterviewScore(
            uid, widget.interviewId, _avgConfidence.toDouble());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading analysis: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTime(int seconds) {
    if (seconds == 0) return '0s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Analyzing responses...',
              style: TextStyle(color: AppColors.primary))
        ])),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Analysis Results',
            style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppComponents.ambientShadow,
                ),
                child: Column(
                  children: [
                    const Text('Overall AI Confidence',
                        style: TextStyle(
                            color: AppColors.onPrimary, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('$_avgConfidence%',
                        style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 48,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text('Total Interview Time: ${_formatTime(_totalTime)}',
                        style: TextStyle(
                            color: AppColors.onPrimary.withValues(alpha: 0.8),
                            fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              const Text('Question Breakdown', style: AppTypography.headlineLg),
              const SizedBox(height: 24),

              if (_responses.isEmpty)
                const Text('No responses analyzed.')
              else
                ..._responses.map((r) => _buildAnalysisCard(r)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(ResponseModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppComponents.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Question', style: AppTypography.labelLarge),
              Text(_formatTime(r.answerTime),
                  style: const TextStyle(color: Colors.black12, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(r.questionText, style: AppTypography.titleSm),
          const Divider(height: 32),

          // Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _metricPill('Clarity', r.clarityScore ?? 0),
              _metricPill('Relevance', r.relevanceScore ?? 0),
              _metricPill('Fluency', r.fluencyScore ?? 0),
            ],
          ),
          const SizedBox(height: 24),

          // Strengths & Weaknesses
          if (r.strengths != null && r.strengths!.isNotEmpty) ...[
            const Text('Strengths',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...r.strengths!
                .map((s) => Text('• $s', style: AppTypography.bodySmall)),
            const SizedBox(height: 16),
          ],

          if (r.weaknesses != null && r.weaknesses!.isNotEmpty) ...[
            const Text('Improvements Needed',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...r.weaknesses!
                .map((w) => Text('• $w', style: AppTypography.bodySmall)),
            const SizedBox(height: 16),
          ],

          const Divider(height: 32),
          const Text('Your Transcript',
              style: TextStyle(color: Colors.black12, fontSize: 12)),
          const SizedBox(height: 8),
          if (r.userAnswer.trim().isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mic_off, color: AppColors.error, size: 16),
                  SizedBox(width: 8),
                  Text('No response provided.',
                      style: TextStyle(color: AppColors.error)),
                ],
              ),
            )
          else
            Text(r.userAnswer, style: AppTypography.bodyMd),

          const SizedBox(height: 24),
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.check_circle_outline,
                          color: AppColors.secondary, size: 16),
                      SizedBox(width: 8),
                      Text('Ideal Answer',
                          style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    Text(r.idealAnswer ?? 'Not provided.',
                        style: AppTypography.bodySmall),
                  ]))
        ],
      ),
    );
  }

  Widget _metricPill(String label, int score) {
    Color color = score >= 80
        ? Colors.green
        : (score >= 50 ? Colors.orange : AppColors.error);
    return Column(children: [
      Text('$score%',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 4),
      Text(label,
          style:
              const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
    ]);
  }
}
