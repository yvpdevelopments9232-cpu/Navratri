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

    // 2. Attempt push to Supabase if connected
    bool pushed = false;
    try {
      if (action == 'DELETE') {
        await SupabaseConfig.client.from(table).delete().eq('id', rowId);
        pushed = true;
      } else {
        final res = await SupabaseConfig.client.from(table).upsert(payload).select();
        if (res.isNotEmpty) {
          pushed = true;
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase push failed for $table (operating offline): $e');
    }

    // 3. If offline or push failed, enqueue for automatic background sync
    if (!pushed) {
      await OfflineDbHelper.instance.enqueueSync(
        tableName: table,
        rowId: rowId,
        action: action,
        payload: action != 'DELETE' ? payload : null,
      );
      await SyncService.instance.refreshPendingCount();
    }
  }

  // Mutations linked to active mandal_id
  Future<void> addDonation(DonationModel donation) async {
    final donId = (donation.id.length == 36) ? donation.id : OfflineDbHelper.generateId();
    final donationWithId = donation.copyWith(id: donId);
    donations.insert(0, donationWithId);

    final payload = donationWithId.toJson();
    payload['mandal_id'] = mandalProfile.id;
    payload['donation_date'] = _formatDateForDb(donationWithId.date);

    await _persistAndSync(
      table: 'donations',
      rowId: donId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final expId = (expense.id.length == 36) ? expense.id : OfflineDbHelper.generateId();
    final expenseWithId = expense.copyWith(id: expId);
    expenses.insert(0, expenseWithId);

    final payload = expenseWithId.toJson();
    payload['mandal_id'] = mandalProfile.id;
    payload['expense_date'] = _formatDateForDb(expenseWithId.date);

    await _persistAndSync(
      table: 'expenses',
      rowId: expId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> addMember(MemberModel member) async {
    final memId = (member.id.length == 36) ? member.id : OfflineDbHelper.generateId();
    final memberWithId = member.copyWith(id: memId);
    members.add(memberWithId);

    final payload = memberWithId.toJson();
    payload['mandal_id'] = mandalProfile.id;

    await _persistAndSync(
      table: 'mandal_members',
      rowId: memId,
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

  Future<void> addParticipant(GarbaParticipantModel participant) async {
    participants.insert(0, participant);
    final rowId = participant.id.length == 36 ? participant.id : OfflineDbHelper.generateId();
    final payload = participant.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = mandalProfile.id;

    await _persistAndSync(
      table: 'event_participants',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> addEvent(EventModel event) async {
    events.add(event);
    final rowId = event.id.length == 36 ? event.id : OfflineDbHelper.generateId();
    final payload = event.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = mandalProfile.id;

    await _persistAndSync(
      table: 'events',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> addVolunteer(VolunteerModel volunteer) async {
    volunteers.add(volunteer);
    final rowId = volunteer.id.length == 36 ? volunteer.id : OfflineDbHelper.generateId();
    final payload = volunteer.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = mandalProfile.id;

    await _persistAndSync(
      table: 'volunteers',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> addVendor(VendorModel vendor) async {
    vendors.add(vendor);
    final rowId = vendor.id.length == 36 ? vendor.id : OfflineDbHelper.generateId();
    final payload = vendor.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = mandalProfile.id;

    await _persistAndSync(
      table: 'vendors',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> addInventoryItem(InventoryItemModel item) async {
    inventory.add(item);
    final rowId = item.id.length == 36 ? item.id : OfflineDbHelper.generateId();
    final payload = item.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = mandalProfile.id;

    await _persistAndSync(
      table: 'inventory_items',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> addDocument(DocumentModel doc) async {
    documents.add(doc);
    final rowId = doc.id.length == 36 ? doc.id : OfflineDbHelper.generateId();
    final payload = doc.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = mandalProfile.id;

    await _persistAndSync(
      table: 'documents',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> addSponsor(SponsorModel sponsor) async {
    sponsors.add(sponsor);
    final rowId = sponsor.id.length == 36 ? sponsor.id : OfflineDbHelper.generateId();
    final payload = sponsor.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = mandalProfile.id;

    await _persistAndSync(
      table: 'sponsors',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
    );
  }

  Future<void> addAarti(AartiModel aarti) async {
    aartis.add(aarti);
    final rowId = aarti.id.length == 36 ? aarti.id : OfflineDbHelper.generateId();
    final payload = aarti.toJson();
    payload['id'] = rowId;
    payload['mandal_id'] = mandalProfile.id;

    await _persistAndSync(
      table: 'aarti_schedule',
      rowId: rowId,
      action: 'UPSERT',
      payload: payload,
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
}
