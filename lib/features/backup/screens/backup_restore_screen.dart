import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../services/backup_restore_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final repository = MandalRepository();
  bool _isExporting = false;
  bool _isImporting = false;
  double _operationProgress = 0.0;
  String _operationStatus = '';

  // -------------------------------------------------------------
  // EXPORT BACKUP ACTION
  // -------------------------------------------------------------
  Future<void> _handleExportBackup() async {
    final mandal = repository.mandalProfile;
    final mandalId = mandal.id.isNotEmpty ? mandal.id : 'mandal_local_001';
    final mandalName = mandal.name.isNotEmpty ? mandal.name : 'नवरात्र उत्सव मंडळ';

    setState(() {
      _isExporting = true;
      _operationProgress = 0.0;
      _operationStatus = AppStrings.tr('तयारी करत आहे...', 'Preparing...');
    });

    try {
      final result = await BackupRestoreService.instance.exportBackup(
        mandalId: mandalId,
        mandalName: mandalName,
        onProgress: (prog, status) {
          if (mounted) {
            setState(() {
              _operationProgress = prog;
              _operationStatus = status;
            });
          }
        },
      );

      if (!mounted) return;

      if (result.success) {
        _showSuccessExportDialog(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? AppStrings.tr('बॅकअप अयशस्वी झाला.', 'Backup failed.')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSuccessExportDialog(BackupOperationResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.successGreen.withAlpha(40), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.tr('बॅकअप फाईल यशस्वी!', 'Backup File Created!'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.tr(
                'सर्व ${result.totalRecords} नोंदी एका प्रमाणित SQLite (.db) फाईलमध्ये सेव्ह झाल्या आहेत.',
                'All ${result.totalRecords} records saved in a standard SQLite (.db) file.',
              ),
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.tr('सेव्ह केलेले ठिकाण:', 'Saved Location:'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                result.filePath ?? 'Downloads Folder',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.primaryMaroon),
              ),
            ),
            const SizedBox(height: 12),
            if (result.tableCounts.isNotEmpty) ...[
              Text(AppStrings.tr('नोंदींचा तपशील:', 'Records Breakdown:'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: result.tableCounts.entries.map((e) {
                  return Chip(
                    label: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primaryMaroon.withAlpha(20),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        actions: [
          if (result.filePath != null)
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: Text(AppStrings.tr('पाथ कॉपी करा', 'Copy Path')),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result.filePath!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.tr('पाथ कॉपी केला!', 'Path copied!')), duration: const Duration(seconds: 2)),
                );
              },
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.tr('ठीक आहे (OK)', 'OK')),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // IMPORT BACKUP ACTION
  // -------------------------------------------------------------
  Future<void> _handleImportBackup() async {
    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: AppStrings.tr('इम्पोर्ट करण्यासाठी .db बॅकअप फाइल निवडा', 'Select .db backup file to restore'),
        type: FileType.any,
      );

      if (picked == null) {
        return;
      }

      final chosenFilePath = picked.path ?? picked.xFile.path;

      setState(() {
        _isImporting = true;
        _operationProgress = 0.05;
        _operationStatus = AppStrings.tr('फाईलची तपासणी करत आहे...', 'Inspecting file...');
      });

      final inspection = await BackupRestoreService.instance.inspectBackupFile(chosenFilePath);

      setState(() => _isImporting = false);

      if (!mounted) return;

      if (!inspection.isValid) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 28),
                const SizedBox(width: 8),
                Text(AppStrings.tr('अवैध फाईल', 'Invalid File')),
              ],
            ),
            content: Text(inspection.errorMessage ?? AppStrings.tr('ही फाईल योग्य बॅकअप फाईल नाही.', 'This file is not a valid backup file.')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.tr('बंद करा', 'Close'))),
            ],
          ),
        );
        return;
      }

      _showPreImportModal(inspection);
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showPreImportModal(BackupInspectionResult inspection) {
    final targetMandalId = repository.mandalProfile.id.isNotEmpty ? repository.mandalProfile.id : 'mandal_local_001';
    final targetMandalName = repository.mandalProfile.name.isNotEmpty ? repository.mandalProfile.name : 'नवरात्र उत्सव मंडळ';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryMaroon.withAlpha(30), shape: BoxShape.circle),
                child: const Icon(Icons.restore_page_rounded, color: AppColors.primaryMaroon, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.tr('बॅकअप इम्पोर्ट खातरजमा', 'Confirm Backup Restore'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.file_present_rounded, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                inspection.originalMandalName ?? 'नवरात्र उत्सव मंडळ',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'फाईल: ${p.basename(inspection.filePath)} (${(inspection.fileSizeBytes / 1024).toStringAsFixed(1)} KB)',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        Text(
                          'तयार तारीख: ${inspection.exportedAt?.day}-${inspection.exportedAt?.month}-${inspection.exportedAt?.year}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(AppStrings.tr('आढळलेल्या नोंदींचा तपशील:', 'Detected Records:'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        _buildPreviewRow(AppStrings.tr('एकूण सर्व नोंदी', 'Total Records'), '${inspection.totalRecords}', isBold: true),
                        const Divider(height: 12),
                        _buildPreviewRow(AppStrings.tr('देणगी नोंदी', 'Donations'), '${inspection.tableCounts['donations'] ?? 0}'),
                        _buildPreviewRow(AppStrings.tr('खर्च नोंदी', 'Expenses'), '${inspection.tableCounts['expenses'] ?? 0}'),
                        _buildPreviewRow(AppStrings.tr('मंडळ सभासद', 'Members'), '${inspection.tableCounts['mandal_members'] ?? 0}'),
                        _buildPreviewRow(AppStrings.tr('बँक खाती', 'Bank Accounts'), '${inspection.tableCounts['bank_accounts'] ?? 0}'),
                        _buildPreviewRow(AppStrings.tr('कार्यक्रम', 'Events'), '${inspection.tableCounts['events'] ?? 0}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.tr(
                              'हा डेटा आपोआप "$targetMandalName" खात्याशी जोडला जाईल आणि क्लाउडवर सुरक्षित सिंक होईल.',
                              'This data will be linked to "$targetMandalName" and automatically synced.',
                            ),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF78350F)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.tr('रद्द करा', 'Cancel')),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download_done_rounded, size: 18),
              label: Text(AppStrings.tr('रिस्टोअर सुरू करा', 'Proceed Restore')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _executeRestore(inspection.filePath, targetMandalId);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.primaryMaroon : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeRestore(String filePath, String targetMandalId) async {
    setState(() {
      _isImporting = true;
      _operationProgress = 0.1;
      _operationStatus = AppStrings.tr('रिस्टोअर प्रक्रिया सुरू करत आहे...', 'Starting restore process...');
    });

    try {
      final res = await BackupRestoreService.instance.restoreBackup(
        backupFilePath: filePath,
        targetMandalId: targetMandalId,
        onProgress: (prog, status) {
          if (mounted) {
            setState(() {
              _operationProgress = prog;
              _operationStatus = status;
            });
          }
        },
      );

      if (!mounted) return;

      if (res.success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.successGreen.withAlpha(30), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 28),
                ),
                const SizedBox(width: 12),
                Text(AppStrings.tr('रिस्टोअर यशस्वी!', 'Restore Complete!')),
              ],
            ),
            content: Text(res.message ?? AppStrings.tr('सर्व नोंदी यशस्वीरित्या रिस्टोअर केल्या.', 'All records restored successfully.')),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {});
                },
                child: Text(AppStrings.tr('ठीक आहे', 'OK')),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Restore error'), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.settings_backup_restore, color: AppColors.primaryMaroon, size: 24),
            const SizedBox(width: 8),
            Text(
              AppStrings.tr('बॅकअप व रिस्टोअर व्यवस्थापन', 'Backup & Restore Management'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.tr(
            'मंडळाच्या सर्व डेटाचे सुरक्षित SQLite (.db) बॅकअप घ्या किंवा जुना बॅकअप रिस्टोअर करा.',
            'Create a secure SQLite (.db) backup of all Mandal data or restore an existing backup.',
          ),
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Divider(height: 24),

        // Progress indicator during active export or import
        if (_isExporting || _isImporting) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMaroon),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _operationStatus,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryMaroon),
                      ),
                    ),
                    Text('${(_operationProgress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _operationProgress > 0 ? _operationProgress : null,
                  backgroundColor: Colors.blue.shade100,
                  color: AppColors.primaryMaroon,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Cards Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;
            if (isNarrow) {
              return Column(
                children: [
                  _buildExportCard(),
                  const SizedBox(height: 16),
                  _buildImportCard(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildExportCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildImportCard()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildExportCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryMaroon.withAlpha(20), shape: BoxShape.circle),
                child: const Icon(Icons.cloud_download, color: AppColors.primaryMaroon, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr('डेटा बॅकअप एक्सपोर्ट', 'Export Data Backup'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'SQLite (.db) File',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.tr(
              'मंडळाच्या सर्व नोंदी एका प्रमाणित SQLite (.db) फाईलमध्ये सुरक्षित सेव्ह करा. ही फाईल तुम्ही कॉम्प्युटर किंवा पेनड्राइव्हवर सेव्ह करू शकता.',
              'Save all Mandal records into a standard SQLite (.db) file on your computer or external drive.',
            ),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          // Current record preview chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildStatChip(AppStrings.tr('देणग्या', 'Donations'), repository.donations.length),
              _buildStatChip(AppStrings.tr('खर्च', 'Expenses'), repository.expenses.length),
              _buildStatChip(AppStrings.tr('सभासद', 'Members'), repository.members.length),
              _buildStatChip(AppStrings.tr('कार्यक्रम', 'Events'), repository.events.length),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting || _isImporting ? null : _handleExportBackup,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(AppStrings.tr('बॅकअप तयार करा (Export Backup)', 'Export Backup (.db)')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                child: Icon(Icons.cloud_upload, color: Colors.teal.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr('डेटा रिस्टोअर करा', 'Restore From Backup'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Restore From .db File',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.tr(
              'अगोदर घेतलेली .db बॅकअप फाईल निवडून सर्व नोंदी पुन्हा ॲपमध्ये पुनर्प्राप्त करा. रिस्टोअर करण्यापूर्वी आपोआप एक सेफ स्नॅपशॉट घेतला जातो.',
              'Select a previously saved .db file to restore all records. A safety snapshot is automatically created before restore.',
            ),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, size: 18, color: AppColors.successGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.tr(
                      'स्वयंचलित सेफ्टी बॅकअप आणि Supabase क्लाउड सिंक सुरक्षा समाविष्ट आहे.',
                      'Automatic safety snapshot and Supabase cloud sync safeguards included.',
                    ),
                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting || _isImporting ? null : _handleImportBackup,
              icon: const Icon(Icons.file_open_rounded, size: 18),
              label: Text(AppStrings.tr('बॅकअप फाईल निवडा (Select .db)', 'Select Backup File (.db)')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        '$label: $count',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }
}
