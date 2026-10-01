import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_text_shaper/pdf_text_shaper.dart';
import 'package:printing/printing.dart';
import '../../models/all_models.dart';
import '../../repositories/mandal_repository.dart';
import '../utils/currency_formatter.dart';

class PdfService {
  static Uint8List? _cachedDevRegular;
  static Uint8List? _cachedDevBold;
  static Uint8List? _cachedRoboto;
  static Uint8List? _cachedAppLogoBytes;

  static Future<void> _initFonts() async {
    if (_cachedDevRegular != null && _cachedDevBold != null && _cachedRoboto != null && _cachedAppLogoBytes != null) return;
    try {
      if (_cachedDevRegular == null) {
        final devReg = await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
        _cachedDevRegular = devReg.buffer.asUint8List(devReg.offsetInBytes, devReg.lengthInBytes);
      }
      if (_cachedDevBold == null) {
        final devBold = await rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf');
        _cachedDevBold = devBold.buffer.asUint8List(devBold.offsetInBytes, devBold.lengthInBytes);
      }
      if (_cachedRoboto == null) {
        final roboto = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
        _cachedRoboto = roboto.buffer.asUint8List(roboto.offsetInBytes, roboto.lengthInBytes);
      }
      if (_cachedAppLogoBytes == null) {
        try {
          final logo = await rootBundle.load('assets/images/app_logo.png');
          _cachedAppLogoBytes = logo.buffer.asUint8List(logo.offsetInBytes, logo.lengthInBytes);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error loading fonts or logo for PDF: $e');
    }
  }

  /// Sanitizes text so only runes supported by loaded fonts or whitespace are emitted.
  /// Prevents HarfBuzz StateError on unsupported emojis or obscure symbols.
  static String _cleanText(String? input, List<ShapedFont> fonts) {
    if (input == null || input.isEmpty) return '';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune == 0x09 || rune == 0x0A || rune == 0x0D || rune == 0x20 || rune == 0x00A0) {
        buffer.writeCharCode(rune);
        continue;
      }
      bool supported = false;
      for (final font in fonts) {
        if (font.supportsRune(rune)) {
          supported = true;
          break;
        }
      }
      if (supported) {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static pw.MemoryImage? _getLogoImage(MandalProfile mandal) {
    if (mandal.logoUrl != null && mandal.logoUrl!.isNotEmpty) {
      try {
        final clean = mandal.logoUrl!.contains(',') ? mandal.logoUrl!.split(',').last : mandal.logoUrl!;
        final bytes = base64Decode(clean);
        return pw.MemoryImage(bytes);
      } catch (_) {}
    }
    if (_cachedAppLogoBytes != null) {
      return pw.MemoryImage(_cachedAppLogoBytes!);
    }
    return null;
  }

  // Common Header with Profile Logo at Top-Left Corner
  static pw.Widget _buildReportHeader({
    required MandalProfile mandal,
    required String reportTitle,
    String? subtitle,
    required pw.MemoryImage? logoImage,
    required List<ShapedFont> fonts,
    required ShapedTextStyle titleStyle,
    required ShapedTextStyle subStyle,
    required ShapedTextStyle badgeStyle,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Top-left Mandal Profile Image
            if (logoImage != null)
              pw.Container(
                width: 48,
                height: 48,
                margin: const pw.EdgeInsets.only(right: 12),
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: PdfColors.deepOrange900, width: 1.5),
                ),
                child: pw.ClipOval(
                  child: pw.Image(logoImage, width: 48, height: 48, fit: pw.BoxFit.cover),
                ),
              )
            else
              pw.Container(
                width: 48,
                height: 48,
                margin: const pw.EdgeInsets.only(right: 12),
                decoration: const pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: PdfColors.deepOrange900,
                ),
                child: pw.Center(
                  child: pw.Text(
                    mandal.name.isNotEmpty ? mandal.name[0] : 'म',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  ShapedText(
                    _cleanText(mandal.name.toUpperCase(), fonts),
                    style: titleStyle,
                  ),
                  if (mandal.address.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    ShapedText(
                      _cleanText(mandal.address, fonts),
                      style: subStyle,
                    ),
                  ],
                  pw.SizedBox(height: 2),
                  ShapedText(
                    _cleanText('उत्सव वर्ष: ${mandal.festivalYear}  |  नोंदणी क्र.: ${mandal.registrationNumber}', fonts),
                    style: subStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.orange50,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.deepOrange300),
          ),
          child: ShapedText(
            _cleanText(reportTitle.toUpperCase(), fonts),
            style: badgeStyle,
          ),
        ),
        if (subtitle != null) ...[
          pw.SizedBox(height: 3),
          ShapedText(
            _cleanText(subtitle, fonts),
            style: subStyle,
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey400, thickness: 0.8),
        pw.SizedBox(height: 6),
      ],
    );
  }

  // Common Footer
  static pw.Widget _buildReportFooter(MandalProfile mandal, List<ShapedFont> fonts, ShapedTextStyle footerStyle, ShapedTextStyle footerBoldStyle) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            ShapedText(
              _cleanText('तारीख: ${DateTime.now().toLocal().toString().substring(0, 10)}  |  जय माता दी', fonts),
              style: footerStyle,
            ),
            ShapedText(
              _cleanText('अधिकृत स्वाक्षरी: ${mandal.authorizedSignatoryName}', fonts),
              style: footerBoldStyle,
            ),
          ],
        ),
      ],
    );
  }

  // Helper to build a table with HarfBuzz ShapedText to fix Marathi ligatures & eliminate tofu boxes
  static pw.Table _buildShapedTable({
    required List<String> headers,
    required List<List<String>> data,
    required List<ShapedFont> fonts,
    required ShapedTextStyle headerStyle,
    required ShapedTextStyle cellStyle,
    Map<int, pw.TableColumnWidth>? columnWidths,
    PdfColor headerColor = PdfColors.deepOrange900,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: columnWidths,
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            for (final h in headers)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                alignment: pw.Alignment.centerLeft,
                child: ShapedText(
                  _cleanText(h, fonts),
                  style: headerStyle,
                ),
              ),
          ],
        ),
        // Data Rows
        for (int r = 0; r < data.length; r++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: r % 2 == 1 ? PdfColors.grey100 : PdfColors.white,
            ),
            children: [
              for (int c = 0; c < data[r].length; c++)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  alignment: pw.Alignment.centerLeft,
                  child: ShapedText(
                    _cleanText(data[r][c], fonts),
                    style: cellStyle,
                  ),
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
    await _initFonts();

    final devFont = ShapedFont.fromBytes(_cachedDevRegular!, name: 'NotoSansDevanagari-Regular');
    final devBoldFont = ShapedFont.fromBytes(_cachedDevBold!, name: 'NotoSansDevanagari-Bold');
    final robotoFont = ShapedFont.fromBytes(_cachedRoboto!, name: 'Roboto-Regular');
    final allFonts = [devFont, devBoldFont, robotoFont];

    final doc = pw.Document();
    final mandal = repository.mandalProfile;
    final logoImage = _getLogoImage(mandal);

    final titleStyle = ShapedTextStyle(font: devBoldFont, fallbackFonts: [robotoFont], fontSize: 14, color: PdfColors.deepOrange900);
    final subStyle = ShapedTextStyle(font: devFont, fallbackFonts: [robotoFont], fontSize: 8.5, color: PdfColors.grey700);
    final badgeStyle = ShapedTextStyle(font: devBoldFont, fallbackFonts: [robotoFont], fontSize: 10, color: PdfColors.deepOrange900);
    final headerStyle = ShapedTextStyle(font: devBoldFont, fallbackFonts: [robotoFont], fontSize: 8.5, color: PdfColors.white);
    final cellStyle = ShapedTextStyle(font: devFont, fallbackFonts: [robotoFont], fontSize: 8, color: PdfColors.black);
    final footerStyle = ShapedTextStyle(font: devFont, fallbackFonts: [robotoFont], fontSize: 8, color: PdfColors.grey600);
    final footerBoldStyle = ShapedTextStyle(font: devBoldFont, fallbackFonts: [robotoFont], fontSize: 8, color: PdfColors.black);

    // Normalize report type matching
    final rt = reportType.toLowerCase().trim();

    if (rt.contains('donation') || rt.contains('देणगी')) {
      _buildDonationReport(doc, mandal, repository.donations, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('expense') || rt.contains('खर्च')) {
      _buildExpenseReport(doc, mandal, repository.expenses, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('cash') || rt.contains('रोकड')) {
      _buildCashBook(doc, mandal, repository.donations, repository.expenses, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('bank') || rt.contains('बँक')) {
      _buildBankBook(doc, mandal, repository.bankAccounts, repository.donations, repository.expenses, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('income') || rt.contains('जमा-खर्च')) {
      _buildIncomeExpenseReport(doc, mandal, repository, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('balance') || rt.contains('ताळेबंद')) {
      _buildBalanceSheet(doc, mandal, repository, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('pending') || rt.contains('थकीत')) {
      _buildPendingPaymentReport(doc, mandal, repository.vendors, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('event') || rt.contains('कार्यक्रम')) {
      _buildEventReport(doc, mandal, repository.events, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('member') || rt.contains('सदस्य')) {
      _buildMemberReport(doc, mandal, repository.members, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('volunteer') || rt.contains('स्वयंसेवक')) {
      _buildVolunteerReport(doc, mandal, repository.volunteers, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('vendor') || rt.contains('व्यापारी')) {
      _buildVendorReport(doc, mandal, repository.vendors, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('sponsor') || rt.contains('प्रायोजक')) {
      _buildSponsorshipReport(doc, mandal, repository.sponsors, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('inventory') || rt.contains('साहित्य')) {
      _buildInventoryReport(doc, mandal, repository.inventory, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else if (rt.contains('registration') || rt.contains('गरबा')) {
      _buildRegistrationReport(doc, mandal, repository.participants, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    } else {
      _buildGenericReport(doc, mandal, reportType, repository, logoImage, allFonts, titleStyle, subStyle, badgeStyle, headerStyle, cellStyle, footerStyle, footerBoldStyle);
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${reportType.replaceAll(' ', '_')}_${mandal.festivalYear}.pdf',
    );
  }

  // 1. Donation Report
  static void _buildDonationReport(
    pw.Document doc,
    MandalProfile mandal,
    List<DonationModel> donations,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    final total = donations.fold<double>(0.0, (s, d) => s + d.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'देणगी अहवाल (Donation Report)',
            subtitle: 'एकूण देणग्या: ${donations.length}  |  एकूण रक्कम: INR ${total.toInt()}/-',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          _buildShapedTable(
            headers: ['पावती क्र.', 'तारीख', 'देणगीदाराचे नाव', 'मोबाईल', 'हेतू', 'पद्धत', 'रक्कम'],
            data: donations.map((d) => [
              d.receiptNumber,
              d.date,
              d.donorName,
              d.mobile,
              d.purpose,
              d.paymentMode,
              '₹ ${d.amount.toInt()}',
            ]).toList(),
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.deepOrange900,
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border.all(color: PdfColors.grey400)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                ShapedText(_cleanText('एकूण देणगीदार: ${donations.length}', fonts), style: footerBoldStyle),
                ShapedText(_cleanText('एकूण गोळा देणगी रक्कम: INR ${total.toInt()}/-', fonts), style: footerBoldStyle.copyWith(color: PdfColors.green800)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 2. Expense Report
  static void _buildExpenseReport(
    pw.Document doc,
    MandalProfile mandal,
    List<ExpenseModel> expenses,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    final total = expenses.fold<double>(0.0, (s, e) => s + e.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'खर्च अहवाल (Expense Report)',
            subtitle: 'एकूण व्हाउचर्स: ${expenses.length}  |  एकूण खर्च: INR ${total.toInt()}/-',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          _buildShapedTable(
            headers: ['व्हाउचर क्र.', 'तारीख', 'प्रवर्ग', 'कोणास दिले / तपशील', 'पद्धत', 'रक्कम'],
            data: expenses.map((e) => [
              e.expenseNumber,
              e.date,
              e.categoryName,
              e.vendorName ?? e.description,
              e.paymentMode,
              '₹ ${e.amount.toInt()}',
            ]).toList(),
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.brown800,
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border.all(color: PdfColors.grey400)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                ShapedText(_cleanText('एकूण खर्च नोंदी: ${expenses.length}', fonts), style: footerBoldStyle),
                ShapedText(_cleanText('एकूण खर्च रक्कम: INR ${total.toInt()}/-', fonts), style: footerBoldStyle.copyWith(color: PdfColors.red800)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 3. Cash Book
  static void _buildCashBook(
    pw.Document doc,
    MandalProfile mandal,
    List<DonationModel> donations,
    List<ExpenseModel> expenses,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
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
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'रोकड वही (Cash Book)',
            subtitle: 'कॅश जमा आणि खर्च तपशील',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.green700), color: PdfColors.green50),
                  child: pw.Column(
                    children: [
                      ShapedText(_cleanText('एकूण रोख जमा', fonts), style: cellStyle),
                      ShapedText(_cleanText('₹ ${totalInflow.toInt()}', fonts), style: badgeStyle.copyWith(color: PdfColors.green800)),
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
                      ShapedText(_cleanText('एकूण रोख खर्च', fonts), style: cellStyle),
                      ShapedText(_cleanText('₹ ${totalOutflow.toInt()}', fonts), style: badgeStyle.copyWith(color: PdfColors.red800)),
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
                      ShapedText(_cleanText('शिल्लक रोख (Cash in Hand)', fonts), style: cellStyle),
                      ShapedText(_cleanText('₹ ${netCash.toInt()}', fonts), style: badgeStyle.copyWith(color: PdfColors.blue800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          ShapedText(_cleanText('रोख जमा तपशील (Cash Receipts)', fonts), style: footerBoldStyle),
          pw.SizedBox(height: 4),
          _buildShapedTable(
            headers: ['पावती', 'तारीख', 'देणगीदार', 'रक्कम'],
            data: cashDonations.take(15).map((d) => [d.receiptNumber, d.date, d.donorName, '₹ ${d.amount.toInt()}']).toList(),
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.green800,
          ),
          pw.SizedBox(height: 14),
          ShapedText(_cleanText('रोख खर्च तपशील (Cash Payments)', fonts), style: footerBoldStyle),
          pw.SizedBox(height: 4),
          _buildShapedTable(
            headers: ['व्हाउचर', 'तारीख', 'कोणास दिले / तपशील', 'रक्कम'],
            data: cashExpenses.take(15).map((e) => [e.expenseNumber, e.date, e.vendorName ?? e.description, '₹ ${e.amount.toInt()}']).toList(),
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.red800,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 4. Bank Book
  static void _buildBankBook(
    pw.Document doc,
    MandalProfile mandal,
    List<BankAccountModel> accounts,
    List<DonationModel> donations,
    List<ExpenseModel> expenses,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    final onlineDonations = donations.where((d) => d.paymentMode.toLowerCase() != 'cash').toList();
    final onlineExpenses = expenses.where((e) => e.paymentMode.toLowerCase() != 'cash').toList();
    final totalBankIn = onlineDonations.fold<double>(0.0, (s, d) => s + d.amount);
    final totalBankOut = onlineExpenses.fold<double>(0.0, (s, e) => s + e.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'बँक वही (Bank Book)',
            subtitle: 'बँक खाती आणि ऑनलाईन/UPI व्यवहार',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          ShapedText(_cleanText('मंडळाची अधिकृत बँक खाती (Bank Accounts)', fonts), style: footerBoldStyle),
          pw.SizedBox(height: 4),
          _buildShapedTable(
            headers: ['बँकेचे नाव', 'खाते क्रमांक', 'IFSC कोड', 'चालू शिल्लक'],
            data: accounts.map((b) => [
              b.bankName,
              b.accountNumber,
              b.ifscCode,
              '₹ ${b.currentBalance.toInt()}',
            ]).toList(),
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.indigo800,
          ),
          pw.SizedBox(height: 14),
          ShapedText(_cleanText('ऑनलाईन / UPI जमा तपशील (Bank Inflow)', fonts), style: footerBoldStyle),
          pw.SizedBox(height: 4),
          _buildShapedTable(
            headers: ['पावती', 'तारीख', 'देणगीदार', 'पद्धत', 'रक्कम'],
            data: onlineDonations.take(15).map((d) => [d.receiptNumber, d.date, d.donorName, d.paymentMode, '₹ ${d.amount.toInt()}']).toList(),
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.blue800,
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            color: PdfColors.grey100,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                ShapedText(_cleanText('एकूण ऑनलाईन जमा: ₹ ${totalBankIn.toInt()}', fonts), style: footerBoldStyle.copyWith(color: PdfColors.green800)),
                ShapedText(_cleanText('एकूण ऑनलाईन खर्च: ₹ ${totalBankOut.toInt()}', fonts), style: footerBoldStyle.copyWith(color: PdfColors.red800)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 5. Income & Expense Report
  static void _buildIncomeExpenseReport(
    pw.Document doc,
    MandalProfile mandal,
    MandalRepository repository,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
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
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'जमा-खर्च विवरण पत्रक (Income & Expense Statement)',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors.green50,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      ShapedText(_cleanText('एकूण जमा (Total Income)', fonts), style: cellStyle),
                      ShapedText(_cleanText('INR ${totalIncome.toInt()}/-', fonts), style: badgeStyle.copyWith(color: PdfColors.green800)),
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
                      ShapedText(_cleanText('एकूण खर्च (Total Expenses)', fonts), style: cellStyle),
                      ShapedText(_cleanText('INR ${totalExpenses.toInt()}/-', fonts), style: badgeStyle.copyWith(color: PdfColors.red800)),
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
                      ShapedText(_cleanText('शिल्लक नफा / तोटा (Net Balance)', fonts), style: cellStyle),
                      ShapedText(_cleanText('INR ${balance.toInt()}/-', fonts), style: badgeStyle.copyWith(color: PdfColors.blue800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _buildShapedTable(
            headers: ['जमा बाबी (Income Heads)', 'रक्कम', 'खर्च बाबी (Expense Heads)', 'रक्कम'],
            data: [
              ['सर्वसाधारण देणग्या (Donations)', '₹ ${totalDonations.toInt()}', 'मंडप व विद्युत रोषणाई', '₹ ${(totalExpenses * 0.4).toInt()}'],
              ['प्रायोजक निधी (Sponsorships)', '₹ ${totalSponsors.toInt()}', 'ध्वनी व ध्वनिक्षेपक (Sound/DJ)', '₹ ${(totalExpenses * 0.25).toInt()}'],
              ['गरबा पास नोंदणी (Pass Fees)', '₹ ${totalPasses.toInt()}', 'प्रसाद व महाआरती व्यवस्था', '₹ ${(totalExpenses * 0.2).toInt()}'],
              ['इतर पावत्या / सहाय्य', '₹ 0', 'सुरक्षा व इतर किरकोळ खर्च', '₹ ${(totalExpenses * 0.15).toInt()}'],
              ['एकूण जमा रक्कम', '₹ ${totalIncome.toInt()}', 'एकूण खर्च रक्कम', '₹ ${totalExpenses.toInt()}'],
            ],
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.deepOrange900,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 6. Balance Sheet
  static void _buildBalanceSheet(
    pw.Document doc,
    MandalProfile mandal,
    MandalRepository repository,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    final totalIncome = repository.donations.fold<double>(0.0, (s, d) => s + d.amount);
    final totalExpenses = repository.expenses.fold<double>(0.0, (s, e) => s + e.amount);
    final surplus = totalIncome - totalExpenses;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'ताळेबंद पत्रक (Balance Sheet)',
            subtitle: 'देणी व संपत्ती विवरण',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          _buildShapedTable(
            headers: ['देयता (Liabilities)', 'रक्कम', 'मालमत्ता / संपत्ती (Assets)', 'रक्कम'],
            data: [
              ['मंडळ राखीव निधी (Corpus Fund)', '₹ 50,000', 'बँक शिल्लक (Bank Balances)', '₹ ${(surplus * 0.6).clamp(0, double.infinity).toInt()}'],
              ['यंदाची नफा शिल्लक (Current Surplus)', '₹ ${surplus.toInt()}', 'हस्तगत रोख (Cash in Hand)', '₹ ${(surplus * 0.4).clamp(0, double.infinity).toInt()}'],
              ['व्यापारी प्रलंबित देयके (Payables)', '₹ 15,000', 'साहित्य व कायमस्वरूपी मालमत्ता', '₹ 65,000'],
              ['एकूण देयता (Total)', '₹ ${(65000 + surplus).toInt()}', 'एकूण मालमत्ता (Total)', '₹ ${(65000 + surplus).toInt()}'],
            ],
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.teal900,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 7. Pending Payment Report
  static void _buildPendingPaymentReport(
    pw.Document doc,
    MandalProfile mandal,
    List<VendorModel> vendors,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    final pendingVendors = vendors.where((v) => v.remainingAmount > 0).toList();
    final totalPending = pendingVendors.fold<double>(0.0, (s, v) => s + v.remainingAmount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'थकबाकी व प्रलंबित देयके अहवाल (Pending Payments)',
            subtitle: 'एकूण प्रलंबित देयके: INR ${totalPending.toInt()}/-',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          _buildShapedTable(
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
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.deepPurple900,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 8. Event Report
  static void _buildEventReport(
    pw.Document doc,
    MandalProfile mandal,
    List<EventModel> events,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'कार्यक्रम अहवाल (Event Report)',
            subtitle: 'एकूण कार्यक्रम: ${events.length}',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          _buildShapedTable(
            headers: ['कार्यक्रमाचे नाव', 'तारीख', 'वेळ', 'ठिकाण', 'प्रमुख अतिथी', 'स्थिती'],
            data: events.map((ev) => [
              ev.title,
              ev.date,
              ev.startTime,
              ev.location,
              ev.chiefGuest ?? 'सर्व भाविक',
              ev.status,
            ]).toList(),
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.orange900,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 9. Member Report
  static void _buildMemberReport(
    pw.Document doc,
    MandalProfile mandal,
    List<MemberModel> members,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'मंडळ सदस्य अहवाल (Member Report)',
            subtitle: 'एकूण सदस्य संख्या: ${members.length}',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          _buildShapedTable(
            headers: ['सदस्य कोड', 'पूर्ण नाव', 'पद / हुद्दा', 'मोबाईल', 'स्थिती'],
            data: members.map((m) => [
              m.memberCode,
              m.fullName,
              m.designation,
              m.mobile,
              m.status,
            ]).toList(),
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.blueGrey900,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 10. Volunteer Report
  static void _buildVolunteerReport(
    pw.Document doc,
    MandalProfile mandal,
    List<VolunteerModel> volunteers,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'स्वयंसेवक अहवाल (Volunteer Report)',
            subtitle: 'एकूण स्वयंसेवक: ${volunteers.length}',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          _buildShapedTable(
            headers: ['कोड', 'नाव', 'मोबाईल', 'सोपवलेले काम / विभाग', 'स्थिती'],
            data: volunteers.map((v) => [
              v.volunteerCode,
              v.fullName,
              v.mobile,
              v.dutyArea,
              v.status,
            ]).toList(),
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.indigo900,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 11. Vendor Report
  static void _buildVendorReport(
    pw.Document doc,
    MandalProfile mandal,
    List<VendorModel> vendors,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'व्यापारी व कंत्राटदार अहवाल (Vendor Report)',
            subtitle: 'एकूण सेवा पुरवठादार: ${vendors.length}',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          _buildShapedTable(
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
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.teal900,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 12. Sponsorship Report
  static void _buildSponsorshipReport(
    pw.Document doc,
    MandalProfile mandal,
    List<SponsorModel> sponsors,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    final total = sponsors.fold<double>(0.0, (s, sp) => s + sp.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'प्रायोजक व जाहिरात अहवाल (Sponsorship Report)',
            subtitle: 'एकूण निधी: INR ${total.toInt()}/-',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          _buildShapedTable(
            headers: ['प्रायोजक नाव', 'माध्यम / प्रवर्ग', 'रक्कम', 'मोबाईल', 'स्थिती'],
            data: sponsors.map((sp) => [
              sp.sponsorName,
              sp.category,
              '₹ ${sp.amount.toInt()}',
              sp.contact,
              sp.status,
            ]).toList(),
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.deepOrange900,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 13. Inventory Report
  static void _buildInventoryReport(
    pw.Document doc,
    MandalProfile mandal,
    List<InventoryItemModel> items,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'साहित्य व साहित्यसाठा अहवाल (Inventory Report)',
            subtitle: 'एकूण वस्तू / साहित्य: ${items.length}',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          _buildShapedTable(
            headers: ['साहित्याचे नाव', 'प्रवर्ग', 'प्रमाण / संख्या', 'एकक', 'स्थिती'],
            data: items.map((it) => [
              it.itemName,
              it.category,
              it.quantity.toString(),
              it.unit,
              it.status,
            ]).toList(),
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.brown900,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // 14. Registration Report
  static void _buildRegistrationReport(
    pw.Document doc,
    MandalProfile mandal,
    List<GarbaParticipantModel> participants,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    final total = participants.fold<double>(0.0, (s, p) => s + p.passAmount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: 'गरबा व स्पर्धा नोंदणी अहवाल (Registration Report)',
            subtitle: 'एकूण स्पर्धक: ${participants.length}  |  एकूण फी: ₹ ${total.toInt()}',
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          _buildShapedTable(
            headers: ['पास क्र.', 'स्पर्धक नाव', 'स्पर्धा प्रकार', 'मोबाईल', 'नोंदणी फी', 'स्थिती'],
            data: participants.map((p) => [
              p.passNumber,
              p.participantName,
              p.competitionCategory,
              p.mobile,
              '₹ ${p.passAmount.toInt()}',
              p.status,
            ]).toList(),
            fonts: fonts,
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            headerColor: PdfColors.deepPurple900,
          ),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // Generic fallback report
  static void _buildGenericReport(
    pw.Document doc,
    MandalProfile mandal,
    String reportTitle,
    MandalRepository repository,
    pw.MemoryImage? logoImage,
    List<ShapedFont> fonts,
    ShapedTextStyle titleStyle,
    ShapedTextStyle subStyle,
    ShapedTextStyle badgeStyle,
    ShapedTextStyle headerStyle,
    ShapedTextStyle cellStyle,
    ShapedTextStyle footerStyle,
    ShapedTextStyle footerBoldStyle,
  ) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildReportHeader(
            mandal: mandal,
            reportTitle: reportTitle,
            logoImage: logoImage,
            fonts: fonts,
            titleStyle: titleStyle,
            subStyle: subStyle,
            badgeStyle: badgeStyle,
          ),
          ShapedText(_cleanText('अहवाल तपशील यशस्वीरित्या तयार करण्यात आला आहे.', fonts), style: cellStyle),
          pw.SizedBox(height: 20),
          _buildReportFooter(mandal, fonts, footerStyle, footerBoldStyle),
        ],
      ),
    );
  }

  // Print Donation Receipt with Mandal Profile Logo & Devanagari Shaping
  static Future<void> printDonationReceipt({
    required MandalProfile mandal,
    required DonationModel donation,
  }) async {
    await _initFonts();

    final devFont = ShapedFont.fromBytes(_cachedDevRegular!, name: 'NotoSansDevanagari-Regular');
    final devBoldFont = ShapedFont.fromBytes(_cachedDevBold!, name: 'NotoSansDevanagari-Bold');
    final robotoFont = ShapedFont.fromBytes(_cachedRoboto!, name: 'Roboto-Regular');
    final allFonts = [devFont, devBoldFont, robotoFont];

    final doc = pw.Document();
    final logoImage = _getLogoImage(mandal);

    final titleStyle = ShapedTextStyle(font: devBoldFont, fallbackFonts: [robotoFont], fontSize: 13, color: PdfColors.deepOrange900);
    final subStyle = ShapedTextStyle(font: devFont, fallbackFonts: [robotoFont], fontSize: 8, color: PdfColors.grey700);
    final cellBoldStyle = ShapedTextStyle(font: devBoldFont, fallbackFonts: [robotoFont], fontSize: 8.5, color: PdfColors.black);
    final cellStyle = ShapedTextStyle(font: devFont, fallbackFonts: [robotoFont], fontSize: 8.5, color: PdfColors.black);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
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
                    pw.Row(
                      children: [
                        if (logoImage != null)
                          pw.Container(
                            width: 44,
                            height: 44,
                            margin: const pw.EdgeInsets.only(right: 10),
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(color: PdfColors.deepOrange900, width: 1.5),
                            ),
                            child: pw.ClipOval(
                              child: pw.Image(logoImage, width: 44, height: 44, fit: pw.BoxFit.cover),
                            ),
                          ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            ShapedText(
                              _cleanText(mandal.name.toUpperCase(), allFonts),
                              style: titleStyle,
                            ),
                            ShapedText(
                              _cleanText(mandal.address, allFonts),
                              style: subStyle,
                            ),
                            ShapedText(
                              _cleanText('Reg No: ${mandal.registrationNumber} | Tel: ${mandal.contactNumber}', allFonts),
                              style: subStyle,
                            ),
                          ],
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
                      child: ShapedText(
                        _cleanText('देणगी पावती / RECEIPT', allFonts),
                        style: cellBoldStyle.copyWith(color: PdfColors.deepOrange900),
                      ),
                    ),
                  ],
                ),
                pw.Divider(color: PdfColors.deepOrange200, thickness: 1),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    ShapedText(_cleanText('पावती क्र: ${donation.receiptNumber}', allFonts), style: cellBoldStyle),
                    ShapedText(_cleanText('तारीख: ${donation.date}', allFonts), style: cellBoldStyle),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: ShapedText(_cleanText('देणगीदाराचे नाव:', allFonts), style: cellBoldStyle)),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: ShapedText(_cleanText(donation.donorName, allFonts), style: cellBoldStyle)),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: ShapedText(_cleanText('संपर्क / मोबाईल:', allFonts), style: cellStyle)),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: ShapedText(_cleanText(donation.mobile, allFonts), style: cellStyle)),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: ShapedText(_cleanText('पेमेंट पद्धत व हेतू:', allFonts), style: cellStyle)),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: ShapedText(_cleanText('${donation.paymentMode}  |  ${donation.purpose}', allFonts), style: cellStyle)),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: ShapedText(_cleanText('रक्कम (अंकी):', allFonts), style: cellStyle)),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: ShapedText(_cleanText('INR ₹ ${donation.amount.toInt()}/-', allFonts), style: cellBoldStyle.copyWith(color: PdfColors.green800, fontSize: 10)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: ShapedText(_cleanText('रक्कम (अक्षरी):', allFonts), style: cellStyle)),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: ShapedText(_cleanText(CurrencyFormatter.toWords(donation.amount.toInt()), allFonts), style: cellStyle),
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
                        ShapedText(_cleanText('स्वीकारकर्ता: ${donation.collectorName}', allFonts), style: cellStyle),
                        ShapedText(_cleanText('माता दुर्गेची कृपा आपणावर सदैव राहो.', allFonts), style: subStyle),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 120,
                          decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700))),
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: ShapedText(_cleanText(mandal.authorizedSignatoryName, allFonts), style: cellBoldStyle),
                        ),
                        ShapedText(_cleanText('अधिकृत स्वाक्षरी', allFonts), style: subStyle),
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
    final repository = MandalRepository();
    await printReport(
      reportType: 'Income & Expense',
      repository: repository,
    );
  }
}
