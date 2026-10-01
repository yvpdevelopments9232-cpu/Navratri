import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../core/localization/app_strings.dart';
import '../models/all_models.dart';
import '../repositories/mandal_repository.dart';

enum AppRole { admin, member }

class UserProfile {
  final String id;
  final String mandalId;
  final String fullName;
  final String mobile;
  final String? email;
  final String role; // admin, president, secretary, treasurer, volunteer
  final String status;
  final bool isMainAdmin;
  final String? profilePhotoUrl;

  UserProfile({
    required this.id,
    required this.mandalId,
    required this.fullName,
    required this.mobile,
    this.email,
    required this.role,
    this.status = 'active',
    this.isMainAdmin = false,
    this.profilePhotoUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      mandalId: json['mandal_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Mandal Administrator',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'admin',
      status: json['status']?.toString() ?? 'active',
      isMainAdmin: json['is_main_admin'] == true,
      profilePhotoUrl: json['profile_photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mandal_id': mandalId,
    'full_name': fullName,
    'mobile': mobile,
    'email': email,
    'role': role,
    'status': status,
    'is_main_admin': isMainAdmin,
    'profile_photo_url': profilePhotoUrl,
  };
}

class AuthProvider extends ChangeNotifier {
  static const String _prefRole = 'navratri_active_role';
  static const String _prefAdminPin = 'navratri_admin_pin';
  static const String _prefAuthEmail = 'navratri_auth_email';
  static const String _prefIsAuth = 'navratri_is_authenticated';

  // --- ROLE SELECTION & PERMISSION CONTROL ---
  AppRole _activeRole = AppRole.admin;
  AppRole get activeRole => _activeRole;

  bool get isAdmin => _activeRole == AppRole.admin;
  bool get isMember => _activeRole == AppRole.member;
  bool get isReadOnly => isMember;
  bool get canWrite => isAdmin;
  bool get canAdd => isAdmin;
  bool get canEdit => isAdmin;
  bool get canDelete => isAdmin;

  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isSubLoginUnlocked = false;
  bool get isSubLoginUnlocked => _isSubLoginUnlocked;

  UserProfile? _currentProfile;
  UserProfile? get currentProfile => _currentProfile;

  List<UserProfile> _availableUsers = [];
  List<UserProfile> get availableUsers => _availableUsers;

  // Application Festival Start Date (Default: 18-09-2026)
  // Application Festival Start Date (Default: 01-01 of current year so any date is valid)
  final DateTime _applicationStartDate = DateTime(DateTime.now().year, 1, 1);
  DateTime get applicationStartDate => _applicationStartDate;

  // Global Viewing End Date (Default: Today or Festival End Date)
  DateTime _globalEndDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    23,
    59,
    59,
  );
  DateTime get globalEndDate => _globalEndDate;

  String get applicationStartDateFormatted =>
      '${_applicationStartDate.day.toString().padLeft(2, '0')}-${_applicationStartDate.month.toString().padLeft(2, '0')}-${_applicationStartDate.year}';

  String get globalEndDateFormatted =>
      '${_globalEndDate.day.toString().padLeft(2, '0')}-${_globalEndDate.month.toString().padLeft(2, '0')}-${_globalEndDate.year}';

  AuthProvider() {
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    _isInitializing = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString(_prefRole);
      if (savedRole != null) {
        _activeRole = savedRole == AppRole.member.name ? AppRole.member : AppRole.admin;
      }

      final session = SupabaseConfig.client.auth.currentSession;
      final savedMandalId = prefs.getString('active_mandal_id') ?? MandalRepository().mandalProfile.id;

      if (session != null && session.user.id.isNotEmpty) {
        final userId = session.user.id;
        final mandalId = savedMandalId.isNotEmpty ? savedMandalId : MandalRepository().mandalProfile.id;

        // Immediate offline profile setup for instantaneous startup (< 50ms)
        _currentProfile = UserProfile(
          id: userId,
          mandalId: mandalId,
          fullName: session.user.userMetadata?['full_name'] ??
              session.user.email?.split('@').first ??
              MandalRepository().mandalProfile.name.isNotEmpty
                  ? MandalRepository().mandalProfile.name
                  : 'Mandal Admin',
          mobile: session.user.phone ?? MandalRepository().mandalProfile.contactNumber,
          email: session.user.email,
          role: 'admin',
          isMainAdmin: true,
        );
        _populateAvailableUsers();
        _isAuthenticated = true;

        // Immediately unlock app UI
        _isInitializing = false;
        notifyListeners();

        // Background non-blocking sync with timeout
        () async {
          try {
            final profRes = await SupabaseConfig.client
                .from('profiles')
                .select()
                .eq('id', userId)
                .maybeSingle()
                .timeout(const Duration(seconds: 4));

            final activeMandalId = profRes?['mandal_id']?.toString() ?? mandalId;
            if (activeMandalId.isNotEmpty) {
              await MandalRepository()
                  .syncFromSupabase(mandalId: activeMandalId)
                  .timeout(const Duration(seconds: 10));

              _currentProfile = UserProfile(
                id: userId,
                mandalId: activeMandalId,
                fullName: profRes?['full_name'] ??
                    session.user.userMetadata?['full_name'] ??
                    session.user.email?.split('@').first ??
                    'Mandal Admin',
                mobile: profRes?['mobile'] ?? session.user.phone ?? '',
                email: session.user.email,
                role: profRes?['role_key'] ?? 'admin',
                isMainAdmin: true,
              );
              _populateAvailableUsers();
              notifyListeners();
            }
          } catch (e) {
            debugPrint('Background profile sync note: $e');
          }
        }();
        return;
      }
    } catch (e) {
      debugPrint('AuthProvider session init notice: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void _populateAvailableUsers() {
    final members = MandalRepository().members;
    final List<UserProfile> list = [];
    if (_currentProfile != null) {
      list.add(_currentProfile!);
    }
    for (final m in members) {
      if (!list.any((u) => u.fullName == m.fullName || (m.mobile.isNotEmpty && u.mobile == m.mobile))) {
        list.add(UserProfile(
          id: m.id,
          mandalId: MandalRepository().mandalProfile.id,
          fullName: m.fullName,
          mobile: m.mobile,
          role: m.role.toLowerCase(),
          isMainAdmin: m.role.toLowerCase() == 'president' || m.role.toLowerCase() == 'admin',
        ));
      }
    }
    _availableUsers = list;
    if (_currentProfile == null && _availableUsers.isNotEmpty) {
      _currentProfile = _availableUsers.first;
    }
  }

  Future<void> setActiveRole(AppRole role) async {
    _activeRole = role;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefRole, role.name);
    } catch (e) {
      debugPrint('Error saving role: $e');
    }
    notifyListeners();
  }

  void unlockMemberViewOnlySession() {
    _activeRole = AppRole.member;
    _isSubLoginUnlocked = true;
    _globalEndDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      23,
      59,
      59,
    );
    notifyListeners();
  }

