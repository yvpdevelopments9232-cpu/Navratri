import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../widgets/status_badge.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  final repository = MandalRepository();
  String _searchQuery = '';

  void _showAddVendorDialog() {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final serviceCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.storefront, color: AppColors.primaryMaroon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('व्यापारी / कंत्राटदार जोडा', 'Add Vendor'),
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
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.tr('व्यापारी / फर्मचे नाव *', 'Vendor Name *'))),
                const SizedBox(height: 12),
                TextField(controller: serviceCtrl, decoration: InputDecoration(labelText: AppStrings.tr('सेवा प्रकार (उदा. मंडप, ध्वनी, रोषणाई) *', 'Service Type (e.g. Sound, Lighting) *'))),
                const SizedBox(height: 12),
                TextField(controller: contactCtrl, decoration: InputDecoration(labelText: AppStrings.tr('मोबाईल क्रमांक *', 'Contact Mobile *')), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: amountCtrl, decoration: InputDecoration(labelText: AppStrings.tr('करार रक्कम (₹) *', 'Contract Amount (₹) *')), keyboardType: TextInputType.number),
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
              final uniqueCode = 'V-${(DateTime.now().millisecondsSinceEpoch % 90000 + 10000)}';
              Navigator.pop(ctx);
              await repository.addVendor(
                VendorModel(
                  id: '',
                  vendorCode: uniqueCode,
                  vendorName: nameCtrl.text.trim(),
                  serviceType: serviceCtrl.text.trim(),
                  contact: contactCtrl.text.trim(),
                  contractAmount: amt,
                  paidAmount: 0,
                  remainingAmount: amt,
                  status: 'Pending',
                ),
              );
              if (mounted) setState(() {});
            },
            child: Text(AppStrings.tr('जतन करा', 'Save Vendor')),
          ),
        ],
      ),
    );
  }

  void _showEditVendorDialog(VendorModel vendor) {
    final nameCtrl = TextEditingController(text: vendor.vendorName);
    final contactCtrl = TextEditingController(text: vendor.contact);
    final serviceCtrl = TextEditingController(text: vendor.serviceType);
    final amountCtrl = TextEditingController(text: vendor.contractAmount.toStringAsFixed(0));
    final paidCtrl = TextEditingController(text: vendor.paidAmount.toStringAsFixed(0));
    String selectedStatus = vendor.status;

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
                  AppStrings.tr('व्यापारी तपशील बदला', 'Edit Vendor'),
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
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.tr('व्यापारी नाव *', 'Vendor Name *'))),
                  const SizedBox(height: 12),
                  TextField(controller: serviceCtrl, decoration: InputDecoration(labelText: AppStrings.tr('सेवा प्रकार *', 'Service Type *'))),
                  const SizedBox(height: 12),
                  TextField(controller: contactCtrl, decoration: InputDecoration(labelText: AppStrings.tr('मोबाईल क्रमांक *', 'Contact Mobile *')), keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  TextField(controller: amountCtrl, decoration: InputDecoration(labelText: AppStrings.tr('करार रक्कम (₹) *', 'Contract Amount (₹) *')), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  TextField(controller: paidCtrl, decoration: InputDecoration(labelText: AppStrings.tr('अदा रक्कम (₹)', 'Paid Amount (₹)')), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ['Pending', 'Active', 'Completed'].contains(selectedStatus) ? selectedStatus : 'Pending',
                    decoration: InputDecoration(labelText: AppStrings.tr('स्थिती', 'Status')),
                    items: [
                      DropdownMenuItem(value: 'Pending', child: Text(AppStrings.tr('प्रलंबित (Pending)', 'Pending'))),
                      DropdownMenuItem(value: 'Active', child: Text(AppStrings.tr('सक्रिय (Active)', 'Active'))),
                      DropdownMenuItem(value: 'Completed', child: Text(AppStrings.tr('पूर्ण (Completed)', 'Completed'))),
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
                final cAmt = double.tryParse(amountCtrl.text.trim()) ?? vendor.contractAmount;
                final pAmt = double.tryParse(paidCtrl.text.trim()) ?? vendor.paidAmount;
                final rAmt = (cAmt - pAmt) > 0 ? (cAmt - pAmt) : 0.0;
                final updated = vendor.copyWith(
                  vendorName: nameCtrl.text.trim().isEmpty ? vendor.vendorName : nameCtrl.text.trim(),
                  serviceType: serviceCtrl.text.trim().isEmpty ? vendor.serviceType : serviceCtrl.text.trim(),
                  contact: contactCtrl.text.trim().isEmpty ? vendor.contact : contactCtrl.text.trim(),
                  contractAmount: cAmt,
                  paidAmount: pAmt,
                  remainingAmount: rAmt,
                  status: selectedStatus,
                );
                Navigator.pop(ctx);
                await repository.updateVendor(updated);
                if (mounted) setState(() {});
              },
              child: Text(AppStrings.tr('बदल सेव्ह करा', 'Save Changes')),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteVendor(VendorModel vendor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr('व्यापारी काढून टाकायचा आहे का?', 'Delete Vendor?')),
        content: Text(AppStrings.tr(
          'आपण खात्रीपूर्वक "${vendor.vendorName}" यांची नोंद काढून टाकू इच्छिता का?',
          'Are you sure you want to delete vendor "${vendor.vendorName}"?',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('नाही / रद्द करा', 'Cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await repository.deleteVendor(vendor.id);
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

    final filtered = repository.vendors.where((v) {
      final q = _searchQuery.toLowerCase();
      return v.vendorName.toLowerCase().contains(q) || v.serviceType.toLowerCase().contains(q) || v.contact.contains(q);
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
                      const Icon(Icons.storefront, color: AppColors.primaryMaroon, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr('व्यापारी व कंत्राट व्यवस्थापन', 'Vendor Management'),
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
                              hintText: AppStrings.tr('शोधा...', 'Search vendor...'),
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
                        onPressed: _showAddVendorDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.tr('+ जोडा', '+ Add')),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.storefront, color: AppColors.primaryMaroon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.tr('व्यापारी व कंत्राट व्यवस्थापन (Vendors & Contracts)', 'Vendor Management & Contracts'),
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
                        hintText: AppStrings.tr('व्यापारी शोधा...', 'Search vendor...'),
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
                    onPressed: _showAddVendorDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.tr('+ व्यापारी जोडा', '+ Add Vendor')),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text(
                    AppStrings.tr('कोणताही व्यापारी उपलब्ध नाही', 'No vendors found'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else if (isMobile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final v = filtered[idx];
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
                                v.vendorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadge(status: v.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${v.serviceType} | 📞 ${v.contact}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.infoBlue),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showEditVendorDialog(v),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _confirmDeleteVendor(v),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${AppStrings.tr('करार', 'Contract')}: ${CurrencyFormatter.format(v.contractAmount)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            Text('${AppStrings.tr('अदा', 'Paid')}: ${CurrencyFormatter.format(v.paidAmount)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.successGreen, fontWeight: FontWeight.bold)),
                            Text('${AppStrings.tr('शिल्लक', 'Rem')}: ${CurrencyFormatter.format(v.remainingAmount)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.expenseRed, fontWeight: FontWeight.bold)),
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
                    DataColumn(label: Text(AppStrings.tr('व्यापारी नाव', 'Vendor Name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('सेवा प्रकार', 'Service Type'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('संपर्क', 'Contact'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('करार रक्कम', 'Amount'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('अदा रक्कम', 'Paid'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('शिल्लक रक्कम', 'Remaining'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('स्थिती', 'Status'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('क्रिया', 'Action'), style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filtered.map((v) {
                    return DataRow(
                      cells: [
                        DataCell(Text(v.vendorName, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(v.serviceType)),
                        DataCell(Text(v.contact)),
                        DataCell(Text(CurrencyFormatter.format(v.contractAmount), style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(CurrencyFormatter.format(v.paidAmount), style: const TextStyle(color: AppColors.successGreen))),
                        DataCell(Text(CurrencyFormatter.format(v.remainingAmount), style: const TextStyle(color: AppColors.expenseRed))),
                        DataCell(StatusBadge(status: v.status)),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.infoBlue),
                                onPressed: () => _showEditVendorDialog(v),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                                onPressed: () => _confirmDeleteVendor(v),
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
