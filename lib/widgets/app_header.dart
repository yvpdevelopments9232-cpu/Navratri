import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/display_mode_provider.dart';
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
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final displayModeProvider = context.watch<DisplayModeProvider>();

    return Material(
      color: AppColors.primaryMaroon,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: isDesktop
              ? _buildDesktopHeader(context, displayModeProvider)
              : _buildMobileHeader(context, displayModeProvider),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, DisplayModeProvider displayModeProvider) {
    return Row(
      children: [
        // Festival Emblem / Logo
        _buildLogo(),
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
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Display Mode Switcher (Dairy Management mechanism)
        InkWell(
          onTap: () => displayModeProvider.toggleMode(),
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
                Icon(
                  displayModeProvider.isMobile ? Icons.smartphone : Icons.desktop_windows,
                  color: AppColors.brightGold,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  displayModeProvider.isMobile ? 'Mobile' : 'Desktop',
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

        // Festival Year Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Notification Icon
        IconButton(
          icon: const Badge(
            label: Text('3'),
            backgroundColor: AppColors.brightGold,
            child: Icon(Icons.notifications_none, color: Colors.white, size: 20),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All Mandal services operating smoothly')),
            );
          },
        ),
        const SizedBox(width: 6),

        // Cloud Sync Status Symbol
        const SyncStatusBadge(),
        const SizedBox(width: 10),

        // Language Toggle Pill
        _buildLanguagePill(),
        const SizedBox(width: 10),

        // User Profile Pill & Actions Menu
        _buildUserProfileMenu(context, displayModeProvider),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context, DisplayModeProvider displayModeProvider) {
    return Row(
      children: [
        // Drawer Menu Button
        if (onMenuToggle != null)
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onMenuToggle,
          ),

        // Durga Logo
        _buildLogo(size: 32),
        const SizedBox(width: 8),

        // Title (flexible to fit without cutting off or overlapping)
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),

        // Cloud Sync Status Symbol (Always visible on mobile)
        const SyncStatusBadge(),
        const SizedBox(width: 6),

        // Language Toggle Pill (Compact)
        _buildLanguagePill(compact: true),
        const SizedBox(width: 2),

        // Mobile Overflow Menu (Contains Display Mode Switcher, Year, Notifications, Profile, Lock, Logout)
        _buildMobileOptionsMenu(context, displayModeProvider),
      ],
    );
  }

  Widget _buildLogo({double size = 36}) {
    return Builder(
      builder: (context) {
        final logoUrl = MandalRepository().mandalProfile.logoUrl;
        if (logoUrl != null && logoUrl.isNotEmpty) {
          try {
            final clean = logoUrl.contains(',') ? logoUrl.split(',').last : logoUrl;
            final bytes = base64Decode(clean);
            return ClipOval(
              child: Image.memory(
                bytes,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultLogo(size),
              ),
            );
          } catch (_) {}
        }
        return _buildDefaultLogo(size);
      },
    );
  }

  Widget _buildDefaultLogo(double size) {
    return ClipOval(
      child: Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.brightGold,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.wb_sunny, color: AppColors.primaryMaroon, size: 18),
        ),
      ),
    );
  }

  Widget _buildLanguagePill({bool compact = false}) {
    return InkWell(
      onTap: () => AppStrings.toggleLanguage(),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accentGold.withAlpha(120)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: AppColors.accentGold, size: 13),
            const SizedBox(width: 3),
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
    );
  }

  Widget _buildMobileOptionsMenu(BuildContext context, DisplayModeProvider displayModeProvider) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Menu',
          onSelected: (val) {
            if (val == 'toggle_mode') {
              displayModeProvider.toggleMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    displayModeProvider.isMobile
                        ? AppStrings.tr('मोबाईल मोड सुरू केला (Mobile Mode)', 'Mobile Mode Enabled')
                        : AppStrings.tr('डेस्कटॉप मोड सुरू केला (Desktop Zoom Mode)', 'Desktop Zoom Mode Enabled'),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (val == 'notifications') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All Mandal services operating smoothly')),
              );
            } else if (val == 'lock') {
              auth.lockSubLogin();
            } else if (val == 'logout') {
              auth.signOut();
            }
          },
          itemBuilder: (ctx) => [
            // User Header Info
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.currentProfile?.fullName ?? 'Administrator',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                  ),
                  Text(
                    'Role: ${auth.isAdmin ? "ADMIN" : "MEMBER"}  •  Year: 2026',
                    style: TextStyle(
                      fontSize: 11,
                      color: auth.isAdmin ? AppColors.primaryMaroon : Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),

            // Display Mode Switcher (Dairy Management mechanism)
            PopupMenuItem(
              value: 'toggle_mode',
              child: Row(
                children: [
                  Icon(
                    displayModeProvider.isMobile ? Icons.desktop_windows_outlined : Icons.smartphone_outlined,
                    size: 18,
                    color: AppColors.primaryMaroon,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayModeProvider.isMobile
                          ? 'डेस्कटॉप मोड बदला (Zoom Mode)'
                          : 'मोबाईल मोड बदला (Responsive)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Notifications
            const PopupMenuItem(
              value: 'notifications',
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined, size: 18, color: AppColors.brightGold),
                  SizedBox(width: 8),
                  Text('सूचना / Notifications (3)', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),

            const PopupMenuDivider(),

            // Lock Sub-Login
            if (auth.isAdmin)
              const PopupMenuItem(
                value: 'lock',
                child: Row(
                  children: [
                    Icon(Icons.lock_clock_outlined, size: 18, color: AppColors.primaryMaroon),
                    SizedBox(width: 8),
                    Text('Lock Sub-Login / तारीख बदला', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),

            // Sign Out
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: AppColors.expenseRed),
                  SizedBox(width: 8),
                  Text('Sign Out / बाहेर पडा', style: TextStyle(fontSize: 13, color: AppColors.expenseRed)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserProfileMenu(BuildContext context, DisplayModeProvider displayModeProvider) {
    return Consumer<AuthProvider>(
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
    );
  }
}
