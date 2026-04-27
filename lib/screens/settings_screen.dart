// ─── FILE: lib/screens/settings_screen.dart ───────────────────────
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _firestoreService = FirestoreService();
  final _auth = FirebaseAuth.instance;

  String _displayName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final data = await _firestoreService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _displayName =
              data?['displayName'] as String? ?? user.displayName ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            context.watch<ThemeService>().isDarkMode
                ? AppColors.darkSurface
                : AppColors.lightSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context);
              await _auth.currentUser?.updateDisplayName(newName);
              final uid = _auth.currentUser?.uid;
              if (uid != null) {
                await _firestoreService.updateUserProfile(uid, newName);
              }
              if (mounted) setState(() => _displayName = newName);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  _snackBar('Display name updated!', AppColors.success),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            context.watch<ThemeService>().isDarkMode
                ? AppColors.darkSurface
                : AppColors.lightSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Account'),
        content: const Text(
            'This will permanently delete all your data. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final uid = _auth.currentUser?.uid;
              if (uid != null) {
                await _firestoreService.deleteUserData(uid);
              }
              await _auth.currentUser?.delete();
              if (!mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (_) => false);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  SnackBar _snackBar(String msg, Color color) => SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDarkMode;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: textPrimary)),
                    const SizedBox(height: 24),

                    // ─── Profile ───────────────────────────
                    _SectionHeader(label: 'Profile', textSecondary: textSecondary),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                child: Text(
                                  _displayName.isNotEmpty
                                      ? _displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_displayName,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary)),
                                    Text(user?.email ?? '',
                                        style: TextStyle(
                                            fontSize: 12, color: textSecondary)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _showEditNameDialog,
                                child: const Text('Edit',
                                    style: TextStyle(color: AppColors.primary)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Preferences ──────────────────────
                    _SectionHeader(label: 'Preferences', textSecondary: textSecondary),
                    Container(
                      decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _ToggleTile(
                            icon: Icons.dark_mode_rounded,
                            title: 'Dark Mode',
                            value: isDark,
                            onChanged: (v) => themeService.setDarkMode(v),
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Account ──────────────────────────
                    _SectionHeader(label: 'Account', textSecondary: textSecondary),
                    Container(
                      decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _ActionTile(
                            icon: Icons.logout_rounded,
                            title: 'Sign Out',
                            iconColor: AppColors.error,
                            onTap: _signOut,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          _Divider(isDark: isDark),
                          _ActionTile(
                            icon: Icons.delete_forever_rounded,
                            title: 'Delete Account',
                            iconColor: AppColors.error,
                            titleColor: AppColors.error,
                            onTap: _showDeleteDialog,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── About ────────────────────────────
                    _SectionHeader(label: 'About', textSecondary: textSecondary),
                    Container(
                      decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.info_outline_rounded,
                            title: 'App Version',
                            value: '1.0.0',
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          _Divider(isDark: isDark),
                          _ActionTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            onTap: () => _showInfoDialog(
                                context,
                                'Privacy Policy',
                                'Your data is stored securely and never shared with third parties.'),
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          _Divider(isDark: isDark),
                          _ActionTile(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            onTap: () => _showInfoDialog(
                                context,
                                'Terms of Service',
                                'By using this app you agree to our terms.'),
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    final isDark = context.read<ThemeService>().isDarkMode;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color textSecondary;
  const _SectionHeader(
      {required this.label, required this.textSecondary});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: textSecondary)),
      );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color:
            isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh,
        indent: 16,
        endIndent: 16,
      );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color textPrimary, textSecondary;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textSecondary),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: TextStyle(fontSize: 14, color: textPrimary))),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor, titleColor;
  final VoidCallback onTap;
  final Color textPrimary, textSecondary;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.textPrimary,
    required this.textSecondary,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon,
            size: 20,
            color: iconColor ?? textSecondary),
        title: Text(title,
            style: TextStyle(
                fontSize: 14,
                color: titleColor ?? textPrimary)),
        trailing:
            Icon(Icons.chevron_right_rounded, size: 18, color: textSecondary),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        dense: true,
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final Color textPrimary, textSecondary;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, size: 20, color: textSecondary),
        title: Text(title,
            style: TextStyle(fontSize: 14, color: textPrimary)),
        trailing: Text(value,
            style: TextStyle(fontSize: 13, color: textSecondary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        dense: true,
      );
}
