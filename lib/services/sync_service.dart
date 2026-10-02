import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../config/supabase_config.dart';
import '../repositories/mandal_repository.dart';
import 'offline_db_helper.dart';

enum SyncStatus { idle, syncing, offline, error }

class SyncState {
  final bool isOnline;
  final SyncStatus status;
  final int pendingCount;
  final String? message;
  final DateTime? lastSyncTime;

  const SyncState({
    required this.isOnline,
    required this.status,
    required this.pendingCount,
    this.message,
    this.lastSyncTime,
  });

  SyncState copyWith({
    bool? isOnline,
    SyncStatus? status,
    int? pendingCount,
    String? message,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      message: message ?? this.message,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final ValueNotifier<SyncState> state = ValueNotifier<SyncState>(
    const SyncState(
      isOnline: false,
      status: SyncStatus.idle,
      pendingCount: 0,
    ),
  );

  /// Incremented after every successful cloud sync to notify UI providers to refresh
  final ValueNotifier<int> syncVersion = ValueNotifier<int>(0);

  StreamSubscription? _connectivitySub;
  Timer? _dynamicTimer;
  Timer? _reconnectTimer;
  bool _isSyncRunning = false;
  bool _initialized = false;

  /// Start monitoring and sync service
  Future<void> start() async {
    if (_initialized) return;
    _initialized = true;

    await refreshPendingCount();

    // Listen to network changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(milliseconds: 800), () async {
        final isOnline = await _hasInternetConnection();
        if (isOnline) {
          await _onInternetRestored();
        } else {
          final count = await refreshPendingCount();
          state.value = state.value.copyWith(
            isOnline: false,
            status: SyncStatus.offline,
            pendingCount: count,
            message: count > 0 ? '$count items pending sync' : 'Offline',
          );
        }
      });
    });

    // Check connectivity and sync quickly on app launch
    _quickLaunchSync();

    // Dynamic rapid heartbeat
    _startDynamicHeartbeat();
  }

  void _startDynamicHeartbeat() {
    _dynamicTimer?.cancel();
    _scheduleNextHeartbeat();
  }

  void _scheduleNextHeartbeat() {
    if (!_initialized) return;

    final hasPendingOrOffline = !state.value.isOnline || state.value.pendingCount > 0;
    final delay = hasPendingOrOffline
        ? const Duration(milliseconds: 3000)
        : const Duration(seconds: 30);

    _dynamicTimer = Timer(delay, () async {
      if (!_initialized) return;
      await _checkAndSyncHeartbeat();
      _scheduleNextHeartbeat();
    });
  }

  Future<void> _checkAndSyncHeartbeat() async {
    if (_isSyncRunning) return;

    final wasOnline = state.value.isOnline;
    final isOnline = await _hasInternetConnection();
    final count = await refreshPendingCount();

    if (!isOnline) {
      if (wasOnline) {
        state.value = state.value.copyWith(
          isOnline: false,
          status: SyncStatus.offline,
          pendingCount: count,
          message: count > 0 ? '$count items pending sync' : 'Offline',
        );
      }
      return;
    }

    // Currently online
    if (!wasOnline) {
      debugPrint('⚡ Dynamic heartbeat detected internet restored! Syncing immediately...');
      state.value = state.value.copyWith(
        isOnline: true,
        message: count > 0 ? 'Internet restored. Syncing $count items...' : 'Online',
      );
      await _onInternetRestored();
    } else if (count > 0) {
      await pushBatchSync();
    }
  }

  Future<void> _onInternetRestored() async {
    final count = await refreshPendingCount();
    if (count > 0) {
      await pushBatchSync();
    }
    await syncAll();
  }

  Future<void> _quickLaunchSync() async {
    final isConnected = await _hasInternetConnection();
    final count = await refreshPendingCount();

    if (!isConnected) {
      state.value = state.value.copyWith(
        isOnline: false,
        status: SyncStatus.offline,
        pendingCount: count,
        message: count > 0 ? '$count items pending sync' : 'Offline',
      );
      return;
    }

    state.value = state.value.copyWith(
      isOnline: true,
      pendingCount: count,
    );
    await syncAll();
  }

  Future<int> refreshPendingCount() async {
    final count = await OfflineDbHelper.instance.getPendingSyncCount();
    state.value = state.value.copyWith(pendingCount: count);
    return count;
  }

  Future<bool> _hasInternetConnection() async {
    try {
      if (kIsWeb) return true;
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Upload queued offline changes to Supabase
  Future<void> pushBatchSync() async {
    if (_isSyncRunning) return;
    final isOnline = await _hasInternetConnection();
    if (!isOnline) return;

    _isSyncRunning = true;
    state.value = state.value.copyWith(status: SyncStatus.syncing);

    try {
      final db = await OfflineDbHelper.instance.database;
      final pendingRows = await db.query(
        'sync_queue',
        where: "status = 'pending'",
        orderBy: 'id ASC',
        limit: 50,
      );

      if (pendingRows.isEmpty) {
        state.value = state.value.copyWith(
          status: SyncStatus.idle,
          pendingCount: 0,
        );
        _isSyncRunning = false;
        return;
      }

      final client = SupabaseConfig.client;

      for (var row in pendingRows) {
        final id = row['id'] as int;
        final tableName = row['table_name'] as String;
        final action = row['action'] as String;
        final payloadStr = row['payload'] as String?;

        try {
          if (action == 'UPSERT' && payloadStr != null) {
            final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
            await client.from(tableName).upsert(payload);
          } else if (action == 'DELETE') {
            final rowId = row['row_id'] as String;
            await client.from(tableName).delete().eq('id', rowId);
          }

          // Mark deleted from queue on success
          await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
        } catch (e) {
          debugPrint('Error syncing queue item $id for $tableName: $e');
          final errStr = e.toString();
          final retries = (row['retry_count'] as int? ?? 0) + 1;
          // Avoid infinite stuck pending counts on permanent constraint violations
          if (retries >= 3 || errStr.contains('duplicate key') || errStr.contains('23505') || errStr.contains('violates foreign key')) {
            await db.rawUpdate(
              "UPDATE sync_queue SET status = 'failed', retry_count = ? WHERE id = ?",
              [retries, id],
            );
          } else {
            await db.rawUpdate(
              'UPDATE sync_queue SET retry_count = ? WHERE id = ?',
              [retries, id],
            );
          }
        }
      }

      final remaining = await refreshPendingCount();
      state.value = state.value.copyWith(
        status: SyncStatus.idle,
        pendingCount: remaining,
        lastSyncTime: DateTime.now(),
      );

      syncVersion.value++;
    } catch (e) {
      debugPrint('pushBatchSync error: $e');
      state.value = state.value.copyWith(status: SyncStatus.error, message: '$e');
    } finally {
      _isSyncRunning = false;
    }
  }

  /// Full 2-way sync: Push local queue, then pull latest data from Supabase
  Future<void> syncAll() async {
    if (_isSyncRunning) return;
    final isOnline = await _hasInternetConnection();
    if (!isOnline) {
      final count = await refreshPendingCount();
      state.value = state.value.copyWith(
        isOnline: false,
        status: SyncStatus.offline,
        pendingCount: count,
        message: count > 0 ? '$count items pending sync' : 'Offline',
      );
      return;
    }

    _isSyncRunning = true;
    state.value = state.value.copyWith(
      isOnline: true,
      status: SyncStatus.syncing,
    );

    try {
      // 1. Push any queued pending writes first
      await pushBatchSync();

      // 2. Pull latest data from Supabase via MandalRepository
      await MandalRepository().syncFromSupabase();

      // 3. Cache latest records into local SQLite
      await _cacheRepositoryToSqlite();

      final count = await refreshPendingCount();
      state.value = state.value.copyWith(
        isOnline: true,
        status: SyncStatus.idle,
        pendingCount: count,
        lastSyncTime: DateTime.now(),
        message: 'Synced',
      );

      syncVersion.value++;
    } catch (e) {
      debugPrint('syncAll error: $e');
      state.value = state.value.copyWith(status: SyncStatus.error, message: '$e');
    } finally {
      _isSyncRunning = false;
    }
  }

  /// Cache current repository data into local SQLite tables
  Future<void> _cacheRepositoryToSqlite() async {
    try {
      final repo = MandalRepository();
      final db = await OfflineDbHelper.instance.database;

      // Cache Mandal Profile
      if (repo.mandalProfile.id.isNotEmpty) {
        await db.insert('mandals', repo.mandalProfile.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Cache Members
      final batch = db.batch();
      for (var m in repo.members) {
        batch.insert('mandal_members', m.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var d in repo.donations) {
        final json = d.toJson();
        json['mandal_id'] = repo.mandalProfile.id;
        batch.insert('donations', json, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var e in repo.expenses) {
        final json = e.toJson();
        json['mandal_id'] = repo.mandalProfile.id;
        batch.insert('expenses', json, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var b in repo.bankAccounts) {
        final json = b.toJson();
        json['mandal_id'] = repo.mandalProfile.id;
        batch.insert('bank_accounts', json, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var ev in repo.events) {
        final json = ev.toJson();
        json['mandal_id'] = repo.mandalProfile.id;
        batch.insert('events', json, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error caching repository to SQLite: $e');
    }
  }

  Future<void> clearPendingQueue() async {
    await OfflineDbHelper.instance.clearPendingSyncQueue();
    await refreshPendingCount();
    state.value = state.value.copyWith(
      pendingCount: 0,
      status: SyncStatus.idle,
      message: 'Queue cleared',
    );
  }

  void stop() {
    _connectivitySub?.cancel();
    _dynamicTimer?.cancel();
    _reconnectTimer?.cancel();
    _initialized = false;
  }
}
