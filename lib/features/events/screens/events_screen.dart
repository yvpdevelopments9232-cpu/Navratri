import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../services/offline_db_helper.dart';
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
        title: Row(
          children: [
            const Icon(Icons.event_note, color: AppColors.primaryMaroon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('कार्यक्रम जोडा', 'Add Navratri Event'),
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
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.tr('कार्यक्रमाचे नाव *', 'Event Name *'))),
                const SizedBox(height: 12),
                TextField(controller: dateCtrl, decoration: InputDecoration(labelText: AppStrings.tr('तारीख (उदा. 20 Sep 2026)', 'Date (e.g. 20 Sep 2026)'))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startCtrl, decoration: InputDecoration(labelText: AppStrings.tr('सुरू होण्याची वेळ', 'Start Time')))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: endCtrl, decoration: InputDecoration(labelText: AppStrings.tr('समाप्ती वेळ', 'End Time')))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: venueCtrl, decoration: InputDecoration(labelText: AppStrings.tr('ठिकाण', 'Venue'))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('रद्द करा', 'Cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final newEvent = EventModel(
                id: OfflineDbHelper.generateId(),
                eventName: nameCtrl.text.trim(),
                date: dateCtrl.text.trim(),
                startTime: startCtrl.text.trim(),
                endTime: endCtrl.text.trim(),
                venue: venueCtrl.text.trim(),
                status: 'Upcoming',
              );
              Navigator.pop(ctx);
              await repository.addEvent(newEvent);
              setState(() {});
            },
            child: Text(AppStrings.tr('जतन करा', 'Save Event')),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(EventModel event) {
    final nameCtrl = TextEditingController(text: event.eventName);
    final dateCtrl = TextEditingController(text: event.date);
    final venueCtrl = TextEditingController(text: event.venue);
    final startCtrl = TextEditingController(text: event.startTime);
    final endCtrl = TextEditingController(text: event.endTime);
    String selectedStatus = event.status;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: AppColors.infoBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.tr('कार्यक्रम बदला', 'Edit Event'),
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
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.tr('कार्यक्रमाचे नाव *', 'Event Name *'))),
                const SizedBox(height: 12),
                TextField(controller: dateCtrl, decoration: InputDecoration(labelText: AppStrings.tr('तारीख (उदा. 20 Sep 2026)', 'Date (e.g. 20 Sep 2026)'))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startCtrl, decoration: InputDecoration(labelText: AppStrings.tr('सुरू होण्याची वेळ', 'Start Time')))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: endCtrl, decoration: InputDecoration(labelText: AppStrings.tr('समाप्ती वेळ', 'End Time')))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: venueCtrl, decoration: InputDecoration(labelText: AppStrings.tr('ठिकाण', 'Venue'))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: AppStrings.tr('स्थिती', 'Status')),
                  items: ['Upcoming', 'Completed', 'Live']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedStatus = val;
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
              if (nameCtrl.text.trim().isEmpty) return;
              final updated = event.copyWith(
                eventName: nameCtrl.text.trim(),
                date: dateCtrl.text.trim(),
                startTime: startCtrl.text.trim(),
                endTime: endCtrl.text.trim(),
                venue: venueCtrl.text.trim(),
                status: selectedStatus,
              );
              Navigator.pop(ctx);
              await repository.updateEvent(updated);
              setState(() {});
            },
            child: Text(AppStrings.tr('बदल सेव्ह करा', 'Save Changes')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEvent(EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr('कार्यक्रम काढून टाकायचा आहे का?', 'Delete Event?')),
        content: Text(AppStrings.tr(
          'आपण खात्रीपूर्वक "${event.eventName}" कार्यक्रम काढून टाकू इच्छिता का?',
          'Are you sure you want to delete event "${event.eventName}"?',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('नाही / रद्द करा', 'Cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await repository.deleteEvent(event.id);
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
                      const Icon(Icons.event_available, color: AppColors.primaryMaroon, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr('उत्सव कार्यक्रम वेळापत्रक', 'Events Schedule'),
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
                      onPressed: _showAddEventDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(AppStrings.tr('+ कार्यक्रम जोडा', '+ Add Event')),
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
                        const Icon(Icons.event_available, color: AppColors.primaryMaroon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.tr('उत्सव कार्यक्रम वेळापत्रक (१० दिवसीय उत्सव)', 'Navratri Events (10-Day Festival Schedule)'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddEventDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppStrings.tr('+ कार्यक्रम जोडा', '+ Add Event')),
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
                      Text(
                        AppStrings.tr('कोणताही कार्यक्रम नोंदवलेला नाही', 'No events scheduled'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.tr('नवीन कार्यक्रम जोडण्यासाठी वरील "+ कार्यक्रम जोडा" बटनावर क्लिक करा.', 'Click "+ Add Event" above to schedule festival programs.'),
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
                itemCount: repository.events.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final e = repository.events[idx];
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
                            Text(e.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
                            StatusBadge(status: e.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(e.eventName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryMaroon)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('⏰ ${e.startTime} - ${e.endTime} | 📍 ${e.venue}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.infoBlue),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: AppStrings.tr('माहिती बदला', 'Edit'),
                                  onPressed: () => _showEditEventDialog(e),
                                ),
                                const SizedBox(width: 14),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: AppStrings.tr('काढून टाका', 'Delete'),
                                  onPressed: () => _confirmDeleteEvent(e),
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
                    DataColumn(label: Text(AppStrings.tr('तारीख', 'Date'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('कार्यक्रमाचे नाव', 'Event Name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('ठिकाण', 'Venue'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('वेळ', 'Timings'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('स्थिती', 'Status'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppStrings.tr('क्रिया', 'Action'), style: const TextStyle(fontWeight: FontWeight.bold))),
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
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: AppColors.infoBlue),
                                tooltip: AppStrings.tr('माहिती बदला', 'Edit'),
                                onPressed: () => _showEditEventDialog(e),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: AppColors.expenseRed),
                                tooltip: AppStrings.tr('काढून टाका', 'Delete'),
                                onPressed: () => _confirmDeleteEvent(e),
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
