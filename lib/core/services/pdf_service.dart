import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/currency_formatter.dart';
import '../../models/all_models.dart';

class PdfService {
  static Future<void> printDonationReceipt({
    required MandalProfile mandal,
    required DonationModel donation,
  }) async {
    final doc = pw.Document();

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
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          mandal.name.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.deepOrange900,
                          ),
                        ),
                        pw.Text(
                          mandal.address,
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'Reg No: ${mandal.registrationNumber} | Tel: ${mandal.contactNumber}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange50,
                        border: pw.Border.all(color: PdfColors.deepOrange700),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'DONATION RECEIPT',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.deepOrange900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Divider(color: PdfColors.deepOrange200, thickness: 1),
                pw.SizedBox(height: 8),

                // Receipt No & Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Receipt No: ${donation.receiptNumber}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${donation.date}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Donor Details Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Received with thanks from:',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(donation.donorName,
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Contact / Mobile:'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(donation.mobile),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Payment Mode & Purpose:'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${donation.paymentMode}  |  ${donation.purpose}'),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Amount in Figures:'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('INR ${donation.amount.toInt()}/-',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green800,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Amount in Words:'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(CurrencyFormatter.toWords(donation.amount.toInt()),
                              style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Spacer(),

                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Collected By: ${donation.collectorName}',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          'May Goddess Durga bring peace & prosperity.',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 140,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700)),
                          ),
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Text(
                            mandal.authorizedSignatoryName,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 9)),
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

  static Future<void> printFinancialReport({
    required MandalProfile mandal,
    required List<DonationModel> donations,
    required List<ExpenseModel> expenses,
  }) async {
    final doc = pw.Document();

    final totalDonations = donations.fold<double>(0.0, (s, d) => s + d.amount);
    final totalExpenses = expenses.fold<double>(0.0, (s, e) => s + e.amount);
    final balance = totalDonations - totalExpenses;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(mandal.name,
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('FINANCIAL REPORT - NAVRATRI ${mandal.festivalYear}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text(mandal.address, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 10),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Total Income: INR ${totalDonations.toInt()}/-',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                  pw.Text('Total Expense: INR ${totalExpenses.toInt()}/-',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                  pw.Text('Current Balance: INR ${balance.toInt()}/-',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Text('Donations Summary',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Receipt', 'Date', 'Donor', 'Amount', 'Mode'],
                data: donations
                    .take(10)
                    .map((d) => [d.receiptNumber, d.date, d.donorName, 'INR ${d.amount.toInt()}', d.paymentMode])
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.deepOrange900),
                cellHeight: 22,
              ),

              pw.SizedBox(height: 16),
              pw.Text('Expenses Summary',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Exp No', 'Date', 'Category', 'Amount', 'Mode'],
                data: expenses
                    .take(10)
                    .map((e) => [e.expenseNumber, e.date, e.categoryName, 'INR ${e.amount.toInt()}', e.paymentMode])
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.brown800),
                cellHeight: 22,
              ),

              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated on: 16-09-2026', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Audited & Signed: ${mandal.authorizedSignatoryName}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Financial_Report_${mandal.festivalYear}.pdf',
    );
  }
}
