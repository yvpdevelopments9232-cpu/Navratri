import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final repository = MandalRepository();

  void _showAddMenuDialog() {
    final dateCtrl = TextEditingController(text: '22 Sep 2026');
    final menuCtrl = TextEditingController(text: 'Mahaprasad & Kheer');
    final estCtrl = TextEditingController(text: '600');
    final actCtrl = TextEditingController(text: '580');
    final costCtrl = TextEditingController(text: '12000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu, color: AppColors.primaryMaroon),
            SizedBox(width: 8),
            Text('Add Food / Prasad Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (DD-MM-YYYY)')),
              const SizedBox(height: 12),
              TextField(controller: menuCtrl, decoration: const InputDecoration(labelText: 'Menu (e.g. Khichdi, Puri Sabzi)')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: estCtrl, decoration: const InputDecoration(labelText: 'Estimated People'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: actCtrl, decoration: const InputDecoration(labelText: 'Actual People'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Total Cost (₹)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              repository.foodMenu.add(
                FoodPrasadModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: dateCtrl.text.trim(),
                  menu: menuCtrl.text.trim(),
                  estimatedPeople: int.tryParse(estCtrl.text.trim()) ?? 500,
                  actualPeople: int.tryParse(actCtrl.text.trim()) ?? 500,
                  cost: double.tryParse(costCtrl.text.trim()) ?? 0,
                ),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save Menu'),
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
                    Icon(Icons.restaurant_menu, color: AppColors.primaryMaroon),
                    SizedBox(width: 8),
                    Text(
                      'Food / Prasad Management (Daily Bhog & Bhandara)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddMenuDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Menu'),
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
                  DataColumn(label: Text('Menu', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Est. People', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actual Served', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: repository.foodMenu.map((f) {
                  return DataRow(
                    cells: [
                      DataCell(Text(f.date, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(f.menu, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon))),
                      DataCell(Text('${f.estimatedPeople}')),
                      DataCell(Text('${f.actualPeople}')),
                      DataCell(
                        Text(
                          CurrencyFormatter.format(f.cost),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expenseRed),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue), onPressed: () {}),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                              onPressed: () {
                                repository.foodMenu.removeWhere((i) => i.id == f.id);
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
