import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../widgets/status_badge.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final repository = MandalRepository();

  void _showAddEventDialog() {
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: '20 Sep 2026');
    final venueCtrl = TextEditingController(text: 'Mandal Ground');
    final startCtrl = TextEditingController(text: '07:00 PM');
    final endCtrl = TextEditingController(text: '11:00 PM');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.event_note, color: AppColors.primaryMaroon),
            SizedBox(width: 8),
            Text('Add Navratri Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Event Name *')),
                const SizedBox(height: 12),
                TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (e.g. 20 Sep 2026)')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time'))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'Venue')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              repository.events.add(
                EventModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  eventName: nameCtrl.text.trim(),
                  date: dateCtrl.text.trim(),
                  startTime: startCtrl.text.trim(),
                  endTime: endCtrl.text.trim(),
                  venue: venueCtrl.text.trim(),
                  status: 'Upcoming',
                ),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save Event'),
          ),
        ],
      ),
    );
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_available, color: AppColors.primaryMaroon),
                    SizedBox(width: 8),
                    Text(
                      'Navratri Events (10-Day Festival Schedule)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddEventDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Event'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (repository.events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.event_busy_outlined, size: 54, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text(
                        'कोणताही कार्यक्रम नोंदवलेला नाही (No events scheduled)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'नवीन कार्यक्रम जोडण्यासाठी वरील "+ Add Event" बटनावर क्लिक करा.',
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
                    DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Event Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Venue', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Timings', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: repository.events.map((e) {
                    return DataRow(
                      cells: [
                        DataCell(Text(e.date, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(e.eventName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon))),
                        DataCell(Text(e.venue)),
                        DataCell(Text('${e.startTime} - ${e.endTime}')),
                        DataCell(StatusBadge(status: e.status)),
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
    );
  }
}
