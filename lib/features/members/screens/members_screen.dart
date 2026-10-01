import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../services/offline_db_helper.dart';
import '../../../widgets/status_badge.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final repository = MandalRepository();
  String _searchQuery = '';

  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String selectedRole = 'Committee Member';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primaryMaroon.withAlpha(20), shape: BoxShape.circle),
              child: const Icon(Icons.person_add, color: AppColors.primaryMaroon, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('नवीन सदस्य नोंदवा', 'Add New Member'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('पूर्ण नाव *', 'Full Name *'),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobileCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('मोबाईल नंबर *', 'Mobile Number *'),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('मंडळ पद / भूमिका', 'Mandal Role'),
                    prefixIcon: const Icon(Icons.badge),
                  ),
                  items: [
                    DropdownMenuItem(value: 'President', child: Text(AppStrings.tr('अध्यक्ष (President)', 'President'))),
                    DropdownMenuItem(value: 'Vice President', child: Text(AppStrings.tr('उपाध्यक्ष (Vice President)', 'Vice President'))),
                    DropdownMenuItem(value: 'Secretary', child: Text(AppStrings.tr('सचिव / कार्यवाह (Secretary)', 'Secretary'))),
                    DropdownMenuItem(value: 'Treasurer', child: Text(AppStrings.tr('खजिनदार (Treasurer)', 'Treasurer'))),
                    DropdownMenuItem(value: 'Committee Member', child: Text(AppStrings.tr('समिती सदस्य (Committee Member)', 'Committee Member'))),
                    DropdownMenuItem(value: 'Volunteer', child: Text(AppStrings.tr('कार्यकर्ता / स्वयंसेवक (Volunteer)', 'Volunteer'))),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedRole = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('पत्ता / गाव', 'Address'),
                    prefixIcon: const Icon(Icons.home),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.tr('रद्द करा', 'Cancel'),
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              final newMember = MemberModel(
                id: OfflineDbHelper.generateId(),
                memberCode: 'MEM-00${repository.members.length + 1}',
                fullName: nameCtrl.text.trim(),
                role: selectedRole,
                mobile: mobileCtrl.text.trim(),
                status: 'Active',
                address: addressCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              try {
                await repository.addMember(newMember);
                if (mounted) {
                  setState(() {});
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.tr(
                        '${newMember.fullName} यांची सदस्य म्हणून यशस्वीरित्या नोंद झाली!',
                        '${newMember.fullName} added to Mandal!',
                      )),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error saving member: $e')),
                  );
                }
              }
            },
            child: Text(
              AppStrings.tr('सदस्य जतन करा', 'Save Member'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 750;
    final filteredMembers = repository.members.where((m) {
      final q = _searchQuery.toLowerCase();
      return m.fullName.toLowerCase().contains(q) ||
          m.mobile.contains(q) ||
          m.role.toLowerCase().contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, color: AppColors.primaryMaroon),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr('मंडळ सभासद', 'Mandal Members'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: AppStrings.tr('सभासद शोधा...', 'Search member...'),
                              prefixIcon: const Icon(Icons.search, size: 18),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.borderLight),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddMemberDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.tr('जोडा', 'Add')),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.people, color: AppColors.primaryMaroon),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.tr('मंडळ सभासद', 'Mandal Members'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 250,
                    height: 40,
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: AppStrings.tr('सभासद शोधा...', 'Search member...'),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddMemberDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.addMember),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exporting members to Excel/CSV...')),
                      );
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Export'),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            // Members Content
            if (filteredMembers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline, size: 54, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text(
                        'कोणतेही सभासद आढळले नाहीत (No members found)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'नवीन सभासद जोडण्यासाठी वरील "+ Add Member" बटनावर क्लिक करा.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else if (isMobile)
              // Mobile View: Responsive Member Cards (No horizontal cutoffs)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredMembers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final m = filteredMembers[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.accentGold.withAlpha(50),
                              child: Text(
                                m.fullName.isNotEmpty ? m.fullName[0] : 'M',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    '${m.memberCode} • ${m.role}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.primaryMaroon, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: m.status),
                          ],
                        ),
                        if (m.address != null && m.address!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  m.address!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: AppColors.borderLight),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  m.mobile,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.infoBlue),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 14),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    await repository.deleteMember(m.id);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              // Desktop View: Classic Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: const [
                    DataColumn(label: Text('Photo', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filteredMembers.map((m) {
                    return DataRow(
                      cells: [
                        DataCell(
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.accentGold.withAlpha(50),
                            child: Text(
                              m.fullName.isNotEmpty ? m.fullName[0] : 'M',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                            ),
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(m.memberCode, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        DataCell(Text(m.role)),
                        DataCell(Text(m.mobile)),
                        DataCell(StatusBadge(status: m.status)),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                                onPressed: () async {
                                  await repository.deleteMember(m.id);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
