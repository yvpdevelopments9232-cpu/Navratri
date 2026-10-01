import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
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

  Widget _buildIdolPhoto(String? photoUrl, double height) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image') || (photoUrl.length > 200 && !photoUrl.startsWith('http'))) {
        try {
          final clean = photoUrl.contains(',') ? photoUrl.split(',').last : photoUrl;
          final bytes = base64Decode(clean);
          return Image.memory(
            bytes,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallbackPhoto(height),
          );
        } catch (_) {}
      } else if (photoUrl.startsWith('assets/')) {
        return Image.asset(
          photoUrl,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackPhoto(height),
        );
      } else if (photoUrl.startsWith('http')) {
        return Image.network(
          photoUrl,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackPhoto(height),
        );
      }
    }
    return _buildFallbackPhoto(height);
  }

  Widget _buildFallbackPhoto(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFFFF9E6),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/app_logo.png',
        width: 100,
        height: 100,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(
          Icons.temple_hindu,
          size: 64,
          color: AppColors.primaryMaroon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idol = repository.idolDetails;
    final isMobile = MediaQuery.of(context).size.width < 750;

    final detailsColumn = Column(
      children: [
        _buildDetailRow(
          AppStrings.tr('मूर्तिकार / पुरवठादार', 'Murti Sculptor / Supplier'),
          idol.supplier,
          Icons.storefront,
        ),
        _buildDetailRow(
          AppStrings.tr('एकूण मूर्ती खर्च', 'Total Murti Cost'),
          CurrencyFormatter.format(idol.cost),
          Icons.currency_rupee,
          isHighlight: true,
        ),
        _buildDetailRow(
          AppStrings.tr('मूर्ती बुकिंग तारीख', 'Booking Date'),
          idol.bookingDate,
          Icons.event,
        ),
        _buildDetailRow(
          AppStrings.tr('आगमन / डिलिव्हरी तारीख', 'Delivery Date'),
          idol.deliveryDate,
          Icons.local_shipping,
        ),
        _buildDetailRow(
          AppStrings.tr('मूर्ती स्थापना तारीख', 'Installation Date'),
          idol.installationDate,
          Icons.check_circle,
        ),
        _buildDetailRow(
          AppStrings.tr('विसर्जन तारीख', 'Visarjan Date'),
          idol.visarjanDate,
          Icons.water,
        ),
        _buildDetailRow(
          AppStrings.tr('वाहतूक वाहन', 'Transport Vehicle'),
          idol.transport,
          Icons.directions_bus,
        ),
        _buildDetailRow(
          AppStrings.tr('विसर्जन घाट / ठिकाण', 'Visarjan Ghat / Location'),
          idol.location,
          Icons.location_on,
        ),
      ],
    );

    final photoCard = Container(
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
            child: _buildIdolPhoto(idol.photoUrl, isMobile ? 200 : 250),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.tr(
              'श्री दुर्गा माताजी मूर्ती (पर्यावरणपूरक ९ फूट)',
              'Shree Durga Mataji Idol (9 Feet Eco-friendly)',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

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
                const Icon(Icons.temple_hindu, color: AppColors.primaryMaroon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.tr(
                      'माताजी मूर्ती व्यवस्थापन व प्रतिष्ठापना तपशील',
                      'Mataji / Idol Management (Murti Sthapana & Details)',
                    ),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  photoCard,
                  const SizedBox(height: 18),
                  detailsColumn,
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: detailsColumn),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: photoCard),
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
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
