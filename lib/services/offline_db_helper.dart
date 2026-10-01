import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

class OfflineDbHelper {
  static final OfflineDbHelper instance = OfflineDbHelper._init();
  static Database? _database;
  static bool _ffiInitialized = false;

  OfflineDbHelper._init();

  static void initializeFfi() {
    if (_ffiInitialized) return;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      if (Platform.isWindows) {
        // Load sqlite3.dll into process memory
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final candidatePaths = [
          p.join(exeDir, 'sqlite3.dll'),
          p.join(Directory.current.path, 'sqlite3.dll'),
          p.join(Directory.current.path, 'build', 'windows', 'x64', 'runner', 'Debug', 'sqlite3.dll'),
          'sqlite3.dll',
        ];
        for (final dllPath in candidatePaths) {
          try {
            if (File(dllPath).existsSync()) {
              DynamicLibrary.open(dllPath);
              debugPrint('Loaded sqlite3.dll from: $dllPath');
              break;
            }
          } catch (e) {
            debugPrint('Failed loading sqlite3 from $dllPath: $e');
          }
        }
      }
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }
  }

  static String generateId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // version 4
    values[8] = (values[8] & 0x3f) | 0x80; // variant 1
    final hexChars = [
      for (int i = 0; i < 16; i++) values[i].toRadixString(16).padLeft(2, '0')
    ].join('');
    return '${hexChars.substring(0, 8)}-${hexChars.substring(8, 12)}-${hexChars.substring(12, 16)}-${hexChars.substring(16, 20)}-${hexChars.substring(20)}';
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB('navratri_hybrid.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    initializeFfi();
    final dbPath = await getDatabasePath();
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        try {
          // Flush WAL transactions and set journal mode to DELETE so single .db file holds 100% data
          await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE);');
          await db.rawQuery('PRAGMA journal_mode=DELETE;');
          await _runMigrations(db);
        } catch (_) {}
      },
    );
  }

  Future<String> getDatabasePath() async {
    const dbName = 'navratri_hybrid.db';
    if (!kIsWeb && Platform.isWindows) {
      Directory? dbFolder;
      // 1. First priority: Create 'NavratriDatabase' next to executable (portable folder on desktop/custom drive)
      try {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final candidate = Directory(p.join(exeDir, 'NavratriDatabase'));
        if (!await candidate.exists()) {
          await candidate.create(recursive: true);
        }
        // Test write permission to ensure it's not a read-only directory
        final testFile = File(p.join(candidate.path, '.test_write'));
        await testFile.writeAsString('ok');
        await testFile.delete();
        dbFolder = candidate;
      } catch (_) {
        dbFolder = null;
      }

      // 2. Fallback: If exe directory is not writable (e.g. Program Files), use %APPDATA%\NavratriDatabase
      if (dbFolder == null) {
        final appData = Platform.environment['APPDATA'] ??
            Platform.environment['USERPROFILE'] ??
            Directory.current.path;
        dbFolder = Directory(p.join(appData, 'NavratriDatabase'));
        if (!await dbFolder.exists()) {
          await dbFolder.create(recursive: true);
        }
      }

      final targetPath = p.join(dbFolder.path, dbName);

      // Automatic Migration: If target file doesn't exist yet, but legacy file exists, copy it over!
      try {
        final targetFile = File(targetPath);
        if (!await targetFile.exists()) {
          final legacyAppData = Platform.environment['APPDATA'] ?? '';
          if (legacyAppData.isNotEmpty) {
            final legacyFile = File(p.join(legacyAppData, 'NavratriDatabase', dbName));
            if (await legacyFile.exists() && legacyFile.path != targetPath) {
              await legacyFile.copy(targetPath);
              debugPrint('Migrated legacy database to $targetPath');
            }
          }
        }
      } catch (e) {
        debugPrint('Legacy DB migration note: $e');
      }

      return targetPath;
    } else {
      // Android / iOS / Linux: Store inside 'NavratriDatabase' folder
      Directory dbFolder;
      try {
        final databasesPath = await getDatabasesPath();
        dbFolder = Directory(p.join(databasesPath, 'NavratriDatabase'));
        if (!await dbFolder.exists()) {
          await dbFolder.create(recursive: true);
        }
      } catch (e) {
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          dbFolder = Directory(p.join(docsDir.path, 'NavratriDatabase'));
          if (!await dbFolder.exists()) {
            await dbFolder.create(recursive: true);
          }
        } catch (_) {
          return dbName;
        }
      }

      final targetPath = p.join(dbFolder.path, dbName);

      // Automatic Migration on Android if legacy database exists directly in documents dir
      try {
        final targetFile = File(targetPath);
        if (!await targetFile.exists()) {
          final docsDir = await getApplicationDocumentsDirectory();
          final legacyFile = File(p.join(docsDir.path, dbName));
          if (await legacyFile.exists()) {
            await legacyFile.copy(targetPath);
            debugPrint('Migrated legacy Android database to $targetPath');
          }
        }
      } catch (_) {}

      return targetPath;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Mandals
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mandals (
        id TEXT PRIMARY KEY,
        name TEXT,
        registration_number TEXT,
        address TEXT,
        contact_number TEXT,
        email TEXT,
        festival_year TEXT,
        starting_date TEXT,
        ending_date TEXT,
        receipt_prefix TEXT,
        authorized_signatory_name TEXT,
        logo_url TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 2. Mandal Members
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mandal_members (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        member_code TEXT,
        full_name TEXT NOT NULL,
        role TEXT,
        mobile TEXT,
        phone TEXT,
        designation TEXT,
        address TEXT,
        status TEXT DEFAULT 'Active',
        photo_url TEXT,
        joining_date TEXT,
        emergency_contact TEXT,
        blood_group TEXT,
        created_at TEXT
      )
    ''');

    // 3. Donations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS donations (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        receipt_number TEXT,
        donation_date TEXT,
        donor_name TEXT NOT NULL,
        mobile TEXT,
        donor_phone TEXT,
        address TEXT,
        donor_address TEXT,
        amount REAL NOT NULL,
        category TEXT,
        payment_mode TEXT,
        purpose TEXT,
        collector_name TEXT,
        collected_by TEXT,
        status TEXT,
        notes TEXT,
        attachment_url TEXT,
        created_at TEXT
      )
    ''');

    // 4. Expenses
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        expense_number TEXT,
        expense_date TEXT,
        category_name TEXT,
        category TEXT,
        vendor_name TEXT,
        description TEXT,
        expense_title TEXT,
        amount REAL NOT NULL,
        payment_mode TEXT,
        paid_by TEXT,
        bill_url TEXT,
        bill_number TEXT,
        status TEXT,
        notes TEXT,
        created_at TEXT
      )
    ''');

    // 5. Bank Accounts
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bank_accounts (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        bank_name TEXT NOT NULL,
        branch_name TEXT,
        account_holder TEXT,
        account_number TEXT NOT NULL,
        ifsc TEXT,
        ifsc_code TEXT,
        current_balance REAL,
        balance REAL,
        account_type TEXT,
        created_at TEXT
      )
    ''');

    // 6. Events
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT,
        time TEXT,
        location TEXT,
        chief_guest TEXT,
        status TEXT,
        created_at TEXT
      )
    ''');

    // 7. Volunteers
    await db.execute('''
      CREATE TABLE IF NOT EXISTS volunteers (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        role TEXT,
        assigned_area TEXT,
        shift TEXT,
        created_at TEXT
      )
    ''');

    // 8. Vendors
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vendors (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT,
        phone TEXT,
        address TEXT,
        total_deal REAL,
        advance_paid REAL,
        pending_amount REAL,
        created_at TEXT
      )
    ''');

    // 9. Inventory Items
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_items (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        category TEXT,
        quantity INTEGER,
        condition TEXT,
        location TEXT,
        created_at TEXT
      )
    ''');

    // 10. Documents
    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        title TEXT NOT NULL,
        category TEXT,
        file_url TEXT,
        uploaded_at TEXT,
        status TEXT,
        created_at TEXT
      )
    ''');

    // 11. Sponsors
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sponsors (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        sponsor_name TEXT NOT NULL,
        company_name TEXT,
        phone TEXT,
        amount REAL,
        banner_size TEXT,
        location TEXT,
        created_at TEXT
      )
    ''');

    // 12. Food Prasad
    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_prasad (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        date TEXT NOT NULL,
        menu_items TEXT,
        expected_devotees INTEGER,
        sponsored_by TEXT,
        sponsor_contact TEXT,
        created_at TEXT
      )
    ''');

    // 13. Aarti Schedule
    await db.execute('''
      CREATE TABLE IF NOT EXISTS aarti_schedule (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        day_number INTEGER,
        aarti_type TEXT,
        time TEXT,
        performed_by TEXT,
        devotee_count INTEGER,
        created_at TEXT
      )
    ''');

    // 14. Event Participants
    await db.execute('''
      CREATE TABLE IF NOT EXISTS event_participants (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        pass_number TEXT,
        participant_name TEXT NOT NULL,
        phone TEXT,
        category TEXT,
        created_at TEXT
      )
    ''');

    // 15. Security Contacts
    await db.execute('''
      CREATE TABLE IF NOT EXISTS security_contacts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT,
        contact_number TEXT NOT NULL
      )
    ''');

    // 16. Sync Queue for Offline-First Mutations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        row_id TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT,
        created_at TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // 17. Backup Metadata
    await db.execute('''
      CREATE TABLE IF NOT EXISTS backup_metadata (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // 18. Gallery & Festival Media
    await db.execute('''
      CREATE TABLE IF NOT EXISTS gallery (
        id TEXT PRIMARY KEY,
        mandal_id TEXT NOT NULL,
        media_type TEXT DEFAULT 'image',
        category TEXT DEFAULT 'festival',
        title TEXT NOT NULL,
        file_url TEXT NOT NULL,
        thumbnail_url TEXT,
        event_id TEXT,
        uploaded_at TEXT
      )
    ''');
  }

  static Future<void> _runMigrations(Database db) async {
    final migrations = {
      'mandal_members': [
        'member_code TEXT',
        'mobile TEXT',
        'status TEXT DEFAULT "Active"',
        'photo_url TEXT',
        'joining_date TEXT',
        'emergency_contact TEXT',
      ],
      'donations': [
        'mobile TEXT',
        'address TEXT',
        'purpose TEXT',
        'collector_name TEXT',
        'attachment_url TEXT',
      ],
      'expenses': [
        'category_name TEXT',
        'expense_number TEXT',
        'bill_url TEXT',
      ],
      'bank_accounts': [
        'ifsc TEXT',
        'current_balance REAL',
      ],
      'events': [
        'event_name TEXT',
        'event_date TEXT',
        'start_time TEXT',
        'end_time TEXT',
        'venue TEXT',
      ],
    };

    for (final entry in migrations.entries) {
      final table = entry.key;
      try {
        final info = await db.rawQuery('PRAGMA table_info($table);');
        final existingCols = info.map((c) => c['name']?.toString().toLowerCase()).toSet();
        for (final colDef in entry.value) {
          final colName = colDef.split(' ').first.toLowerCase();
          if (!existingCols.contains(colName)) {
            await db.execute('ALTER TABLE $table ADD COLUMN $colDef;');
            debugPrint('Migrated column $colName into SQLite table $table');
          }
        }
      } catch (e) {
        debugPrint('Migration notice for $table: $e');
      }
    }

    // Ensure gallery table exists
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS gallery (
          id TEXT PRIMARY KEY,
          mandal_id TEXT NOT NULL,
          media_type TEXT DEFAULT 'image',
          category TEXT DEFAULT 'festival',
          title TEXT NOT NULL,
          file_url TEXT NOT NULL,
          thumbnail_url TEXT,
          event_id TEXT,
          uploaded_at TEXT
        )
      ''');
    } catch (_) {}

    // Flush stuck sync queue records that failed repeatedly
    try {
      await db.rawUpdate("UPDATE sync_queue SET status = 'failed' WHERE retry_count >= 5;");
    } catch (_) {}
  }

  Future<void> createAllTables(Database db) async {
    await _createDB(db, 1);
  }

  /// Enqueue an action (UPSERT or DELETE) to sync_queue
  Future<void> enqueueSync({
    required String tableName,
    required String rowId,
    required String action,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final db = await database;
      await db.insert('sync_queue', {
        'table_name': tableName,
        'row_id': rowId,
        'action': action,
        'payload': payload != null ? jsonEncode(payload) : null,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
        'retry_count': 0,
      });
    } catch (e) {
      debugPrint('Error enqueuing sync item: $e');
    }
  }

  Future<int> getPendingSyncCount() async {
    try {
      final db = await database;
      final res = await db.rawQuery("SELECT COUNT(*) as c FROM sync_queue WHERE status = 'pending'");
      return Sqflite.firstIntValue(res) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
