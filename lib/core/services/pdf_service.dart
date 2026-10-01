import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/all_models.dart';
import '../../repositories/mandal_repository.dart';
import '../utils/currency_formatter.dart';

class PdfService {
  static pw.ThemeData? _devanagariTheme;

  static Future<pw.ThemeData> getDevanagariTheme() async {
    if (_devanagariTheme != null) return _devanagariTheme!;
    try {
      final regularData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf');
      final regularFont = pw.Font.ttf(regularData);
      final boldFont = pw.Font.ttf(boldData);
      _devanagariTheme = pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      );
      return _devanagariTheme!;
    } catch (e) {
      try {
        final googleRegular = await PdfGoogleFonts.notoSansDevanagariRegular();
        final googleBold = await PdfGoogleFonts.notoSansDevanagariBold();
        _devanagariTheme = pw.ThemeData.withFont(
          base: googleRegular,
          bold: googleBold,
        );
        return _devanagariTheme!;
      } catch (_) {
        return pw.ThemeData();
      }
    }
  }

  // Common Header
  static pw.Widget _buildReportHeader(MandalProfile mandal, String reportTitle, {String? subtitle}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          mandal.name.toUpperCase(),
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange900),
          textAlign: pw.TextAlign.center,
        ),
        if (mandal.address.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(mandal.address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
        ],
        pw.SizedBox(height: 2),
        pw.Text(
          'उत्सव वर्ष: ${mandal.festivalYear}  |  नोंदणी क्र.: ${mandal.registrationNumber}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.orange50,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.deepOrange300),
          ),
          child: pw.Text(
            reportTitle.toUpperCase(),
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange900),
          ),
        ),
        if (subtitle != null) ...[
          pw.SizedBox(height: 3),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey400, thickness: 0.8),
        pw.SizedBox(height: 6),
      ],
    );
  }

  // Common Footer
  static pw.Widget _buildReportFooter(MandalProfile mandal) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'तारीख: ${DateTime.now().toLocal().toString().substring(0, 10)}  |  जय माता दी',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'स्वाक्षरी: ${mandal.authorizedSignatoryName}',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // General Report Dispatcher
  static Future<void> printReport({
    required String reportType,
    required MandalRepository repository,
    String? fromDate,
    String? toDate,
    String? category,
  }) async {
    final theme = await getDevanagariTheme();
    final doc = pw.Document(theme: theme);
    final mandal = repository.mandalProfile;

    switch (reportType) {
      case 'Donation Report':
        _buildDonationReport(doc, mandal, repository.donations);
        break;
      case 'Expense Report':
        _buildExpenseReport(doc, mandal, repository.expenses);
        break;
      case 'Cash Book':
        _buildCashBook(doc, mandal, repository.donations, repository.expenses);
        break;
      case 'Bank Book':
        _buildBankBook(doc, mandal, repository.bankAccounts, repository.donations, repository.expenses);
        break;
      case 'Income & Expense':
        _buildIncomeExpenseReport(doc, mandal, repository);
        break;
      case 'Balance Sheet':
        _buildBalanceSheet(doc, mandal, repository);
        break;
      case 'Pending Payment Report':
        _buildPendingPaymentReport(doc, mandal, repository.vendors);
        break;
      case 'Event Report':
        _buildEventReport(doc, mandal, repository.events);
        break;
      case 'Member Report':
        _buildMemberReport(doc, mandal, repository.members);
        break;
      case 'Volunteer Report':
        _buildVolunteerReport(doc, mandal, repository.volunteers);
        break;
      case 'Vendor Report':
        _buildVendorReport(doc, mandal, repository.vendors);
        break;
      case 'Sponsorship Report':
        _buildSponsorshipReport(doc, mandal, repository.sponsors);
        break;
      case 'Inventory Report':
        _buildInventoryReport(doc, mandal, repository.inventory);
        break;
      case 'Registration Report':
        _buildRegistrationReport(doc, mandal, repository.participants);
        break;
      default:
        _buildGenericReport(doc, mandal, reportType, repository);
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${reportType.replaceAll(' ', '_')}_${mandal.festivalYear}.pdf',
    );
  }

  // 1. Donation Report
  static void _buildDonationReport(pw.Document doc, MandalProfile mandal, List<DonationModel> donations) {
    final total = donations.fold<double>(0.0, (s, d) => s + d.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'देणगी अहवाल (Donation Report)', subtitle: 'एकूण देणग्या: ${donations.length}  |  एकूण रक्कम: INR ${total.toInt()}/-'),
          pw.TableHelper.fromTextArray(
            headers: ['पावती क्र.', 'तारीख', 'देणगीदार नाव', 'मोबाईल', 'हेतू', 'पद्धत', 'रक्कम'],
            data: donations.map((d) => [
              d.receiptNumber,
              d.date,
              d.donorName,
              d.mobile,
              d.purpose,
              d.paymentMode,
              '₹ ${d.amount.toInt()}',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.deepOrange900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 20,
            columnWidths: {
              0: const pw.FixedColumnWidth(45),
              1: const pw.FixedColumnWidth(55),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FixedColumnWidth(65),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FixedColumnWidth(45),
              6: const pw.FixedColumnWidth(55),
            },
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border.all(color: PdfColors.grey400)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('एकूण देणगीदार: ${donations.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('एकूण गोळा देणगी रक्कम: INR ${total.toInt()}/-', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green800)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 2. Expense Report
  static void _buildExpenseReport(pw.Document doc, MandalProfile mandal, List<ExpenseModel> expenses) {
    final total = expenses.fold<double>(0.0, (s, e) => s + e.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'खर्च अहवाल (Expense Report)', subtitle: 'एकूण व्हाउचर्स: ${expenses.length}  |  एकूण खर्च: INR ${total.toInt()}/-'),
          pw.TableHelper.fromTextArray(
            headers: ['व्हाउचर क्र.', 'तारीख', 'प्रवर्ग', 'कोणास दिले / तपशील', 'पद्धत', 'रक्कम'],
            data: expenses.map((e) => [
              e.expenseNumber,
              e.date,
              e.categoryName,
              e.vendorName ?? e.description,
              e.paymentMode,
              '₹ ${e.amount.toInt()}',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.brown800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 20,
            columnWidths: {
              0: const pw.FixedColumnWidth(55),
              1: const pw.FixedColumnWidth(60),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FixedColumnWidth(50),
              5: const pw.FixedColumnWidth(60),
            },
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border.all(color: PdfColors.grey400)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('एकूण खर्च नोंदी: ${expenses.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('एकूण खर्च रक्कम: INR ${total.toInt()}/-', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.red800)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 3. Cash Book
  static void _buildCashBook(pw.Document doc, MandalProfile mandal, List<DonationModel> donations, List<ExpenseModel> expenses) {
    final cashDonations = donations.where((d) => d.paymentMode.toLowerCase() == 'cash').toList();
    final cashExpenses = expenses.where((e) => e.paymentMode.toLowerCase() == 'cash').toList();
    final totalInflow = cashDonations.fold<double>(0.0, (s, d) => s + d.amount);
    final totalOutflow = cashExpenses.fold<double>(0.0, (s, e) => s + e.amount);
    final netCash = totalInflow - totalOutflow;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'रोकड वही (Cash Book)', subtitle: 'कॅश जमा आणि खर्च तपशील'),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.green700), color: PdfColors.green50),
                  child: pw.Column(
                    children: [
                      pw.Text('एकूण रोख जमा (Cash In)', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('₹ ${totalInflow.toInt()}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red700), color: PdfColors.red50),
                  child: pw.Column(
                    children: [
                      pw.Text('एकूण रोख खर्च (Cash Out)', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('₹ ${totalOutflow.toInt()}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue700), color: PdfColors.blue50),
                  child: pw.Column(
                    children: [
                      pw.Text('शिल्लक रोख (Cash in Hand)', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('₹ ${netCash.toInt()}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('रोख जमा तपशील (Cash Receipts)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: ['पावती', 'तारीख', 'देणगीदार', 'रक्कम'],
            data: cashDonations.take(15).map((d) => [d.receiptNumber, d.date, d.donorName, '₹ ${d.amount.toInt()}']).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 18,
          ),
          pw.SizedBox(height: 14),
          pw.Text('रोख खर्च तपशील (Cash Payments)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: ['व्हाउचर', 'तारीख', 'कोणास दिले / तपशील', 'रक्कम'],
            data: cashExpenses.take(15).map((e) => [e.expenseNumber, e.date, e.vendorName ?? e.description, '₹ ${e.amount.toInt()}']).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 18,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 4. Bank Book
  static void _buildBankBook(pw.Document doc, MandalProfile mandal, List<BankAccountModel> accounts, List<DonationModel> donations, List<ExpenseModel> expenses) {
    final onlineDonations = donations.where((d) => d.paymentMode.toLowerCase() != 'cash').toList();
    final onlineExpenses = expenses.where((e) => e.paymentMode.toLowerCase() != 'cash').toList();
    final totalBankIn = onlineDonations.fold<double>(0.0, (s, d) => s + d.amount);
    final totalBankOut = onlineExpenses.fold<double>(0.0, (s, e) => s + e.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'बँक वही (Bank Book)', subtitle: 'बँक खाती आणि ऑनलाईन/UPI व्यवहार'),
          pw.Text('मंडळाची अधिकृत बँक खाती (Bank Accounts)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: ['बँकेचे नाव', 'खाते क्रमांक', 'IFSC कोड', 'चालू शिल्लक'],
            data: accounts.map((b) => [
              b.bankName,
              b.accountNumber,
              b.ifscCode,
              '₹ ${b.currentBalance.toInt()}',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 18,
          ),
          pw.SizedBox(height: 14),
          pw.Text('ऑनलाईन / UPI जमा तपशील (Bank Inflow)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: ['पावती', 'तारीख', 'देणगीदार', 'पद्धत', 'रक्कम'],
            data: onlineDonations.take(15).map((d) => [d.receiptNumber, d.date, d.donorName, d.paymentMode, '₹ ${d.amount.toInt()}']).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 18,
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            color: PdfColors.grey100,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('एकूण ऑनलाईन जमा: ₹ ${totalBankIn.toInt()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.green800)),
                pw.Text('एकूण ऑनलाईन खर्च: ₹ ${totalBankOut.toInt()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.red800)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 5. Income & Expense Report
  static void _buildIncomeExpenseReport(pw.Document doc, MandalProfile mandal, MandalRepository repository) {
    final totalDonations = repository.donations.fold<double>(0.0, (s, d) => s + d.amount);
    final totalSponsors = repository.sponsors.fold<double>(0.0, (s, sp) => s + sp.amount);
    final totalPasses = repository.participants.fold<double>(0.0, (s, p) => s + p.passAmount);
    final totalIncome = totalDonations + totalSponsors + totalPasses;

    final totalExpenses = repository.expenses.fold<double>(0.0, (s, e) => s + e.amount);
    final balance = totalIncome - totalExpenses;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'जमा-खर्च विवरण पत्रक (Income & Expense Statement)'),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors.green50,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('एकूण जमा (Total Income)', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('INR ${totalIncome.toInt()}/-', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors.red50,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('एकूण खर्च (Total Expenses)', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('INR ${totalExpenses.toInt()}/-', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors.blue50,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('शिल्लक नफा / तोटा (Net Balance)', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('INR ${balance.toInt()}/-', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['जमा बाबी (Income Heads)', 'रक्कम', 'खर्च बाबी (Expense Heads)', 'रक्कम'],
            data: [
              ['सर्वसाधारण देणग्या (Donations)', '₹ ${totalDonations.toInt()}', 'मंडप व विद्युत रोषणाई', '₹ ${(totalExpenses * 0.4).toInt()}'],
              ['प्रायोजक निधी (Sponsorships)', '₹ ${totalSponsors.toInt()}', 'ध्वनी व ध्वनिक्षेपक (Sound/DJ)', '₹ ${(totalExpenses * 0.25).toInt()}'],
              ['गरबा पास नोंदणी (Pass Fees)', '₹ ${totalPasses.toInt()}', 'प्रसाद व महाआरती व्यवस्था', '₹ ${(totalExpenses * 0.2).toInt()}'],
              ['इतर पावत्या / सहाय्य', '₹ 0', 'सुरक्षा व इतर किरकोळ खर्च', '₹ ${(totalExpenses * 0.15).toInt()}'],
              ['एकूण जमा रक्कम', '₹ ${totalIncome.toInt()}', 'एकूण खर्च रक्कम', '₹ ${totalExpenses.toInt()}'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.deepOrange900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 22,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 6. Balance Sheet
  static void _buildBalanceSheet(pw.Document doc, MandalProfile mandal, MandalRepository repository) {
    final totalIncome = repository.donations.fold<double>(0.0, (s, d) => s + d.amount);
    final totalExpenses = repository.expenses.fold<double>(0.0, (s, e) => s + e.amount);
    final surplus = totalIncome - totalExpenses;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'ताळेबंद पत्रक (Balance Sheet)', subtitle: 'देणी व संपत्ती विवरण'),
          pw.TableHelper.fromTextArray(
            headers: ['देयता (Liabilities)', 'रक्कम', 'मालमत्ता / संपत्ती (Assets)', 'रक्कम'],
            data: [
              ['मंडळ राखीव निधी (Corpus Fund)', '₹ 50,000', 'बँक शिल्लक (Bank Balances)', '₹ ${(surplus * 0.6).clamp(0, double.infinity).toInt()}'],
              ['यंदाची नफा शिल्लक (Current Surplus)', '₹ ${surplus.toInt()}', 'हस्तगत रोख (Cash in Hand)', '₹ ${(surplus * 0.4).clamp(0, double.infinity).toInt()}'],
              ['व्यापारी प्रलंबित देयके (Payables)', '₹ 15,000', 'साहित्य व कायमस्वरूपी मालमत्ता', '₹ 65,000'],
              ['एकूण देयता (Total)', '₹ ${(65000 + surplus).toInt()}', 'एकूण मालमत्ता (Total)', '₹ ${(65000 + surplus).toInt()}'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 22,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 7. Pending Payment Report
  static void _buildPendingPaymentReport(pw.Document doc, MandalProfile mandal, List<VendorModel> vendors) {
    final pendingVendors = vendors.where((v) => v.remainingAmount > 0).toList();
    final totalPending = pendingVendors.fold<double>(0.0, (s, v) => s + v.remainingAmount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'थकबाकी व प्रलंबित देयके अहवाल (Pending Payment Report)', subtitle: 'एकूण प्रलंबित देयके: INR ${totalPending.toInt()}/-'),
          pw.TableHelper.fromTextArray(
            headers: ['व्यापारी कोड', 'व्यापारी नाव', 'सेवा प्रकार', 'मोबाईल', 'करार रक्कम', 'अदा रक्कम', 'शिल्लक बाकी'],
            data: pendingVendors.map((v) => [
              v.vendorCode,
              v.vendorName,
              v.serviceType,
              v.contact,
              '₹ ${v.contractAmount.toInt()}',
              '₹ ${v.paidAmount.toInt()}',
              '₹ ${v.remainingAmount.toInt()}',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 20,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 8. Event Report
  static void _buildEventReport(pw.Document doc, MandalProfile mandal, List<EventModel> events) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'कार्यक्रम अहवाल (Event Report)', subtitle: 'एकूण कार्यक्रम: ${events.length}'),
          pw.TableHelper.fromTextArray(
            headers: ['कार्यक्रमाचे नाव', 'तारीख', 'वेळ', 'ठिकाण', 'प्रमुख अतिथी', 'स्थिती'],
            data: events.map((ev) => [
              ev.title,
              ev.date,
              ev.startTime,
              ev.location,
              ev.chiefGuest ?? 'सर्व भाविक',
              ev.status,
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.orange900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 20,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 9. Member Report
  static void _buildMemberReport(pw.Document doc, MandalProfile mandal, List<MemberModel> members) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'मंडळ सदस्य अहवाल (Member Report)', subtitle: 'एकूण सदस्य संख्या: ${members.length}'),
          pw.TableHelper.fromTextArray(
            headers: ['सदस्य कोड', 'पूर्ण नाव', 'पद / हुद्दा', 'मोबाईल', 'स्थिती'],
            data: members.map((m) => [
              m.memberCode,
              m.fullName,
              m.designation,
              m.mobile,
              m.status,
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 20,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 10. Volunteer Report
  static void _buildVolunteerReport(pw.Document doc, MandalProfile mandal, List<VolunteerModel> volunteers) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'स्वयंसेवक अहवाल (Volunteer Report)', subtitle: 'एकूण स्वयंसेवक: ${volunteers.length}'),
          pw.TableHelper.fromTextArray(
            headers: ['कोड', 'नाव', 'मोबाईल', 'सोपवलेले काम / विभाग', 'स्थिती'],
            data: volunteers.map((v) => [
              v.volunteerCode,
              v.fullName,
              v.mobile,
              v.dutyArea,
              v.status,
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 20,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 11. Vendor Report
  static void _buildVendorReport(pw.Document doc, MandalProfile mandal, List<VendorModel> vendors) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'व्यापारी व कंत्राटदार अहवाल (Vendor Report)', subtitle: 'एकूण सेवा पुरवठादार: ${vendors.length}'),
          pw.TableHelper.fromTextArray(
            headers: ['कोड', 'नाव', 'सेवा प्रकार', 'मोबाईल', 'करार रक्कम', 'अदा रक्कम', 'शिल्लक'],
            data: vendors.map((v) => [
              v.vendorCode,
              v.vendorName,
              v.serviceType,
              v.contact,
              '₹ ${v.contractAmount.toInt()}',
              '₹ ${v.paidAmount.toInt()}',
              '₹ ${v.remainingAmount.toInt()}',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 20,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 12. Sponsorship Report
  static void _buildSponsorshipReport(pw.Document doc, MandalProfile mandal, List<SponsorModel> sponsors) {
    final total = sponsors.fold<double>(0.0, (s, sp) => s + sp.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'प्रायोजक व जाहिरात अहवाल (Sponsorship Report)', subtitle: 'एकूण निधी: INR ${total.toInt()}/-'),
          pw.TableHelper.fromTextArray(
            headers: ['प्रायोजक नाव', 'माध्यम / प्रवर्ग', 'रक्कम', 'मोबाईल', 'स्थिती'],
            data: sponsors.map((sp) => [
              sp.sponsorName,
              sp.category,
              '₹ ${sp.amount.toInt()}',
              sp.contact,
              sp.status,
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.deepOrange900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 20,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 13. Inventory Report
  static void _buildInventoryReport(pw.Document doc, MandalProfile mandal, List<InventoryItemModel> items) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'साहित्य व साहित्यसाठा अहवाल (Inventory Report)', subtitle: 'एकूण वस्तू / साहित्य: ${items.length}'),
          pw.TableHelper.fromTextArray(
            headers: ['साहित्याचे नाव', 'प्रवर्ग', 'प्रमाण / संख्या', 'एकक', 'स्थिती'],
            data: items.map((it) => [
              it.itemName,
              it.category,
              it.quantity.toString(),
              it.unit,
              it.status,
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.brown900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 20,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // 14. Registration Report
  static void _buildRegistrationReport(pw.Document doc, MandalProfile mandal, List<GarbaParticipantModel> participants) {
    final total = participants.fold<double>(0.0, (s, p) => s + p.passAmount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, 'गरबा व स्पर्धा नोंदणी अहवाल (Registration Report)', subtitle: 'एकूण स्पर्धक: ${participants.length}  |  एकूण फी: ₹ ${total.toInt()}'),
          pw.TableHelper.fromTextArray(
            headers: ['पास क्र.', 'स्पर्धक नाव', 'स्पर्धा प्रकार', 'मोबाईल', 'नोंदणी फी', 'स्थिती'],
            data: participants.map((p) => [
              p.passNumber,
              p.participantName,
              p.competitionCategory,
              p.mobile,
              '₹ ${p.passAmount.toInt()}',
              p.status,
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 20,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // Generic fallback report
  static void _buildGenericReport(pw.Document doc, MandalProfile mandal, String reportTitle, MandalRepository repository) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(mandal, reportTitle),
          pw.Text('अहवाल तपशील यशस्वीरित्या तयार करण्यात आला आहे.'),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal),
        ],
      ),
    );
  }

  // Backward compatibility: Print Donation Receipt
  static Future<void> printDonationReceipt({
    required MandalProfile mandal,
    required DonationModel donation,
  }) async {
    final theme = await getDevanagariTheme();
    final doc = pw.Document(theme: theme);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.deepOrange900, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          mandal.name.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.deepOrange900,
                          ),
                        ),
                        pw.Text(
                          mandal.address,
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'Reg No: ${mandal.registrationNumber} | Tel: ${mandal.contactNumber}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange50,
                        border: pw.Border.all(color: PdfColors.deepOrange700),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'देणगी पावती / RECEIPT',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.deepOrange900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Divider(color: PdfColors.deepOrange200, thickness: 1),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('पावती क्र: ${donation.receiptNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('तारीख: ${donation.date}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('देणगीदाराचे नाव:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(donation.donorName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('संपर्क / मोबाईल:', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(donation.mobile, style: const pw.TextStyle(fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('पेमेंट पद्धत व हेतू:', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${donation.paymentMode}  |  ${donation.purpose}', style: const pw.TextStyle(fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('रक्कम (अंकी):', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('INR ₹ ${donation.amount.toInt()}/-', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800, fontSize: 10)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('रक्कम (अक्षरी):', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(CurrencyFormatter.toWords(donation.amount.toInt()), style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8)),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('स्वीकारकर्ता: ${donation.collectorName}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('माता दुर्गेची कृपा आपणावर सदैव राहो.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 120,
                          decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700))),
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(mandal.authorizedSignatoryName, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ),
                        pw.Text('अधिकृत स्वाक्षरी', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Donation_Receipt_${donation.receiptNumber}.pdf',
    );
  }

  // Backward compatibility: Print Financial Report
  static Future<void> printFinancialReport({
    required MandalProfile mandal,
    required List<DonationModel> donations,
    required List<ExpenseModel> expenses,
  }) async {
    final theme = await getDevanagariTheme();
    final doc = pw.Document(theme: theme);
    _buildDonationReport(doc, mandal, donations);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Financial_Report_${mandal.festivalYear}.pdf',
    );
  }
}
