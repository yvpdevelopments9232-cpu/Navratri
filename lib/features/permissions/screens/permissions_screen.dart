import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../widgets/status_badge.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final repository = MandalRepository();

  void _showAddDocDialog() {
    final nameCtrl = TextEditingController();
    final issueCtrl = TextEditingController(text: '01-09-2026');
    final expiryCtrl = TextEditingController(text: '30-09-2026');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.description, color: AppColors.primaryMaroon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('शासकीय परवानगी जोडा', 'Add Statutory Permission'),
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
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.tr('परवानगी / दस्तऐवजाचे नाव * (उदा. पोलीस परवानगी, अग्निशामक)', 'Document Name * (e.g. Police Permission)'))),
                const SizedBox(height: 12),
                TextField(controller: issueCtrl, decoration: InputDecoration(labelText: AppStrings.tr('मंजुरी तारीख (DD-MM-YYYY)', 'Issue Date (DD-MM-YYYY)'))),
                const SizedBox(height: 12),
                TextField(controller: expiryCtrl, decoration: InputDecoration(labelText: AppStrings.tr('मुदत समाप्ती तारीख (DD-MM-YYYY)', 'Expiry Date (DD-MM-YYYY)'))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('रद्द करा', 'Cancel'))),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              repository.documents.add(
                DocumentModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  documentName: nameCtrl.text.trim(),
                  issueDate: issueCtrl.text.trim(),
                  expiryDate: expiryCtrl.text.trim(),
                  status: 'Valid',
                ),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(AppStrings.tr('जतन करा', 'Save Document')),
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
                      const Icon(Icons.verified_user_outlined, color: AppColors.primaryMaroon, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr('शासकीय परवानग्या व ना-हरकत प्रमाणपत्रे', 'Permissions & Approvals'),
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
                      onPressed: _showAddDocDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(AppStrings.tr('+ परवानगी जोडा', '+ Add Document')),
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
                        const Icon(Icons.verified_user_outlined, color: AppColors.primaryMaroon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.tr('शासकीय परवानग्या व ना-हरकत प्रमाणपत्रे (Statutory Permissions)', 'Statutory Permissions & Approvals'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddDocDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.tr('+ परवानगी जोडा', '+ Add Document')),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            if (repository.documents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text(
                    AppStrings.tr('कोणतेही दस्तऐवज उपलब्ध नाही', 'No documents added yet'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else if (isMobile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: repository.documents.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final d = repository.documents[idx];
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
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf, color: AppColors.expenseRed, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      d.documentName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: d.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${AppStrings.tr('जारी', 'Issued')}: ${d.issueDate} • ${AppStrings.tr('मुदत', 'Expiry')}: ${d.expiryDate}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download, size: 18, color: AppColors.infoBlue),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Download',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Viewing ${d.documentName}...')));
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    repository.documents.removeWhere((i) => i.id == d.id);
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: [
                    DataColumn(label: Text(AppStrings.tr('दस्तऐवज नाव', 'Document Name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('जारी तारीख', 'Issue Date'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('मुदत तारीख', 'Expiry Date'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('स्थिती', 'Status'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('क्रिया', 'Action'), style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: repository.documents.map((d) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, color: AppColors.expenseRed, size: 18),
                              const SizedBox(width: 8),
                              Text(d.documentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataCell(Text(d.issueDate)),
                        DataCell(Text(d.expiryDate)),
                        DataCell(StatusBadge(status: d.status)),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.download, size: 18, color: AppColors.infoBlue),
                                tooltip: 'Download / View Permission File',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Viewing ${d.documentName}...')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                                onPressed: () {
                                  repository.documents.removeWhere((i) => i.id == d.id);
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
