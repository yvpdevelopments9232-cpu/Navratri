import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../widgets/status_badge.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  final repository = MandalRepository();
  String _searchQuery = '';

  void _showAddVendorDialog() {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final serviceCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storefront, color: AppColors.primaryMaroon),
            SizedBox(width: 8),
            Text('Add Vendor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Vendor Name *')),
              const SizedBox(height: 12),
              TextField(controller: serviceCtrl, decoration: const InputDecoration(labelText: 'Service Type (e.g. Sound, Lighting) *')),
              const SizedBox(height: 12),
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Mobile *'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Contract Amount (₹) *'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (nameCtrl.text.trim().isEmpty || amt <= 0) return;
              repository.vendors.add(
                VendorModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  vendorCode: 'V-00${repository.vendors.length + 1}',
                  vendorName: nameCtrl.text.trim(),
                  serviceType: serviceCtrl.text.trim(),
                  contact: contactCtrl.text.trim(),
                  contractAmount: amt,
                  paidAmount: 0,
                  remainingAmount: amt,
                  status: 'Pending',
                ),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save Vendor'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = repository.vendors.where((v) {
      final q = _searchQuery.toLowerCase();
      return v.vendorName.toLowerCase().contains(q) || v.serviceType.toLowerCase().contains(q) || v.contact.contains(q);
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
                const Icon(Icons.storefront, color: AppColors.primaryMaroon),
                const SizedBox(width: 8),
                const Text(
                  'Vendor Management & Contracts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Spacer(),
                SizedBox(
                  width: 250,
                  height: 40,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search vendor...',
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
                  onPressed: _showAddVendorDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Vendor'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Vendor Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Service Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Paid', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Remaining', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filtered.map((v) {
                  return DataRow(
                    cells: [
                      DataCell(Text(v.vendorName, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(v.serviceType)),
                      DataCell(Text(v.contact)),
                      DataCell(Text(CurrencyFormatter.format(v.contractAmount), style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(CurrencyFormatter.format(v.paidAmount), style: const TextStyle(color: AppColors.successGreen))),
                      DataCell(Text(CurrencyFormatter.format(v.remainingAmount), style: const TextStyle(color: AppColors.expenseRed))),
                      DataCell(StatusBadge(status: v.status)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue), onPressed: () {}),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                              onPressed: () {
                                repository.vendors.removeWhere((i) => i.id == v.id);
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
