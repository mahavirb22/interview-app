// ─── FILE: lib/screens/categories_screen.dart ───────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/theme_service.dart';
import '../models/interview_category.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _seedIfNeeded();
    _searchController.addListener(
        () => setState(() => _searchQuery = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _seedIfNeeded() async {
    if (_seeded) return;
    await _firestoreService.seedCategories();
    _seeded = true;
  }

  Color _hexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  IconData _mapIcon(String iconName) {
    const mapping = {
      'web': Icons.web_rounded,
      'dns': Icons.dns_rounded,
      'analytics': Icons.analytics_rounded,
      'cloud': Icons.cloud_rounded,
      'people': Icons.people_rounded,
      'architecture': Icons.architecture,
      'code': Icons.code_rounded,
    };
    return mapping[iconName] ?? Icons.category_rounded;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Categories',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                  const SizedBox(height: 4),
                  Text('Choose a topic to practice',
                      style: TextStyle(fontSize: 13, color: textSecondary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search categories…',
                      prefixIcon:
                          Icon(Icons.search_rounded, color: textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: textSecondary),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<InterviewCategory>>(
                stream: _firestoreService.getCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSkeleton(isDark);
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error loading categories',
                            style: TextStyle(color: textSecondary)));
                  }
                  final cats = (snapshot.data ?? []).where((c) {
                    if (_searchQuery.isEmpty) return true;
                    return c.title.toLowerCase().contains(_searchQuery) ||
                        c.description.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (cats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 48, color: textSecondary),
                          const SizedBox(height: 12),
                          Text('No categories found',
                              style: TextStyle(
                                  fontSize: 15, color: textSecondary)),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: cats.length,
                    itemBuilder: (context, i) => _CategoryCard(
                      category: cats[i],
                      color: _hexColor(cats[i].colorHex),
                      icon: _mapIcon(cats[i].iconName),
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CategoryDetailScreen(category: cats[i]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: List.generate(
            6,
            (_) => Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final InterviewCategory category;
  final Color color;
  final IconData icon;
  final Color surface, textPrimary, textSecondary;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.color,
    required this.icon,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Beginner':
        return AppColors.success;
      case 'Advanced':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _difficultyColor(category.difficulty)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category.difficulty,
                          style: TextStyle(
                              fontSize: 10,
                              color: _difficultyColor(category.difficulty),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 11, color: textSecondary),
                          const SizedBox(width: 3),
                          Text('${category.estimatedMinutes}m',
                              style: TextStyle(
                                  fontSize: 11, color: textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
