import 'package:flutter/material.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/mandal_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final repository = MandalRepository();
  String selectedReport = 'Donation Report';

  final List<String> financialReports = [
    'Donation Report',
    'Expense Report',
    'Cash Book',
    'Bank Book',
    'Income & Expense',
    'Balance Sheet',
    'Pending Payment Report',
  ];

  final List<String> festivalReports = [
    'Event Report',
    'Member Report',
    'Volunteer Report',
    'Vendor Report',
    'Sponsorship Report',
    'Inventory Report',
    'Registration Report',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primaryMaroon),
                SizedBox(width: 8),
                Text(
                  'Reports & Financial Auditing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Two Column Lists: Financial Reports & Festival Reports matching Screen 19
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Financial Reports
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Financial Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Divider(),
                        ...financialReports.map((r) {
                          final isSel = selectedReport == r;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.description_outlined,
                              size: 18,
                              color: isSel ? AppColors.primaryMaroon : AppColors.textSecondary,
                            ),
                            title: Text(
                              r,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? AppColors.primaryMaroon : AppColors.textPrimary,
                              ),
                            ),
                            trailing: isSel ? const Icon(Icons.check_circle, size: 16, color: AppColors.primaryMaroon) : null,
                            onTap: () => setState(() => selectedReport = r),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Festival Reports
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Festival Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Divider(),
                        ...festivalReports.map((r) {
                          final isSel = selectedReport == r;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.insert_chart_outlined,
                              size: 18,
                              color: isSel ? AppColors.primaryMaroon : AppColors.textSecondary,
                            ),
                            title: Text(
                              r,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? AppColors.primaryMaroon : AppColors.textPrimary,
                              ),
                            ),
                            trailing: isSel ? const Icon(Icons.check_circle, size: 16, color: AppColors.primaryMaroon) : null,
                            onTap: () => setState(() => selectedReport = r),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Filter & Action Panel
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Filter & Generate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Divider(),
                        const TextField(
                          decoration: InputDecoration(labelText: 'From Date', hintText: '01-09-2026', prefixIcon: Icon(Icons.calendar_today, size: 16)),
                        ),
                        const SizedBox(height: 10),
                        const TextField(
                          decoration: InputDecoration(labelText: 'To Date', hintText: '30-09-2026', prefixIcon: Icon(Icons.calendar_today, size: 16)),
                        ),
                        const SizedBox(height: 10),
                        const TextField(
                          decoration: InputDecoration(labelText: 'Category', hintText: 'All Categories', prefixIcon: Icon(Icons.filter_list, size: 16)),
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons: View, Print, PDF, Excel matching Screen 19
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Viewing $selectedReport...')),
                                  );
                                },
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text('View'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => PdfService.printFinancialReport(
                                  mandal: repository.mandalProfile,
                                  donations: repository.donations,
                                  expenses: repository.expenses,
                                ),
                                icon: const Icon(Icons.picture_as_pdf, size: 16),
                                label: const Text('PDF'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => PdfService.printFinancialReport(
                                  mandal: repository.mandalProfile,
                                  donations: repository.donations,
                                  expenses: repository.expenses,
                                ),
                                icon: const Icon(Icons.print, size: 16),
                                label: const Text('Print'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Exporting $selectedReport to Excel...')),
                                  );
                                },
                                icon: const Icon(Icons.table_view, size: 16),
                                label: const Text('Excel'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
