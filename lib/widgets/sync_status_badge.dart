import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/localization/app_strings.dart';
import '../services/sync_service.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncState>(
      valueListenable: SyncService.instance.state,
      builder: (context, state, _) {
        Color bgColor;
        Color textColor;
        IconData iconData;
        String label;

        if (state.status == SyncStatus.syncing) {
          bgColor = Colors.blue.shade100;
          textColor = Colors.blue.shade900;
          iconData = Icons.sync;
          label = AppStrings.tr('सिंक होत आहे...', 'Syncing...');
        } else if (!state.isOnline || state.status == SyncStatus.offline) {
          bgColor = Colors.amber.shade100;
          textColor = Colors.amber.shade900;
          iconData = Icons.cloud_off;
          label = state.pendingCount > 0
              ? '${state.pendingCount} ${AppStrings.tr("प्रलंबित", "Pending")}'
              : AppStrings.tr('ऑफलाइन', 'Offline');
        } else if (state.pendingCount > 0) {
          bgColor = Colors.orange.shade100;
          textColor = Colors.orange.shade900;
          iconData = Icons.sync_problem;
          label = '${state.pendingCount} ${AppStrings.tr("प्रलंबित", "Pending")}';
        } else {
          bgColor = Colors.green.shade100;
          textColor = Colors.green.shade900;
          iconData = Icons.cloud_done;
          label = AppStrings.tr('सिंक झाले', 'Synced');
        }

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showSyncDetailsDialog(context, state),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: textColor.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                state.status == SyncStatus.syncing
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: textColor,
                        ),
                      )
                    : Icon(iconData, size: 16, color: textColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSyncDetailsDialog(BuildContext context, SyncState state) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                state.isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: state.isOnline ? Colors.green : Colors.amber.shade800,
              ),
              const SizedBox(width: 10),
              Text(AppStrings.tr('क्लाउड सिंक स्थिती', 'Cloud Sync Status')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(
                AppStrings.tr('कनेक्शन', 'Connection'),
                state.isOnline
                    ? '🟢 ${AppStrings.tr("ऑनलाइन (Supabase)", "Online (Supabase)")}'
                    : '🟡 ${AppStrings.tr("ऑफलाइन (स्थानिक SQLite डेटाबेस)", "Offline (Local SQLite database)")}',
              ),
              const SizedBox(height: 8),
              _infoRow(
                AppStrings.tr('प्रलंबित नोंदी', 'Pending Uploads'),
                '${state.pendingCount} ${AppStrings.tr("नोंदी", "records")}',
              ),
              const SizedBox(height: 8),
              _infoRow(
                AppStrings.tr('शेवटचे सिंक', 'Last Synced'),
                state.lastSyncTime != null
                    ? DateFormat('dd MMM yyyy, hh:mm:ss a').format(state.lastSyncTime!)
                    : AppStrings.tr('अद्याप नाही', 'Not synced yet'),
              ),
              if (state.message != null && state.message!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _infoRow(AppStrings.tr('तपशील', 'Details'), state.message!),
              ],
            ],
          ),
          actions: [
            if (state.pendingCount > 0)
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await SyncService.instance.clearPendingQueue();
                },
                icon: const Icon(Icons.cleaning_services, size: 16, color: Colors.orange),
                label: Text(
                  AppStrings.tr('रांग स्वच्छ करा', 'Clear Queue'),
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.tr('बंद करा', 'Close')),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                SyncService.instance.syncAll();
              },
              icon: const Icon(Icons.sync, size: 18),
              label: Text(AppStrings.tr('आता सिंक करा', 'Sync Now')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
