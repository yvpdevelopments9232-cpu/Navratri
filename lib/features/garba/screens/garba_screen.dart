import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';

class GarbaScreen extends StatefulWidget {
  const GarbaScreen({super.key});

  @override
  State<GarbaScreen> createState() => _GarbaScreenState();
}

class _GarbaScreenState extends State<GarbaScreen> {
  final repository = MandalRepository();
  String _searchQuery = '';

  void _showPassModal(GarbaParticipantModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryMaroon,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'GARBA NIGHT ENTRY PASS',
                  style: TextStyle(color: AppColors.brightGold, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 180,
              height: 180,
              child: QrImageView(
                data: 'PASS:${p.regNumber}|${p.name}|${p.mobile}',
                version: QrVersions.auto,
                size: 180.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Pass No: ${p.regNumber} • ${p.gender} / ${p.age} yrs', style: const TextStyle(color: AppColors.textSecondary)),
            Text('Fee Paid: ${CurrencyFormatter.format(p.amount)}', style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printing QR Pass...')));
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print Pass'),
          ),
        ],
      ),
    );
  }

  void _showAddRegistrationDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: '22');
    String selectedGender = 'F';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.nightlife, color: AppColors.primaryMaroon),
            SizedBox(width: 8),
            Text('Garba / Dandiya Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Participant Name *')),
                const SizedBox(height: 12),
                TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile Number *'), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedGender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const [
                          DropdownMenuItem(value: 'F', child: Text('Female (F)')),
                          DropdownMenuItem(value: 'M', child: Text('Male (M)')),
                        ],
                        onChanged: (val) {
                          if (val != null) selectedGender = val;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '₹ 200.00 (Standard Entry Fee)',
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Registration Fee'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) return;
              final newP = GarbaParticipantModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                regNumber: 'REG-${100 + repository.participants.length + 1}',
                name: nameCtrl.text.trim(),
                mobile: mobileCtrl.text.trim(),
                age: int.tryParse(ageCtrl.text.trim()) ?? 20,
                gender: selectedGender,
                amount: 200,
                status: 'Active',
              );
              repository.participants.insert(0, newP);
              Navigator.pop(ctx);
              setState(() {});
              _showPassModal(newP);
            },
            child: const Text('Register & Generate Pass'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = repository.participants.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.mobile.contains(q) || p.regNumber.toLowerCase().contains(q);
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
            Row(
              children: [
                const Icon(Icons.nightlife, color: AppColors.primaryMaroon),
                const SizedBox(width: 8),
                const Text(
                  'Garba / Dandiya Participants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Spacer(),
                SizedBox(
                  width: 250,
                  height: 40,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search participant...',
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
                  onPressed: _showAddRegistrationDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Registration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Pass No.', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Age', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Gender', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filtered.map((p) {
                  return DataRow(
                    cells: [
                      DataCell(Text(p.regNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(p.mobile)),
                      DataCell(Text('${p.age}')),
                      DataCell(Text(p.gender)),
                      DataCell(
                        Text(
                          CurrencyFormatter.format(p.amount),
                          style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.qr_code, size: 20, color: AppColors.primaryMaroon),
                              tooltip: 'View QR Pass',
                              onPressed: () => _showPassModal(p),
                            ),
                            IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue), onPressed: () {}),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                              onPressed: () {
                                repository.participants.removeWhere((item) => item.id == p.id);
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
