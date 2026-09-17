import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';

class NavItem {
  final int index;
  final String title;
  final IconData icon;

  const NavItem(this.index, this.title, this.icon);
}

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  List<NavItem> getNavItems() => [
    NavItem(0, AppStrings.navDashboard, Icons.dashboard_outlined),
    NavItem(1, AppStrings.navMembers, Icons.people_outline),
    NavItem(2, AppStrings.navDonations, Icons.currency_rupee),
    NavItem(3, AppStrings.navExpenses, Icons.receipt_long_outlined),
    NavItem(4, AppStrings.navBankCash, Icons.account_balance_outlined),
    NavItem(5, AppStrings.navEvents, Icons.event_note_outlined),
    NavItem(6, AppStrings.navGarba, Icons.nightlife),
    NavItem(7, AppStrings.navVolunteers, Icons.groups_outlined),
    NavItem(8, AppStrings.navVendors, Icons.storefront_outlined),
    NavItem(9, AppStrings.navInventory, Icons.inventory_2_outlined),
    NavItem(10, AppStrings.navPermissions, Icons.description_outlined),
    NavItem(11, AppStrings.navSponsors, Icons.handshake_outlined),
    NavItem(12, AppStrings.navFoodPrasad, Icons.restaurant_menu),
    NavItem(13, AppStrings.navSecurity, Icons.shield_outlined),
    NavItem(14, AppStrings.navGallery, Icons.photo_library_outlined),
    NavItem(15, AppStrings.navAarti, Icons.flare),
    NavItem(16, AppStrings.navMatajiIdol, Icons.temple_hindu),
    NavItem(17, AppStrings.navVisarjan, Icons.sailing_outlined),
    NavItem(18, AppStrings.navReports, Icons.analytics_outlined),
    NavItem(19, AppStrings.navUsersRoles, Icons.admin_panel_settings_outlined),
    NavItem(20, AppStrings.navBackupRestore, Icons.settings_backup_restore_rounded),
    NavItem(21, AppStrings.navSettings, Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Dark Navy/Charcoal Sidebar matching mockup
        border: Border(right: BorderSide(color: Color(0xFF334155))),
      ),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(bottom: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.brightGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.temple_hindu, color: AppColors.primaryMaroon, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr('नवरात्र ERP', 'NAVRATRI ERP'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        AppStrings.tr('उत्सव व्यवस्थापन', 'Utsav Management'),
                        style: const TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Navigation List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: getNavItems().length,
              itemBuilder: (context, idx) {
                final item = getNavItems()[idx];
                final isSelected = selectedIndex == item.index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: isSelected ? AppColors.primaryMaroon : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onDestinationSelected(item.index),
                      hoverColor: Colors.white.withAlpha(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 19,
                              color: isSelected ? AppColors.brightGold : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.brightGold,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Sidebar Footer Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(top: BorderSide(color: Color(0xFF334155))),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.successGreen,
                ),
                SizedBox(width: 8),
                Text(
                  'Database: Supabase Live',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
