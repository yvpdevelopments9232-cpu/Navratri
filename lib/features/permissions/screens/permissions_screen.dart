import 'package:flutter/material.dart';
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
        title: const Row(
          children: [
            Icon(Icons.description, color: AppColors.primaryMaroon),
            SizedBox(width: 8),
            Text('Add Statutory Permission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Document Name * (e.g. Police Permission)')),
              const SizedBox(height: 12),
              TextField(controller: issueCtrl, decoration: const InputDecoration(labelText: 'Issue Date (DD-MM-YYYY)')),
              const SizedBox(height: 12),
              TextField(controller: expiryCtrl, decoration: const InputDecoration(labelText: 'Expiry Date (DD-MM-YYYY)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
            child: const Text('Save Document'),
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
                    Icon(Icons.verified_user_outlined, color: AppColors.primaryMaroon),
                    SizedBox(width: 8),
                    Text(
                      'Statutory Permissions & Approvals',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddDocDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Document'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Document Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Issue Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
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
