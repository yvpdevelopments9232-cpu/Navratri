import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/mandal_repository.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final repository = MandalRepository();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final metrics = [
      {'label': AppStrings.tr('सुरक्षा स्वयंसेवक', 'Security Volunteers'), 'val': '25', 'col': AppColors.expenseRed, 'ico': Icons.security},
      {'label': AppStrings.tr('प्रवेशद्वारे', 'Entry Points'), 'val': '3', 'col': AppColors.infoBlue, 'ico': Icons.door_front_door},
      {'label': AppStrings.tr('पार्किंग जागा', 'Parking Points'), 'val': '2', 'col': AppColors.warningOrange, 'ico': Icons.local_parking},
      {'label': AppStrings.tr('आपत्कालीन पथक', 'Emergency Team'), 'val': '2', 'col': AppColors.purpleAccent, 'ico': Icons.emergency},
      {'label': AppStrings.tr('वैद्यकीय पथक', 'Medical Team'), 'val': '5', 'col': AppColors.successGreen, 'ico': Icons.medical_services},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Management Card
          Container(
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
                Row(
                  children: [
                    const Icon(Icons.shield, color: AppColors.primaryMaroon, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.tr('सुरक्षा व गर्दी नियंत्रण व्यवस्थापन', 'Security & Crowd Control'),
                        style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Top KPI Metrics
                if (isMobile)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: metrics.map((m) {
                      return _buildMetricBadgeBox(
                        m['label'] as String,
                        m['val'] as String,
                        m['col'] as Color,
                        m['ico'] as IconData,
                      );
                    }).toList(),
                  )
                else
                  Row(
                    children: metrics.map((m) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _buildMetricBadgeBox(
                            m['label'] as String,
                            m['val'] as String,
                            m['col'] as Color,
                            m['ico'] as IconData,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Emergency Speed-Dial Contacts
          Container(
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
                Text(
                  AppStrings.tr('आपत्कालीन महत्त्वाचे संपर्क (Speed-Dial)', 'Emergency Speed-Dial Contacts'),
                  style: TextStyle(fontSize: isMobile ? 15 : 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),

                ...repository.securityContacts.map((contact) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.expenseRed.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phone_in_talk, color: AppColors.expenseRed, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contact.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(contact.category, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMaroon,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            contact.contactNumber,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadgeBox(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
