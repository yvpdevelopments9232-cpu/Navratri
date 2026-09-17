import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'core/localization/app_strings.dart';
import 'core/responsive/adaptive_responsive_layout.dart';
import 'core/theme/app_theme.dart';
import 'features/aarti/screens/aarti_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/sub_login_screen.dart';
import 'features/backup/screens/backup_restore_screen.dart';
import 'features/bank_cash/screens/bank_cash_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/donations/screens/donations_screen.dart';
import 'features/events/screens/events_screen.dart';
import 'features/expenses/screens/expenses_screen.dart';
import 'features/food/screens/food_screen.dart';
import 'features/gallery/screens/gallery_screen.dart';
import 'features/garba/screens/garba_screen.dart';
import 'features/idol/screens/idol_screen.dart';
import 'features/inventory/screens/inventory_screen.dart';
import 'features/members/screens/members_screen.dart';
import 'features/permissions/screens/permissions_screen.dart';
import 'features/reports/screens/reports_screen.dart';
import 'features/security/screens/security_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/sponsors/screens/sponsors_screen.dart';
import 'features/users/screens/users_screen.dart';
import 'features/visarjan/screens/visarjan_screen.dart';
import 'features/volunteers/screens/volunteers_screen.dart';
import 'features/vendors/screens/vendors_screen.dart';
import 'providers/auth_provider.dart';
import 'repositories/mandal_repository.dart';
import 'services/offline_db_helper.dart';
import 'services/sync_service.dart';
import 'widgets/app_header.dart';
import 'widgets/app_sidebar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Offline Local SQLite (FFI on Windows Desktop, Native on Android)
  OfflineDbHelper.initializeFfi();

  // 2. Initialize Supabase Client
  await SupabaseConfig.initialize();

  // 3. Load Bilingual Marathi/English preference
  await AppStrings.loadLanguagePreference();

  // 4. Load cached data from local SQLite database (Instant offline startup)
  await MandalRepository().loadFromLocalDb();

  // 5. Start dynamic background auto-sync engine (Dynamic heartbeat & network listener)
  SyncService.instance.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const NavratriMandalApp(),
    ),
  );
}

class NavratriMandalApp extends StatelessWidget {
  const NavratriMandalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppStrings.languageNotifier,
      builder: (context, isMarathi, _) {
        return MaterialApp(
          title: 'Navratri Utsav Mandal Management ERP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const MainAppController(),
        );
      },
    );
  }
}

class MainAppController extends StatefulWidget {
  const MainAppController({super.key});

  @override
  State<MainAppController> createState() => _MainAppControllerState();
}

class _MainAppControllerState extends State<MainAppController> {
  int selectedModuleIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildCurrentScreen() {
    switch (selectedModuleIndex) {
      case 0:
        return DashboardScreen(onNavigate: (idx) => setState(() => selectedModuleIndex = idx));
      case 1:
        return const MembersScreen();
      case 2:
        return const DonationsScreen();
      case 3:
        return const ExpensesScreen();
      case 4:
        return const BankCashScreen();
      case 5:
        return const EventsScreen();
      case 6:
        return const GarbaScreen();
      case 7:
        return const VolunteersScreen();
      case 8:
        return const VendorsScreen();
      case 9:
        return const InventoryScreen();
      case 10:
        return const PermissionsScreen();
      case 11:
        return const SponsorsScreen();
      case 12:
        return const FoodScreen();
      case 13:
        return const SecurityScreen();
      case 14:
        return const GalleryScreen();
      case 15:
        return const AartiScreen();
      case 16:
        return const IdolScreen();
      case 17:
        return const VisarjanScreen();
      case 18:
        return const ReportsScreen();
      case 19:
        return const UsersScreen();
      case 20:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: BackupRestoreScreen(),
        );
      case 21:
        return const SettingsScreen();
      default:
        return DashboardScreen(onNavigate: (idx) => setState(() => selectedModuleIndex = idx));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Initial loading indicator while session initializes
    if (auth.isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryMaroon),
        ),
      );
    }

    // Step 1: Bachatgat Login Screen
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Step 2: Bachatgat Sub-Login Screen for Admin users
    if (auth.isAdmin && !auth.isSubLoginUnlocked) {
      return const SubLoginScreen();
    }

    // Step 3: Main Mandal Application (Windows Desktop vs Android Mobile/Tablet)
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final repository = MandalRepository();

    if (isDesktop) {
      // Windows Desktop Layout: Fixed Sidebar + Main Content Area
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Row(
          children: [
            AppSidebar(
              selectedIndex: selectedModuleIndex,
              onDestinationSelected: (idx) => setState(() => selectedModuleIndex = idx),
            ),
            Expanded(
              child: Column(
                children: [
                  AppHeader(
                    title: repository.mandalProfile.name,
                  ),
                  Expanded(
                    child: _buildCurrentScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Android Mobile & Tablet Layout: Responsive Drawer Navigation
      return Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: true,
        appBar: AppHeader(
          title: repository.mandalProfile.name,
          onMenuToggle: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        drawer: Drawer(
          child: AppSidebar(
            selectedIndex: selectedModuleIndex,
            onDestinationSelected: (idx) {
              Navigator.pop(context); // Close drawer
              setState(() => selectedModuleIndex = idx);
            },
          ),
        ),
        body: SafeArea(
          child: _buildCurrentScreen(),
        ),
      );
    }
  }
}
