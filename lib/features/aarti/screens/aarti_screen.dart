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
            Text('आरती वेळ व यजमान जोडा', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'आरतीचे नाव (उदा. महाआरती, सकाळची आरती)')),
              const SizedBox(height: 12),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'दिनांक (उदा. 23 Sep 2026)')),
              const SizedBox(height: 12),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'वेळ (उदा. 7:30 PM)')),
              const SizedBox(height: 12),
              TextField(controller: leadCtrl, decoration: const InputDecoration(labelText: 'आरती यजमान / प्रमुख व्यक्ती')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करा')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await repository.addAarti(
                AartiModel(
                  id: '',
                  aartiName: nameCtrl.text.trim(),
                  date: dateCtrl.text.trim(),
                  time: timeCtrl.text.trim(),
                  leadPerson: leadCtrl.text.trim(),
                ),
              );
              if (mounted) setState(() {});
            },
            child: const Text('जतन करा'),
          ),
        ],
      ),
    );
  }

  void _showEditAartiDialog(AartiModel aarti) {
    final nameCtrl = TextEditingController(text: aarti.aartiName);
    final dateCtrl = TextEditingController(text: aarti.date);
    final timeCtrl = TextEditingController(text: aarti.time);
    final leadCtrl = TextEditingController(text: aarti.leadPerson);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.infoBlue),
            SizedBox(width: 8),
            Text('आरती तपशील बदला', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'आरतीचे नाव')),
              const SizedBox(height: 12),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'दिनांक')),
              const SizedBox(height: 12),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'वेळ')),
              const SizedBox(height: 12),
              TextField(controller: leadCtrl, decoration: const InputDecoration(labelText: 'आरती यजमान / प्रमुख व्यक्ती')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करा')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.infoBlue, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final updated = aarti.copyWith(
                aartiName: nameCtrl.text.trim(),
                date: dateCtrl.text.trim(),
                time: timeCtrl.text.trim(),
                leadPerson: leadCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              await repository.updateAarti(updated);
              if (mounted) setState(() {});
            },
            child: const Text('बदल सेव्ह करा'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAarti(AartiModel aarti) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('आरती नोंद काढून टाकायची आहे का?'),
        content: Text('आपण खात्रीपूर्वक "${aarti.aartiName}" यांची नोंद काढून टाकू इच्छिता का?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('नाही / रद्द करा')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await repository.deleteAarti(aarti.id);
              if (mounted) setState(() {});
            },
            child: const Text('काढून टाका'),
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
                    const Icon(Icons.flare, color: AppColors.brightGold),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Aarti Schedule & Yajman',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.infoBlue),
                              onPressed: () => _showEditAartiDialog(a),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                              onPressed: () => _confirmDeleteAarti(a),
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
