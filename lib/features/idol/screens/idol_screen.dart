import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../repositories/mandal_repository.dart';

class IdolScreen extends StatefulWidget {
  const IdolScreen({super.key});

  @override
  State<IdolScreen> createState() => _IdolScreenState();
}

class _IdolScreenState extends State<IdolScreen> {
  final repository = MandalRepository();

  @override
  Widget build(BuildContext context) {
    final idol = repository.idolDetails;

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
                Icon(Icons.temple_hindu, color: AppColors.primaryMaroon),
                SizedBox(width: 8),
                Text(
                  'Mataji / Idol Management (Murti Sthapana & Details)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Idol Details Form/Grid
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildDetailRow('Murti Supplier / Sculptor', idol.supplier, Icons.storefront),
                      _buildDetailRow('Total Murti Cost', CurrencyFormatter.format(idol.cost), Icons.currency_rupee, isHighlight: true),
                      _buildDetailRow('Booking Date', idol.bookingDate, Icons.event),
                      _buildDetailRow('Delivery Date', idol.deliveryDate, Icons.local_shipping),
                      _buildDetailRow('Installation (Sthapana) Date', idol.installationDate, Icons.check_circle),
                      _buildDetailRow('Visarjan Date', idol.visarjanDate, Icons.water),
                      _buildDetailRow('Transportation Vehicle', idol.transport, Icons.directions_bus),
                      _buildDetailRow('Visarjan Ghat / Location', idol.location, Icons.location_on),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Photo Preview Box from Screen 17
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.brightGold.withAlpha(100)),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            idol.photoUrl ?? 'https://images.unsplash.com/photo-1601614749377-622f67ec1656?w=600&q=80',
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const SizedBox(
                              height: 250,
                              child: Center(child: Icon(Icons.temple_hindu, size: 64, color: AppColors.primaryMaroon)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Shree Durga Mataji Idol (9 Feet Eco-friendly)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, fontSize: 13),
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

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isHighlight ? AppColors.successGreen : AppColors.primaryMaroon),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isHighlight ? AppColors.successGreen : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
