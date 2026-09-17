import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../repositories/mandal_repository.dart';
import 'offline_db_helper.dart';
import 'sync_service.dart';

class BackupInspectionResult {
  final bool isValid;
  final String? errorMessage;
  final String? originalMandalName;
  final String? originalMandalId;
  final DateTime? exportedAt;
  final String? sourcePlatform;
  final Map<String, int> tableCounts;
  final int totalRecords;
  final String filePath;
  final int fileSizeBytes;

  const BackupInspectionResult({
    required this.isValid,
    this.errorMessage,
    this.originalMandalName,
    this.originalMandalId,
    this.exportedAt,
    this.sourcePlatform,
    this.tableCounts = const {},
    this.totalRecords = 0,
    required this.filePath,
    this.fileSizeBytes = 0,
  });
}

class BackupOperationResult {
  final bool success;
  final String? filePath;
  final String? message;
  final int totalRecords;
  final Map<String, int> tableCounts;

  const BackupOperationResult({
    required this.success,
    this.filePath,
    this.message,
    this.totalRecords = 0,
    this.tableCounts = const {},
  });
}

class BackupRestoreService {
  static final BackupRestoreService instance = BackupRestoreService._();
  BackupRestoreService._();

  static const List<String> allBackupTables = [
    'mandals',
    'mandal_members',
    'donations',
    'expenses',
    'bank_accounts',
    'events',
    'volunteers',
    'vendors',
    'inventory_items',
    'documents',
    'sponsors',
    'food_prasad',
    'aarti_schedule',
    'event_participants',
    'security_contacts',
  ];

