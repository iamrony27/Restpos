import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/restaurant_profile.dart';

class ReportPdfService {
  static Future<Uint8List> generateSalesReportBytes({
    required RestaurantProfile profile,
    required String periodType, // Monthly, Quarterly, Yearly
    required String periodName, // e.g. "October 2026", "Q3 FY26", "FY 2025-26"
    required int totalOrders,
    required double grossSalesRupees,
    required double taxableBaseRupees,
    required double cgstRupees,
    required double sgstRupees,
    required double totalGstRupees,
    required double roundOffRupees,
    required double netRevenueRupees,
    required bool isTaxInclusive,
    required Map<String, double> categorySales,
    required Map<String, double> paymentBreakdown,
  }) async {
    final pdf = pw.Document();
    final currencyFormatter = NumberFormat.currency(symbol: 'INR ', decimalDigits: 2);
    final nowFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile.name.toUpperCase(),
                      style: const pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepOrange900,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(profile.tagline, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 3),
                    pw.Text(profile.address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.Text('Phone: ${profile.phone}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.deepOrange50,
                        border: pw.Border.all(color: PdfColors.deepOrange),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text(
                        '$periodType SALES & GST REPORT',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.deepOrange900,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Period: $periodName', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Generated: $nowFormatted', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1, color: PdfColors.grey300),

            // Statutory Credentials Box
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('GSTIN / UIN', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.Text(profile.isGstEnabled ? profile.gstin : 'EXEMPT / UNREGISTERED',
                          style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FSSAI Food Safety Lic. No.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.Text(profile.fssai, style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Tax Treatment', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.Text(
                        !profile.isGstEnabled
                            ? 'Non-GST (0%)'
                            : (isTaxInclusive ? 'Inclusive of GST (${profile.gstRatePercent}%)' : 'Exclusive of GST (${profile.gstRatePercent}%)'),
                        style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange800),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Executive Summary Table
            pw.Text('1. Financial & Tax Collection Summary', style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cellHeader('Parameter'),
                    _cellHeader('Count / Rate'),
                    _cellHeader('Amount (INR)', align: pw.TextAlign.right),
                  ],
                ),
                pw.TableRow(children: [
                  _cell('Total Completed Invoices / Bills'),
                  _cell('$totalOrders Orders'),
                  _cell(totalOrders.toString(), align: pw.TextAlign.right),
                ]),
                pw.TableRow(children: [
                  _cell('Gross Billed Volume (Total Sales)'),
                  _cell('100.0%'),
                  _cell(currencyFormatter.format(grossSalesRupees), align: pw.TextAlign.right),
                ]),
                pw.TableRow(children: [
                  _cell('Net Taxable Turnover (Base Value)'),
                  _cell(profile.isGstEnabled ? '${profile.gstRatePercent}% Slab' : 'Exempt'),
                  _cell(currencyFormatter.format(taxableBaseRupees), align: pw.TextAlign.right),
                ]),
                if (profile.isGstEnabled) ...[
                  pw.TableRow(children: [
                    _cell('Central GST (CGST)'),
                    _cell('${profile.gstRatePercent / 2.0}%'),
                    _cell(currencyFormatter.format(cgstRupees), align: pw.TextAlign.right),
                  ]),
                  pw.TableRow(children: [
                    _cell('State GST (SGST)'),
                    _cell('${profile.gstRatePercent / 2.0}%'),
                    _cell(currencyFormatter.format(sgstRupees), align: pw.TextAlign.right),
                  ]),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.deepOrange50),
                    children: [
                      _cell('Total GST Tax Collected', isBold: true),
                      _cell('${profile.gstRatePercent}% Total', isBold: true),
                      _cell(currencyFormatter.format(totalGstRupees), isBold: true, align: pw.TextAlign.right),
                    ],
                  ),
                ],
                pw.TableRow(children: [
                  _cell('Round-Off Adjustments (Paise)'),
                  _cell('Auto Rounded'),
                  _cell(currencyFormatter.format(roundOffRupees), align: pw.TextAlign.right),
                ]),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Net Realized Revenue', isBold: true),
                    _cell('Bank / Cash', isBold: true),
                    _cell(currencyFormatter.format(netRevenueRupees), isBold: true, align: pw.TextAlign.right),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // Payment Methods & Category Breakdown Side by Side
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Payment Methods
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('2. Payment Method Mix', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                            children: [
                              _cellHeader('Channel'),
                              _cellHeader('Settled (INR)', align: pw.TextAlign.right),
                            ],
                          ),
                          ...paymentBreakdown.entries.map((entry) {
                            return pw.TableRow(
                              children: [
                                _cell(entry.key),
                                _cell(currencyFormatter.format(entry.value), align: pw.TextAlign.right),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                // Category Sales
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('3. Category Turnover', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                            children: [
                              _cellHeader('Category'),
                              _cellHeader('Sales (INR)', align: pw.TextAlign.right),
                            ],
                          ),
                          ...categorySales.entries.map((entry) {
                            return pw.TableRow(
                              children: [
                                _cell(entry.key),
                                _cell(currencyFormatter.format(entry.value), align: pw.TextAlign.right),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Sign-off / Compliance note
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Declaration & Statutory Compliance:', style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text('This report is automatically synthesized from the local POS transactional ledger.',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                    pw.Text('All tax calculations adhere to Central Goods and Services Tax (CGST) Act regulations.',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 120, height: 1, color: PdfColors.grey500),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(profile.name, style: const pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _cellHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
      ),
    );
  }

  static pw.Widget _cell(String text, {bool isBold = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static Future<void> printOrShareReport({
    required RestaurantProfile profile,
    required String periodType,
    required String periodName,
    required int totalOrders,
    required double grossSalesRupees,
    required double taxableBaseRupees,
    required double cgstRupees,
    required double sgstRupees,
    required double totalGstRupees,
    required double roundOffRupees,
    required double netRevenueRupees,
    required bool isTaxInclusive,
    required Map<String, double> categorySales,
    required Map<String, double> paymentBreakdown,
  }) async {
    final pdfBytes = await generateSalesReportBytes(
      profile: profile,
      periodType: periodType,
      periodName: periodName,
      totalOrders: totalOrders,
      grossSalesRupees: grossSalesRupees,
      taxableBaseRupees: taxableBaseRupees,
      cgstRupees: cgstRupees,
      sgstRupees: sgstRupees,
      totalGstRupees: totalGstRupees,
      roundOffRupees: roundOffRupees,
      netRevenueRupees: netRevenueRupees,
      isTaxInclusive: isTaxInclusive,
      categorySales: categorySales,
      paymentBreakdown: paymentBreakdown,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '${profile.name.replaceAll(' ', '_')}_${periodType}_Report_${periodName.replaceAll(' ', '_')}.pdf',
    );
  }
}
