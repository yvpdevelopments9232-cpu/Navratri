import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../services/offline_db_helper.dart';
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
        title: Row(
          children: [
            const Icon(Icons.groups, color: AppColors.primaryMaroon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('स्वयंसेवक जोडा', 'Add Volunteer'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.tr('स्वयंसेवकाचे पूर्ण नाव *', 'Volunteer Name *'))),
                const SizedBox(height: 12),
                TextField(controller: mobileCtrl, decoration: InputDecoration(labelText: AppStrings.tr('मोबाईल क्रमांक *', 'Mobile Number *')), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDept,
                  decoration: InputDecoration(labelText: AppStrings.tr('नेमून दिलेला विभाग / जबाबदारी', 'Assigned Department')),
                  items: const [
                    DropdownMenuItem(value: 'Security', child: Text('Security (सुरक्षा व गर्दी नियंत्रण)')),
                    DropdownMenuItem(value: 'Medical', child: Text('Medical (वैद्यकीय मदत)')),
                    DropdownMenuItem(value: 'Decoration', child: Text('Decoration (सजावट व्यवस्था)')),
                    DropdownMenuItem(value: 'Food', child: Text('Food (महाप्रसाद वाटप)')),
                    DropdownMenuItem(value: 'Parking', child: Text('Parking (वाहनतळ व्यवस्था)')),
                    DropdownMenuItem(value: 'Crowd Management', child: Text('Crowd Management (रांग व्यवस्थापन)')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedDept = val;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('रद्द करा', 'Cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) return;
              final newVol = VolunteerModel(
                id: OfflineDbHelper.generateId(),
                code: 'VOL-${(DateTime.now().millisecondsSinceEpoch % 900000 + 100000)}',
                name: nameCtrl.text.trim(),
                mobile: mobileCtrl.text.trim(),
                department: selectedDept,
                status: 'Active',
              );
              Navigator.pop(ctx);
              await repository.addVolunteer(newVol);
              setState(() {});
            },
            child: Text(AppStrings.tr('जतन करा', 'Save Volunteer')),
          ),
        ],
      ),
    );
  }

  void _showEditVolunteerDialog(VolunteerModel volunteer) {
    final nameCtrl = TextEditingController(text: volunteer.name);
    final mobileCtrl = TextEditingController(text: volunteer.mobile);
    String selectedDept = volunteer.department;
    String selectedStatus = volunteer.status;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: AppColors.infoBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('स्वयंसेवक माहिती बदला', 'Edit Volunteer'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.tr('पूर्ण नाव *', 'Full Name *'))),
                const SizedBox(height: 12),
                TextField(controller: mobileCtrl, decoration: InputDecoration(labelText: AppStrings.tr('मोबाईल नंबर *', 'Mobile Number *')), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDept,
                  decoration: InputDecoration(labelText: AppStrings.tr('नेमून दिलेला विभाग / जबाबदारी', 'Assigned Department')),
                  items: const [
                    DropdownMenuItem(value: 'Security', child: Text('Security (सुरक्षा व गर्दी नियंत्रण)')),
                    DropdownMenuItem(value: 'Medical', child: Text('Medical (वैद्यकीय मदत)')),
                    DropdownMenuItem(value: 'Decoration', child: Text('Decoration (सजावट व्यवस्था)')),
                    DropdownMenuItem(value: 'Food', child: Text('Food (महाप्रसाद वाटप)')),
                    DropdownMenuItem(value: 'Parking', child: Text('Parking (वाहनतळ व्यवस्था)')),
                    DropdownMenuItem(value: 'Crowd Management', child: Text('Crowd Management (रांग व्यवस्थापन)')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedDept = val;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: InputDecoration(labelText: AppStrings.tr('स्थिती', 'Status')),
                  items: ['Active', 'On Duty', 'Inactive']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedStatus = val;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('रद्द करा', 'Cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.infoBlue, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) return;
              final updated = volunteer.copyWith(
                name: nameCtrl.text.trim(),
                mobile: mobileCtrl.text.trim(),
                department: selectedDept,
                status: selectedStatus,
              );
              Navigator.pop(ctx);
              await repository.updateVolunteer(updated);
              setState(() {});
            },
            child: Text(AppStrings.tr('बदल सेव्ह करा', 'Save Changes')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVolunteer(VolunteerModel volunteer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr('स्वयंसेवक काढून टाकायचा आहे का?', 'Delete Volunteer?')),
        content: Text(AppStrings.tr(
          'आपण खात्रीपूर्वक "${volunteer.name}" यांना यादीतून काढू इच्छिता का?',
          'Are you sure you want to delete "${volunteer.name}"?',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('नाही / रद्द करा', 'Cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await repository.deleteVolunteer(volunteer.id);
              if (mounted) setState(() {});
            },
            child: Text(AppStrings.tr('काढून टाका', 'Delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.groups, color: AppColors.primaryMaroon, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr('स्वयंसेवक व सेवा दल', 'Volunteer Management'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAddVolunteerDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(AppStrings.tr('+ स्वयंसेवक जोडा', '+ Add Volunteer')),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.groups, color: AppColors.primaryMaroon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.tr('स्वयंसेवक व सेवा दल व्यवस्थापन (Volunteers & Duties)', 'Volunteer Management & Duties'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddVolunteerDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.tr('+ स्वयंसेवक जोडा', '+ Add Volunteer')),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            if (repository.volunteers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text(
                    AppStrings.tr('कोणताही स्वयंसेवक नोंदवलेला नाही', 'No volunteers registered yet'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else if (isMobile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: repository.volunteers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final v = repository.volunteers[idx];
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.cyanAccent.withAlpha(40),
                                  child: Text(
                                    v.name.isNotEmpty ? v.name[0] : 'V',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.infoBlue, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                              ],
                            ),
                            StatusBadge(status: v.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryMaroon.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(v.department, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryMaroon)),
                            ),
                            Row(
                              children: [
                                Text('📞 ${v.mobile}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.infoBlue),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showEditVolunteerDialog(v),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _confirmDeleteVolunteer(v),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: [
                    DataColumn(label: Text(AppStrings.tr('नाव', 'Name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('मोबाईल', 'Mobile'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('विभाग', 'Department'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('स्थिती', 'Status'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('क्रिया', 'Action'), style: const TextStyle(fontWeight: FontWeight.bold))),
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
                                  v.name.isNotEmpty ? v.name[0] : 'V',
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
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.infoBlue),
                                onPressed: () => _showEditVolunteerDialog(v),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                                onPressed: () => _confirmDeleteVolunteer(v),
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
