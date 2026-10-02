import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../config/supabase_config.dart';
import '../models/all_models.dart';
import '../services/offline_db_helper.dart';
import '../services/sync_service.dart';

class MandalRepository {
  static final MandalRepository _instance = MandalRepository._internal();
  factory MandalRepository() => _instance;
  MandalRepository._internal();

  // Active Mandal Profile - empty by default until loaded / signed up
  MandalProfile mandalProfile = MandalProfile(
    id: '',
    name: '',
    registrationNumber: '',
    address: '',
    contactNumber: '',
    email: '',
    festivalYear: '2026',
    startingDate: '2026-09-18',
    endingDate: '2026-09-27',
    receiptPrefix: 'R-',
    authorizedSignatoryName: '',
  );

  // Pure dynamic data lists - ZERO hardcoded dummy records
  List<MemberModel> members = [];
  List<DonationModel> donations = [];
  List<ExpenseModel> expenses = [];
  List<BankAccountModel> bankAccounts = [];
  List<EventModel> events = [];
  List<GarbaParticipantModel> participants = [];
  List<VolunteerModel> volunteers = [];
  List<VendorModel> vendors = [];
  List<InventoryItemModel> inventory = [];
  List<DocumentModel> documents = [];
  List<SponsorModel> sponsors = [];
  List<FoodPrasadModel> foodMenu = [];
  List<GalleryMediaModel> galleryMedia = [];
  List<SecurityContactModel> securityContacts = [
    SecurityContactModel(id: '1', title: 'Police Control Room', category: 'Police', contactNumber: '100'),
    SecurityContactModel(id: '2', title: 'Fire Brigade', category: 'Fire Brigade', contactNumber: '101'),
    SecurityContactModel(id: '3', title: 'Ambulance', category: 'Ambulance', contactNumber: '108'),
  ];
  List<AartiModel> aartis = [];
  List<UserModel> users = [];

  IdolModel idolDetails = IdolModel(
    supplier: '',
    cost: 0,
    bookingDate: '',
    deliveryDate: '',
    installationDate: '',
    visarjanDate: '',
    transport: '',
    location: '',
  );

  VisarjanModel visarjanDetails = VisarjanModel(
    date: '',
    time: '',
    route: '',
    vehicle: '',
    driver: '',
    volunteers: 0,
    status: 'Scheduled',
  );

  /// Dynamic summary calculation with strictly 0 fallback when empty
  DashboardSummary getSummary() {
    final totalDonations = donations.fold<double>(0.0, (sum, d) => sum + d.amount);
    final totalExpenses = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final currentBal = totalDonations - totalExpenses;
    final totalBank = bankAccounts.fold<double>(0.0, (sum, b) => sum + b.balance);

    // Dynamic cash balance: Cash donations - Cash expenses
    final cashIn = donations
        .where((d) => d.paymentMode.toLowerCase() == 'cash')
        .fold<double>(0.0, (sum, d) => sum + d.amount);
    final cashOut = expenses
        .where((e) => e.paymentMode.toLowerCase() == 'cash')
        .fold<double>(0.0, (sum, e) => sum + e.amount);
    final totalCash = (cashIn - cashOut) > 0 ? (cashIn - cashOut) : 0.0;

    final now = DateTime.now();
    final todayStr1 = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    final todayStr2 = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final todayColl = donations
        .where((d) => d.date == todayStr1 || d.date == todayStr2)
        .fold<double>(0.0, (sum, d) => sum + d.amount);
    final todayExp = expenses
        .where((e) => e.date == todayStr1 || e.date == todayStr2)
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    return DashboardSummary(
      totalDonation: totalDonations,
      totalExpense: totalExpenses,
      currentBalance: currentBal,
      totalMembers: members.length,
      totalVolunteers: volunteers.length,
      upcomingEvents: events.where((e) => e.status.toLowerCase() == 'upcoming').length,
      todayCollection: todayColl,
      todayExpenses: todayExp,
      bankBalance: totalBank,
      cashBalance: totalCash,
      totalBalance: totalBank + totalCash,
      deposits: totalBank,
      withdrawals: totalExpenses,
      netChange: currentBal,
    );
  }

