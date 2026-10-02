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
    String selectedPurpose = 'सदस्य वर्गणी (Member Contribution)';
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
        builder: (context, setModalState) {
          final isMobile = MediaQuery.of(context).size.width < 600;

          Widget buildFieldRow({required Widget first, required Widget second}) {
            if (isMobile) {
              return Column(
                children: [
                  first,
                  const SizedBox(height: 12),
                  second,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: first),
                const SizedBox(width: 12),
                Expanded(child: second),
              ],
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    // Member quick picker button
                    if (repository.members.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryMaroon,
                            side: const BorderSide(color: AppColors.primaryMaroon),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.person_search, size: 16),
                          label: Text(AppStrings.tr('नोंदणीकृत सदस्यांमधून निवडा', 'Select from Registered Members')),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (bCtx) => Container(
                                padding: const EdgeInsets.all(16),
                                constraints: const BoxConstraints(maxHeight: 400),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.tr('सदस्य निवडा (ऑटो-फिल)', 'Select Member (Auto-fill)'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryMaroon),
                                    ),
                                    const Divider(),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: repository.members.length,
                                        itemBuilder: (_, mIdx) {
                                          final mem = repository.members[mIdx];
                                          return ListTile(
                                            leading: const CircleAvatar(
                                              backgroundColor: AppColors.primaryMaroon,
                                              child: Icon(Icons.person, color: Colors.white, size: 18),
                                            ),
                                            title: Text(mem.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            subtitle: Text('${mem.memberCode} • ${mem.role} • ${mem.mobile}'),
                                            onTap: () {
                                              setModalState(() {
                                                nameCtrl.text = mem.fullName;
                                                mobileCtrl.text = mem.mobile;
                                                if (mem.address != null && mem.address!.isNotEmpty) {
                                                  addressCtrl.text = mem.address!;
                                                }
                                                selectedPurpose = 'सदस्य वर्गणी (Member Contribution)';
                                              });
                                              Navigator.pop(bCtx);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    buildFieldRow(
                      first: TextFormField(
                        initialValue: nextReceiptNo,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.tr('पावती क्र.', 'Receipt No.'),
                          prefixIcon: const Icon(Icons.tag),
                        ),
                      ),
                      second: TextField(
                        controller: dateCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.tr('तारीख', 'Date'),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildFieldRow(
                      first: TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.tr('देणगीदाराचे नाव *', 'Donor Name *'),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      second: TextField(
                        controller: mobileCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.tr('मोबाईल नंबर', 'Mobile No.'),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('पत्ता / गाव', 'Address'),
                        prefixIcon: const Icon(Icons.home),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('रक्कम (₹) *', 'Amount (₹) *'),
                        prefixIcon: const Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppStrings.tr('पैसे भरण्याची पद्धत', 'Payment Mode'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        {'key': 'Cash', 'label': AppStrings.tr('रोख (Cash)', 'Cash')},
                        {'key': 'UPI', 'label': AppStrings.tr('UPI / QR', 'UPI')},
                        {'key': 'Bank Transfer', 'label': AppStrings.tr('बँक ट्रान्सफर', 'Bank Transfer')},
                        {'key': 'Cheque', 'label': AppStrings.tr('धनादेश (Cheque)', 'Cheque')},
                        {'key': 'Other', 'label': AppStrings.tr('इतर', 'Other')},
                      ].map((item) {
                        final mode = item['key']!;
                        final label = item['label']!;
                        final isSelected = selectedMode == mode;
                        return ChoiceChip(
                          label: Text(label),
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
                    buildFieldRow(
                      first: DropdownButtonFormField<String>(
                        initialValue: selectedPurpose,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.tr('हेतू / वर्गणी प्रकार', 'Purpose'),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'सदस्य वर्गणी (Member Contribution)',
                            child: Text(AppStrings.tr('सदस्य वर्गणी (Member Contribution)', 'Member Contribution'), overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'Festival Donation',
                            child: Text(AppStrings.tr('उत्सव देणगी (Festival Donation)', 'Festival Donation'), overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'Aarti Donation',
                            child: Text(AppStrings.tr('आरती देणगी (Aarti Donation)', 'Aarti Donation'), overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'Mahaprasad Fund',
                            child: Text(AppStrings.tr('महाप्रसाद निधी (Mahaprasad Fund)', 'Mahaprasad Fund'), overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'Idol Sthapana',
                            child: Text(AppStrings.tr('मूर्ती स्थापना निधी (Idol Sthapana)', 'Idol Sthapana'), overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'Sponsorship',
                            child: Text(AppStrings.tr('जाहिरात / प्रायोजकत्व', 'Sponsorship'), overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'Other Donation',
                            child: Text(AppStrings.tr('इतर देणगी (Other Donation)', 'Other Donation'), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) selectedPurpose = val;
                        },
                      ),
                      second: DropdownButtonFormField<String>(
                        initialValue: selectedCollector,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.tr('पावती पुस्तक / जमाकर्ता', 'Collector Name'),
                        ),
                        items: collectorList
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) selectedCollector = val;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('विशेष नोंद / शेरा', 'Notes'),
                        hintText: AppStrings.tr('सहकार्याबद्दल धन्यवाद.', 'Thank you for your support.'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  AppStrings.tr('रद्द करा', 'Cancel'),
                  style: const TextStyle(color: AppColors.expenseRed, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
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
                        content: Text(AppStrings.tr(
                          'पावती ${newDonation.receiptNumber} यशस्वीरित्या नोंदवली गेली!',
                          'Donation ${newDonation.receiptNumber} recorded successfully!',
                        )),
                        action: SnackBarAction(
                          label: AppStrings.tr('प्रिंट पावती', 'Print Receipt'),
                          textColor: AppColors.brightGold,
                          onPressed: () => PdfService.printDonationReceipt(
                            mandal: repository.mandalProfile,
                            donation: newDonation,
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  AppStrings.tr('देणगी जतन करा', 'Save Donation'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDonationDialog(DonationModel donation) {
    final dateCtrl = TextEditingController(text: donation.date);
    final nameCtrl = TextEditingController(text: donation.donorName);
    final mobileCtrl = TextEditingController(text: donation.mobile);
    final addressCtrl = TextEditingController(text: donation.address);
    final amountCtrl = TextEditingController(text: donation.amount.toStringAsFixed(0));
    final notesCtrl = TextEditingController(text: donation.notes ?? '');
    String selectedMode = donation.paymentMode;
    String selectedPurpose = donation.purpose;
    String selectedCollector = donation.collectorName;

    final collectorList = [
      'Sonu nikole',
      'Rajesh Patel',
      'Sunil Mehta',
      'Pooja Sharma',
      'Anil Desai',
      'Neha Joshi',
      if (repository.mandalProfile.authorizedSignatoryName.isNotEmpty)
        repository.mandalProfile.authorizedSignatoryName,
    ].toSet().toList();

    if (!collectorList.contains(selectedCollector)) {
      collectorList.add(selectedCollector);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isMobileDialog = MediaQuery.of(context).size.width < 600;

          Widget buildFieldRow(Widget left, Widget right) {
            if (isMobileDialog) {
              return Column(
                children: [
                  left,
                  const SizedBox(height: 12),
                  right,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: left),
                const SizedBox(width: 12),
                Expanded(child: right),
              ],
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.infoBlue.withAlpha(20), shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: AppColors.infoBlue, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppStrings.tr('देणगी पावती बदला', 'Edit Donation')} (${donation.receiptNumber})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildFieldRow(
                      TextField(
                        controller: dateCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.tr('तारीख *', 'Date *'),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                      ),
                      TextField(
                        controller: amountCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.tr('रक्कम (₹) *', 'Amount (₹) *'),
                          prefixIcon: const Icon(Icons.currency_rupee),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildFieldRow(
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.tr('देणगीदाराचे नाव *', 'Donor Name *'),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      TextField(
                        controller: mobileCtrl,
                        decoration: InputDecoration(
                          labelText: AppStrings.tr('मोबाईल नंबर', 'Mobile Number'),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('पत्ता / गाव', 'Address'),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildFieldRow(
                      DropdownButtonFormField<String>(
                        initialValue: selectedMode,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.tr('पेमेंट पद्धत', 'Payment Mode'),
                          prefixIcon: const Icon(Icons.payments),
                        ),
                        items: ['Cash', 'UPI / QR', 'Bank Transfer', 'Cheque']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedMode = val);
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPurpose,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.tr('हेतू / कारण', 'Purpose'),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: [
                          'सदस्य वर्गणी (Member Contribution)',
                          'Festival Donation',
                          'Maha Aarti',
                          'Garba Pass',
                          'Prasad Seva',
                          'General',
                        ].map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedPurpose = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCollector,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('स्वीकारकर्ता (Collector)', 'Collector'),
                        prefixIcon: const Icon(Icons.badge),
                      ),
                      items: collectorList
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) selectedCollector = val;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('विशेष नोंद / शेरा', 'Notes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  AppStrings.tr('रद्द करा', 'Cancel'),
                  style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.infoBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () async {
                  final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                  if (nameCtrl.text.trim().isEmpty || amt <= 0) return;

                  final messenger = ScaffoldMessenger.of(context);
                  final updatedDonation = donation.copyWith(
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

                  Navigator.pop(ctx);
                  await repository.updateDonation(updatedDonation);

                  if (mounted) {
                    setState(() {});
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.tr(
                          'पावती ${donation.receiptNumber} यशस्वीरित्या अद्ययावत केली!',
                          'Receipt ${donation.receiptNumber} updated successfully!',
                        )),
                        backgroundColor: AppColors.infoBlue,
                      ),
                    );
                  }
                },
                child: Text(
                  AppStrings.tr('बदल सेव्ह करा', 'Save Changes'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteDonation(DonationModel donation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr('देणगी पावती काढून टाकायची आहे का?', 'Delete Donation Receipt?')),
        content: Text(AppStrings.tr(
          'आपण खात्रीपूर्वक पावती क्र. "${donation.receiptNumber}" (${donation.donorName} - ₹${donation.amount.toInt()}) काढून टाकू इच्छिता का?',
          'Are you sure you want to delete receipt "${donation.receiptNumber}" (${donation.donorName} - ₹${donation.amount.toInt()})?',
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
              await repository.deleteDonation(donation.id);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.tr('देणगी नोंद यशस्वीरित्या काढून टाकली!', 'Donation receipt deleted successfully!')),
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
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.print, size: 20, color: AppColors.primaryMaroon),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: AppStrings.tr('पावती प्रिंट करा', 'Print Receipt'),
                                  onPressed: () => PdfService.printDonationReceipt(
                                    mandal: repository.mandalProfile,
                                    donation: d,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.infoBlue),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: AppStrings.tr('बदला', 'Edit'),
                                  onPressed: () => _showEditDonationDialog(d),
                                ),
                                const SizedBox(width: 14),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.expenseRed),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: AppStrings.tr('काढून टाका', 'Delete'),
                                  onPressed: () => _confirmDeleteDonation(d),
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
                    DataColumn(label: Text(AppStrings.tr('पावती क्र.', 'Receipt No'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('तारीख', 'Date'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('देणगीदाराचे नाव', 'Donor Name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('मोबाईल', 'Mobile'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('रक्कम', 'Amount'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('पेमेंट पद्धत', 'Payment Mode'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('हेतू', 'Purpose'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('स्वीकारकर्ता', 'Collector'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('क्रिया', 'Action'), style: const TextStyle(fontWeight: FontWeight.bold))),
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.print, size: 18, color: AppColors.primaryMaroon),
                                tooltip: AppStrings.tr('पावती प्रिंट करा', 'Print Receipt'),
                                onPressed: () => PdfService.printDonationReceipt(
                                  mandal: repository.mandalProfile,
                                  donation: d,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue),
                                tooltip: AppStrings.tr('बदला', 'Edit'),
                                onPressed: () => _showEditDonationDialog(d),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                                tooltip: AppStrings.tr('काढून टाका', 'Delete'),
                                onPressed: () => _confirmDeleteDonation(d),
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