  // -------------------------------------------------------------
  // 1. INSPECT BACKUP FILE (.db)
  // -------------------------------------------------------------
  Future<BackupInspectionResult> inspectBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return BackupInspectionResult(
          isValid: false,
          errorMessage: 'फाइल अस्तित्वात नाही (File does not exist).',
          filePath: filePath,
        );
      }

      final fileSizeBytes = await file.length();
      if (fileSizeBytes < 1024) {
        return BackupInspectionResult(
          isValid: false,
          errorMessage: 'अवैध फाईल! फाईलचा आकार खूप लहान आहे (File too small).',
          filePath: filePath,
        );
      }

      OfflineDbHelper.initializeFfi();

      Database? db;
      try {
        db = await openDatabase(filePath, readOnly: true);
      } catch (e) {
        return BackupInspectionResult(
          isValid: false,
          errorMessage: 'डेटाबेस उघडताना त्रुटी: $e (Corrupt or unreadable SQLite file)',
          filePath: filePath,
        );
      }

      final tableRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final existingTables = tableRows.map((r) => r['name']?.toString() ?? '').toSet();

      if (!existingTables.contains('donations') && !existingTables.contains('mandals') && !existingTables.contains('mandal_members')) {
        await db.close();
        return BackupInspectionResult(
          isValid: false,
          errorMessage: 'अवैध बॅकअप फाईल! ही नवरात्र उत्सव मंडळ ॲपची मूळ डेटाबेस फाईल नाही.',
          filePath: filePath,
        );
      }

      String? originalMandalName;
      String? originalMandalId;
      DateTime? exportedAt;
      String? sourcePlatform;

      if (existingTables.contains('backup_metadata')) {
        try {
          final metaRows = await db.query('backup_metadata');
          final metaMap = {for (var r in metaRows) r['key']?.toString(): r['value']?.toString()};
          originalMandalName = metaMap['mandal_name'];
          originalMandalId = metaMap['mandal_id'];
          sourcePlatform = metaMap['source_platform'];
          if (metaMap['exported_at'] != null) {
            exportedAt = DateTime.tryParse(metaMap['exported_at']!);
          }
        } catch (_) {}
      }

      if (originalMandalName == null && existingTables.contains('mandals')) {
        try {
          final mRows = await db.query('mandals', limit: 1);
          if (mRows.isNotEmpty) {
            originalMandalName = mRows.first['name']?.toString();
            originalMandalId = mRows.first['id']?.toString();
          }
        } catch (_) {}
      }

      final tableCounts = <String, int>{};
      int totalRecords = 0;

      for (var table in allBackupTables) {
        if (existingTables.contains(table)) {
          try {
            final countRes = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
            final c = (countRes.first['c'] as num?)?.toInt() ?? 0;
            if (c > 0) {
              tableCounts[table] = c;
              totalRecords += c;
            }
          } catch (_) {}
        }
      }

      await db.close();

      return BackupInspectionResult(
        isValid: true,
        originalMandalName: originalMandalName ?? 'नवरात्र उत्सव मंडळ',
        originalMandalId: originalMandalId,
        exportedAt: exportedAt ?? DateTime.now(),
        sourcePlatform: sourcePlatform ?? 'Unknown',
        tableCounts: tableCounts,
        totalRecords: totalRecords,
        filePath: filePath,
        fileSizeBytes: fileSizeBytes,
      );
    } catch (e) {
      return BackupInspectionResult(
        isValid: false,
        errorMessage: 'तपासणी करताना त्रुटी आली: $e',
        filePath: filePath,
      );
    }
  }

  // -------------------------------------------------------------
  // 2. EXPORT BACKUP (.db)
  // -------------------------------------------------------------
  Future<BackupOperationResult> exportBackup({
    required String mandalId,
    required String mandalName,
    void Function(double progress, String status)? onProgress,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final cleanName = mandalName.replaceAll(RegExp(r'[^a-zA-Z0-9\u0900-\u097F_-]'), '_');
      final targetFileName = 'NavratriMandal_Backup_${cleanName}_$dateStr.db';

      OfflineDbHelper.initializeFfi();

      onProgress?.call(0.1, 'स्थानिक डेटाबेस तयार करत आहे...');
      final localDb = await OfflineDbHelper.instance.database;
      try {
        await localDb.rawQuery('PRAGMA wal_checkpoint(FULL);');
      } catch (_) {}

      await _writeMetadataTable(localDb, mandalId, mandalName, now);

      final tableCounts = <String, int>{};
      int totalRecords = 0;

      for (var t in allBackupTables) {
        try {
          final res = await localDb.rawQuery('SELECT COUNT(*) AS c FROM $t');
          final c = (res.first['c'] as num?)?.toInt() ?? 0;
          if (c > 0) {
            tableCounts[t] = c;
            totalRecords += c;
          }
        } catch (_) {}
      }

      onProgress?.call(0.4, 'बॅकअप फाइल कॉपी करत आहे...');
      final tempDir = await getTemporaryDirectory();
      final tempExportPath = p.join(tempDir.path, targetFileName);

      final sourcePath = await OfflineDbHelper.instance.getDatabasePath();
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(tempExportPath);
      } else {
        return const BackupOperationResult(
          success: false,
          message: 'स्थानिक डेटाबेस फाईल सापडली नाही.',
        );
      }

      onProgress?.call(0.8, 'फाइल सेव्ह करत आहे...');

      String? finalSavedPath;
      if (!kIsWeb && Platform.isWindows) {
        final bytes = await File(tempExportPath).readAsBytes();
        final savedUri = await FilePicker.saveFile(
          dialogTitle: 'बॅकअप (.db) फाइल कुठे सेव्ह करायची ते निवडा',
          fileName: targetFileName,
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: ['db'],
        );

        if (savedUri != null) {
          finalSavedPath = savedUri.toFilePath();
        } else {
          return const BackupOperationResult(
            success: false,
            message: 'बॅकअप सेव्ह करणे रद्द केले.',
          );
        }
      } else {
        // Mobile (Android)
        String? selectedDir;
        try {
          selectedDir = await FilePicker.getDirectoryPath(
            dialogTitle: 'बॅकअप फाइल सेव्ह करण्यासाठी फोल्डर निवडा',
          );
        } catch (_) {}

        if (selectedDir != null && selectedDir.isNotEmpty) {
          final dest = p.join(selectedDir, targetFileName);
          await File(tempExportPath).copy(dest);
          finalSavedPath = dest;
        } else {
          // Fallback to Downloads directory
          Directory? destDir;
          try {
            final downloadPath = Directory('/storage/emulated/0/Download');
            if (await downloadPath.exists()) {
              destDir = downloadPath;
            }
          } catch (_) {}

          destDir ??= await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
          final dest = p.join(destDir.path, targetFileName);
          await File(tempExportPath).copy(dest);
          finalSavedPath = dest;
        }
      }

      onProgress?.call(1.0, 'बॅकअप यशस्वीरित्या पूर्ण झाला!');

      return BackupOperationResult(
        success: true,
        filePath: finalSavedPath,
        message: 'बॅकअप यशस्वी! ($totalRecords नोंदी सेव्ह केल्या)',
        totalRecords: totalRecords,
        tableCounts: tableCounts,
      );
    } catch (e) {
      return BackupOperationResult(
        success: false,
        message: 'बॅकअप एक्सपोर्ट करताना त्रुटी: $e',
      );
    }
  }

  // -------------------------------------------------------------
  // 3. RESTORE BACKUP (.db) WITH MANDAL REMAPPING & CLOUD BATCH UPLOAD
  // -------------------------------------------------------------
  Future<BackupOperationResult> restoreBackup({
    required String backupFilePath,
    required String targetMandalId,
    void Function(double progress, String status)? onProgress,
  }) async {
    try {
      OfflineDbHelper.initializeFfi();

      final sourceFile = File(backupFilePath);
      if (!await sourceFile.exists()) {
        return const BackupOperationResult(
          success: false,
          message: 'निवडलेली बॅकअप फाइल सापडली नाही.',
        );
      }

      onProgress?.call(0.05, 'सुरक्षिततेसाठी सध्याचा स्नॅपशॉट घेत आहे (Safety Backup)...');
      await _createSafetySnapshot();

      onProgress?.call(0.2, 'बॅकअप फाईलमधील डेटा वाचत आहे...');
      final Database sourceDb;
      try {
        sourceDb = await openDatabase(backupFilePath, readOnly: true);
      } catch (e) {
        return BackupOperationResult(
          success: false,
          message: 'बॅकअप फाईल उघडताना त्रुटी: $e',
        );
      }

      final tableRows = await sourceDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final existingTables = tableRows.map((r) => r['name']?.toString() ?? '').toSet();

      final localDb = await OfflineDbHelper.instance.database;
      final tableCounts = <String, int>{};
      int totalRestored = 0;

      int processed = 0;
      for (var table in allBackupTables) {
        processed++;
        final progress = 0.2 + (0.5 * (processed / allBackupTables.length));
        onProgress?.call(progress, '$table रिस्टोअर होत आहे ($processed/${allBackupTables.length})...');

        if (existingTables.contains(table)) {
          final rows = await sourceDb.query(table);
          if (rows.isNotEmpty) {
            final validCols = await _getTableColumns(localDb, table);

            await localDb.transaction((txn) async {
              for (var r in rows) {
                final row = Map<String, dynamic>.from(r);

                // Remap mandal_id to current target mandal
                if (row.containsKey('mandal_id')) {
                  row['mandal_id'] = targetMandalId;
                }
                if (table == 'mandals') {
                  row['id'] = targetMandalId;
                }

                final sanitized = _sanitizeRowForSqlite(row, validCols);
                await txn.insert(table, sanitized, conflictAlgorithm: ConflictAlgorithm.replace);

                // Enqueue into sync_queue so it pushes to Supabase Cloud
                await txn.insert('sync_queue', {
                  'table_name': table,
                  'row_id': row['id']?.toString() ?? '',
                  'action': 'UPSERT',
                  'payload': jsonEncode(sanitized),
                  'created_at': DateTime.now().toIso8601String(),
                  'status': 'pending',
                  'retry_count': 0,
                });
              }
            });

            tableCounts[table] = rows.length;
            totalRestored += rows.length;
          }
        }
      }

      await sourceDb.close();

      // Refresh in-memory repository from updated local database
      await MandalRepository().loadFromLocalDb(mandalId: targetMandalId);

      // Trigger cloud batch upload
      onProgress?.call(0.8, 'क्लाउडवर डेटा सिंक करत आहे...');
      try {
        await SyncService.instance.pushBatchSync();
      } catch (_) {}

      onProgress?.call(1.0, 'डेटा यशस्वीरित्या रिस्टोअर झाला!');

      return BackupOperationResult(
        success: true,
        filePath: backupFilePath,
        message: 'यशस्वी रिस्टोअर! एकूण $totalRestored नोंदी पुनर्प्राप्त केल्या.',
        totalRecords: totalRestored,
        tableCounts: tableCounts,
      );
    } catch (e) {
      return BackupOperationResult(
        success: false,
        message: 'रिस्टोअर करताना त्रुटी आली: $e',
      );
    }
  }

  Future<void> _writeMetadataTable(Database db, String mandalId, String mandalName, DateTime now) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS backup_metadata (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    final meta = {
      'mandal_id': mandalId,
      'mandal_name': mandalName,
      'exported_at': now.toIso8601String(),
      'source_platform': Platform.operatingSystem,
      'app_version': '1.0.0',
      'format': 'navratri_mandal_standard_db',
    };

    for (var entry in meta.entries) {
      await db.insert(
        'backup_metadata',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _createSafetySnapshot() async {
    try {
      final sourcePath = await OfflineDbHelper.instance.getDatabasePath();
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        final docsDir = await getApplicationDocumentsDirectory();
        final safetyPath = p.join(
          docsDir.path,
          'pre_restore_safety_backup_${DateTime.now().millisecondsSinceEpoch}.db',
        );
        await sourceFile.copy(safetyPath);
      }
    } catch (e) {
      debugPrint('Safety snapshot warning: $e');
    }
  }

  Future<Set<String>> _getTableColumns(Database db, String table) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      return info.map((r) => r['name'].toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> _sanitizeRowForSqlite(Map<String, dynamic> raw, Set<String> validCols) {
    final sanitized = <String, dynamic>{};
    raw.forEach((k, v) {
      if (validCols.isEmpty || validCols.contains(k)) {
        if (v is bool) {
          sanitized[k] = v ? 1 : 0;
        } else if (v is Map || v is List) {
          sanitized[k] = jsonEncode(v);
        } else {
          sanitized[k] = v;
        }
      }
    });
    return sanitized;
  }
}
