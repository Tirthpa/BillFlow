import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../models/business_model.dart';

class PdfService {
  static pw.Font? _cachedFont;
  static pw.Font? _cachedFontBold;

  /// Pre-caches fonts to reduce load time during PDF generation
  static Future<void> precacheFonts() async {
    if (_cachedFont == null || _cachedFontBold == null) {
      try {
        _cachedFont = await PdfGoogleFonts.notoSansRegular();
        _cachedFontBold = await PdfGoogleFonts.notoSansBold();
      } catch (e) {
        print('Error pre-caching fonts: $e');
      }
    }
  }

  static Future<Uint8List> generateInvoiceBytes(
    InvoiceModel invoice,
    BusinessModel business,
  ) async {
    print('Starting PDF Generation for Invoice #${invoice.invoiceNumber}...');
    final pdf = pw.Document();

    // Use NotoSans for full Unicode (Rupee symbol) support
    if (_cachedFont == null || _cachedFontBold == null) {
      _cachedFont = await PdfGoogleFonts.notoSansRegular();
      _cachedFontBold = await PdfGoogleFonts.notoSansBold();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (pw.Context context) {
          final gstSplit = invoice.totalTax / 2;
          // Use NotoSans ONLY for Rupee symbol. Use Helvetica for everything else for speed.
          final rupeeStyle = pw.TextStyle(
            font: _cachedFont ?? pw.Font.helvetica(),
          );
          final rupeeStyleBold = pw.TextStyle(
            font: _cachedFontBold ?? pw.Font.helveticaBold(),
          );

          return [
            // PROFESSIONAL HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      business.businessName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      business.address,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    if (business.gstNumber.isNotEmpty)
                      pw.Text(
                        'GSTIN: ${business.gstNumber}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    pw.Text(
                      'Phone: ${business.phone}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    if (business.email.isNotEmpty)
                      pw.Text(
                        'Email: ${business.email}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'TAX INVOICE',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.indigo50,
                      ),
                      child: pw.Text(
                        'Original for Recipient',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.indigo900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 10),

            // INVOICE DETAILS GRID
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              children: [
                pw.TableRow(
                  children: [
                    _infoBlock('INVOICE NO.', '#${invoice.invoiceNumber}'),
                    _infoBlock(
                      'DATE OF ISSUE',
                      DateFormat('dd-MM-yyyy').format(invoice.date),
                    ),
                    _infoBlock('PAYMENT STATUS', invoice.status.toUpperCase()),
                    _infoBlock(
                      'PAYMENT MODE',
                      invoice.paymentMode.toUpperCase(),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // BILL TO / SHIP TO
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('BILL TO'),
                      pw.Text(
                        invoice.customer['name'],
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        invoice.customer['address'] ?? 'No Address Provided',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Phone: ${invoice.customer['phone'] ?? 'N/A'}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      if (invoice.customer['gstNumber'] != null &&
                          invoice.customer['gstNumber'].isNotEmpty)
                        pw.Text(
                          'GSTIN: ${invoice.customer['gstNumber']}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 40),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('SHIP TO'),
                      pw.Text(
                        invoice.customer['name'],
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        invoice.customer['address'] ?? 'Same as Billing',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // PROFESSIONAL ITEMS TABLE
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5), // SL
                1: const pw.FlexColumnWidth(3), // DESCRIPTION
                2: const pw.FlexColumnWidth(0.8), // QTY
                3: const pw.FlexColumnWidth(1.2), // UNIT PRICE
                4: const pw.FlexColumnWidth(1), // TOTAL
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.indigo900,
                  ),
                  children: [
                    _tableHeaderCell('#'),
                    _tableHeaderCell('DESCRIPTION'),
                    _tableHeaderCell('QTY'),
                    _tableHeaderCell('UNIT PRICE'),
                    _tableHeaderCell('TOTAL'),
                  ],
                ),
                ...List.generate(invoice.items.length, (index) {
                  final item = invoice.items[index];
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: index % 2 == 1
                          ? PdfColors.grey50
                          : PdfColors.white,
                    ),
                    children: [
                      _tableCell(
                        (index + 1).toString(),
                        align: pw.Alignment.center,
                      ),
                      _tableCell(item.productName),
                      _tableCell(
                        item.quantity.toString(),
                        align: pw.Alignment.center,
                      ),
                      _tableCell(
                        '₹${item.price.toStringAsFixed(2)}',
                        align: pw.Alignment.centerRight,
                        style: rupeeStyle,
                      ),
                      _tableCell(
                        '₹${item.total.toStringAsFixed(2)}',
                        align: pw.Alignment.centerRight,
                        style: rupeeStyle,
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            // SUMMARY & FOOTER
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (business.bankName != null &&
                          business.bankName!.isNotEmpty) ...[
                        _sectionHeader('BANK DETAILS'),
                        _bankRow('Bank Name', business.bankName!),
                        _bankRow('A/C Number', business.accountNumber!),
                        _bankRow('IFSC Code', business.ifscCode!),
                        if (business.upiId != null &&
                            business.upiId!.isNotEmpty)
                          _bankRow('UPI ID', business.upiId!),
                        pw.SizedBox(height: 15),
                      ],
                      if (invoice.terms != null &&
                          invoice.terms!.isNotEmpty) ...[
                        _sectionHeader('TERMS & CONDITIONS'),
                        pw.Text(
                          invoice.terms!,
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 50),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    children: [
                      _summaryRow(
                        'SUBTOTAL',
                        invoice.subTotal,
                        style: rupeeStyle,
                      ),
                      if (invoice.totalTax > 0) ...[
                        _summaryRow('CGST (9%)', gstSplit, style: rupeeStyle),
                        _summaryRow('SGST (9%)', gstSplit, style: rupeeStyle),
                      ],
                      if (invoice.discount > 0)
                        _summaryRow(
                          'DISCOUNT',
                          -invoice.discount,
                          color: PdfColors.red900,
                          style: rupeeStyle.copyWith(color: PdfColors.red900),
                        ),
                      pw.Divider(color: PdfColors.grey300),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.indigo900,
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'GRAND TOTAL',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            pw.Text(
                              '₹${invoice.grandTotal.toStringAsFixed(2)}',
                              style: rupeeStyleBold.copyWith(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'For ${business.businessName}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 30),
                          pw.Divider(
                            thickness: 0.5,
                            color: PdfColors.grey400,
                            indent: 20,
                            endIndent: 20,
                          ),
                          pw.Text(
                            'AUTHORIZED SIGNATURE',
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
        footer: (pw.Context context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'This is a computer generated invoice.',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static Future<void> generateAndShareInvoice(
    InvoiceModel invoice,
    BusinessModel business,
  ) async {
    final bytes = await generateInvoiceBytes(invoice, business);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  static pw.Widget _infoBlock(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.indigo900,
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    pw.Alignment align = pw.Alignment.centerLeft,
    pw.TextStyle? style,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: style ?? const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _bankRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 60,
            child: pw.Text(
              '$label:',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    double value, {
    PdfColor color = PdfColors.grey800,
    pw.TextStyle? style,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: color)),
          pw.Text(
            '₹${value.toStringAsFixed(2)}',
            style:
                (style ??
                        pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ))
                    .copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