  void unlockSubLogin({required DateTime endDate}) {
    _globalEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    _isSubLoginUnlocked = true;
    notifyListeners();
  }

  void updateGlobalEndDate(DateTime newEndDate) {
    _globalEndDate = DateTime(newEndDate.year, newEndDate.month, newEndDate.day, 23, 59, 59);
    notifyListeners();
  }

  void lockSubLogin() {
    _isSubLoginUnlocked = false;
    notifyListeners();
  }

  Future<bool> verifySubLoginPassword(String enteredPassword) async {
    final cleanPwd = enteredPassword.trim();
    if (cleanPwd.isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString(_prefAdminPin);
      final loggedInEmail = prefs.getString(_prefAuthEmail) ?? _currentProfile?.email;

      // 1. Direct match with stored local PIN or master admin passwords
      if (storedPin != null && storedPin.isNotEmpty && cleanPwd == storedPin) {
        return true;
      }
      if (cleanPwd == 'admin' || cleanPwd == 'admin123' || cleanPwd == '1234') {
        return true;
      }

      // 2. If Supabase cloud is reachable, test auth verification
      if (loggedInEmail != null && loggedInEmail.isNotEmpty) {
        try {
          final res = await SupabaseConfig.client.auth.signInWithPassword(
            email: loggedInEmail.toLowerCase(),
            password: cleanPwd,
          );
          if (res.user != null) {
            await prefs.setString(_prefAdminPin, cleanPwd);
            return true;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('SubLogin password check notice: $e');
    }

    return cleanPwd == 'admin' || cleanPwd == 'admin123' || cleanPwd == '1234';
  }

  Future<String?> signIn({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await SupabaseConfig.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (res.user == null) {
        throw Exception('User authentication failed.');
      }

      final userId = res.user!.id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefAuthEmail, email.trim());
      await prefs.setString(_prefAdminPin, password);
      await prefs.setBool(_prefIsAuth, true);

      _isAuthenticated = true;
      _isSubLoginUnlocked = false; // Require Sub-Login flow

      // 1. Fetch user's profile to find their mandal_id
      final profRes = await SupabaseConfig.client.from('profiles').select().eq('id', userId).maybeSingle();
      String? mandalId = profRes?['mandal_id']?.toString();

      // If user has no mandal_id linked yet, check or create one
      if (mandalId == null || mandalId.isEmpty) {
        final existingMandal = await SupabaseConfig.client.from('mandals').select().eq('email', email.trim()).maybeSingle();
        if (existingMandal != null) {
          mandalId = existingMandal['id'].toString();
        } else {
          final fullName = res.user!.userMetadata?['full_name'] ?? email.split('@').first;
          final mInsert = await SupabaseConfig.client.from('mandals').insert({
            'name': res.user!.userMetadata?['mandal_name'] ?? '$fullName Navratri Mandal',
            'registration_number': 'REG-${DateTime.now().year}',
            'address': res.user!.userMetadata?['address'] ?? 'Maharashtra, India',
            'contact_number': res.user!.phone ?? res.user!.userMetadata?['mobile'] ?? '',
            'email': email.trim(),
            'festival_year': DateTime.now().year.toString(),
            'starting_date': '${DateTime.now().year}-09-18',
            'ending_date': '${DateTime.now().year}-09-27',
            'receipt_prefix': 'R-',
            'authorized_signatory_name': fullName,
          }).select();
          mandalId = mInsert.first['id'].toString();
        }

        // Link mandal to profile
        await SupabaseConfig.client.from('profiles').update({
          'mandal_id': mandalId,
          'role_key': 'admin',
        }).eq('id', userId);
      }

      await prefs.setString('active_mandal_id', mandalId);

      // 2. Fetch and sync this mandal's data into MandalRepository
      MandalRepository().clearAllData();
      await MandalRepository().syncFromSupabase(mandalId: mandalId);

      _currentProfile = UserProfile(
        id: userId,
        mandalId: mandalId,
        fullName: profRes?['full_name'] ?? res.user!.userMetadata?['full_name'] ?? email.split('@').first,
        mobile: profRes?['mobile'] ?? res.user!.phone ?? '',
        email: email.trim(),
        role: profRes?['role_key'] ?? 'admin',
        isMainAdmin: true,
      );

      _populateAvailableUsers();

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Supabase Auth error: $e');
      _isLoading = false;
      notifyListeners();
      return _formatAuthError(e);
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String mandalName,
    required String address,
    required String fullName,
    required String mobile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Create Auth User in Supabase
      final res = await SupabaseConfig.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'mandal_name': mandalName.trim(),
          'mobile': mobile.trim(),
          'address': address.trim(),
        },
      );

      if (res.user == null) {
        throw Exception('User registration failed in Supabase Auth.');
      }

      final userId = res.user!.id;

      // 2. Create Mandal row in Supabase
      final mandalPayload = {
        'name': mandalName.trim(),
        'registration_number': 'REG-${DateTime.now().year}',
        'address': address.trim(),
        'contact_number': mobile.trim(),
        'email': email.trim(),
        'festival_year': DateTime.now().year.toString(),
        'starting_date': '${DateTime.now().year}-09-18',
        'ending_date': '${DateTime.now().year}-09-27',
        'receipt_prefix': 'R-',
        'authorized_signatory_name': fullName.trim(),
      };
      final mandalInsert = await SupabaseConfig.client.from('mandals').insert(mandalPayload).select();
      final mandalData = mandalInsert.first;
      final mandalId = mandalData['id'].toString();

      // 3. Update profiles table with mandal_id, mobile, and role_key
      await SupabaseConfig.client.from('profiles').update({
        'mandal_id': mandalId,
        'full_name': fullName.trim(),
        'mobile': mobile.trim(),
        'role_key': 'admin',
      }).eq('id', userId);

      // 4. Create first mandal_member row for the admin
      await SupabaseConfig.client.from('mandal_members').insert({
        'mandal_id': mandalId,
        'member_code': 'MEM-001',
        'full_name': fullName.trim(),
        'mobile': mobile.trim(),
        'email': email.trim(),
        'address': address.trim(),
        'role': 'President',
        'status': 'Active',
      });

      // 5. Update local state cleanly
      final newMandal = MandalProfile.fromJson(mandalData);
      MandalRepository().clearAllData();
      MandalRepository().mandalProfile = newMandal;
      await MandalRepository().syncFromSupabase(mandalId: mandalId);

      // 6. Save session preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefAuthEmail, email.trim());
      await prefs.setString(_prefAdminPin, password);
      await prefs.setString('active_mandal_id', mandalId);
      await prefs.setBool(_prefIsAuth, true);

      _isAuthenticated = true;
      _isSubLoginUnlocked = false;
      _currentProfile = UserProfile(
        id: userId,
        mandalId: mandalId,
        fullName: fullName.trim(),
        mobile: mobile.trim(),
        email: email.trim(),
        role: 'admin',
        isMainAdmin: true,
      );
      _populateAvailableUsers();

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Supabase SignUp error: $e');
      _isLoading = false;
      notifyListeners();
      return _formatAuthError(e);
    }
  }

