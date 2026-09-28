import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/mandal_repository.dart';
import '../../backup/screens/backup_restore_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final repository = MandalRepository();
  int selectedSubTab = 0;
  String? _selectedLogoBase64;
  bool _isSaving = false;

  late TextEditingController nameCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController contactCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController yearCtrl;

  List<String> get subTabs => [
    AppStrings.tr('मंडळ प्रोफाइल', 'Mandal Profile'),
    AppStrings.tr('पावती सेटिंग्ज', 'Receipt Settings'),
    AppStrings.tr('देणगीदार सेटिंग्ज', 'Investor / Donor Settings'),
    AppStrings.tr('PDF सेटिंग्ज', 'PDF Settings'),
    AppStrings.tr('वापरकर्ता व्यवस्थापन', 'User Management'),
    AppStrings.tr('बॅकअप व रिस्टोअर', 'Backup & Restore'),
    AppStrings.tr('भाषा (Language)', 'Language'),
    AppStrings.tr('थीम (Theme)', 'Theme'),
    AppStrings.tr('सूचना सेटिंग्ज', 'Notification Settings'),
  ];

  @override
  void initState() {
    super.initState();
    final p = repository.mandalProfile;
    nameCtrl = TextEditingController(text: p.name);
    addressCtrl = TextEditingController(text: p.address);
    contactCtrl = TextEditingController(text: p.contactNumber);
    emailCtrl = TextEditingController(text: p.email);
    yearCtrl = TextEditingController(text: p.festivalYear);
    _selectedLogoBase64 = p.logoUrl;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    contactCtrl.dispose();
    emailCtrl.dispose();
    yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndSaveLogo() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.image,
      );

      if (picked != null) {
        final bytes = await picked.xFile.readAsBytes();
        final ext = (picked.extension ?? 'png').toLowerCase();
        final mime = (ext == 'jpg' || ext == 'jpeg') ? 'image/jpeg' : 'image/png';
        final b64 = 'data:$mime;base64,${base64Encode(bytes)}';

        setState(() {
          _selectedLogoBase64 = b64;
        });

        // Update repository in-memory and save directly to Supabase
        final updated = repository.mandalProfile.copyWith(logoUrl: b64);
        await repository.updateMandalProfile(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.tr(
                'मंडळ लोगो Base64 मध्ये रूपांतरित करून Supabase वर जतन केला!',
                'Profile image converted to Base64 and saved to Supabase successfully!',
              )),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Widget _buildLogoPreview() {
    if (_selectedLogoBase64 != null && _selectedLogoBase64!.isNotEmpty) {
      try {
        final clean = _selectedLogoBase64!.contains(',')
            ? _selectedLogoBase64!.split(',').last
            : _selectedLogoBase64!;
        final decoded = base64Decode(clean);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            decoded,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
          ),
        );
      } catch (_) {}
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/images/app_logo.png',
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.brightGold,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.wb_sunny, color: AppColors.primaryMaroon),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final updated = repository.mandalProfile.copyWith(
        name: nameCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        contactNumber: contactCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        festivalYear: yearCtrl.text.trim(),
        logoUrl: _selectedLogoBase64,
      );

      await repository.updateMandalProfile(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.tr('सेटिंग्ज यशस्वीरित्या जतन केल्या!', 'Settings saved successfully!')),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 700;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.settings, color: AppColors.primaryMaroon),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.tr('मंडळ ERP सेटिंग्ज व संरचना', 'Mandal ERP Settings & Configuration'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveSettings,
                          icon: _isSaving
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check, size: 16),
                          label: Text(_isSaving ? AppStrings.tr('जतन होत आहे...', 'Saving...') : AppStrings.saveSettings),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryMaroon,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (isCompact) ...[
                      // Mobile: Horizontal Scrollable Tab Bar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: List.generate(subTabs.length, (idx) {
                            final isSelected = selectedSubTab == idx;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(
                                  subTabs[idx],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.primaryMaroon,
                                backgroundColor: const Color(0xFFF1F5F9),
                                onSelected: (_) => setState(() => selectedSubTab = idx),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Settings Form Content (Full Width)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: selectedSubTab == 5
                            ? const BackupRestoreScreen()
                            : selectedSubTab == 6
                                ? _buildLanguageTab()
                                : _buildMandalProfileTab(),
                      ),
                    ] else ...[
                      // Desktop: Side-by-side split layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Settings Left Menu
                          Container(
                            width: 220,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: subTabs.length,
                              itemBuilder: (ctx, idx) {
                                final isSelected = selectedSubTab == idx;
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    subTabs[idx],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? AppColors.primaryMaroon : AppColors.textPrimary,
                                    ),
                                  ),
                                  tileColor: isSelected ? Colors.white : Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    side: isSelected ? const BorderSide(color: AppColors.primaryMaroon, width: 2) : BorderSide.none,
                                  ),
                                  onTap: () => setState(() => selectedSubTab = idx),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Settings Form Content
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: selectedSubTab == 5
                                  ? const BackupRestoreScreen()
                                  : selectedSubTab == 6
                                      ? _buildLanguageTab()
                                      : _buildMandalProfileTab(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.tr('भाषा निवडा (Select Language)', 'Select Application Language'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryMaroon),
        ),
        const Divider(),
        const SizedBox(height: 16),
        _buildLanguageOptionCard(
          title: 'मराठी (Marathi) - मूळ भाषा',
          subtitle: 'सर्व स्क्रीन, मेनू आणि पावत्या मराठी भाषेत दिसतील',
          isSelected: AppStrings.isMarathi,
          onTap: () {
            AppStrings.setLanguage(marathi: true);
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        _buildLanguageOptionCard(
          title: 'English',
          subtitle: 'All screens, menus, and reports will be in English',
          isSelected: !AppStrings.isMarathi,
          onTap: () {
            AppStrings.setLanguage(marathi: false);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildLanguageOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMaroon.withAlpha(15) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryMaroon : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryMaroon : AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? AppColors.primaryMaroon : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMandalProfileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subTabs[selectedSubTab],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryMaroon),
        ),
        const Divider(),
        const SizedBox(height: 12),

        TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: AppStrings.tr('मंडळाचे नाव *', 'Mandal Name *'),
            prefixIcon: const Icon(Icons.temple_hindu),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: addressCtrl,
          decoration: InputDecoration(
            labelText: AppStrings.tr('पत्ता / प्रभाग *', 'Address / Ward *'),
            prefixIcon: const Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: contactCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.tr('संपर्क क्रमांक', 'Contact No.'),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.tr('ईमेल पत्ता', 'Email Address'),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: yearCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.tr('उत्सव वर्ष', 'Festival Year'),
                  prefixIcon: const Icon(Icons.calendar_month),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  _buildLogoPreview(),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _pickAndSaveLogo,
                    icon: const Icon(Icons.photo_camera, size: 16),
                    label: Text(AppStrings.changeLogo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMaroon,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
