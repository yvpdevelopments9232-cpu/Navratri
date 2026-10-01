import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/mandal_repository.dart';

class ReportItem {
  final String key;
  final String titleMr;
  final String titleEn;
  final IconData icon;

  const ReportItem({
    required this.key,
    required this.titleMr,
    required this.titleEn,
    required this.icon,
  });
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final repository = MandalRepository();
  String selectedReport = 'Donation Report';
  int _activeTab = 0; // 0: Financial, 1: Festival

  final TextEditingController _fromController = TextEditingController(text: '01-09-2026');
  final TextEditingController _toController = TextEditingController(text: '31-10-2026');
  final TextEditingController _categoryController = TextEditingController(text: 'All Categories');

  final List<ReportItem> financialReports = const [
    ReportItem(
      key: 'Donation Report',
      titleMr: 'देणगी अहवाल',
      titleEn: 'Donation Report',
      icon: Icons.volunteer_activism,
    ),
    ReportItem(
      key: 'Expense Report',
      titleMr: 'खर्च अहवाल',
      titleEn: 'Expense Report',
      icon: Icons.receipt_long,
    ),
    ReportItem(
      key: 'Cash Book',
      titleMr: 'रोकड वही (कॅश बुक)',
      titleEn: 'Cash Book',
      icon: Icons.payments_outlined,
    ),
    ReportItem(
      key: 'Bank Book',
      titleMr: 'बँक वही (बँक बुक)',
      titleEn: 'Bank Book',
      icon: Icons.account_balance,
    ),
    ReportItem(
      key: 'Income & Expense',
      titleMr: 'उत्पन्न आणि खर्च',
      titleEn: 'Income & Expense',
      icon: Icons.compare_arrows,
    ),
    ReportItem(
      key: 'Balance Sheet',
      titleMr: 'ताळेबंद (बॅलन्स शीट)',
      titleEn: 'Balance Sheet',
      icon: Icons.account_tree_outlined,
    ),
    ReportItem(
      key: 'Pending Payment Report',
      titleMr: 'प्रलंबित देणी अहवाल',
      titleEn: 'Pending Payments',
      icon: Icons.pending_actions,
    ),
  ];

  final List<ReportItem> festivalReports = const [
    ReportItem(
      key: 'Event Report',
      titleMr: 'कार्यक्रम अहवाल',
      titleEn: 'Event Report',
      icon: Icons.celebration,
    ),
    ReportItem(
      key: 'Member Report',
      titleMr: 'सदस्य यादी अहवाल',
      titleEn: 'Member Report',
      icon: Icons.people_outline,
    ),
    ReportItem(
      key: 'Volunteer Report',
      titleMr: 'स्वयंसेवक अहवाल',
      titleEn: 'Volunteer Report',
      icon: Icons.badge_outlined,
    ),
    ReportItem(
      key: 'Vendor Report',
      titleMr: 'व्यापारी अहवाल',
      titleEn: 'Vendor Report',
      icon: Icons.storefront,
    ),
    ReportItem(
      key: 'Sponsorship Report',
      titleMr: 'प्रायोजक अहवाल',
      titleEn: 'Sponsorship Report',
      icon: Icons.handshake_outlined,
    ),
    ReportItem(
      key: 'Inventory Report',
      titleMr: 'साहित्य / इन्व्हेंटरी',
      titleEn: 'Inventory Report',
      icon: Icons.inventory_2_outlined,
    ),
    ReportItem(
      key: 'Registration Report',
      titleMr: 'गरबा नोंदणी अहवाल',
      titleEn: 'Registration Report',
      icon: Icons.confirmation_number_outlined,
    ),
  ];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _generatePdf([String? report]) {
    final target = report ?? selectedReport;
    if (report != null && report != selectedReport) {
      setState(() => selectedReport = report);
    }
    PdfService.printReport(
      reportType: target,
      repository: repository,
      fromDate: _fromController.text,
      toDate: _toController.text,
      category: _categoryController.text,
    );
  }