  /// Purge all cached data on sign out or user switch
  void clearAllData() {
    mandalProfile = MandalProfile(
      id: '',
      name: '',
      registrationNumber: '',
      address: '',
      contactNumber: '',
      email: '',
      festivalYear: '2026',
      startingDate: '2026-09-18',
      endingDate: '2026-09-27',
      receiptPrefix: 'R-',
      authorizedSignatoryName: '',
    );
    members = [];
    donations = [];
    expenses = [];
    bankAccounts = [];
    events = [];
    participants = [];
    volunteers = [];
    vendors = [];
    inventory = [];
    documents = [];
    sponsors = [];
    foodMenu = [];
    aartis = [];
    users = [];
  }

  /// Load all cached data from local SQLite database (Instant startup, zero offline delay)
  Future<void> loadFromLocalDb({String? mandalId}) async {
    try {
      final db = await OfflineDbHelper.instance.database;

      // 1. Mandal Profile
      final mandalRows = await db.query(
        'mandals',
        where: mandalId != null ? 'id = ?' : null,
        whereArgs: mandalId != null ? [mandalId] : null,
        limit: 1,
      );
      if (mandalRows.isNotEmpty) {
        mandalProfile = MandalProfile.fromJson(mandalRows.first);
      }

      final activeMandalId = mandalProfile.id;
      final whereClause = activeMandalId.isNotEmpty ? 'mandal_id = ?' : null;
      final whereArgs = activeMandalId.isNotEmpty ? [activeMandalId] : null;

      // 2. Donations
      final donRows = await db.query(
        'donations',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC, id DESC',
      );
      if (donRows.isNotEmpty) {
        donations = donRows.map((e) => DonationModel.fromJson(e)).toList();
      }

      // 3. Members
      final memRows = await db.query(
        'mandal_members',
        where: whereClause,
        whereArgs: whereArgs,
      );
      if (memRows.isNotEmpty) {
        members = memRows.map((e) => MemberModel.fromJson(e)).toList();
      }

      // 4. Expenses
      final expRows = await db.query(
        'expenses',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC, id DESC',
      );
      if (expRows.isNotEmpty) {
        expenses = expRows.map((e) => ExpenseModel.fromJson(e)).toList();
      }

      // 5. Bank Accounts
      final bankRows = await db.query(
        'bank_accounts',
        where: whereClause,
        whereArgs: whereArgs,
      );
      if (bankRows.isNotEmpty) {
        bankAccounts = bankRows.map((e) => BankAccountModel.fromJson(e)).toList();
      }

      // 6. Events
      final eventRows = await db.query(
        'events',
        where: whereClause,
        whereArgs: whereArgs,
      );
      if (eventRows.isNotEmpty) {
        events = eventRows.map((e) => EventModel.fromJson(e)).toList();
      }

      // 7. Volunteers
      final volRows = await db.query(
        'volunteers',
        where: whereClause,
        whereArgs: whereArgs,
      );
      if (volRows.isNotEmpty) {
        volunteers = volRows.map((e) => VolunteerModel.fromJson(e)).toList();
      }

      // 8. Vendors
      final venRows = await db.query(
        'vendors',
        where: whereClause,
        whereArgs: whereArgs,
      );
      if (venRows.isNotEmpty) {
        vendors = venRows.map((e) => VendorModel.fromJson(e)).toList();
      }

      // 9. Gallery Media
      try {
        final galRows = await db.query(
          'gallery',
          where: whereClause,
          whereArgs: whereArgs,
          orderBy: 'uploaded_at DESC, id DESC',
        );
        if (galRows.isNotEmpty) {
          galleryMedia = galRows.map((e) => GalleryMediaModel.fromJson(e)).toList();
        }
      } catch (_) {}

      debugPrint('Loaded local SQLite database cache successfully.');
    } catch (e) {
      debugPrint('Error loading from local SQLite database: $e');
    }
  }

