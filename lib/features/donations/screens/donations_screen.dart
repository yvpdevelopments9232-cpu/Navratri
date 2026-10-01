import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';

class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  final repository = MandalRepository();
  String _searchQuery = '';

  void _showAddDonationDialog() {
    final now = DateTime.now();
    final todayStr = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    final mandalCode = repository.mandalProfile.id.length >= 4
        ? repository.mandalProfile.id.substring(0, 4).toUpperCase()
        : '0000';
    String prefix = repository.mandalProfile.receiptPrefix.isNotEmpty ? repository.mandalProfile.receiptPrefix : 'R-';
    if (!prefix.contains(mandalCode)) {
      prefix = prefix.endsWith('-') ? '$prefix$mandalCode-' : '$prefix-$mandalCode-';
    }
    final nextReceiptNo = '$prefix${(repository.donations.length + 1).toString().padLeft(4, '0')}';
    final dateCtrl = TextEditingController(text: todayStr);
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedMode = 'Cash';
    String selectedPurpose = 'Festival Donation';
    final collectorList = <String>{
      if (repository.mandalProfile.authorizedSignatoryName.isNotEmpty)
        repository.mandalProfile.authorizedSignatoryName,
      ...repository.members.map((m) => m.fullName).where((n) => n.trim().isNotEmpty),
      'Mandal Admin',
    }.toList();

    String selectedCollector = repository.mandalProfile.authorizedSignatoryName.isNotEmpty
        ? repository.mandalProfile.authorizedSignatoryName
        : collectorList.first;
    if (!collectorList.contains(selectedCollector)) {
      selectedCollector = collectorList.first;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.successGreen.withAlpha(30), shape: BoxShape.circle),
                child: const Icon(Icons.currency_rupee, color: AppColors.successGreen, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.tr('देणगी / वर्गणी नोंदवा', 'Add Donation / Vargani'),
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
                          initialValue: nextReceiptNo,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Receipt No.', prefixIcon: Icon(Icons.tag)),
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
                        child: TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Donor Name *', prefixIcon: Icon(Icons.person)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: mobileCtrl,
                          decoration: const InputDecoration(labelText: 'Mobile No.', prefixIcon: Icon(Icons.phone)),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  const Text('Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Cash', 'UPI', 'Bank Transfer', 'Cheque', 'Other'].map((mode) {
                      final isSelected = selectedMode == mode;
                      return ChoiceChip(
                        label: Text(mode),
                        selected: isSelected,
                        selectedColor: AppColors.primaryMaroon,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedMode = mode);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedPurpose,
                          decoration: const InputDecoration(labelText: 'Purpose'),
                          items: const [
                            DropdownMenuItem(value: 'Festival Donation', child: Text('Festival Donation')),
                            DropdownMenuItem(value: 'Aarti Donation', child: Text('Aarti Donation')),
                            DropdownMenuItem(value: 'Mahaprasad Fund', child: Text('Mahaprasad Fund')),
                            DropdownMenuItem(value: 'Idol Sthapana', child: Text('Idol Sthapana')),
                          ],
                          onChanged: (val) {
                            if (val != null) selectedPurpose = val;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCollector,
                          decoration: const InputDecoration(labelText: 'Collector Name'),
                          items: collectorList
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) selectedCollector = val;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes', hintText: 'Thank you for your support.'),
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
                if (nameCtrl.text.trim().isEmpty || amt <= 0) return;

                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);

                final newDonation = DonationModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  receiptNumber: nextReceiptNo,
                  date: dateCtrl.text.trim(),
                  donorName: nameCtrl.text.trim(),
                  mobile: mobileCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  amount: amt,
                  paymentMode: selectedMode,
                  purpose: selectedPurpose,
                  collectorName: selectedCollector,
                  notes: notesCtrl.text.trim(),
                );

                await repository.addDonation(newDonation);
                if (mounted) {
                  nav.pop();
                  setState(() {});
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Donation ${newDonation.receiptNumber} recorded successfully!'),
                      action: SnackBarAction(
                        label: 'Print PDF',
                        onPressed: () => PdfService.printDonationReceipt(
                          mandal: repository.mandalProfile,
                          donation: newDonation,
                        ),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save Donation'),
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

    final filteredDonations = repository.donations.where((d) {
      final q = _searchQuery.toLowerCase();
      return d.donorName.toLowerCase().contains(q) ||
          d.receiptNumber.toLowerCase().contains(q) ||
          d.mobile.contains(q) ||
          d.paymentMode.toLowerCase().contains(q);
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
                      const Icon(Icons.currency_rupee, color: AppColors.successGreen, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr('देणगी / वर्गणी व्यवस्थापन', 'Donation Management'),
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
                              hintText: AppStrings.tr('पावती / देणगीदार शोधा...', 'Search...'),
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
                        onPressed: _showAddDonationDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.tr('+ देणगी', '+ Add')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.currency_rupee, color: AppColors.successGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.tr('देणगी / वर्गणी व्यवस्थापन (Donation & Vargani)', 'Donation / Vargani Management'),
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
                        hintText: AppStrings.tr('पावती क्रमांक / देणगीदार शोधा...', 'Search receipt / donor...'),
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
                    onPressed: _showAddDonationDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.addDonation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            // Table or Empty State
            if (filteredDonations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 54, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.tr('कोणतीही देणगी नोंद उपलब्ध नाही', 'No donation records found'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.tr('नवीन देणगी / वर्गणी जोडण्यासाठी वरील बटणावर क्लिक करा.', 'Click the button above to add a new donation.'),
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
                itemCount: filteredDonations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final d = filteredDonations[idx];
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
                            Text(d.receiptNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryMaroon)),
                            Text(
                              CurrencyFormatter.format(d.amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(d.donorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${d.date} • ${d.paymentMode} • ${d.purpose}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            IconButton(
                              icon: const Icon(Icons.print, size: 20, color: AppColors.primaryMaroon),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Print Receipt',
                              onPressed: () => PdfService.printDonationReceipt(
                                mandal: repository.mandalProfile,
                                donation: d,
                              ),
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
                    DataColumn(label: Text(AppStrings.tr('पावती क्र.', 'Receipt No'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('तारीख', 'Date'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('देणगीदाराचे नाव', 'Donor Name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('मोबाईल', 'Mobile'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('रक्कम', 'Amount'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('पेमेंट पद्धत', 'Payment Mode'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('हेतू', 'Purpose'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('स्वीकारकर्ता', 'Collector'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('पावती', 'Action'), style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filteredDonations.map((d) {
                    return DataRow(
                      cells: [
                        DataCell(Text(d.receiptNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(d.date)),
                        DataCell(Text(d.donorName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(d.mobile)),
                        DataCell(
                          Text(
                            CurrencyFormatter.format(d.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.borderLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(d.paymentMode, style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        DataCell(Text(d.purpose)),
                        DataCell(Text(d.collectorName)),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.print, size: 18, color: AppColors.primaryMaroon),
                            tooltip: 'Print Donation Receipt PDF',
                            onPressed: () => PdfService.printDonationReceipt(
                              mandal: repository.mandalProfile,
                              donation: d,
                            ),
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
