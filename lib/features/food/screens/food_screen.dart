import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
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
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: AppColors.primaryMaroon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('अन्नदान / महाप्रसाद मेनू जोडा', 'Add Food / Prasad Menu'),
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
                TextField(controller: dateCtrl, decoration: InputDecoration(labelText: AppStrings.tr('तारीख (DD-MM-YYYY)', 'Date (DD-MM-YYYY)'))),
                const SizedBox(height: 12),
                TextField(controller: menuCtrl, decoration: InputDecoration(labelText: AppStrings.tr('मेनू तपशील (उदा. खिचडी, पुरी भाजी)', 'Menu (e.g. Khichdi, Puri Sabzi)'))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: estCtrl, decoration: InputDecoration(labelText: AppStrings.tr('अपेक्षित भाविक', 'Est. People')), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: actCtrl, decoration: InputDecoration(labelText: AppStrings.tr('प्रत्यक्ष वाटप', 'Actual People')), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: costCtrl, decoration: InputDecoration(labelText: AppStrings.tr('एकूण खर्च (₹)', 'Total Cost (₹)')), keyboardType: TextInputType.number),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('रद्द करा', 'Cancel'))),
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
            child: Text(AppStrings.tr('मेनू जतन करा', 'Save Menu')),
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
                      const Icon(Icons.restaurant_menu, color: AppColors.primaryMaroon, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr('महाप्रसाद व अन्नदान व्यवस्थापन', 'Food & Prasad Management'),
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
                      onPressed: _showAddMenuDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(AppStrings.tr('+ मेनू जोडा', '+ Add Menu')),
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
                        const Icon(Icons.restaurant_menu, color: AppColors.primaryMaroon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.tr('महाप्रसाद व अन्नदान व्यवस्थापन (Daily Bhog & Bhandara)', 'Food / Prasad Management (Daily Bhog & Bhandara)'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddMenuDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.tr('+ मेनू जोडा', '+ Add Menu')),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            if (repository.foodMenu.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text(
                    AppStrings.tr('कोणताही महाप्रसाद मेनू उपलब्ध नाही', 'No food menu added yet'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else if (isMobile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: repository.foodMenu.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final f = repository.foodMenu[idx];
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
                            Text(f.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                repository.foodMenu.removeWhere((i) => i.id == f.id);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(f.menu, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryMaroon)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${AppStrings.tr('अपेक्षित', 'Est')}: ${f.estimatedPeople} | ${AppStrings.tr('प्रत्यक्ष', 'Actual')}: ${f.actualPeople}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                            Text(
                              CurrencyFormatter.format(f.cost),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.expenseRed),
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
                    DataColumn(label: Text(AppStrings.tr('तारीख', 'Date'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('मेनू', 'Menu'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('अपेक्षित', 'Est. People'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('प्रत्यक्ष वाटप', 'Actual Served'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('खर्च', 'Cost'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('क्रिया', 'Action'), style: const TextStyle(fontWeight: FontWeight.bold))),
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
