class MandalProfile {
  final String id;
  final String name;
  final String registrationNumber;
  final String address;
  final String contactNumber;
  final String email;
  final String festivalYear;
  final String startingDate;
  final String endingDate;
  final String receiptPrefix;
  final String authorizedSignatoryName;
  final String? logoUrl;

  MandalProfile({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.address,
    required this.contactNumber,
    required this.email,
    required this.festivalYear,
    required this.startingDate,
    required this.endingDate,
    required this.receiptPrefix,
    required this.authorizedSignatoryName,
    this.logoUrl,
  });

  MandalProfile copyWith({
    String? id,
    String? name,
    String? registrationNumber,
    String? address,
    String? contactNumber,
    String? email,
    String? festivalYear,
    String? startingDate,
    String? endingDate,
    String? receiptPrefix,
    String? authorizedSignatoryName,
    String? logoUrl,
  }) {
    return MandalProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      festivalYear: festivalYear ?? this.festivalYear,
      startingDate: startingDate ?? this.startingDate,
      endingDate: endingDate ?? this.endingDate,
      receiptPrefix: receiptPrefix ?? this.receiptPrefix,
      authorizedSignatoryName: authorizedSignatoryName ?? this.authorizedSignatoryName,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  factory MandalProfile.fromJson(Map<String, dynamic> json) {
    return MandalProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Shree Mataji Navratri Utsav Mandal',
      registrationNumber: json['registration_number'] ?? '',
      address: json['address'] ?? 'Pune, Maharashtra',
      contactNumber: json['contact_number'] ?? '9876543210',
      email: json['email'] ?? 'info@mandal.org',
      festivalYear: json['festival_year'] ?? '2026',
      startingDate: json['starting_date'] ?? '2026-09-18',
      endingDate: json['ending_date'] ?? '2026-09-27',
      receiptPrefix: json['receipt_prefix'] ?? 'R-',
      authorizedSignatoryName: json['authorized_signatory_name'] ?? 'Anil Desai',
      logoUrl: json['logo_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty && id.length == 36) 'id': id,
    'name': name,
    'registration_number': registrationNumber,
    'address': address,
    'contact_number': contactNumber,
    'email': email,
    'festival_year': festivalYear,
    'starting_date': startingDate,
    'ending_date': endingDate,
    'receipt_prefix': receiptPrefix,
    'authorized_signatory_name': authorizedSignatoryName,
    if (logoUrl != null) 'logo_url': logoUrl,
  };
}

class MemberModel {
  final String id;
  final String memberCode;
  final String fullName;
  final String role;
  final String mobile;
  final String status;
  final String? photoUrl;
  final String? address;
  final String? joiningDate;
  final String? emergencyContact;

  MemberModel({
    required this.id,
    required this.memberCode,
    required this.fullName,
    required this.role,
    required this.mobile,
    required this.status,
    this.photoUrl,
    this.address,
    this.joiningDate,
    this.emergencyContact,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] ?? '',
      memberCode: json['member_code'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'Member',
      mobile: json['mobile'] ?? '',
      status: json['status'] ?? 'Active',
      photoUrl: json['photo_url'],
      address: json['address'],
      joiningDate: json['joining_date'],
      emergencyContact: json['emergency_contact'],
    );
  }

  String get designation => role;

  MemberModel copyWith({
    String? id,
    String? memberCode,
    String? fullName,
    String? role,
    String? mobile,
    String? status,
    String? photoUrl,
    String? address,
    String? joiningDate,
    String? emergencyContact,
  }) {
    return MemberModel(
      id: id ?? this.id,
      memberCode: memberCode ?? this.memberCode,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      mobile: mobile ?? this.mobile,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      joiningDate: joiningDate ?? this.joiningDate,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'member_code': memberCode,
    'full_name': fullName,
    'role': role,
    'mobile': mobile,
    'status': status,
    'photo_url': photoUrl,
    'address': address,
    'joining_date': joiningDate,
    'emergency_contact': emergencyContact,
  };
}

class DonationModel {
  final String id;
  final String receiptNumber;
  final String date;
  final String donorName;
  final String mobile;
  final String? address;
  final double amount;
  final String paymentMode;
  final String purpose;
  final String collectorName;
  final String? notes;
  final String? attachmentUrl;

  DonationModel({
    required this.id,
    required this.receiptNumber,
    required this.date,
    required this.donorName,
    required this.mobile,
    this.address,
    required this.amount,
    required this.paymentMode,
    required this.purpose,
    required this.collectorName,
    this.notes,
    this.attachmentUrl,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: json['id'] ?? '',
      receiptNumber: json['receipt_number'] ?? '',
      date: json['donation_date'] ?? '',
      donorName: json['donor_name'] ?? '',
      mobile: json['mobile'] ?? '',
      address: json['address'],
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      paymentMode: json['payment_mode'] ?? 'Cash',
      purpose: json['purpose'] ?? 'Festival Donation',
      collectorName: json['collector_name'] ?? '',
      notes: json['notes'],
      attachmentUrl: json['attachment_url'],
    );
  }

  DonationModel copyWith({
    String? id,
    String? receiptNumber,
    String? date,
    String? donorName,
    String? mobile,
    String? address,
    double? amount,
    String? paymentMode,
    String? purpose,
    String? collectorName,
    String? notes,
    String? attachmentUrl,
  }) {
    return DonationModel(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      date: date ?? this.date,
      donorName: donorName ?? this.donorName,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      purpose: purpose ?? this.purpose,
      collectorName: collectorName ?? this.collectorName,
      notes: notes ?? this.notes,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'receipt_number': receiptNumber,
    'donation_date': date,
    'donor_name': donorName,
    'mobile': mobile,
    'address': address,
    'amount': amount,
    'payment_mode': paymentMode,
    'purpose': purpose,
    'collector_name': collectorName,
    'notes': notes,
    'attachment_url': attachmentUrl,
  };
}

class ExpenseModel {
  final String id;
  final String expenseNumber;
  final String date;
  final String categoryName;
  final String? vendorName;
  final String description;
  final double amount;
  final String paymentMode;
  final String paidBy;
  final String? billUrl;
  final String? notes;
  final String status;

  ExpenseModel({
    required this.id,
    required this.expenseNumber,
    required this.date,
    required this.categoryName,
    this.vendorName,
    required this.description,
    required this.amount,
    required this.paymentMode,
    required this.paidBy,
    this.billUrl,
    this.notes,
    required this.status,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? '',
      expenseNumber: json['expense_number'] ?? '',
      date: json['expense_date'] ?? '',
      categoryName: json['category_name'] ?? (json['expense_categories'] != null ? json['expense_categories']['name'] : 'Miscellaneous'),
      vendorName: json['vendor_name'] ?? (json['vendors'] != null ? json['vendors']['vendor_name'] : null),
      description: json['description'] ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      paymentMode: json['payment_mode'] ?? 'Cash',
      paidBy: json['paid_by'] ?? 'Treasurer',
      billUrl: json['bill_url'],
      notes: json['notes'],
      status: json['status'] ?? 'Paid',
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? expenseNumber,
    String? date,
    String? categoryName,
    String? vendorName,
    String? description,
    double? amount,
    String? paymentMode,
    String? paidBy,
    String? billUrl,
    String? notes,
    String? status,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      expenseNumber: expenseNumber ?? this.expenseNumber,
      date: date ?? this.date,
      categoryName: categoryName ?? this.categoryName,
      vendorName: vendorName ?? this.vendorName,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      paidBy: paidBy ?? this.paidBy,
      billUrl: billUrl ?? this.billUrl,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'expense_number': expenseNumber,
    'expense_date': date,
    'description': description,
    'amount': amount,
    'payment_mode': paymentMode,
    'paid_by': paidBy,
    'bill_url': billUrl,
    'notes': notes,
    'status': status,
  };
}

class BankAccountModel {
  final String id;
  final String bankName;
  final String branchName;
  final String accountHolder;
  final String accountNumber;
  final String ifsc;
  final double balance;

  BankAccountModel({
    required this.id,
    required this.bankName,
    required this.branchName,
    required this.accountHolder,
    required this.accountNumber,
    required this.ifsc,
    required this.balance,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] ?? '',
      bankName: json['bank_name'] ?? '',
      branchName: json['branch_name'] ?? '',
      accountHolder: json['account_holder'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifsc: json['ifsc'] ?? '',
      balance: (json['current_balance'] is num) ? (json['current_balance'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bank_name': bankName,
    'branch_name': branchName,
    'account_holder': accountHolder,
    'account_number': accountNumber,
    'ifsc': ifsc,
    'current_balance': balance,
  };

  String get ifscCode => ifsc;
  double get currentBalance => balance;
}

class EventModel {
  final String id;
  final String eventName;
  final String date;
  final String startTime;
  final String endTime;
  final String venue;
  final String status;
  final String? description;

  EventModel({
    required this.id,
    required this.eventName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.status,
    this.description,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      eventName: json['event_name'] ?? '',
      date: json['event_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      venue: json['venue'] ?? 'Mandal Ground',
      status: json['status'] ?? 'Upcoming',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty && id.length == 36) 'id': id,
    'event_name': eventName,
    'event_date': date,
    'start_time': startTime,
    'end_time': endTime,
    'venue': venue,
    'status': status,
    if (description != null) 'description': description,
  };

  String get title => eventName;
  String get location => venue;
  String? get chiefGuest => description;
}

class GarbaParticipantModel {
  final String id;
  final String regNumber;
  final String name;
  final String mobile;
  final int age;
  final String gender;
  final double amount;
  final String status;

  GarbaParticipantModel({
    required this.id,
    required this.regNumber,
    required this.name,
    required this.mobile,
    required this.age,
    required this.gender,
    required this.amount,
    required this.status,
  });

  factory GarbaParticipantModel.fromJson(Map<String, dynamic> json) {
    return GarbaParticipantModel(
      id: json['id'] ?? '',
      regNumber: json['registration_number'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      age: json['age'] ?? 20,
      gender: json['gender'] ?? 'F',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 200.0,
      status: json['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty && id.length == 36) 'id': id,
    'registration_number': regNumber,
    'name': name,
    'mobile': mobile,
    'age': age,
    'gender': gender,
    'amount': amount,
    'status': status,
  };

  String get passNumber => regNumber;
  String get participantName => name;
  String get competitionCategory => gender == 'M' ? 'पुरुष (Men)' : 'महिला (Women)';
  double get passAmount => amount;
}

class VolunteerModel {
  final String id;
  final String code;
  final String name;
  final String mobile;
  final String department;
  final String status;
  final String? photoUrl;

  VolunteerModel({
    required this.id,
    required this.code,
    required this.name,
    required this.mobile,
    required this.department,
    required this.status,
    this.photoUrl,
  });

  factory VolunteerModel.fromJson(Map<String, dynamic> json) {
    return VolunteerModel(
      id: json['id'] ?? '',
      code: json['volunteer_code'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      department: json['department'] ?? 'General',
      status: json['status'] ?? 'Active',
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty && id.length == 36) 'id': id,
    'volunteer_code': code,
    'name': name,
    'mobile': mobile,
    'department': department,
    'status': status,
    if (photoUrl != null) 'photo_url': photoUrl,
  };

  String get volunteerCode => code;
  String get fullName => name;
  String get dutyArea => department;
}

class VendorModel {
  final String id;
  final String vendorCode;
  final String vendorName;
  final String serviceType;
  final String contact;
  final double contractAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;

  VendorModel({
    required this.id,
    required this.vendorCode,
    required this.vendorName,
    required this.serviceType,
    required this.contact,
    required this.contractAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    final contract = (json['contract_amount'] is num) ? (json['contract_amount'] as num).toDouble() : 0.0;
    final paid = (json['paid_amount'] is num) ? (json['paid_amount'] as num).toDouble() : 0.0;
    final remaining = (json['remaining_amount'] is num)
        ? (json['remaining_amount'] as num).toDouble()
        : (contract - paid);

    return VendorModel(
      id: json['id'] ?? '',
      vendorCode: json['vendor_code'] ?? '',
      vendorName: json['vendor_name'] ?? '',
      serviceType: json['service_type'] ?? '',
      contact: json['mobile'] ?? '',
      contractAmount: contract,
      paidAmount: paid,
      remainingAmount: remaining,
      status: json['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty && id.length == 36) 'id': id,
    'vendor_code': vendorCode,
    'vendor_name': vendorName,
    'service_type': serviceType,
    'mobile': contact,
    'contract_amount': contractAmount,
    'paid_amount': paidAmount,
    'remaining_amount': remainingAmount,
    'status': status,
  };
}

class InventoryItemModel {
  final String id;
  final String itemName;
  final String category;
  final int quantity;
  final String unit;
  final String status;

  InventoryItemModel({
    required this.id,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.status,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] ?? '',
      itemName: json['item_name'] ?? '',
      category: json['category'] ?? 'General',
      quantity: json['current_stock'] ?? 0,
      unit: json['unit'] ?? 'Nos',
      status: json['status'] ?? 'In Stock',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty && id.length == 36) 'id': id,
    'item_name': itemName,
    'category': category,
    'current_stock': quantity,
    'unit': unit,
    'status': status,
  };
}

class DocumentModel {
  final String id;
  final String documentName;
  final String issueDate;
  final String expiryDate;
  final String status;
  final String? fileUrl;

  DocumentModel({
    required this.id,
    required this.documentName,
    required this.issueDate,
    required this.expiryDate,
    required this.status,
    this.fileUrl,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] ?? '',
      documentName: json['document_name'] ?? '',
      issueDate: json['issue_date'] ?? '',
      expiryDate: json['expiry_date'] ?? '',
      status: json['status'] ?? 'Valid',
      fileUrl: json['file_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty && id.length == 36) 'id': id,
    'document_name': documentName,
    'issue_date': issueDate,
    'expiry_date': expiryDate,
    'status': status,
    if (fileUrl != null) 'file_url': fileUrl,
  };
}

class SponsorModel {
  final String id;
  final String sponsorName;
  final String package;
  final double amount;
  final double paidAmount;
  final String status;

  SponsorModel({
    required this.id,
    required this.sponsorName,
    required this.package,
    required this.amount,
    required this.paidAmount,
    required this.status,
  });

  factory SponsorModel.fromJson(Map<String, dynamic> json) {
    return SponsorModel(
      id: json['id'] ?? '',
      sponsorName: json['sponsor_name'] ?? '',
      package: json['package_name'] ?? 'General',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      paidAmount: (json['paid_amount'] is num) ? (json['paid_amount'] as num).toDouble() : 0.0,
      status: json['payment_status'] ?? 'Paid',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty && id.length == 36) 'id': id,
    'sponsor_name': sponsorName,
    'package_name': package,
    'amount': amount,
    'paid_amount': paidAmount,
    'payment_status': status,
  };

  String get category => package;
  String get contact => status;
}

class FoodPrasadModel {
  final String id;
  final String date;
  final String menu;
  final int estimatedPeople;
  final int actualPeople;
  final double cost;

  FoodPrasadModel({
    required this.id,
    required this.date,
    required this.menu,
    required this.estimatedPeople,
    required this.actualPeople,
    required this.cost,
  });

  factory FoodPrasadModel.fromJson(Map<String, dynamic> json) {
    return FoodPrasadModel(
      id: json['id'] ?? '',
      date: json['meal_date'] ?? '',
      menu: json['menu'] ?? '',
      estimatedPeople: json['estimated_people'] ?? 0,
      actualPeople: json['actual_people'] ?? 0,
      cost: (json['cost'] is num) ? (json['cost'] as num).toDouble() : 0.0,
    );
  }
}

class SecurityContactModel {
  final String id;
  final String title;
  final String category;
  final String contactNumber;

  SecurityContactModel({
    required this.id,
    required this.title,
    required this.category,
    required this.contactNumber,
  });

  factory SecurityContactModel.fromJson(Map<String, dynamic> json) {
    return SecurityContactModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      contactNumber: json['contact_number'] ?? '',
    );
  }
}

class AartiModel {
  final String id;
  final String aartiName;
  final String date;
  final String time;
  final String leadPerson;

  AartiModel({
    required this.id,
    required this.aartiName,
    required this.date,
    required this.time,
    required this.leadPerson,
  });

  factory AartiModel.fromJson(Map<String, dynamic> json) {
    return AartiModel(
      id: json['id'] ?? '',
      aartiName: json['aarti_name'] ?? '',
      date: json['aarti_date'] ?? '',
      time: json['aarti_time'] ?? '',
      leadPerson: json['lead_person'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty && id.length == 36) 'id': id,
    'aarti_name': aartiName,
    'aarti_date': date,
    'aarti_time': time,
    'lead_person': leadPerson,
  };
}

class IdolModel {
  final String supplier;
  final double cost;
  final String bookingDate;
  final String deliveryDate;
  final String installationDate;
  final String visarjanDate;
  final String transport;
  final String location;
  final String? photoUrl;

  IdolModel({
    required this.supplier,
    required this.cost,
    required this.bookingDate,
    required this.deliveryDate,
    required this.installationDate,
    required this.visarjanDate,
    required this.transport,
    required this.location,
    this.photoUrl,
  });

  factory IdolModel.fromJson(Map<String, dynamic> json) {
    return IdolModel(
      supplier: json['supplier'] ?? 'Mahalaxmi Murti Art',
      cost: (json['idol_cost'] is num) ? (json['idol_cost'] as num).toDouble() : 75000.0,
      bookingDate: json['booking_date'] ?? '2026-06-30',
      deliveryDate: json['delivery_date'] ?? '2026-09-17',
      installationDate: json['installation_date'] ?? '2026-09-17',
      visarjanDate: json['visarjan_date'] ?? '2026-09-27',
      transport: json['transportation_mode'] ?? 'Tempo',
      location: json['visarjan_location'] ?? 'River Bank',
      photoUrl: json['photo_url'],
    );
  }
}

class VisarjanModel {
  final String date;
  final String time;
  final String route;
  final String vehicle;
  final String driver;
  final int volunteers;
  final String status;

  VisarjanModel({
    required this.date,
    required this.time,
    required this.route,
    required this.vehicle,
    required this.driver,
    required this.volunteers,
    required this.status,
  });

  factory VisarjanModel.fromJson(Map<String, dynamic> json) {
    return VisarjanModel(
      date: json['visarjan_date'] ?? '2026-09-27',
      time: json['start_time'] ?? '06:00 AM',
      route: json['route'] ?? 'River Bank',
      vehicle: json['vehicle'] ?? 'Truck',
      driver: json['driver_name'] ?? 'Ramesh',
      volunteers: json['volunteers_count'] ?? 15,
      status: json['status'] ?? 'Scheduled',
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String role;
  final String username;
  final String status;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.username,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['full_name'] ?? '',
      role: json['role_key'] ?? 'Volunteer',
      username: json['email'] ?? '',
      status: json['status'] ?? 'Active',
    );
  }
}

class DashboardSummary {
  final double totalDonation;
  final double totalExpense;
  final double currentBalance;
  final int totalMembers;
  final int totalVolunteers;
  final int upcomingEvents;
  final double todayCollection;
  final double todayExpenses;
  final double bankBalance;
  final double cashBalance;
  final double totalBalance;
  final double deposits;
  final double withdrawals;
  final double netChange;

  DashboardSummary({
    required this.totalDonation,
    required this.totalExpense,
    required this.currentBalance,
    required this.totalMembers,
    required this.totalVolunteers,
    required this.upcomingEvents,
    required this.todayCollection,
    required this.todayExpenses,
    required this.bankBalance,
    required this.cashBalance,
    required this.totalBalance,
    required this.deposits,
    required this.withdrawals,
    required this.netChange,
  });

  factory DashboardSummary.initial() {
    return DashboardSummary(
      totalDonation: 245000.0,
      totalExpense: 118500.0,
      currentBalance: 126500.0,
      totalMembers: 125,
      totalVolunteers: 48,
      upcomingEvents: 9,
      todayCollection: 18500.0,
      todayExpenses: 12000.0,
      bankBalance: 155000.0,
      cashBalance: 32000.0,
      totalBalance: 187000.0,
      deposits: 95000.0,
      withdrawals: 48000.0,
      netChange: 47000.0,
    );
  }
}

class GalleryMediaModel {
  final String id;
  final String mandalId;
  final String mediaType;
  final String category;
  final String title;
  final String fileUrl;
  final String? thumbnailUrl;
  final String? eventId;
  final String? uploadedAt;

  GalleryMediaModel({
    required this.id,
    required this.mandalId,
    this.mediaType = 'image',
    this.category = 'festival',
    required this.title,
    required this.fileUrl,
    this.thumbnailUrl,
    this.eventId,
    this.uploadedAt,
  });

  factory GalleryMediaModel.fromJson(Map<String, dynamic> json) {
    return GalleryMediaModel(
      id: json['id']?.toString() ?? '',
      mandalId: json['mandal_id']?.toString() ?? '',
      mediaType: json['media_type']?.toString() ?? 'image',
      category: json['category']?.toString() ?? 'festival',
      title: json['title']?.toString() ?? 'Celebration Photo',
      fileUrl: json['file_url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      eventId: json['event_id']?.toString(),
      uploadedAt: json['uploaded_at']?.toString() ?? json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mandal_id': mandalId,
    'media_type': mediaType,
    'category': category,
    'title': title,
    'file_url': fileUrl,
    if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
    if (eventId != null) 'event_id': eventId,
    'uploaded_at': uploadedAt ?? DateTime.now().toIso8601String(),
  };
}
