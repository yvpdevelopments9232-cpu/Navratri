import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';

class AartiScreen extends StatefulWidget {
  const AartiScreen({super.key});

  @override
  State<AartiScreen> createState() => _AartiScreenState();
}

class _AartiScreenState extends State<AartiScreen> {
  final repository = MandalRepository();

  void _showAddAartiDialog() {
    final nameCtrl = TextEditingController(text: 'Morning Aarti');
    final dateCtrl = TextEditingController(text: '23 Sep 2026');
    final timeCtrl = TextEditingController(text: '6:30 AM');
    final leadCtrl = TextEditingController(text: 'Pandit Sharma');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.flare, color: AppColors.brightGold),
            SizedBox(width: 8),
            Text('Schedule Daily Aarti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Aarti Name (e.g. Maha Aarti)')),
              const SizedBox(height: 12),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (DD MMM YYYY)')),
              const SizedBox(height: 12),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Aarti Time (e.g. 7:30 PM)')),
              const SizedBox(height: 12),
              TextField(controller: leadCtrl, decoration: const InputDecoration(labelText: 'Lead Person / Pooja Host')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              repository.aartis.add(
                AartiModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  aartiName: nameCtrl.text.trim(),
                  date: dateCtrl.text.trim(),
                  time: timeCtrl.text.trim(),
                  leadPerson: leadCtrl.text.trim(),
                ),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save Aarti'),
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
                    Icon(Icons.flare, color: AppColors.brightGold),
                    SizedBox(width: 8),
                    Text(
                      'Daily Aarti Schedule & Yajman',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddAartiDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Aarti'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Aarti Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Lead Person / Host', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: repository.aartis.map((a) {
                  return DataRow(
                    cells: [
                      DataCell(Text(a.date, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(
                        Row(
                          children: [
                            const Icon(Icons.wb_twilight, color: AppColors.brightGold, size: 16),
                            const SizedBox(width: 6),
                            Text(a.aartiName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                          ],
                        ),
                      ),
                      DataCell(Text(a.time)),
                      DataCell(Text(a.leadPerson)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue), onPressed: () {}),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                              onPressed: () {
                                repository.aartis.removeWhere((i) => i.id == a.id);
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
