import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../repositories/mandal_repository.dart';
import 'sync_status_badge.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuToggle;

  const AppHeader({
    super.key,
    required this.title,
    this.onMenuToggle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.primaryMaroon,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!isDesktop && onMenuToggle != null)
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: onMenuToggle,
            ),
          // Festival Emblem / Logo (Base64 if available, otherwise Durga App Logo)
          Builder(
            builder: (context) {
              final logoUrl = MandalRepository().mandalProfile.logoUrl;
              if (logoUrl != null && logoUrl.isNotEmpty) {
                try {
                  final clean = logoUrl.contains(',') ? logoUrl.split(',').last : logoUrl;
                  final bytes = base64Decode(clean);
                  return ClipOval(
                    child: Image.memory(
                      bytes,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultLogo(),
                    ),
                  );
                } catch (_) {}
              }
              return _buildDefaultLogo();
            },
          ),
          const SizedBox(width: 12),
          // Mandal Name & Tagline
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppStrings.tr('नियोजन • व्यवस्थापन • उत्सव  |  जय माता दी', 'Plan  •  Manage  •  Celebrate  |  Jai Mata Di'),
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Festival Year Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentGold.withAlpha(150)),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_month, color: AppColors.accentGold, size: 14),
                SizedBox(width: 4),
                Text(
                  '2026',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Notification Icon
          IconButton(
            icon: const Badge(
              label: Text('3'),
              backgroundColor: AppColors.brightGold,
              child: Icon(Icons.notifications_none, color: Colors.white),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All Mandal services operating smoothly')),
              );
            },
          ),
          const SizedBox(width: 8),
          // Bachatgat-Identical Cloud Sync Status Symbol
          const SyncStatusBadge(),
          const SizedBox(width: 8),
          // Language Toggle Pill
          InkWell(
            onTap: () => AppStrings.toggleLanguage(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentGold.withAlpha(120)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, color: AppColors.accentGold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.isMarathi ? 'मराठी' : 'EN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // User Profile Pill & Actions Menu
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return PopupMenuButton<String>(
                tooltip: 'User Menu',
                onSelected: (val) {
                  if (val == 'lock') {
                    auth.lockSubLogin();
                  } else if (val == 'logout') {
                    auth.signOut();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentProfile?.fullName ?? 'Administrator',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Role: ${auth.isAdmin ? "ADMIN (Full Access)" : "MEMBER (View Only)"}',
                          style: TextStyle(
                            fontSize: 11,
                            color: auth.isAdmin ? AppColors.primaryMaroon : Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Data date: ${auth.globalEndDateFormatted}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  if (auth.isAdmin)
                    const PopupMenuItem(
                      value: 'lock',
                      child: Row(
                        children: [
                          Icon(Icons.lock_clock_outlined, size: 18, color: AppColors.primaryMaroon),
                          SizedBox(width: 8),
                          Text('Lock Sub-Login / तारीख बदला'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: AppColors.expenseRed),
                        SizedBox(width: 8),
                        Text('Sign Out / बाहेर पडा'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.accentGold,
                        child: Text(
                          auth.currentProfile?.fullName.isNotEmpty == true
                              ? auth.currentProfile!.fullName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryMaroon,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        auth.isAdmin ? 'Admin' : 'Member',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return ClipOval(
      child: Image.asset(
        'assets/images/app_logo.png',
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: AppColors.brightGold,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.wb_sunny, color: AppColors.primaryMaroon, size: 20),
        ),
      ),
    );
  }
}
