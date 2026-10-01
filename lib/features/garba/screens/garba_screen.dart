import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';

class GarbaScreen extends StatefulWidget {
  const GarbaScreen({super.key});

  @override
  State<GarbaScreen> createState() => _GarbaScreenState();
}

class _GarbaScreenState extends State<GarbaScreen> {
  final repository = MandalRepository();
  String _searchQuery = '';

  void _showPassModal(GarbaParticipantModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryMaroon,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'GARBA NIGHT ENTRY PASS',
                    style: TextStyle(color: AppColors.brightGold, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 170,
                height: 170,
                child: QrImageView(
                  data: 'PASS:${p.regNumber}|${p.name}|${p.mobile}',
                  version: QrVersions.auto,
                  size: 170.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              Text('Pass No: ${p.regNumber} • ${p.gender} / ${p.age} yrs', style: const TextStyle(color: AppColors.textSecondary)),
              Text('Fee Paid: ${CurrencyFormatter.format(p.amount)}', style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('बंद करा', 'Close'))),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.tr('पास प्रिंट करत आहे...', 'Printing QR Pass...'))));
            },
            icon: const Icon(Icons.print, size: 16),
            label: Text(AppStrings.tr('पास प्रिंट', 'Print Pass')),
          ),
        ],
      ),
    );
  }

  void _showAddRegistrationDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: '22');
    String selectedGender = 'F';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.nightlife, color: AppColors.primaryMaroon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('गरबा / दांडिया नोंदणी', 'Garba / Dandiya Registration'),
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
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.tr('स्पर्धक / पासधारकाचे नाव *', 'Participant Name *'))),
                const SizedBox(height: 12),
                TextField(controller: mobileCtrl, decoration: InputDecoration(labelText: AppStrings.tr('मोबाईल क्रमांक *', 'Mobile Number *')), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: ageCtrl, decoration: InputDecoration(labelText: AppStrings.tr('वय', 'Age')), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedGender,
                        decoration: InputDecoration(labelText: AppStrings.tr('लिंग', 'Gender')),
                        items: const [
                          DropdownMenuItem(value: 'F', child: Text('Female (महिला)')),
                          DropdownMenuItem(value: 'M', child: Text('Male (पुरुष)')),
                        ],
                        onChanged: (val) {
                          if (val != null) selectedGender = val;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '₹ 200.00 (Standard Entry Fee)',
                  readOnly: true,
                  decoration: InputDecoration(labelText: AppStrings.tr('प्रवेश फी', 'Registration Fee')),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('रद्द करा', 'Cancel'))),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) return;
              final newP = GarbaParticipantModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                regNumber: 'REG-${100 + repository.participants.length + 1}',
                name: nameCtrl.text.trim(),
                mobile: mobileCtrl.text.trim(),
                age: int.tryParse(ageCtrl.text.trim()) ?? 20,
                gender: selectedGender,
                amount: 200,
                status: 'Active',
              );
              repository.participants.insert(0, newP);
              Navigator.pop(ctx);
              setState(() {});
              _showPassModal(newP);
            },
            child: Text(AppStrings.tr('नोंदणी करा व पास द्या', 'Register & Generate Pass')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final filtered = repository.participants.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.mobile.contains(q) || p.regNumber.toLowerCase().contains(q);
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
                      const Icon(Icons.nightlife, color: AppColors.primaryMaroon, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr('गरबा व दांडिया नोंदणी', 'Garba / Dandiya'),
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
                              hintText: AppStrings.tr('शोधा...', 'Search participant...'),
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
                        onPressed: _showAddRegistrationDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.tr('+ पास', '+ Add')),
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
                  const Icon(Icons.nightlife, color: AppColors.primaryMaroon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.tr('गरबा व दांडिया नोंदणी (Garba / Dandiya Passes)', 'Garba / Dandiya Participants'),
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
                        hintText: AppStrings.tr('नाव / पास क्र. शोधा...', 'Search participant...'),
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
                    onPressed: _showAddRegistrationDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.tr('+ नवीन नोंदणी', '+ Add Registration')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text(
                    AppStrings.tr('कोणतीही नोंदणी आढळली नाही', 'No participants found'),
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
                  final p = filtered[idx];
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
                            Text(p.regNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryMaroon)),
                            Text(
                              CurrencyFormatter.format(p.amount),
                              style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('📞 ${p.mobile} • ${p.gender}/${p.age} yrs', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.qr_code, size: 20, color: AppColors.primaryMaroon),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'QR Pass',
                                  onPressed: () => _showPassModal(p),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    repository.participants.removeWhere((item) => item.id == p.id);
                                    setState(() {});
                                  },
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
                    DataColumn(label: Text(AppStrings.tr('पास क्र.', 'Pass No.'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('नाव', 'Name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('मोबाईल', 'Mobile'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('वय', 'Age'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('लिंग', 'Gender'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('शुल्क', 'Amount'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('क्रिया', 'Action'), style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filtered.map((p) {
                    return DataRow(
                      cells: [
                        DataCell(Text(p.regNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(p.mobile)),
                        DataCell(Text('${p.age}')),
                        DataCell(Text(p.gender)),
                        DataCell(
                          Text(
                            CurrencyFormatter.format(p.amount),
                            style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code, size: 20, color: AppColors.primaryMaroon),
                                tooltip: 'View QR Pass',
                                onPressed: () => _showPassModal(p),
                              ),
                              IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue), onPressed: () {}),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                                onPressed: () {
                                  repository.participants.removeWhere((item) => item.id == p.id);
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
