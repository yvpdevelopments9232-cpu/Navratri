import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../widgets/status_badge.dart';

class SponsorsScreen extends StatefulWidget {
  const SponsorsScreen({super.key});

  @override
  State<SponsorsScreen> createState() => _SponsorsScreenState();
}

class _SponsorsScreenState extends State<SponsorsScreen> {
  final repository = MandalRepository();

  void _showAddSponsorDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedPkg = 'Main Sponsor';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.handshake, color: AppColors.primaryMaroon),
            SizedBox(width: 8),
            Text('Add Festival Sponsor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Sponsor / Company Name *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPkg,
                decoration: const InputDecoration(labelText: 'Sponsorship Package'),
                items: const [
                  DropdownMenuItem(value: 'Main Sponsor', child: Text('Main Sponsor')),
                  DropdownMenuItem(value: 'Gold Sponsor', child: Text('Gold Sponsor')),
                  DropdownMenuItem(value: 'Silver Sponsor', child: Text('Silver Sponsor')),
                  DropdownMenuItem(value: 'Banner Sponsor', child: Text('Banner Sponsor')),
                  DropdownMenuItem(value: 'Event Sponsor', child: Text('Event Sponsor')),
                ],
                onChanged: (val) {
                  if (val != null) selectedPkg = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (₹) *'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (nameCtrl.text.trim().isEmpty || amt <= 0) return;
              repository.sponsors.add(
                SponsorModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  sponsorName: nameCtrl.text.trim(),
                  package: selectedPkg,
                  amount: amt,
                  paidAmount: amt,
                  status: 'Paid',
                ),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save Sponsor'),
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
                    Icon(Icons.handshake_outlined, color: AppColors.primaryMaroon),
                    SizedBox(width: 8),
                    Text(
                      'Sponsorship & Advertisements',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddSponsorDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Sponsor'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Sponsor Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Package', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: repository.sponsors.map((s) {
                  return DataRow(
                    cells: [
                      DataCell(Text(s.sponsorName, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brightGold.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(s.package, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      DataCell(
                        Text(
                          CurrencyFormatter.format(s.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen),
                        ),
                      ),
                      DataCell(StatusBadge(status: s.status)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue), onPressed: () {}),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                              onPressed: () {
                                repository.sponsors.removeWhere((i) => i.id == s.id);
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
