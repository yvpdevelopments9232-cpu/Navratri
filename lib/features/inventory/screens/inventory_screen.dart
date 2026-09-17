import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../widgets/status_badge.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final repository = MandalRepository();

  void _showAddItemDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '10');
    String selectedCat = 'Furniture';
    String selectedUnit = 'Nos';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.inventory_2, color: AppColors.primaryMaroon),
            SizedBox(width: 8),
            Text('Add Inventory Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name * (e.g. Chairs, Speakers)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCat,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'Furniture', child: Text('Furniture')),
                  DropdownMenuItem(value: 'Sound', child: Text('Sound')),
                  DropdownMenuItem(value: 'Lighting', child: Text('Lighting')),
                  DropdownMenuItem(value: 'Electrical', child: Text('Electrical')),
                  DropdownMenuItem(value: 'Decoration', child: Text('Decoration')),
                ],
                onChanged: (val) {
                  if (val != null) selectedCat = val;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity *'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const [
                        DropdownMenuItem(value: 'Nos', child: Text('Nos')),
                        DropdownMenuItem(value: 'Sets', child: Text('Sets')),
                        DropdownMenuItem(value: 'Meters', child: Text('Meters')),
                      ],
                      onChanged: (val) {
                        if (val != null) selectedUnit = val;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              repository.inventory.add(
                InventoryItemModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  itemName: nameCtrl.text.trim(),
                  category: selectedCat,
                  quantity: int.tryParse(qtyCtrl.text.trim()) ?? 1,
                  unit: selectedUnit,
                  status: 'In Stock',
                ),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save Item'),
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
                    Icon(Icons.inventory_2_outlined, color: AppColors.primaryMaroon),
                    SizedBox(width: 8),
                    Text(
                      'Inventory / Material Management',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: repository.inventory.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(item.category)),
                      DataCell(Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(item.unit)),
                      DataCell(StatusBadge(status: item.status)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue), onPressed: () {}),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                              onPressed: () {
                                repository.inventory.removeWhere((i) => i.id == item.id);
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