  /// Multi-tenant sync strictly scoped by mandal_id
  Future<void> syncFromSupabase({String? mandalId}) async {
    final activeId = mandalId ?? mandalProfile.id;
    if (activeId.isEmpty) {
      debugPrint('syncFromSupabase: No active mandal_id provided.');
      return;
    }

    try {
      final client = SupabaseConfig.client;

      // 1. Fetch Mandal Profile
      final mandalRes = await client.from('mandals').select().eq('id', activeId).maybeSingle();
      if (mandalRes != null) {
        mandalProfile = MandalProfile.fromJson(mandalRes);
      }

      // 2. Fetch Donations
      final donRes = await client
          .from('donations')
          .select()
          .eq('mandal_id', activeId)
          .order('created_at', ascending: false);
      donations = (donRes as List).map((e) => DonationModel.fromJson(e)).toList();

      // 3. Fetch Members
      final memRes = await client.from('mandal_members').select().eq('mandal_id', activeId);
      members = (memRes as List).map((e) => MemberModel.fromJson(e)).toList();

      // 4. Fetch Expenses
      final expRes = await client
          .from('expenses')
          .select()
          .eq('mandal_id', activeId)
          .order('created_at', ascending: false);
      expenses = (expRes as List).map((e) => ExpenseModel.fromJson(e)).toList();

      // 5. Fetch Bank Accounts
      final bankRes = await client.from('bank_accounts').select().eq('mandal_id', activeId);
      bankAccounts = (bankRes as List).map((e) => BankAccountModel.fromJson(e)).toList();

      // 6. Fetch Events
      final eventRes = await client.from('events').select().eq('mandal_id', activeId);
      events = (eventRes as List).map((e) => EventModel.fromJson(e)).toList();

      // 7. Fetch Volunteers
      final volRes = await client.from('volunteers').select().eq('mandal_id', activeId);
      volunteers = (volRes as List).map((e) => VolunteerModel.fromJson(e)).toList();

      // 8. Fetch Vendors
      final venRes = await client.from('vendors').select().eq('mandal_id', activeId);
      vendors = (venRes as List).map((e) => VendorModel.fromJson(e)).toList();

      // 9. Fetch Inventory
      final invRes = await client.from('inventory_items').select().eq('mandal_id', activeId);
      inventory = (invRes as List).map((e) => InventoryItemModel.fromJson(e)).toList();

      // 10. Fetch Documents
      final docRes = await client.from('documents').select().eq('mandal_id', activeId);
      documents = (docRes as List).map((e) => DocumentModel.fromJson(e)).toList();

      // 11. Fetch Sponsors
      final sponRes = await client.from('sponsors').select().eq('mandal_id', activeId);
      sponsors = (sponRes as List).map((e) => SponsorModel.fromJson(e)).toList();

      // 12. Fetch Food Prasad
      final foodRes = await client.from('food_prasad').select().eq('mandal_id', activeId);
      foodMenu = (foodRes as List).map((e) => FoodPrasadModel.fromJson(e)).toList();

      // 13. Fetch Aarti Schedule
      final aartiRes = await client.from('aarti_schedule').select().eq('mandal_id', activeId);
      aartis = (aartiRes as List).map((e) => AartiModel.fromJson(e)).toList();

      // 14. Fetch Event Participants
      final partRes = await client.from('event_participants').select().eq('mandal_id', activeId);
      participants = (partRes as List).map((e) => GarbaParticipantModel.fromJson(e)).toList();

      // 15. Fetch Gallery Media
      try {
        final galRes = await client.from('gallery').select().eq('mandal_id', activeId).order('uploaded_at', ascending: false);
        if (galRes.isNotEmpty) {
          galleryMedia = galRes.map((e) => GalleryMediaModel.fromJson(e)).toList();
          final db = await OfflineDbHelper.instance.database;
          for (final g in galleryMedia) {
            await db.insert('gallery', g.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      } catch (_) {}

      debugPrint('Supabase 2-way sync successfully completed for mandal: $activeId');
    } catch (e) {
      debugPrint('Supabase live fetch notice: $e (using current in-memory state)');
    }
  }

  String _formatDateForDb(String inputDate) {
    if (inputDate.contains('-')) {
      final parts = inputDate.split('-');
      if (parts.length == 3 && parts[0].length == 2 && parts[2].length == 4) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    }
    return inputDate.isNotEmpty ? inputDate : DateTime.now().toIso8601String().substring(0, 10);
  }

  // Offline-First Mutation & Sync Engine
  Future<void> _persistAndSync({
    required String table,
    required String rowId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    // 1. Save to local SQLite database
    try {
      final db = await OfflineDbHelper.instance.database;
      if (action == 'DELETE') {
        await db.delete(table, where: 'id = ?', whereArgs: [rowId]);
      } else {
        await db.insert(table, payload, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      debugPrint('Local SQLite mutation error for $table: $e');
    }

    // 2. Push to Supabase asynchronously in background so UI and buttons remain 100% smooth & instant
    () async {
      bool pushed = false;
      try {
        if (action == 'DELETE') {
          await SupabaseConfig.client
              .from(table)
              .delete()
              .eq('id', rowId)
              .timeout(const Duration(milliseconds: 2500));
          pushed = true;
        } else {
          final res = await SupabaseConfig.client
              .from(table)
              .upsert(payload)
              .select()
              .timeout(const Duration(milliseconds: 2500));
          if (res.isNotEmpty) {
            pushed = true;
          }
        }
      } catch (e) {
        debugPrint('Direct Supabase push notice for $table: $e');
      }

      // 3. If offline, timeout, or push failed, enqueue for automatic background sync
      if (!pushed) {
        await OfflineDbHelper.instance.enqueueSync(
          tableName: table,
          rowId: rowId,
          action: action,
          payload: action != 'DELETE' ? payload : null,
        );
        await SyncService.instance.refreshPendingCount();
      }
    }();
  }

  String get _activeMandalId => mandalProfile.id.isNotEmpty ? mandalProfile.id : '00000000-0000-0000-0000-000000000001';

  // Mutations linked to active mandal_id
  Future<void> addDonation(DonationModel donation) async {
    final donId = (donation.id.length == 36) ? donation.id : OfflineDbHelper.generateId();
    final donationWithId = donation.copyWith(id: donId);
    donations.insert(0, donationWithId);

    final payload = donationWithId.toJson();
    payload['mandal_id'] = _activeMandalId;
    payload['donation_date'] = _formatDateForDb(donationWithId.date);

    await _persistAndSync(
      table: 'donations',
      rowId: donId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> updateDonation(DonationModel donation) async {
    final idx = donations.indexWhere((d) => d.id == donation.id);
    if (idx != -1) {
      donations[idx] = donation;
    }
    final payload = donation.toJson();
    payload['mandal_id'] = _activeMandalId;
    payload['donation_date'] = _formatDateForDb(donation.date);

    await _persistAndSync(
      table: 'donations',
      rowId: donation.id,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> deleteDonation(String id) async {
    donations.removeWhere((d) => d.id == id);
    await _persistAndSync(
      table: 'donations',
      rowId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final expId = (expense.id.length == 36) ? expense.id : OfflineDbHelper.generateId();
    final expenseWithId = expense.copyWith(id: expId);
    expenses.insert(0, expenseWithId);

    final payload = expenseWithId.toJson();
    payload['mandal_id'] = _activeMandalId;
    payload['expense_date'] = _formatDateForDb(expenseWithId.date);

    await _persistAndSync(
      table: 'expenses',
      rowId: expId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final idx = expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      expenses[idx] = expense;
    }
    final payload = expense.toJson();
    payload['mandal_id'] = _activeMandalId;
    payload['expense_date'] = _formatDateForDb(expense.date);

    await _persistAndSync(
      table: 'expenses',
      rowId: expense.id,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> deleteExpense(String id) async {
    expenses.removeWhere((e) => e.id == id);
    await _persistAndSync(
      table: 'expenses',
      rowId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  Future<void> addMember(MemberModel member) async {
    final memId = (member.id.length == 36) ? member.id : OfflineDbHelper.generateId();
    final memberWithId = member.copyWith(id: memId);
    members.add(memberWithId);

    final payload = memberWithId.toJson();
    payload['mandal_id'] = _activeMandalId;

    await _persistAndSync(
      table: 'mandal_members',
      rowId: memId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> updateMember(MemberModel member) async {
    final idx = members.indexWhere((m) => m.id == member.id);
    if (idx != -1) {
      members[idx] = member;
    }
    final payload = member.toJson();
    payload['mandal_id'] = _activeMandalId;

    await _persistAndSync(
      table: 'mandal_members',
      rowId: member.id,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> deleteMember(String id) async {
    members.removeWhere((m) => m.id == id);
    await _persistAndSync(
      table: 'mandal_members',
      rowId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  // Bank Accounts
  Future<void> addBankAccount(BankAccountModel account) async {
    final accId = account.id.length == 36 ? account.id : OfflineDbHelper.generateId();
    final accWithId = account.copyWith(id: accId);
    bankAccounts.add(accWithId);
    final payload = accWithId.toJson();
    payload['mandal_id'] = _activeMandalId;
    await _persistAndSync(
      table: 'bank_accounts',
      rowId: accId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> updateBankAccount(BankAccountModel account) async {
    final idx = bankAccounts.indexWhere((b) => b.id == account.id);
    if (idx != -1) {
      bankAccounts[idx] = account;
    }
    final payload = account.toJson();
    payload['mandal_id'] = _activeMandalId;
    await _persistAndSync(
      table: 'bank_accounts',
      rowId: account.id,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> deleteBankAccount(String id) async {
    bankAccounts.removeWhere((b) => b.id == id);
    await _persistAndSync(
      table: 'bank_accounts',
      rowId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  Future<void> addParticipant(GarbaParticipantModel participant) async {
    final rowId = participant.id.length == 36 ? participant.id : OfflineDbHelper.generateId();
    final pWithId = participant.copyWith(id: rowId);
    participants.insert(0, pWithId);
    final payload = pWithId.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = _activeMandalId;

    await _persistAndSync(
      table: 'event_participants',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> updateParticipant(GarbaParticipantModel participant) async {
    final idx = participants.indexWhere((p) => p.id == participant.id);
    if (idx != -1) participants[idx] = participant;
    final payload = participant.toJson();
    payload['id'] = participant.id;
    payload['mandal_id'] = _activeMandalId;
    await _persistAndSync(
      table: 'event_participants',
      rowId: participant.id,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> deleteParticipant(String id) async {
    participants.removeWhere((p) => p.id == id);
    await _persistAndSync(
      table: 'event_participants',
      rowId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  Future<void> addEvent(EventModel event) async {
    final rowId = event.id.length == 36 ? event.id : OfflineDbHelper.generateId();
    final evWithId = event.copyWith(id: rowId);
    events.add(evWithId);
    final payload = evWithId.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = _activeMandalId;

    await _persistAndSync(
      table: 'events',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> updateEvent(EventModel event) async {
    final idx = events.indexWhere((e) => e.id == event.id);
    if (idx != -1) events[idx] = event;
    final payload = event.toJson();
    payload['id'] = event.id;
    payload['mandal_id'] = _activeMandalId;
    await _persistAndSync(
      table: 'events',
      rowId: event.id,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> deleteEvent(String id) async {
    events.removeWhere((e) => e.id == id);
    await _persistAndSync(
      table: 'events',
      rowId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  Future<void> addVolunteer(VolunteerModel volunteer) async {
    final rowId = volunteer.id.length == 36 ? volunteer.id : OfflineDbHelper.generateId();
    final volWithId = volunteer.copyWith(id: rowId);
    volunteers.add(volWithId);
    final payload = volWithId.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = _activeMandalId;

    await _persistAndSync(
      table: 'volunteers',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> updateVolunteer(VolunteerModel volunteer) async {
    final idx = volunteers.indexWhere((v) => v.id == volunteer.id);
    if (idx != -1) volunteers[idx] = volunteer;
    final payload = volunteer.toJson();
    payload['id'] = volunteer.id;
    payload['mandal_id'] = _activeMandalId;
    await _persistAndSync(
      table: 'volunteers',
      rowId: volunteer.id,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> deleteVolunteer(String id) async {
    volunteers.removeWhere((v) => v.id == id);
    await _persistAndSync(
      table: 'volunteers',
      rowId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  Future<void> addVendor(VendorModel vendor) async {
    final rowId = vendor.id.length == 36 ? vendor.id : OfflineDbHelper.generateId();
    final venWithId = vendor.copyWith(id: rowId);
    vendors.add(venWithId);
    final payload = venWithId.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = _activeMandalId;

    await _persistAndSync(
      table: 'vendors',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> updateVendor(VendorModel vendor) async {
    final idx = vendors.indexWhere((v) => v.id == vendor.id);
    if (idx != -1) vendors[idx] = vendor;
    final payload = vendor.toJson();
    payload['id'] = vendor.id;
    payload['mandal_id'] = _activeMandalId;
    await _persistAndSync(
      table: 'vendors',
      rowId: vendor.id,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> deleteVendor(String id) async {
    vendors.removeWhere((v) => v.id == id);
    await _persistAndSync(
      table: 'vendors',
      rowId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  Future<void> addInventoryItem(InventoryItemModel item) async {
    final rowId = item.id.length == 36 ? item.id : OfflineDbHelper.generateId();
    final itemWithId = item.copyWith(id: rowId);
    inventory.add(itemWithId);
    final payload = itemWithId.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = _activeMandalId;

    await _persistAndSync(
      table: 'inventory_items',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> updateInventoryItem(InventoryItemModel item) async {
    final idx = inventory.indexWhere((i) => i.id == item.id);
    if (idx != -1) inventory[idx] = item;
    final payload = item.toJson();
    payload['id'] = item.id;
    payload['mandal_id'] = _activeMandalId;
    await _persistAndSync(
      table: 'inventory_items',
      rowId: item.id,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> deleteInventoryItem(String id) async {
    inventory.removeWhere((i) => i.id == id);
    await _persistAndSync(
      table: 'inventory_items',
      rowId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  Future<void> addDocument(DocumentModel doc) async {
    documents.add(doc);
    final rowId = doc.id.length == 36 ? doc.id : OfflineDbHelper.generateId();
    final payload = doc.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = _activeMandalId;

    await _persistAndSync(
      table: 'documents',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> addSponsor(SponsorModel sponsor) async {
    final rowId = sponsor.id.length == 36 ? sponsor.id : OfflineDbHelper.generateId();
    final spWithId = sponsor.copyWith(id: rowId);
    sponsors.add(spWithId);
    final payload = spWithId.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = _activeMandalId;

    await _persistAndSync(
      table: 'sponsors',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> updateSponsor(SponsorModel sponsor) async {
    final idx = sponsors.indexWhere((s) => s.id == sponsor.id);
    if (idx != -1) sponsors[idx] = sponsor;
    final payload = sponsor.toJson();
    payload['id'] = sponsor.id;
    payload['mandal_id'] = _activeMandalId;
    await _persistAndSync(
      table: 'sponsors',
      rowId: sponsor.id,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> deleteSponsor(String id) async {
    sponsors.removeWhere((s) => s.id == id);
    await _persistAndSync(
      table: 'sponsors',
      rowId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  Future<void> addAarti(AartiModel aarti) async {
    final rowId = aarti.id.length == 36 ? aarti.id : OfflineDbHelper.generateId();
    final aWithId = aarti.copyWith(id: rowId);
    aartis.add(aWithId);
    final payload = aWithId.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = _activeMandalId;

    await _persistAndSync(
      table: 'aarti_schedule',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> updateAarti(AartiModel aarti) async {
    final idx = aartis.indexWhere((a) => a.id == aarti.id);
    if (idx != -1) aartis[idx] = aarti;
    final payload = aarti.toJson();
    payload['id'] = aarti.id;
    payload['mandal_id'] = _activeMandalId;
    await _persistAndSync(
      table: 'aarti_schedule',
      rowId: aarti.id,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> deleteAarti(String id) async {
    aartis.removeWhere((a) => a.id == id);
    await _persistAndSync(
      table: 'aarti_schedule',
      rowId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }

  Future<void> updateMandalProfile(MandalProfile updated) async {
    mandalProfile = updated;
    final rowId = updated.id.isNotEmpty ? updated.id : OfflineDbHelper.generateId();
    final payload = updated.toJson();
    payload['id'] = rowId;

    await _persistAndSync(
      table: 'mandals',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );

    // Also update profiles table avatar_url if logoUrl is provided
    if (updated.logoUrl != null && updated.logoUrl!.isNotEmpty) {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        try {
          await SupabaseConfig.client.from('profiles').update({'avatar_url': updated.logoUrl}).eq('id', userId);
        } catch (_) {}
      }
    }
  }

  Future<void> addGalleryMedia(GalleryMediaModel media) async {
    galleryMedia.insert(0, media);
    final rowId = media.id.length == 36 ? media.id : OfflineDbHelper.generateId();
    final payload = media.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = _activeMandalId;

    await _persistAndSync(
      table: 'gallery',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> deleteGalleryMedia(String id) async {
    galleryMedia.removeWhere((g) => g.id == id);
    await _persistAndSync(
      table: 'gallery',
      rowId: id,
      action: 'DELETE',
      payload: {'id': id},
    );
  }
}

