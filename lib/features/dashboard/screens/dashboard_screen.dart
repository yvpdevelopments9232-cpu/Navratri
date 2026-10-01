import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final repository = MandalRepository();

  @override
  Widget build(BuildContext context) {
    final summary = repository.getSummary();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final isMobile = MediaQuery.of(context).size.width < 750;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 20 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Header Title & Action Buttons
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repository.mandalProfile.name.isNotEmpty
                      ? repository.mandalProfile.name
                      : AppStrings.appName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryMaroon,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onNavigate(2), // Navigate to Donations
                        icon: const Icon(Icons.add, size: 15),
                        label: Text(
                          AppStrings.tr('देणगी जमा', 'Add Donation'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onNavigate(3), // Navigate to Expenses
                        icon: const Icon(Icons.receipt, size: 15),
                        label: Text(
                          AppStrings.tr('खर्च नोंद', 'Add Expense'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMaroon,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    repository.mandalProfile.name.isNotEmpty
                        ? repository.mandalProfile.name
                        : AppStrings.appName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMaroon,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => widget.onNavigate(2),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(AppStrings.tr('देणगी जमा', 'Add Donation')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => widget.onNavigate(3),
                      icon: const Icon(Icons.receipt, size: 16),
                      label: Text(AppStrings.tr('खर्च नोंद', 'Add Expense')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),

          // 6 Top Summary KPI Cards (Responsive Aspect Ratio prevents any bleeding)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1100
                  ? 6
                  : constraints.maxWidth > 750
                      ? 3
                      : 2;
              final childAspectRatio = constraints.maxWidth > 1100
                  ? 1.7
                  : constraints.maxWidth > 750
                      ? 1.45
                      : 1.22;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: childAspectRatio,
                children: [
                  SummaryCard(
                    title: AppStrings.totalDonations,
                    value: CurrencyFormatter.format(summary.totalDonation),
                    icon: Icons.currency_rupee,
                    color: AppColors.successGreen,
                  ),
                  SummaryCard(
                    title: AppStrings.totalExpenses,
                    value: CurrencyFormatter.format(summary.totalExpense),
                    icon: Icons.shopping_bag_outlined,
                    color: AppColors.expenseRed,
                  ),
                  SummaryCard(
                    title: AppStrings.currentBalance,
                    value: CurrencyFormatter.format(summary.currentBalance),
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF0D9488),
                  ),
                  SummaryCard(
                    title: AppStrings.activeMembers,
                    value: '${summary.totalMembers}',
                    icon: Icons.people_outline,
                    color: AppColors.infoBlue,
                  ),
                  SummaryCard(
                    title: AppStrings.totalVolunteers,
                    value: '${summary.totalVolunteers}',
                    icon: Icons.groups_outlined,
                    color: AppColors.cyanAccent,
                  ),
                  SummaryCard(
                    title: AppStrings.upcomingEvents,
                    value: '${summary.upcomingEvents}',
                    icon: Icons.event_available_outlined,
                    color: AppColors.warningOrange,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Middle Row: Donation vs Expense Chart & Today's Summary & Upcoming Events
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildChartCard()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildRightSidePanels(summary)),
              ],
            )
          else
            Column(
              children: [
                _buildChartCard(),
                const SizedBox(height: 16),
                _buildRightSidePanels(summary),
              ],
            ),

          const SizedBox(height: 20),

          // Recent Transactions Table matching Screen 1
          _buildRecentTransactionsCard(),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final now = DateTime.now();
    final List<BarChartGroupData> groups = [];
    final List<String> dayLabels = [];
    double maxVal = 10;

    for (int i = 0; i < 7; i++) {
      final targetDate = now.subtract(Duration(days: 6 - i));
      final dStr1 = '${targetDate.day.toString().padLeft(2, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.year}';
      final dStr2 = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

      final dTotal = repository.donations
          .where((d) => d.date == dStr1 || d.date == dStr2)
          .fold<double>(0.0, (sum, d) => sum + d.amount) / 1000.0;
      final eTotal = repository.expenses
          .where((e) => e.date == dStr1 || e.date == dStr2)
          .fold<double>(0.0, (sum, e) => sum + e.amount) / 1000.0;

      if (dTotal > maxVal) maxVal = dTotal;
      if (eTotal > maxVal) maxVal = eTotal;

      dayLabels.add('${targetDate.day}/${targetDate.month}');
      groups.add(_makeBarGroup(i, dTotal, eTotal));
    }

    return Container(
      height: 330,
      padding: const EdgeInsets.all(18),
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
                'Donation vs Expense (Daily)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  _chartLegend('Donation', AppColors.successGreen),
                  const SizedBox(width: 12),
                  _chartLegend('Expense', AppColors.expenseRed),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxVal * 1.25).ceilToDouble(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() >= 0 && val.toInt() < dayLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(dayLabels[val.toInt()], style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) {
                        return Text('${val.toInt()}k', style: const TextStyle(fontSize: 9));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: groups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double don, double exp) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: don, color: AppColors.successGreen, width: 9, borderRadius: BorderRadius.circular(3)),
        BarChartRodData(toY: exp, color: AppColors.expenseRed, width: 9, borderRadius: BorderRadius.circular(3)),
      ],
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildRightSidePanels(DashboardSummary summary) {
    return Column(
      children: [
        // Today's Collection & Expenses Cards matching Screen 1
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Collection", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(summary.todayCollection),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Expenses", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(summary.todayExpenses),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.expenseRed),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Upcoming Events Panel matching Screen 1
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigate(5), // Navigate to Events
                    child: const Text('View All', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (repository.events.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'कोणताही आगामी कार्यक्रम नाही (No upcoming events)',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...repository.events.take(3).map(
                      (ev) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.event, color: AppColors.primaryMaroon, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ev.eventName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                  Text('${ev.date} • ${ev.startTime}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F0FE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                ev.status,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF1967D2), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigate(2), // Navigate to Donations
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (repository.donations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined, size: 44, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    const Text(
                      'कोणतीही देणगी नोंद उपलब्ध नाही (No donation records found)',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'नवीन देणगी जोडण्यासाठी वरील + Add Donation बटनावर क्लिक करा',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Receipt No', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Donor Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Mode', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: repository.donations.take(4).map((d) {
                  return DataRow(
                    cells: [
                      DataCell(Text(d.receiptNumber, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(d.donorName)),
                      DataCell(Text(CurrencyFormatter.format(d.amount),
                          style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w600))),
                      DataCell(Text(d.date)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(d.paymentMode, style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 18, color: AppColors.infoBlue),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.print, size: 18, color: AppColors.primaryMaroon),
                              onPressed: () {},
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
    );
  }
}
