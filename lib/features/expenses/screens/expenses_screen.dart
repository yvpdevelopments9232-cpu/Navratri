import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../widgets/status_badge.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final repository = MandalRepository();
  String _searchQuery = '';

  void _showAddExpenseDialog() {
    final now = DateTime.now();
    final todayStr = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    final mandalCode = repository.mandalProfile.id.length >= 4
        ? repository.mandalProfile.id.substring(0, 4).toUpperCase()
        : '0000';
    final nextExpenseNo = 'E-$mandalCode-${(repository.expenses.length + 1).toString().padLeft(4, '0')}';
    final dateCtrl = TextEditingController(text: todayStr);
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedCategory = 'Decoration';
    final vendorList = <String>{
      'Direct / Other',
      ...repository.vendors.map((v) => v.vendorName).where((n) => n.trim().isNotEmpty),
    }.toList();
    String selectedVendor = vendorList.first;

    String selectedPaymentMode = 'Cash';
    final paidByList = <String>{
      if (repository.mandalProfile.authorizedSignatoryName.isNotEmpty)
        repository.mandalProfile.authorizedSignatoryName,
      'President',
      'Secretary',
      'Treasurer',
      ...repository.members.map((m) => m.fullName).where((n) => n.trim().isNotEmpty),
    }.toList();
    String selectedPaidBy = repository.mandalProfile.authorizedSignatoryName.isNotEmpty
        ? repository.mandalProfile.authorizedSignatoryName
        : paidByList.first;
    if (!paidByList.contains(selectedPaidBy)) {
      selectedPaidBy = paidByList.first;
    }
    String billFileName = 'bill.pdf';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.expenseRed.withAlpha(30), shape: BoxShape.circle),
                child: const Icon(Icons.shopping_bag_outlined, color: AppColors.expenseRed, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.tr('नवीन खर्च नोंदवा', 'Add Expense'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: nextExpenseNo,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Expense No.', prefixIcon: Icon(Icons.tag)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: dateCtrl,
                          decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: const [
                            DropdownMenuItem(value: 'Decoration', child: Text('Decoration')),
                            DropdownMenuItem(value: 'Sound', child: Text('Sound')),
                            DropdownMenuItem(value: 'Lighting', child: Text('Lighting')),
                            DropdownMenuItem(value: 'Stage', child: Text('Stage')),
                            DropdownMenuItem(value: 'Idol', child: Text('Idol')),
                            DropdownMenuItem(value: 'Prasad', child: Text('Prasad')),
                            DropdownMenuItem(value: 'Food', child: Text('Food')),
                            DropdownMenuItem(value: 'Advertisement', child: Text('Advertisement')),
                            DropdownMenuItem(value: 'Security', child: Text('Security')),
                            DropdownMenuItem(value: 'Miscellaneous', child: Text('Miscellaneous')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCategory = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedVendor,
                          decoration: const InputDecoration(labelText: 'Vendor'),
                          items: vendorList
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedVendor = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description *', hintText: 'Stage Decoration'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedPaymentMode,
                          decoration: const InputDecoration(labelText: 'Payment Mode'),
                          items: const [
                            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                            DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                            DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedPaymentMode = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedPaidBy,
                          decoration: const InputDecoration(labelText: 'Paid By'),
                          items: paidByList
                              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedPaidBy = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setModalState(() => billFileName = 'uploaded_bill.pdf');
                          },
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: Text(billFileName, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                if (descCtrl.text.trim().isEmpty || amt <= 0) return;

                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);

                final newExpense = ExpenseModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  expenseNumber: nextExpenseNo,
                  date: dateCtrl.text.trim(),
                  categoryName: selectedCategory,
                  vendorName: selectedVendor,
                  description: descCtrl.text.trim(),
                  amount: amt,
                  paymentMode: selectedPaymentMode,
                  paidBy: selectedPaidBy,
                  billUrl: billFileName,
                  notes: notesCtrl.text.trim(),
                  status: 'Paid',
                );

                await repository.addExpense(newExpense);
                if (mounted) {
                  nav.pop();
                  setState(() {});
                  messenger.showSnackBar(
                    SnackBar(content: Text('Expense ${newExpense.expenseNumber} added successfully!')),
                  );
                }
              },
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final filteredExpenses = repository.expenses.where((e) {
      final q = _searchQuery.toLowerCase();
      return e.description.toLowerCase().contains(q) ||
          e.categoryName.toLowerCase().contains(q) ||
          (e.vendorName?.toLowerCase().contains(q) ?? false) ||
          e.expenseNumber.toLowerCase().contains(q);
    }).toList();

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
                      const Icon(Icons.receipt_long, color: AppColors.expenseRed, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr('खर्च व्यवस्थापन', 'Expense Management'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: AppStrings.tr('खर्च / विक्रेता शोधा...', 'Search...'),
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
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddExpenseDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.tr('+ खर्च', '+ Add')),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.expenseRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.tr('खर्च व्यवस्थापन (Expense Management)', 'Expense Management'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 220,
                    height: 40,
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: AppStrings.tr('खर्च तपशील / विक्रेता शोधा...', 'Search expense / vendor...'),
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
                    onPressed: _showAddExpenseDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.addExpense),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            if (filteredExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 54, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.tr('कोणतीही खर्चाची नोंद उपलब्ध नाही', 'No expense records found'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.tr('नवीन खर्चाची नोंद करण्यासाठी वरील बटणावर क्लिक करा.', 'Click the button above to add an expense.'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else if (isMobile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredExpenses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final e = filteredExpenses[idx];
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
                            Text(e.expenseNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryMaroon)),
                            Text(
                              CurrencyFormatter.format(e.amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expenseRed, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryMaroon.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(e.categoryName, style: const TextStyle(fontSize: 11, color: AppColors.primaryMaroon, fontWeight: FontWeight.bold)),
                            ),
                            Text('${e.date} • ${e.paymentMode} • ${e.vendorName ?? e.paidBy}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                    DataColumn(label: Text(AppStrings.tr('व्हाउचर क्र.', 'Expense No'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('तारीख', 'Date'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('प्रवर्ग', 'Category'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('विक्रेता', 'Vendor'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('तपशील', 'Description'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('रक्कम', 'Amount'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('पेमेंट पद्धत', 'Payment Mode'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('अदाकर्ता', 'Paid By'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('स्थिती', 'Status'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('बिल', 'Action'), style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filteredExpenses.map((e) {
                    return DataRow(
                      cells: [
                        DataCell(Text(e.expenseNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(e.date)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryMaroon.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(e.categoryName,
                                style: const TextStyle(fontSize: 11, color: AppColors.primaryMaroon, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        DataCell(Text(e.vendorName ?? '-')),
                        DataCell(Text(e.description)),
                        DataCell(
                          Text(
                            CurrencyFormatter.format(e.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expenseRed),
                          ),
                        ),
                        DataCell(Text(e.paymentMode)),
                        DataCell(Text(e.paidBy)),
                        DataCell(StatusBadge(status: e.status)),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.file_present, size: 18, color: AppColors.infoBlue),
                            tooltip: 'View Bill / Invoice',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Bill file: ${e.billUrl ?? "decoration_bill.pdf"}')),
                              );
                            },
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
