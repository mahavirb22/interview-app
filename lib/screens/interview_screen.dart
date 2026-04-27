// ─── FILE: lib/screens/interview_screen.dart ───────────────────────
// This screen is now launched from CategoryDetailScreen with pre-generated questions.
// It keeps the existing audio recording flow intact.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/theme_service.dart';
import '../models/interview_category.dart';
import '../models/interview_question.dart';
import '../models/interview_session.dart';

class InterviewScreen extends StatefulWidget {
  final InterviewCategory? category;
  final List<InterviewQuestion>? questions;

  const InterviewScreen({super.key, this.category, this.questions});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  final _firestoreService = FirestoreService();
  final _uuid = const Uuid();

  int _currentIndex = 0;
  bool _isRecording = false;
  bool _isSubmitting = false;
  final List<String> _answers = [];
  String _partialAnswer = '';
  int _elapsedSeconds = 0;
  Timer? _timer;
  
  // Real Transcript UI
  List<String> _simulatedTranscript = [];

  int _totalDuration = 0;

  List<InterviewQuestion> get _questions =>
      widget.questions ?? _fallbackQuestions;

  final List<InterviewQuestion> _fallbackQuestions = const [
    InterviewQuestion(
      id: 'fallback_1',
      question: 'Tell me about yourself.',
      hint: 'Focus on your professional background and key achievements.',
      expectedKeyPoints: ['Background', 'Experience', 'Career goals'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _answers.addAll(List.filled(_questions.length, ''));
    _initSpeech();
    _startTimer();
  }

  void _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (sttStatus) {
          if (sttStatus == 'done' || sttStatus == 'notListening') {
            if (_isRecording) {
              _partialAnswer = _answers[_currentIndex];
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _isRecording) {
                  _startListening();
                }
              });
            }
          }
        }
      );
      setState(() {});
    } else {
      _speechEnabled = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speechToText.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  String get _formattedTime {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _speechToText.stop();
      setState(() {
        _isRecording = false;
      });
    } else {
      if (_speechEnabled) {
        setState(() {
          _isRecording = true;
          _simulatedTranscript.clear();
          _partialAnswer = '';
        });
        _startListening();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available.')),
        );
      }
    }
  }

  void _startListening() async {
    await _speechToText.listen(
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(minutes: 5),
      cancelOnError: false,
      onResult: (result) {
        if (mounted) {
          setState(() {
            _answers[_currentIndex] = (_partialAnswer + ' ' + result.recognizedWords).trim();
            List<String> words = _answers[_currentIndex].split(' ');
            List<String> lines = [];
            for (int i = 0; i < words.length; i += 7) {
              var chunk = words.sublist(i, i + 7 > words.length ? words.length : i + 7).join(' ');
              lines.add(chunk);
            }
            if (lines.length > 5) {
              _simulatedTranscript = lines.sublist(lines.length - 5);
            } else {
              _simulatedTranscript = lines;
            }
          });
        }
      }
    );
  }

  void _nextQuestion() {
    if (_isRecording) _toggleRecording();
    setState(() {
      _simulatedTranscript.clear();
      _partialAnswer = '';
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
      }
    });
  }

  Future<void> _finishInterview() async {
    if (_isRecording) {
      await _speechToText.stop();
      setState(() => _isRecording = false);
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSubmitting = true);
    _timer?.cancel();
    _totalDuration = _elapsedSeconds;

    try {
      final session = InterviewSession(
        id: _uuid.v4(),
        categoryId: widget.category?.id ?? 'general',
        categoryTitle: widget.category?.title ?? 'General',
        questions: _questions,
        answers: _answers,
        score: 0.0, // initial score before any AI analysis
        feedback:
            'Interview completed. Analysis pending...',
        duration: _totalDuration,
        timestamp: DateTime.now(),
        questionCount: _questions.length,
      );

      await _firestoreService.saveInterview(uid, session);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/results',
        arguments: {'interviewId': session.id, 'session': session},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppColors.error,
        ));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category?.title ?? 'Interview',
          style: TextStyle(
              color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(_formattedTime,
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            Row(
              children: [
                Text('Q ${_currentIndex + 1}/${_questions.length}',
                    style: TextStyle(fontSize: 13, color: textSecondary)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question card
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q.question,
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Record button
            Center(
              child: GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: _isRecording ? AppColors.error : AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: _isRecording ? AppColors.error : AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Simulated Transcript Area
            if (_isRecording || _simulatedTranscript.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 140, // Enough for ~5 lines
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _simulatedTranscript.length,
                  itemBuilder: (context, index) {
                    return TweenAnimationBuilder<double>(
                      key: ValueKey(_simulatedTranscript[index]),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value * 0.7,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - value)),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _simulatedTranscript[index],
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic
                                ),
                              ),
                            )
                          ),
                        );
                      }
                    );
                  }
                ),
              ),

            // Navigation
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _currentIndex--),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : (_currentIndex < _questions.length - 1
                            ? _nextQuestion
                            : _finishInterview),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_currentIndex < _questions.length - 1
                            ? 'Next Question'
                            : 'Finish Interview'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
