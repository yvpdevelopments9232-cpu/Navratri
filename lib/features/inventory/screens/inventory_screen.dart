import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
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
        title: Row(
          children: [
            const Icon(Icons.inventory_2, color: AppColors.primaryMaroon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('साहित्य नोंदवा', 'Add Inventory Item'),
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
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.tr('साहित्याचे नाव * (उदा. खुर्च्या, मंडप, स्पीकर)', 'Item Name * (e.g. Chairs, Speakers)'))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCat,
                  decoration: InputDecoration(labelText: AppStrings.tr('प्रवर्ग', 'Category')),
                  items: const [
                    DropdownMenuItem(value: 'Furniture', child: Text('Furniture (फर्निचर/मंडप)')),
                    DropdownMenuItem(value: 'Sound', child: Text('Sound (ध्वनी यंत्रणा)')),
                    DropdownMenuItem(value: 'Lighting', child: Text('Lighting (लाईटिंग/रोषणाई)')),
                    DropdownMenuItem(value: 'Electrical', child: Text('Electrical (इलेक्ट्रिकल)')),
                    DropdownMenuItem(value: 'Decoration', child: Text('Decoration (सजावट)')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedCat = val;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: qtyCtrl, decoration: InputDecoration(labelText: AppStrings.tr('संख्या *', 'Quantity *')), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedUnit,
                        decoration: InputDecoration(labelText: AppStrings.tr('एकक', 'Unit')),
                        items: const [
                          DropdownMenuItem(value: 'Nos', child: Text('Nos (नग)')),
                          DropdownMenuItem(value: 'Sets', child: Text('Sets (संच)')),
                          DropdownMenuItem(value: 'Meters', child: Text('Meters (मीटर)')),
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
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('रद्द करा', 'Cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
              Navigator.pop(ctx);
              await repository.addInventoryItem(
                InventoryItemModel(
                  id: '',
                  itemName: nameCtrl.text.trim(),
                  category: selectedCat,
                  quantity: qty,
                  unit: selectedUnit,
                  status: 'In Stock',
                ),
              );
              if (mounted) setState(() {});
            },
            child: Text(AppStrings.tr('जतन करा', 'Save Item')),
          ),
        ],
      ),
    );
  }

  void _showEditInventoryDialog(InventoryItemModel item) {
    final nameCtrl = TextEditingController(text: item.itemName);
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    String selectedCat = item.category;
    String selectedUnit = item.unit;
    String selectedStatus = item.status;

    final categories = ['Furniture', 'Sound', 'Lighting', 'Electrical', 'Decoration'];
    if (!categories.contains(selectedCat)) selectedCat = 'Furniture';

    final units = ['Nos', 'Sets', 'Meters'];
    if (!units.contains(selectedUnit)) selectedUnit = 'Nos';

    final statuses = ['In Stock', 'In Use', 'Damaged', 'Returned'];
    if (!statuses.contains(selectedStatus)) selectedStatus = 'In Stock';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: AppColors.infoBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.tr('साहित्य माहिती बदला', 'Edit Inventory Item'),
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
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.tr('साहित्याचे नाव *', 'Item Name *'))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    decoration: InputDecoration(labelText: AppStrings.tr('प्रवर्ग', 'Category')),
                    items: const [
                      DropdownMenuItem(value: 'Furniture', child: Text('Furniture (फर्निचर/मंडप)')),
                      DropdownMenuItem(value: 'Sound', child: Text('Sound (ध्वनी यंत्रणा)')),
                      DropdownMenuItem(value: 'Lighting', child: Text('Lighting (लाईटिंग/रोषणाई)')),
                      DropdownMenuItem(value: 'Electrical', child: Text('Electrical (इलेक्ट्रिकल)')),
                      DropdownMenuItem(value: 'Decoration', child: Text('Decoration (सजावट)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedCat = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: qtyCtrl, decoration: InputDecoration(labelText: AppStrings.tr('संख्या *', 'Quantity *')), keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedUnit,
                          decoration: InputDecoration(labelText: AppStrings.tr('एकक', 'Unit')),
                          items: const [
                            DropdownMenuItem(value: 'Nos', child: Text('Nos (नग)')),
                            DropdownMenuItem(value: 'Sets', child: Text('Sets (संच)')),
                            DropdownMenuItem(value: 'Meters', child: Text('Meters (मीटर)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDlgState(() => selectedUnit = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(labelText: AppStrings.tr('स्थिती', 'Status')),
                    items: [
                      DropdownMenuItem(value: 'In Stock', child: Text(AppStrings.tr('उपलब्ध (In Stock)', 'In Stock'))),
                      DropdownMenuItem(value: 'In Use', child: Text(AppStrings.tr('वापरात (In Use)', 'In Use'))),
                      DropdownMenuItem(value: 'Damaged', child: Text(AppStrings.tr('खराब / नादुरुस्त', 'Damaged'))),
                      DropdownMenuItem(value: 'Returned', child: Text(AppStrings.tr('परत केले (Returned)', 'Returned'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedStatus = val);
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
                if (nameCtrl.text.trim().isEmpty) return;
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? item.quantity;
                final updated = item.copyWith(
                  itemName: nameCtrl.text.trim(),
                  category: selectedCat,
                  quantity: qty,
                  unit: selectedUnit,
                  status: selectedStatus,
                );
                Navigator.pop(ctx);
                await repository.updateInventoryItem(updated);
                if (mounted) setState(() {});
              },
              child: Text(AppStrings.tr('बदल सेव्ह करा', 'Save Changes')),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteInventory(InventoryItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr('साहित्य काढून टाकायचे आहे का?', 'Delete Inventory Item?')),
        content: Text(AppStrings.tr(
          'आपण खात्रीपूर्वक "${item.itemName}" साहित्याची नोंद काढून टाकू इच्छिता का?',
          'Are you sure you want to delete "${item.itemName}"?',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('नाही / रद्द करा', 'Cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await repository.deleteInventoryItem(item.id);
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
                      const Icon(Icons.inventory_2_outlined, color: AppColors.primaryMaroon, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr('साहित्य व स्टॉक व्यवस्थापन', 'Inventory Management'),
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
                      onPressed: _showAddItemDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(AppStrings.tr('+ साहित्य जोडा', '+ Add Item')),
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
                        const Icon(Icons.inventory_2_outlined, color: AppColors.primaryMaroon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.tr('साहित्य व स्टॉक व्यवस्थापन (Inventory & Material)', 'Inventory / Material Management'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddItemDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.tr('+ साहित्य जोडा', '+ Add Item')),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            if (repository.inventory.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text(
                    AppStrings.tr('कोणतेही साहित्य नोंदवलेले नाही', 'No inventory items yet'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else if (isMobile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: repository.inventory.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final item = repository.inventory[idx];
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
                              child: Text(
                                item.itemName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadge(status: item.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${AppStrings.tr('प्रवर्ग', 'Cat')}: ${item.category}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Row(
                              children: [
                                Text('${item.quantity} ${item.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryMaroon)),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.infoBlue),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showEditInventoryDialog(item),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _confirmDeleteInventory(item),
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
                    DataColumn(label: Text(AppStrings.tr('साहित्याचे नाव', 'Item Name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('प्रवर्ग', 'Category'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('प्रमाण / संख्या', 'Quantity'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('एकक', 'Unit'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('स्थिती', 'Status'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('क्रिया', 'Action'), style: const TextStyle(fontWeight: FontWeight.bold))),
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
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.infoBlue),
                                onPressed: () => _showEditInventoryDialog(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                                onPressed: () => _confirmDeleteInventory(item),
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
