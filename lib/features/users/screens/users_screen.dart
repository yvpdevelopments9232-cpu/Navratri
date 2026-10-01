import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../widgets/status_badge.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final repository = MandalRepository();

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    String selectedRole = 'Volunteer';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppColors.primaryMaroon),
            SizedBox(width: 8),
            Text('Add App User & Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
              const SizedBox(height: 12),
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username / Email *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Assigned Role'),
                items: const [
                  DropdownMenuItem(value: 'Admin', child: Text('Admin (Full Access)')),
                  DropdownMenuItem(value: 'President', child: Text('President')),
                  DropdownMenuItem(value: 'Secretary', child: Text('Secretary')),
                  DropdownMenuItem(value: 'Treasurer', child: Text('Treasurer (Financials)')),
                  DropdownMenuItem(value: 'Volunteer', child: Text('Volunteer (Read-only / Ground)')),
                ],
                onChanged: (val) {
                  if (val != null) selectedRole = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || userCtrl.text.trim().isEmpty) return;
              repository.users.add(
                UserModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  role: selectedRole,
                  username: userCtrl.text.trim(),
                  status: 'Active',
                ),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save User'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 750;

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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings, color: AppColors.primaryMaroon),
                    const SizedBox(width: 8),
                    Text(
                      'User & Permission Management',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add User'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Username / Email', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: repository.users.map((u) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryMaroon.withAlpha(30),
                              child: Text(u.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brightGold.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(u.role, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                        ),
                      ),
                      DataCell(Text(u.username)),
                      DataCell(StatusBadge(status: u.status)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue), onPressed: () {}),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                              onPressed: () {
                                repository.users.removeWhere((i) => i.id == u.id);
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