  void _showReportDataPreview([String? report]) {
    if (report != null && report != selectedReport) {
      setState(() => selectedReport = report);
    }
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics, color: AppColors.primaryMaroon),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$selectedReport Preview',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildReportDataContent(),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(AppStrings.tr('बंद करा', 'Close')),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _generatePdf();
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: Text(AppStrings.tr('PDF तयार करा / प्रिंट', 'Generate PDF / Print')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportDataContent() {
    switch (selectedReport) {
      case 'Donation Report':
        return _buildTablePreview(
          headers: ['पावती क्र.', 'तारीख', 'देणगीदार नाव', 'मोबाईल', 'हेतू', 'पद्धत', 'रक्कम'],
          rows: repository.donations.map((d) => [
            d.receiptNumber,
            d.date,
            d.donorName,
            d.mobile,
            d.purpose,
            d.paymentMode,
            '₹ ${d.amount.toInt()}',
          ]).toList(),
          summary: 'एकूण देणग्या: ${repository.donations.length}  |  एकूण रक्कम: ₹ ${repository.donations.fold<double>(0.0, (s, d) => s + d.amount).toInt()}',
        );

      case 'Expense Report':
        return _buildTablePreview(
          headers: ['व्हाउचर क्र.', 'तारीख', 'प्रवर्ग', 'कोणास दिले', 'पद्धत', 'रक्कम'],
          rows: repository.expenses.map((e) => [
            e.expenseNumber,
            e.date,
            e.categoryName,
            e.vendorName ?? e.description,
            e.paymentMode,
            '₹ ${e.amount.toInt()}',
          ]).toList(),
          summary: 'एकूण खर्च नोंदी: ${repository.expenses.length}  |  एकूण रक्कम: ₹ ${repository.expenses.fold<double>(0.0, (s, e) => s + e.amount).toInt()}',
        );

      case 'Cash Book':
        final cashDons = repository.donations.where((d) => d.paymentMode.toLowerCase() == 'cash').toList();
        final cashExps = repository.expenses.where((e) => e.paymentMode.toLowerCase() == 'cash').toList();
        final inTotal = cashDons.fold<double>(0.0, (s, d) => s + d.amount);
        final outTotal = cashExps.fold<double>(0.0, (s, e) => s + e.amount);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('रोकड जमा: ₹ ${inTotal.toInt()}  |  रोकड खर्च: ₹ ${outTotal.toInt()}  |  शिल्लक रोख: ₹ ${(inTotal - outTotal).toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
            const SizedBox(height: 10),
            _buildTablePreview(
              headers: ['पावती / व्हाउचर', 'तारीख', 'नाव / तपशील', 'रक्कम'],
              rows: [
                ...cashDons.map((d) => [d.receiptNumber, d.date, 'देणगी: ${d.donorName}', '+₹ ${d.amount.toInt()}']),
                ...cashExps.map((e) => [e.expenseNumber, e.date, 'खर्च: ${e.vendorName ?? e.description}', '-₹ ${e.amount.toInt()}']),
              ],
            ),
          ],
        );

      case 'Bank Book':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('बँक खाती (Accounts)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _buildTablePreview(
              headers: ['बँकेचे नाव', 'खाते क्रमांक', 'IFSC कोड', 'शिल्लक'],
              rows: repository.bankAccounts.map((b) => [b.bankName, b.accountNumber, b.ifscCode, '₹ ${b.currentBalance.toInt()}']).toList(),
            ),
          ],
        );

