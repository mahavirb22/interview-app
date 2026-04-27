// ─── FILE: lib/screens/dashboard_screen.dart ───────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/theme_service.dart';
import '../models/interview_session.dart';
import 'main_shell.dart';
import '../screens/history_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _firestoreService = FirestoreService();
  bool _isLoading = true;
  String _userName = '';
  List<InterviewSession> _recent = [];
  Map<String, String> _quote = {'text': '', 'author': ''};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final results = await Future.wait([
        _firestoreService.getUserData(user.uid),
        _firestoreService.getRecentInterviews(user.uid, limit: 2),
        _firestoreService.getRandomQuote(),
      ]);
      if (!mounted) return;
      setState(() {
        final userData = results[0] as Map<String, dynamic>?;
        _userName = userData?['displayName'] as String? ??
            userData?['fullName'] as String? ??
            user.displayName ??
            'User';
        _recent = results[1] as List<InterviewSession>;
        _quote = results[2] as Map<String, String>;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading
            ? _buildSkeleton(isDark)
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(textPrimary, textSecondary),
                      const SizedBox(height: 24),
                      const SizedBox(height: 24),
                      _buildQuickStart(),
                      const SizedBox(height: 24),
                      _buildRecentActivity(surface, textPrimary, textSecondary),
                      const SizedBox(height: 24),
                      _buildQuoteCard(surface, textPrimary, textSecondary),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    final user = FirebaseAuth.instance.currentUser;
    final initials =
        _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_greeting,',
              style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 2),
            Text(
              '$_userName! 👋',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              'Ready to ace your next interview?',
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
          ],
        ),
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage:
              user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
          child: user?.photoURL == null
              ? Text(initials,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18))
              : null,
        ),
      ],
    );
  }



  Widget _buildQuickStart() {
    return GestureDetector(
      onTap: _goToCategories,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start New Interview',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Begin your practice session →',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  void _goToCategories() {
    // Switch to Categories tab (index 1) in the parent MainShell
    final shellState = context.findAncestorStateOfType<MainShellState>();
    if (shellState != null) {
      shellState.setIndex(1);
    }
  }

  Widget _buildRecentActivity(
      Color surface, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary)),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen())
                );
                // Navigate to history tab – handled by parent shell navigation
              },
              child: const Text('View All',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 40, color: textSecondary),
                  const SizedBox(height: 8),
                  Text('No interviews yet',
                      style: TextStyle(color: textSecondary, fontSize: 14)),
                ],
              ),
            ),
          )
        else
          ...List.generate(
            _recent.length,
            (i) => _RecentCard(
              session: _recent[i],
              surface: surface,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => Navigator.pushNamed(
                context, 
                '/results', 
                arguments: {'interviewId': _recent[i].id}
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuoteCard(
      Color surface, Color textPrimary, Color textSecondary) {
    if (_quote['text']?.isEmpty ?? true) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded,
              color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text('"${_quote['text']}"',
              style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: textPrimary,
                  height: 1.5)),
          const SizedBox(height: 8),
          Text('— ${_quote['author']}',
              style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    final base = isDark ? AppColors.darkSurface : AppColors.lightSurfaceHigh;
    final highlight =
        isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurface;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 20, width: 150, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 28, width: 220, color: Colors.white),
            const SizedBox(height: 28),
            Row(
              children: List.generate(
                4,
                (_) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    height: 90,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
                height: 80,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18))),
          ],
        ),
      ),
    );
  }
}



class _RecentCard extends StatelessWidget {
  final InterviewSession session;
  final Color surface, textPrimary, textSecondary;
  final VoidCallback onTap;

  const _RecentCard(
      {required this.session,
      required this.surface,
      required this.textPrimary,
      required this.textSecondary,
      required this.onTap});

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${score.toStringAsFixed(0)}%',
                style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.categoryTitle,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const SizedBox(height: 2),
                Text('$date  •  ${_formatDuration(session.duration)}',
                    style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: textSecondary, size: 18),
        ],
      ),
    ));
  }
}

