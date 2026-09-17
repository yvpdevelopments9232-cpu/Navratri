import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
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
        title: const Row(
          children: [
            Icon(Icons.person_add, color: AppColors.primaryMaroon),
            SizedBox(width: 8),
            Text('Add Mandal Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobileCtrl,
                  decoration: const InputDecoration(labelText: 'Mobile Number *', prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Mandal Role', prefixIcon: Icon(Icons.badge)),
                  items: const [
                    DropdownMenuItem(value: 'President', child: Text('President')),
                    DropdownMenuItem(value: 'Vice President', child: Text('Vice President')),
                    DropdownMenuItem(value: 'Secretary', child: Text('Secretary')),
                    DropdownMenuItem(value: 'Treasurer', child: Text('Treasurer')),
                    DropdownMenuItem(value: 'Committee Member', child: Text('Committee Member')),
                    DropdownMenuItem(value: 'Volunteer', child: Text('Volunteer')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedRole = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);
              final newMember = MemberModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                memberCode: 'MEM-00${repository.members.length + 1}',
                fullName: nameCtrl.text.trim(),
                role: selectedRole,
                mobile: mobileCtrl.text.trim(),
                status: 'Active',
                address: addressCtrl.text.trim(),
              );
              await repository.addMember(newMember);
              if (mounted) {
                nav.pop();
                setState(() {});
                messenger.showSnackBar(
                  SnackBar(content: Text('${newMember.fullName} added to Mandal!')),
                );
              }
            },
            child: const Text('Save Member'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = repository.members.where((m) {
      final q = _searchQuery.toLowerCase();
      return m.fullName.toLowerCase().contains(q) ||
          m.mobile.contains(q) ||
          m.role.toLowerCase().contains(q);
    }).toList();

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
            // Header Bar matching Screen 2
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

            // Members Table or Empty State
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
            else
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
