// ─── FILE: lib/screens/history_screen.dart ───────────────────────
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/theme_service.dart';
import '../models/interview_session.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _firestoreService = FirestoreService();
  String _filter = 'All';
  final _filters = ['All', 'This Week', 'This Month'];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = context.watch<ThemeService>().isDarkMode;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
            child: Text('Not logged in',
                style: TextStyle(color: textSecondary))),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('History',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                  const SizedBox(height: 4),
                  Text('Your past interview sessions',
                      style: TextStyle(fontSize: 13, color: textSecondary)),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters
                          .map((f) => _FilterChip(
                                label: f,
                                isSelected: _filter == f,
                                isDark: isDark,
                                onTap: () => setState(() => _filter = f),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<InterviewSession>>(
                stream: _firestoreService.getAllInterviews(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  List<InterviewSession> sessions = snapshot.data ?? [];
                  sessions = _applyFilter(sessions);

                  if (sessions.isEmpty) {
                    return _buildEmptyState(textSecondary);
                  }

                  final grouped = _groupByMonth(sessions);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: grouped.entries.expand((entry) {
                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(entry.key,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary)),
                        ),
                        ...entry.value.map((s) => _SessionCard(
                              session: s,
                              surface: surface,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              onTap: () => Navigator.pushNamed(
                                context, 
                                '/results', 
                                arguments: {'interviewId': s.id}
                              ),
                            )),
                      ];
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<InterviewSession> _applyFilter(List<InterviewSession> sessions) {
    final now = DateTime.now();
    if (_filter == 'This Week') {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      return sessions.where((s) {
        final t = s.timestamp;
        return t != null && t.isAfter(weekStart);
      }).toList();
    }
    if (_filter == 'This Month') {
      return sessions.where((s) {
        final t = s.timestamp;
        return t != null && t.month == now.month && t.year == now.year;
      }).toList();
    }
    return sessions;
  }

  Map<String, List<InterviewSession>> _groupByMonth(
      List<InterviewSession> sessions) {
    final map = <String, List<InterviewSession>>{};
    for (final s in sessions) {
      final key = s.timestamp != null
          ? DateFormat('MMMM yyyy').format(s.timestamp!)
          : 'Unknown';
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off_rounded,
              size: 64, color: textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No interviews yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const SizedBox(height: 8),
          Text('Start one from the Dashboard!',
              style: TextStyle(fontSize: 14, color: textSecondary)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark
                    ? AppColors.darkSurfaceHigh
                    : AppColors.lightSurfaceHigh),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final InterviewSession session;
  final Color surface, textPrimary, textSecondary;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m min ${s.toString().padLeft(2, '0')} sec';
  }

  @override
  Widget build(BuildContext context) {
    final score = session.score;
    final scoreColor = AppColors.scoreColor(score);
    final date = session.timestamp != null
        ? DateFormat('MMM d, hh:mm a').format(session.timestamp!)
        : 'Unknown';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Score ring badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor, width: 2.5),
                color: scoreColor.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  '${score.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.categoryTitle,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  const SizedBox(height: 3),
                  Text(date,
                      style: TextStyle(fontSize: 11, color: textSecondary)),
                  const SizedBox(height: 3),
                  Text(_formatDuration(session.duration),
                      style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