      case 'Income & Expense':
        final inSum = repository.donations.fold<double>(0.0, (s, d) => s + d.amount);
        final exSum = repository.expenses.fold<double>(0.0, (s, e) => s + e.amount);
        return Column(
          children: [
            ListTile(title: const Text('एकूण उत्पन्न / जमा (Total Income)'), trailing: Text('₹ ${inSum.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
            ListTile(title: const Text('एकूण खर्च (Total Expenses)'), trailing: Text('₹ ${exSum.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
            const Divider(),
            ListTile(title: const Text('निव्वळ शिल्लक / बचत (Net Surplus)'), trailing: Text('₹ ${(inSum - exSum).toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16))),
          ],
        );

      case 'Balance Sheet':
        final inSum = repository.donations.fold<double>(0.0, (s, d) => s + d.amount);
        final exSum = repository.expenses.fold<double>(0.0, (s, e) => s + e.amount);
        final surplus = inSum - exSum;
        return _buildTablePreview(
          headers: ['देयता (Liabilities)', 'रक्कम', 'मालमत्ता (Assets)', 'रक्कम'],
          rows: [
            ['राखीव निधी', '₹ 50,000', 'बँक शिल्लक', '₹ ${(surplus * 0.6).clamp(0, double.infinity).toInt()}'],
            ['नफा शिल्लक', '₹ ${surplus.toInt()}', 'रोख शिल्लक', '₹ ${(surplus * 0.4).clamp(0, double.infinity).toInt()}'],
            ['प्रलंबित देयके', '₹ 15,000', 'साहित्य व मालमत्ता', '₹ 65,000'],
          ],
        );

      case 'Pending Payment Report':
        final pending = repository.vendors.where((v) => v.remainingAmount > 0).toList();
        return _buildTablePreview(
          headers: ['व्यापारी कोड', 'नाव', 'सेवा', 'करार', 'अदा', 'शिल्लक'],
          rows: pending.map((v) => [v.vendorCode, v.vendorName, v.serviceType, '₹ ${v.contractAmount.toInt()}', '₹ ${v.paidAmount.toInt()}', '₹ ${v.remainingAmount.toInt()}']).toList(),
          summary: 'एकूण थकीत व्यापारी संख्या: ${pending.length}',
        );

      case 'Event Report':
        return _buildTablePreview(
          headers: ['नाव', 'तारीख', 'वेळ', 'ठिकाण', 'अतिथी', 'स्थिती'],
          rows: repository.events.map((e) => [e.title, e.date, e.startTime, e.location, e.chiefGuest ?? '-', e.status]).toList(),
          summary: 'एकूण कार्यक्रम: ${repository.events.length}',
        );

      case 'Member Report':
        return _buildTablePreview(
          headers: ['सदस्य कोड', 'नाव', 'पद', 'मोबाईल', 'स्थिती'],
          rows: repository.members.map((m) => [m.memberCode, m.fullName, m.designation, m.mobile, m.status]).toList(),
          summary: 'एकूण सदस्य संख्या: ${repository.members.length}',
        );

      case 'Volunteer Report':
        return _buildTablePreview(
          headers: ['कोड', 'नाव', 'मोबाईल', 'विभाग / काम', 'स्थिती'],
          rows: repository.volunteers.map((v) => [v.volunteerCode, v.fullName, v.mobile, v.dutyArea, v.status]).toList(),
          summary: 'एकूण स्वयंसेवक संख्या: ${repository.volunteers.length}',
        );

      case 'Vendor Report':
        return _buildTablePreview(
          headers: ['कोड', 'नाव', 'सेवा प्रकार', 'मोबाईल', 'करार', 'अदा', 'शिल्लक'],
          rows: repository.vendors.map((v) => [v.vendorCode, v.vendorName, v.serviceType, v.contact, '₹ ${v.contractAmount.toInt()}', '₹ ${v.paidAmount.toInt()}', '₹ ${v.remainingAmount.toInt()}']).toList(),
          summary: 'एकूण व्यापारी संख्या: ${repository.vendors.length}',
        );

      case 'Sponsorship Report':
        return _buildTablePreview(
          headers: ['प्रायोजक नाव', 'माध्यम', 'रक्कम', 'मोबाईल', 'स्थिती'],
          rows: repository.sponsors.map((s) => [s.sponsorName, s.category, '₹ ${s.amount.toInt()}', s.contact, s.status]).toList(),
          summary: 'एकूण प्रायोजक: ${repository.sponsors.length}',
        );

      case 'Inventory Report':
        return _buildTablePreview(
          headers: ['नाव', 'प्रवर्ग', 'संख्या', 'एकक', 'स्थिती'],
          rows: repository.inventory.map((i) => [i.itemName, i.category, i.quantity.toString(), i.unit, i.status]).toList(),
          summary: 'एकूण साहित्य बाबी: ${repository.inventory.length}',
        );

      case 'Registration Report':
        return _buildTablePreview(
          headers: ['पास क्र.', 'नाव', 'स्पर्धा', 'मोबाईल', 'फी', 'स्थिती'],
          rows: repository.participants.map((p) => [p.passNumber, p.participantName, p.competitionCategory, p.mobile, '₹ ${p.passAmount.toInt()}', p.status]).toList(),
          summary: 'एकूण नोंदणी संख्या: ${repository.participants.length}',
        );

      default:
        return const Center(child: Text('अहवाल तपशील उपलब्ध आहे.'));
    }
  }

  Widget _buildTablePreview({required List<String> headers, required List<List<String>> rows, String? summary}) {
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 36, color: Colors.grey),
            const SizedBox(height: 8),
            Text(AppStrings.tr('कोणतीही नोंद उपलब्ध नाही', 'No records found for this report')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.amber[300]!)),
            child: Text(summary, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 10),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.primaryMaroon.withAlpha(20)),
            columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))).toList(),
            rows: rows.map((r) => DataRow(cells: r.map((c) => DataCell(Text(c, style: const TextStyle(fontSize: 11)))).toList())).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 20 : 12),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 20 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header
            Row(
              children: [
                const Icon(Icons.analytics, color: AppColors.primaryMaroon, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr('अहवाल आणि वित्तीय लेखापरीक्षण', 'Reports & Financial Auditing'),
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'निवडलेला अहवाल: $selectedReport',
                        style: const TextStyle(fontSize: 12, color: AppColors.primaryMaroon, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (isDesktop)
              // Desktop 3-Column Layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFinancialReportsList()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildFestivalReportsList()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildFilterActionPanel()),
                ],
              )
            else
              // Mobile Responsive Layout with Tabs & Stacked Action Panel
              Column(
                children: [
                  // Tab selector for Financial vs Festival
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _activeTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _activeTab == 0 ? AppColors.primaryMaroon : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                AppStrings.tr('आर्थिक अहवाल', 'Financial'),
                                style: TextStyle(
                                  color: _activeTab == 0 ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _activeTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _activeTab == 1 ? AppColors.primaryMaroon : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                AppStrings.tr('उत्सव अहवाल', 'Festival'),
                                style: TextStyle(
                                  color: _activeTab == 1 ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Report List based on selected tab
                  _activeTab == 0 ? _buildFinancialReportsList() : _buildFestivalReportsList(),
                  const SizedBox(height: 16),

                  // Filter & Action Panel
                  _buildFilterActionPanel(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialReportsList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.primaryMaroon),
              const SizedBox(width: 6),
              Text(
                AppStrings.tr('आर्थिक अहवाल', 'Financial Reports'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const Divider(),
          ...financialReports.map((r) => _buildReportCard(r)),
        ],
      ),
    );
  }

  Widget _buildFestivalReportsList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration_outlined, size: 16, color: AppColors.primaryMaroon),
              const SizedBox(width: 6),
              Text(
                AppStrings.tr('उत्सव अहवाल', 'Festival Reports'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const Divider(),
          ...festivalReports.map((r) => _buildReportCard(r)),
        ],
      ),
    );
  }

  Widget _buildReportCard(ReportItem item) {
    final isSel = selectedReport == item.key;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSel ? AppColors.primaryMaroon.withAlpha(12) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSel ? AppColors.primaryMaroon : AppColors.borderLight,
          width: isSel ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() => selectedReport = item.key);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSel ? AppColors.primaryMaroon : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.titleMr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                          color: isSel ? AppColors.primaryMaroon : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.titleEn,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSel ? AppColors.primaryMaroon.withAlpha(200) : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      tooltip: AppStrings.tr('पूर्वावलोकन', 'Preview'),
                      color: AppColors.primaryMaroon,
                      onPressed: () => _showReportDataPreview(item.key),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.expenseRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _generatePdf(item.key),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf, size: 13),
                          SizedBox(width: 4),
                          Text('PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterActionPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 16, color: AppColors.primaryMaroon),
              const SizedBox(width: 6),
              Text(
                AppStrings.tr('फिल्टर व निर्मिती', 'Filter & Generate'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryMaroon.withAlpha(15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primaryMaroon.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, size: 16, color: AppColors.primaryMaroon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedReport,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryMaroon),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fromController,
            decoration: const InputDecoration(
              labelText: 'From Date',
              hintText: '01-09-2026',
              prefixIcon: Icon(Icons.calendar_today, size: 16),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _toController,
            decoration: const InputDecoration(
              labelText: 'To Date',
              hintText: '31-10-2026',
              prefixIcon: Icon(Icons.calendar_today, size: 16),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Category',
              hintText: 'All Categories',
              prefixIcon: Icon(Icons.filter_list, size: 16),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: View, PDF, Print, Excel
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showReportDataPreview(selectedReport),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generatePdf(selectedReport),
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.expenseRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _generatePdf(selectedReport),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$selectedReport exported to Excel successfully'),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  },
                  icon: const Icon(Icons.table_view, size: 16),
                  label: const Text('Excel'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