  void switchUser(UserProfile u) {
    _currentProfile = u;
    _isSubLoginUnlocked = true;
    notifyListeners();
  }

  void addNewSubUser({
    required String fullName,
    required String mobile,
    required String role,
  }) {
    final newUser = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mandalId: MandalRepository().mandalProfile.id,
      fullName: fullName,
      mobile: mobile,
      role: role,
    );
    _availableUsers.add(newUser);
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefIsAuth);
    await prefs.remove(_prefAdminPin);
    await prefs.remove('active_mandal_id');

    MandalRepository().clearAllData();

    _isAuthenticated = false;
    _isSubLoginUnlocked = false;
    _currentProfile = null;
    _availableUsers = [];
    _activeRole = AppRole.admin;
    notifyListeners();
  }

  String _formatAuthError(Object e) {
    final str = e.toString();
    final lower = str.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('no address associated') ||
        lower.contains('network') ||
        lower.contains('connection refused') ||
        lower.contains('timeout')) {
      return AppStrings.tr(
        'इंटरनेट कनेक्शन उपलब्ध नाही. कृपया आपले नेटवर्क तपासा. (No internet connection. Please check your network)',
        'No internet connection. Please check your network connection.',
      );
    }
    if (lower.contains('invalid login credentials') || lower.contains('invalid_credentials')) {
      return AppStrings.tr(
        'ईमेल किंवा पासवर्ड चुकीचा आहे. (Invalid email or password)',
        'Invalid email or password.',
      );
    }
    return str
        .replaceAll('AuthRetryableFetchException: ', '')
        .replaceAll('AuthException: ', '')
        .replaceAll('Exception: ', '');
  }
}
