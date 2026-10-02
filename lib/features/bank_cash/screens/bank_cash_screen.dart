import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../services/offline_db_helper.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.account_balance, color: AppColors.primaryMaroon),
            const SizedBox(width: 8),
            Text(
              AppStrings.tr('नवीन बँक खाते जोडा', 'Add Bank Account'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bankCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('बँकेचे नाव (उदा. SBI, HDFC)', 'Bank Name (e.g. SBI)'),
                    prefixIcon: const Icon(Icons.account_balance),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: branchCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('शाखेचे नाव (Branch)', 'Branch Name'),
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: holderCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('खातेदाराचे नाव (Mandal Name)', 'Account Holder Name'),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accNumCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('खाते क्रमांक (Account Number)', 'Account Number'),
                    prefixIcon: const Icon(Icons.tag),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ifscCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('IFSC कोड', 'IFSC Code'),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('सुरुवातीची शिल्लक (₹)', 'Opening Balance (₹)'),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.tr('रद्द करा', 'Cancel'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final bal = double.tryParse(balCtrl.text.trim()) ?? 0.0;
              if (bankCtrl.text.trim().isEmpty || accNumCtrl.text.trim().isEmpty) return;
              final newAccount = BankAccountModel(
                id: OfflineDbHelper.generateId(),
                bankName: bankCtrl.text.trim(),
                branchName: branchCtrl.text.trim(),
                accountHolder: holderCtrl.text.trim(),
                accountNumber: accNumCtrl.text.trim(),
                ifsc: ifscCtrl.text.trim(),
                balance: bal,
              );
              Navigator.pop(ctx);
              await repository.addBankAccount(newAccount);
              setState(() {});
            },
            child: Text(AppStrings.tr('खाते जतन करा', 'Save Account')),
          ),
        ],
      ),
    );
  }

  void _showEditBankDialog(BankAccountModel account) {
    final bankCtrl = TextEditingController(text: account.bankName);
    final branchCtrl = TextEditingController(text: account.branchName);
    final holderCtrl = TextEditingController(text: account.accountHolder);
    final accNumCtrl = TextEditingController(text: account.accountNumber);
    final ifscCtrl = TextEditingController(text: account.ifsc);
    final balCtrl = TextEditingController(text: account.balance.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit, color: AppColors.infoBlue),
            const SizedBox(width: 8),
            Text(
              AppStrings.tr('बँक माहिती बदला', 'Edit Bank Account'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bankCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('बँकेचे नाव (उदा. SBI, HDFC)', 'Bank Name (e.g. SBI)'),
                    prefixIcon: const Icon(Icons.account_balance),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: branchCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('शाखेचे नाव (Branch)', 'Branch Name'),
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: holderCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('खातेदाराचे नाव', 'Account Holder Name'),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accNumCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('खाते क्रमांक (Account Number)', 'Account Number'),
                    prefixIcon: const Icon(Icons.tag),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ifscCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('IFSC कोड', 'IFSC Code'),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('शिल्लक (₹)', 'Current Balance (₹)'),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.tr('रद्द करा', 'Cancel'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.infoBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final bal = double.tryParse(balCtrl.text.trim()) ?? account.balance;
              final updated = account.copyWith(
                bankName: bankCtrl.text.trim(),
                branchName: branchCtrl.text.trim(),
                accountHolder: holderCtrl.text.trim(),
                accountNumber: accNumCtrl.text.trim(),
                ifsc: ifscCtrl.text.trim(),
                balance: bal,
              );
              Navigator.pop(ctx);
              await repository.updateBankAccount(updated);
              setState(() {});
            },
            child: Text(AppStrings.tr('बदल सेव्ह करा', 'Save Changes')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBank(BankAccountModel account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr('बँक खाते काढून टाकायचे आहे का?', 'Delete Bank Account?')),
        content: Text(AppStrings.tr(
          'आपण खात्रीपूर्वक "${account.bankName} (${account.accountNumber})" खाते काढून टाकू इच्छिता का?',
          'Are you sure you want to delete "${account.bankName} (${account.accountNumber})"?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.tr('नाही / रद्द करा', 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await repository.deleteBankAccount(account.id);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.tr('बँक खाते काढून टाकण्यात आले!', 'Bank account deleted!')),
                    backgroundColor: AppColors.expenseRed,
                  ),
                );
              }
            },
            child: Text(AppStrings.tr('काढून टाका', 'Delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = repository.getSummary();
    final isMobile = MediaQuery.of(context).size.width < 750;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs: Bank | Cash matching Screen 5
          Container(
            width: double.infinity,
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
              tabs: [
                Tab(icon: const Icon(Icons.account_balance), text: AppStrings.tr('बँक खाती', 'Bank Accounts')),
                Tab(icon: const Icon(Icons.payments), text: AppStrings.tr('हातची रोकड (Cash)', 'Cash in Hand')),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Bank Table Container
          Container(
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
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Text(
                      AppStrings.tr('बँक खाती व्यवस्थापन', 'Bank Accounts'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddBankDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(AppStrings.tr('+ बँक जोडा', '+ Add Bank')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: [
                      DataColumn(label: Text(AppStrings.tr('बँकेचे नाव', 'Bank Name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(AppStrings.tr('शाखा', 'Branch'), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(AppStrings.tr('खाते क्रमांक', 'Account No.'), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(AppStrings.tr('IFSC', 'IFSC'), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(AppStrings.tr('शिल्लक रक्कम', 'Balance'), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(AppStrings.tr('कृती', 'Action'), style: const TextStyle(fontWeight: FontWeight.bold))),
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
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue),
                                  tooltip: AppStrings.tr('माहिती बदला', 'Edit'),
                                  onPressed: () => _showEditBankDialog(b),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                                  tooltip: AppStrings.tr('काढून टाका', 'Delete'),
                                  onPressed: () => _confirmDeleteBank(b),
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
          const SizedBox(height: 20),

          // Overview Cards matching Screen 5 exactly
          Text(
            AppStrings.tr('वित्तीय अवलोकन (Overview)', 'Financial Overview'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth > 900 ? 3 : 2;
              final ratio = constraints.maxWidth > 900 ? 2.2 : 1.45;
              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: ratio,
                children: [
                  _buildBalanceTile(
                    AppStrings.tr('बँक शिल्लक', 'Bank Balance'),
                    CurrencyFormatter.format(summary.bankBalance),
                    AppColors.infoBlue,
                    Icons.account_balance,
                    isMobile,
                  ),
                  _buildBalanceTile(
                    AppStrings.tr('रोख शिल्लक', 'Cash Balance'),
                    CurrencyFormatter.format(summary.cashBalance),
                    AppColors.warningOrange,
                    Icons.payments,
                    isMobile,
                  ),
                  _buildBalanceTile(
                    AppStrings.tr('एकूण शिल्लक', 'Total Balance'),
                    CurrencyFormatter.format(summary.totalBalance),
                    AppColors.successGreen,
                    Icons.account_balance_wallet,
                    isMobile,
                  ),
                  _buildBalanceTile(
                    AppStrings.tr('जमा रक्कम', 'Deposits'),
                    CurrencyFormatter.format(summary.deposits),
                    AppColors.successGreen,
                    Icons.arrow_downward,
                    isMobile,
                  ),
                  _buildBalanceTile(
                    AppStrings.tr('खर्च / काढलेली', 'Withdrawals'),
                    CurrencyFormatter.format(summary.withdrawals),
                    AppColors.expenseRed,
                    Icons.arrow_upward,
                    isMobile,
                  ),
                  _buildBalanceTile(
                    AppStrings.tr('निव्वळ शिल्लक', 'Net Change'),
                    CurrencyFormatter.format(summary.netChange),
                    const Color(0xFF0D9488),
                    Icons.trending_up,
                    isMobile,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceTile(String title, String value, Color color, IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 22),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: isMobile ? 10 : 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 17,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
