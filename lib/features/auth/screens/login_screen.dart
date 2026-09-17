import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import 'sub_login_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSignUp = false;
  bool isSubUserLogin = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Login Controllers
  final TextEditingController _loginEmailController =
      TextEditingController(text: 'admin@mandal.org');
  final TextEditingController _loginPasswordController =
      TextEditingController(text: 'admin123');

  // Sign Up Controllers
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _signupMandalNameController = TextEditingController();
  final TextEditingController _signupAddressController = TextEditingController();
  final TextEditingController _signupFullNameController = TextEditingController();
  final TextEditingController _signupMobileController = TextEditingController();

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupMandalNameController.dispose();
    _signupAddressController.dispose();
    _signupFullNameController.dispose();
    _signupMobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return ValueListenableBuilder<bool>(
      valueListenable: AppStrings.languageNotifier,
      builder: (context, isMr, _) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.background,
          body: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                child: isSubUserLogin
                    ? _buildSubUserSwitchView(context, auth)
                    : isSignUp
                        ? _buildSignUpForm(context, auth)
                        : _buildLoginForm(context, auth),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        // App Logo & Title
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primaryMaroon, AppColors.secondaryRed],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryMaroon.withAlpha(70),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.temple_hindu, color: AppColors.brightGold, size: 44),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.appName,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryMaroon,
          ),
        ),
        Text(
          AppStrings.appSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),

        // Language Selector Pill
        InkWell(
          onTap: () => AppStrings.toggleLanguage(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryMaroon.withAlpha(70)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 16, color: AppColors.primaryMaroon),
                const SizedBox(width: 8),
                Text(
                  AppStrings.isMarathi ? 'मराठी  |  English' : 'English  |  मराठी',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryMaroon,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Login Card
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.loginTitle,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMaroon.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Supabase Auth',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryMaroon,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withAlpha(70)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              TextField(
                controller: _loginEmailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
                decoration: InputDecoration(
                  labelText: AppStrings.emailLabel,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _loginPasswordController,
                obscureText: _obscurePassword,
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
                decoration: InputDecoration(
                  labelText: AppStrings.passwordLabel,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    AppStrings.forgotPassword,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                width: double.infinity,
                text: auth.isLoading ? AppStrings.loggingIn : AppStrings.loginButton,
                isLoading: auth.isLoading,
                onPressed: auth.isLoading ? null : () => _handleLogin(context, auth),
              ),
              const SizedBox(height: 14),

              // Switch to Sign Up
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    AppStrings.newAccountPrompt,
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      isSignUp = true;
                      _errorMessage = null;
                    }),
                    child: Text(
                      AppStrings.signUpLink,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryMaroon,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.divider),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      isSubUserLogin = true;
                      _errorMessage = null;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.switch_account_rounded, color: AppColors.primaryMaroon, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppStrings.subUserSwitch,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primaryMaroon,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        // App Logo & Title
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primaryMaroon, AppColors.secondaryRed],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryMaroon.withAlpha(70),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.app_registration_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.signUpTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryMaroon,
          ),
        ),
        Text(
          AppStrings.signUpSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Sign Up Card
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withAlpha(70)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 1. Email ID (Username)
              TextField(
                controller: _signupEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Username / Email ID (ईमेल आयडी) *',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Password
              TextField(
                controller: _signupPasswordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password (किमान ६ अक्षरे) *',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Mandal Name
              TextField(
                controller: _signupMandalNameController,
                decoration: InputDecoration(
                  labelText: AppStrings.mandalNameLabel,
                  prefixIcon: const Icon(Icons.temple_hindu_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // 4. Address / Village / City
              TextField(
                controller: _signupAddressController,
                decoration: InputDecoration(
                  labelText: AppStrings.addressLabel,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Full Name
              TextField(
                controller: _signupFullNameController,
                decoration: InputDecoration(
                  labelText: AppStrings.adminNameLabel,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),

              // 6. Mobile (Optional)
              TextField(
                controller: _signupMobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: AppStrings.mobileLabel,
                  prefixIcon: const Icon(Icons.phone_android_rounded),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              AppButton(
                width: double.infinity,
                text: auth.isLoading ? AppStrings.signingUp : AppStrings.signUpButton,
                isLoading: auth.isLoading,
                onPressed: auth.isLoading ? null : () => _handleSignUp(context, auth),
              ),
              const SizedBox(height: 14),

              // Back to Login
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    AppStrings.alreadyHaveAccount,
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      isSignUp = false;
                      _errorMessage = null;
                    }),
                    child: Text(
                      AppStrings.loginLink,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryMaroon,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin(BuildContext context, AuthProvider auth) async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage =
          'कृपया ईमेल आयडी आणि पासवर्ड टाका (Please enter email and password)');
      return;
    }

    setState(() => _errorMessage = null);
    final error = await auth.signIn(email: email, password: password);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      if (!context.mounted) return;
      _showRoleSelectionDialog(context, auth);
    }
  }

  Future<void> _handleSignUp(BuildContext context, AuthProvider auth) async {
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text;
    final mandal = _signupMandalNameController.text.trim();
    final address = _signupAddressController.text.trim();
    final fullName = _signupFullNameController.text.trim();
    final mobile = _signupMobileController.text.trim();

    if (email.isEmpty || password.isEmpty || mandal.isEmpty || address.isEmpty || fullName.isEmpty) {
      setState(() => _errorMessage =
          'सर्व आवश्यक माहिती भरा (Please fill all required fields marked with *)');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage =
          'पासवर्ड किमान ६ अक्षरांचा असावा (Password must be at least 6 characters)');
      return;
    }

    setState(() => _errorMessage = null);
    final error = await auth.signUp(
      email: email,
      password: password,
      mandalName: mandal,
      address: address,
      fullName: fullName,
      mobile: mobile,
    );

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('मंडळ आणि खाते यशस्वीरित्या तयार झाले! (Mandal account registered!)'),
          backgroundColor: AppColors.success,
        ),
      );
      _showRoleSelectionDialog(context, auth);
    }
  }

  Future<void> _showRoleSelectionDialog(BuildContext context, AuthProvider auth) async {
    AppRole selectedRole = AppRole.admin;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 10,
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMaroon.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: AppColors.primaryMaroon,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.selectRole,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                AppStrings.selectRoleSubtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Role Option 1: Admin
                    InkWell(
                      onTap: () {
                        setDialogState(() => selectedRole = AppRole.admin);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selectedRole == AppRole.admin
                              ? const Color(0xFFFEF2F2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedRole == AppRole.admin
                                ? AppColors.primaryMaroon
                                : AppColors.cardBorder,
                            width: selectedRole == AppRole.admin ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // ignore: deprecated_member_use
                            Radio<AppRole>(
                              value: AppRole.admin,
                              // ignore: deprecated_member_use
                              groupValue: selectedRole,
                              activeColor: AppColors.primaryMaroon,
                              // ignore: deprecated_member_use
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedRole = val);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        AppStrings.roleAdmin,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: selectedRole == AppRole.admin
                                              ? AppColors.primaryMaroon
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryMaroon.withAlpha(25),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Full Access',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryMaroon,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppStrings.roleAdminDesc,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Role Option 2: Member
                    InkWell(
                      onTap: () {
                        setDialogState(() => selectedRole = AppRole.member);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selectedRole == AppRole.member
                              ? const Color(0xFFF0FDF4)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedRole == AppRole.member
                                ? const Color(0xFF16A34A)
                                : AppColors.cardBorder,
                            width: selectedRole == AppRole.member ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // ignore: deprecated_member_use
                            Radio<AppRole>(
                              value: AppRole.member,
                              // ignore: deprecated_member_use
                              groupValue: selectedRole,
                              activeColor: const Color(0xFF16A34A),
                              // ignore: deprecated_member_use
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedRole = val);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        AppStrings.roleMember,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: selectedRole == AppRole.member
                                              ? const Color(0xFF15803D)
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'View Only',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF15803D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppStrings.roleMemberDesc,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Button: CONTINUE
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        if (selectedRole == AppRole.admin) {
                          await auth.setActiveRole(AppRole.admin);
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubLoginScreen(
                                onSubLoginSuccess: widget.onLoginSuccess,
                              ),
                            ),
                          );
                        } else {
                          await auth.setActiveRole(AppRole.member);
                          auth.unlockMemberViewOnlySession();
                          if (!context.mounted) return;
                          widget.onLoginSuccess?.call();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedRole == AppRole.admin
                            ? AppColors.primaryMaroon
                            : const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.continueBtn,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubUserSwitchView(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => isSubUserLogin = false),
            ),
            Text(
              'Select Account / खाते निवडा',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...auth.availableUsers.map((u) {
          final isSelected = auth.currentProfile?.id == u.id;
          return AppCard(
            onTap: () {
              auth.switchUser(u);
              _showRoleSelectionDialog(context, auth);
            },
            color: isSelected ? AppColors.primaryMaroon.withAlpha(15) : Colors.white,
            border: isSelected
                ? Border.all(color: AppColors.primaryMaroon, width: 2)
                : null,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryMaroon.withAlpha(25),
                  child: const Icon(Icons.person, color: AppColors.primaryMaroon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.fullName,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(u.role.toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.primaryMaroon),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        AppButton(
          width: double.infinity,
          isOutlined: true,
          icon: Icons.person_add_rounded,
          text: '+ Add New Sub-User',
          onPressed: () => _showAddUserDialog(context, auth),
        ),
      ],
    );
  }

  void _showAddUserDialog(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    String selectedRole = 'volunteer';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Sub-User (नवीन वापरकर्ता)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name (पूर्ण नाव)')),
                const SizedBox(height: 12),
                TextField(
                    controller: mobileCtrl,
                    decoration: const InputDecoration(labelText: 'Mobile (मोबाईल)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  items: ['admin', 'president', 'secretary', 'treasurer', 'volunteer'].map((r) {
                    return DropdownMenuItem(value: r, child: Text(r.toUpperCase()));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedRole = v);
                  },
                  decoration: const InputDecoration(labelText: 'Role (भूमिका)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  auth.addNewSubUser(
                    fullName: nameCtrl.text,
                    mobile: mobileCtrl.text,
                    role: selectedRole,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save User'),
            ),
          ],
        ),
      ),
    );
  }
}
