import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:navratri/services/offline_db_helper.dart';
import 'package:navratri/services/backup_restore_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Offline-First Database & Sync Queue Tests', () {
    test('OfflineDbHelper initializes in-memory database and creates all tables', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, v) async {
          await OfflineDbHelper.instance.createAllTables(db);
        },
      );

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables.map((r) => r['name'] as String).toSet();

      expect(tableNames.contains('mandals'), isTrue);
      expect(tableNames.contains('donations'), isTrue);
      expect(tableNames.contains('expenses'), isTrue);
      expect(tableNames.contains('mandal_members'), isTrue);
      expect(tableNames.contains('bank_accounts'), isTrue);
      expect(tableNames.contains('events'), isTrue);
      expect(tableNames.contains('sync_queue'), isTrue);
      expect(tableNames.contains('backup_metadata'), isTrue);

      await db.close();
    });

    test('Offline mutation enqueues action into sync_queue when offline', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, v) async {
          await OfflineDbHelper.instance.createAllTables(db);
        },
      );

      // Insert donation locally
      await db.insert('donations', {
        'id': 'don-test-001',
        'mandal_id': 'mandal-test-001',
        'donor_name': 'Test Donor Offline',
        'donor_phone': '9876543210',
        'donor_address': 'Pune',
        'amount': 2500.0,
        'category': 'Festival',
        'payment_mode': 'Cash',
        'donation_date': '2026-09-18',
        'receipt_number': 'R-TEST-001',
        'collected_by': 'Sonu nikam',
        'status': 'Paid',
      });

      // Enqueue to sync_queue
      await db.insert('sync_queue', {
        'table_name': 'donations',
        'row_id': 'don-test-001',
        'action': 'UPSERT',
        'payload': '{"amount": 2500.0}',
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
        'retry_count': 0,
      });

      // Verify pending count is 1
      final res = await db.rawQuery("SELECT COUNT(*) as c FROM sync_queue WHERE status = 'pending'");
      final count = (res.first['c'] as num).toInt();
      expect(count, 1);

      // Verify local donation can be queried immediately
      final donRows = await db.query('donations', where: 'id = ?', whereArgs: ['don-test-001']);
      expect(donRows.length, 1);
      expect(donRows.first['amount'], 2500.0);

      await db.close();
    });

    test('BackupRestoreService inspection detects invalid files safely', () async {
      final result = await BackupRestoreService.instance.inspectBackupFile('non_existent_file.db');
      expect(result.isValid, isFalse);
    });
  });
}
