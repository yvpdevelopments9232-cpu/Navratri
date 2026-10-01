import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/mandal_repository.dart';

class VisarjanScreen extends StatefulWidget {
  const VisarjanScreen({super.key});

  @override
  State<VisarjanScreen> createState() => _VisarjanScreenState();
}

class _VisarjanScreenState extends State<VisarjanScreen> {
  final repository = MandalRepository();

  final Map<String, bool> checklist = {
    'Police Permission & Route Clearance': true,
    'Visarjan Vehicle & Truck Inspection': true,
    'Driver Verification & Contact': true,
    '15 Assigned Visarjan Volunteers': true,
    'Security Team & Barricades': true,
    'Sound System & Mobile Generator': true,
    'Lighting & Focus Searchlights': true,
    'First Aid & Medical Emergency Kit': true,
    'Drinking Water & Refreshments': true,
    'Emergency Contact Coordination': true,
  };

  @override
  Widget build(BuildContext context) {
    final v = repository.visarjanDetails;

    final isMobile = MediaQuery.of(context).size.width < 750;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sailing, color: AppColors.primaryMaroon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Visarjan Management & Procession Route',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Visarjan Details Grid
            if (isMobile)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.1,
                children: [
                  _buildDetailCard('Date', v.date, Icons.calendar_today),
                  _buildDetailCard('Start Time', v.time, Icons.access_time),
                  _buildDetailCard('Route / Ghat', v.route, Icons.route),
                  _buildDetailCard('Vehicle', v.vehicle, Icons.local_shipping),
                  _buildDetailCard('Driver Name', v.driver, Icons.person),
                  _buildDetailCard('Volunteers', '${v.volunteers}', Icons.groups),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildDetailCard('Date', v.date, Icons.calendar_today)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDetailCard('Start Time', v.time, Icons.access_time)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDetailCard('Route / Ghat', v.route, Icons.route)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDetailCard('Vehicle', v.vehicle, Icons.local_shipping)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDetailCard('Driver Name', v.driver, Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDetailCard('Volunteers', '${v.volunteers}', Icons.groups)),
                ],
              ),
            const SizedBox(height: 24),

            // Checklist Card
            const Text(
              'Visarjan Procession Operational Checklist',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: checklist.entries.map((entry) {
                return SizedBox(
                  width: isMobile ? double.infinity : 320,
                  child: CheckboxListTile(
                    value: entry.value,
                    onChanged: (val) {
                      setState(() {
                        checklist[entry.key] = val ?? false;
                      });
                    },
                    title: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    activeColor: AppColors.successGreen,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.borderLight),
                    ),
                    tileColor: const Color(0xFFF8FAFC),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primaryMaroon),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
