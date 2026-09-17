import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../widgets/status_badge.dart';

class VolunteersScreen extends StatefulWidget {
  const VolunteersScreen({super.key});

  @override
  State<VolunteersScreen> createState() => _VolunteersScreenState();
}

class _VolunteersScreenState extends State<VolunteersScreen> {
  final repository = MandalRepository();

  void _showAddVolunteerDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    String selectedDept = 'Security';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.groups, color: AppColors.primaryMaroon),
            SizedBox(width: 8),
            Text('Add Volunteer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Volunteer Name *')),
              const SizedBox(height: 12),
              TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile Number *'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedDept,
                decoration: const InputDecoration(labelText: 'Assigned Department'),
                items: const [
                  DropdownMenuItem(value: 'Security', child: Text('Security')),
                  DropdownMenuItem(value: 'Medical', child: Text('Medical')),
                  DropdownMenuItem(value: 'Decoration', child: Text('Decoration')),
                  DropdownMenuItem(value: 'Food', child: Text('Food')),
                  DropdownMenuItem(value: 'Parking', child: Text('Parking')),
                  DropdownMenuItem(value: 'Crowd Management', child: Text('Crowd Management')),
                ],
                onChanged: (val) {
                  if (val != null) selectedDept = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) return;
              repository.volunteers.add(
                VolunteerModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  code: 'VOL-0${repository.volunteers.length + 1}',
                  name: nameCtrl.text.trim(),
                  mobile: mobileCtrl.text.trim(),
                  department: selectedDept,
                  status: 'Active',
                ),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save Volunteer'),
          ),
        ],
      ),
    );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.groups, color: AppColors.primaryMaroon),
                    SizedBox(width: 8),
                    Text(
                      'Volunteer Management & Duties',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddVolunteerDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Volunteer'),
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
                  DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: repository.volunteers.map((v) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.cyanAccent.withAlpha(40),
                              child: Text(
                                v.name[0],
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.infoBlue, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      DataCell(Text(v.mobile)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(v.department, style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                      DataCell(StatusBadge(status: v.status)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue), onPressed: () {}),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                              onPressed: () {
                                repository.volunteers.removeWhere((i) => i.id == v.id);
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
