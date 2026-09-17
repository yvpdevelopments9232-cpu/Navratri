import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';

class BankCashScreen extends StatefulWidget {
  const BankCashScreen({super.key});

  @override
  State<BankCashScreen> createState() => _BankCashScreenState();
}

class _BankCashScreenState extends State<BankCashScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final repository = MandalRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddBankDialog() {
    final bankCtrl = TextEditingController();
    final branchCtrl = TextEditingController();
    final holderCtrl = TextEditingController(text: repository.mandalProfile.name);
    final accNumCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    final balCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: AppColors.primaryMaroon),
            SizedBox(width: 8),
            Text('Add Bank Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'Bank Name (e.g. SBI)')),
                const SizedBox(height: 12),
                TextField(controller: branchCtrl, decoration: const InputDecoration(labelText: 'Branch Name')),
                const SizedBox(height: 12),
                TextField(controller: holderCtrl, decoration: const InputDecoration(labelText: 'Account Holder Name')),
                const SizedBox(height: 12),
                TextField(controller: accNumCtrl, decoration: const InputDecoration(labelText: 'Account Number'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: ifscCtrl, decoration: const InputDecoration(labelText: 'IFSC Code')),
                const SizedBox(height: 12),
                TextField(controller: balCtrl, decoration: const InputDecoration(labelText: 'Opening Balance (₹)'), keyboardType: TextInputType.number),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final bal = double.tryParse(balCtrl.text.trim()) ?? 0.0;
              if (bankCtrl.text.trim().isEmpty || accNumCtrl.text.trim().isEmpty) return;
              repository.bankAccounts.add(
                BankAccountModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  bankName: bankCtrl.text.trim(),
                  branchName: branchCtrl.text.trim(),
                  accountHolder: holderCtrl.text.trim(),
                  accountNumber: accNumCtrl.text.trim(),
                  ifsc: ifscCtrl.text.trim(),
                  balance: bal,
                ),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = repository.getSummary();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs: Bank | Cash matching Screen 5
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryMaroon,
              indicatorColor: AppColors.primaryMaroon,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.account_balance), text: 'Bank Accounts'),
                Tab(icon: Icon(Icons.payments), text: 'Cash in Hand'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Bank Table Container
          Container(
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
                    const Text(
                      'Bank Accounts',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddBankDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ Add Bank'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('Bank Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Branch', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Account No.', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('IFSC', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: repository.bankAccounts.map((b) {
                      return DataRow(
                        cells: [
                          DataCell(Text(b.bankName, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(b.branchName)),
                          DataCell(Text(b.accountNumber)),
                          DataCell(Text(b.ifsc)),
                          DataCell(
                            Text(
                              CurrencyFormatter.format(b.balance),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue), onPressed: () {}),
                                IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed), onPressed: () {}),
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
          const SizedBox(height: 20),

          // Overview Cards matching Screen 5 exactly
          const Text(
            'Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth > 900 ? 3 : 2;
              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _buildBalanceTile('Bank Balance', CurrencyFormatter.format(summary.bankBalance), AppColors.infoBlue, Icons.account_balance),
                  _buildBalanceTile('Cash Balance', CurrencyFormatter.format(summary.cashBalance), AppColors.warningOrange, Icons.payments),
                  _buildBalanceTile('Total Balance', CurrencyFormatter.format(summary.totalBalance), AppColors.successGreen, Icons.account_balance_wallet),
                  _buildBalanceTile('Deposits', CurrencyFormatter.format(summary.deposits), AppColors.successGreen, Icons.arrow_downward),
                  _buildBalanceTile('Withdrawals', CurrencyFormatter.format(summary.withdrawals), AppColors.expenseRed, Icons.arrow_upward),
                  _buildBalanceTile('Net Change', CurrencyFormatter.format(summary.netChange), const Color(0xFF0D9488), Icons.trending_up),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceTile(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
