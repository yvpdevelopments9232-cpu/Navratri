import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../widgets/status_badge.dart';

class SponsorsScreen extends StatefulWidget {
  const SponsorsScreen({super.key});

  @override
  State<SponsorsScreen> createState() => _SponsorsScreenState();
}

class _SponsorsScreenState extends State<SponsorsScreen> {
  final repository = MandalRepository();

  void _showAddSponsorDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedPkg = 'Main Sponsor';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.handshake, color: AppColors.primaryMaroon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('प्रायोजक जोडा', 'Add Festival Sponsor'),
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
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.tr('प्रायोजक / कंपनी नाव *', 'Sponsor / Company Name *'))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedPkg,
                  decoration: InputDecoration(labelText: AppStrings.tr('प्रायोजक पॅकेज', 'Sponsorship Package')),
                  items: const [
                    DropdownMenuItem(value: 'Main Sponsor', child: Text('Main Sponsor (मुख्य प्रायोजक)')),
                    DropdownMenuItem(value: 'Gold Sponsor', child: Text('Gold Sponsor (सुवर्ण प्रायोजक)')),
                    DropdownMenuItem(value: 'Silver Sponsor', child: Text('Silver Sponsor (रौप्य प्रायोजक)')),
                    DropdownMenuItem(value: 'Banner Sponsor', child: Text('Banner Sponsor (बॅनर प्रायोजक)')),
                    DropdownMenuItem(value: 'Event Sponsor', child: Text('Event Sponsor (कार्यक्रम प्रायोजक)')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedPkg = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: amountCtrl, decoration: InputDecoration(labelText: AppStrings.tr('रक्कम (₹) *', 'Amount (₹) *')), keyboardType: TextInputType.number),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('रद्द करा', 'Cancel'))),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (nameCtrl.text.trim().isEmpty || amt <= 0) return;
              Navigator.pop(ctx);
              await repository.addSponsor(
                SponsorModel(
                  id: '',
                  sponsorName: nameCtrl.text.trim(),
                  package: selectedPkg,
                  amount: amt,
                  paidAmount: amt,
                  status: 'Paid',
                ),
              );
              if (mounted) setState(() {});
            },
            child: Text(AppStrings.tr('जतन करा', 'Save Sponsor')),
          ),
        ],
      ),
    );
  }

  void _showEditSponsorDialog(SponsorModel sponsor) {
    final nameCtrl = TextEditingController(text: sponsor.sponsorName);
    final amountCtrl = TextEditingController(text: sponsor.amount.toStringAsFixed(0));
    final paidCtrl = TextEditingController(text: sponsor.paidAmount.toStringAsFixed(0));
    String selectedPkg = sponsor.package;
    String selectedStatus = sponsor.status;

    final packages = ['Main Sponsor', 'Gold Sponsor', 'Silver Sponsor', 'Banner Sponsor', 'Event Sponsor'];
    if (!packages.contains(selectedPkg)) selectedPkg = 'Main Sponsor';

    final statuses = ['Paid', 'Pending', 'Partial'];
    if (!statuses.contains(selectedStatus)) selectedStatus = 'Paid';

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
                  AppStrings.tr('प्रायोजक माहिती बदला', 'Edit Sponsor'),
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
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.tr('प्रायोजक नाव *', 'Sponsor Name *'))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPkg,
                    decoration: InputDecoration(labelText: AppStrings.tr('प्रायोजक पॅकेज', 'Sponsorship Package')),
                    items: const [
                      DropdownMenuItem(value: 'Main Sponsor', child: Text('Main Sponsor (मुख्य प्रायोजक)')),
                      DropdownMenuItem(value: 'Gold Sponsor', child: Text('Gold Sponsor (सुवर्ण प्रायोजक)')),
                      DropdownMenuItem(value: 'Silver Sponsor', child: Text('Silver Sponsor (रौप्य प्रायोजक)')),
                      DropdownMenuItem(value: 'Banner Sponsor', child: Text('Banner Sponsor (बॅनर प्रायोजक)')),
                      DropdownMenuItem(value: 'Event Sponsor', child: Text('Event Sponsor (कार्यक्रम प्रायोजक)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedPkg = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: amountCtrl, decoration: InputDecoration(labelText: AppStrings.tr('एकूण प्रायोजक रक्कम (₹) *', 'Total Amount (₹) *')), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  TextField(controller: paidCtrl, decoration: InputDecoration(labelText: AppStrings.tr('जमा रक्कम (₹)', 'Paid Amount (₹)')), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(labelText: AppStrings.tr('स्थिती', 'Status')),
                    items: [
                      DropdownMenuItem(value: 'Paid', child: Text(AppStrings.tr('जमा (Paid)', 'Paid'))),
                      DropdownMenuItem(value: 'Partial', child: Text(AppStrings.tr('अंशतः जमा (Partial)', 'Partial'))),
                      DropdownMenuItem(value: 'Pending', child: Text(AppStrings.tr('प्रलंबित (Pending)', 'Pending'))),
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
                final amt = double.tryParse(amountCtrl.text.trim()) ?? sponsor.amount;
                final pAmt = double.tryParse(paidCtrl.text.trim()) ?? sponsor.paidAmount;
                final updated = sponsor.copyWith(
                  sponsorName: nameCtrl.text.trim().isEmpty ? sponsor.sponsorName : nameCtrl.text.trim(),
                  package: selectedPkg,
                  amount: amt,
                  paidAmount: pAmt,
                  status: selectedStatus,
                );
                Navigator.pop(ctx);
                await repository.updateSponsor(updated);
                if (mounted) setState(() {});
              },
              child: Text(AppStrings.tr('बदल सेव्ह करा', 'Save Changes')),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSponsor(SponsorModel sponsor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr('प्रायोजक काढून टाकायचे आहेत का?', 'Delete Sponsor?')),
        content: Text(AppStrings.tr(
          'आपण खात्रीपूर्वक "${sponsor.sponsorName}" यांची नोंद काढून टाकू इच्छिता का?',
          'Are you sure you want to delete sponsor "${sponsor.sponsorName}"?',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('नाही / रद्द करा', 'Cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await repository.deleteSponsor(sponsor.id);
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
                      const Icon(Icons.handshake_outlined, color: AppColors.primaryMaroon, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr('प्रायोजक व जाहिराती', 'Sponsorship & Ads'),
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
                      onPressed: _showAddSponsorDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(AppStrings.tr('+ प्रायोजक जोडा', '+ Add Sponsor')),
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
                        const Icon(Icons.handshake_outlined, color: AppColors.primaryMaroon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.tr('प्रायोजक व जाहिरात व्यवस्थापन', 'Sponsorship & Advertisements'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddSponsorDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.tr('+ प्रायोजक जोडा', '+ Add Sponsor')),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            if (repository.sponsors.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text(
                    AppStrings.tr('कोणताही प्रायोजक नोंदवलेला नाही', 'No sponsors added yet'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else if (isMobile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: repository.sponsors.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final s = repository.sponsors[idx];
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
                                s.sponsorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadge(status: s.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.brightGold.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(s.package, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                            Row(
                              children: [
                                Text(
                                  CurrencyFormatter.format(s.amount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.successGreen),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.infoBlue),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showEditSponsorDialog(s),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _confirmDeleteSponsor(s),
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
                    DataColumn(label: Text(AppStrings.tr('प्रायोजक नाव', 'Sponsor Name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('पॅकेज', 'Package'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('रक्कम', 'Amount'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('स्थिती', 'Status'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('क्रिया', 'Action'), style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: repository.sponsors.map((s) {
                    return DataRow(
                      cells: [
                        DataCell(Text(s.sponsorName, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brightGold.withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(s.package, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        DataCell(
                          Text(
                            CurrencyFormatter.format(s.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen),
                          ),
                        ),
                        DataCell(StatusBadge(status: s.status)),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.infoBlue),
                                onPressed: () => _showEditSponsorDialog(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                                onPressed: () => _confirmDeleteSponsor(s),
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
