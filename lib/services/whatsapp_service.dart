import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/invoice_model.dart';
import '../models/business_model.dart';

class WhatsAppService {
  static Future<void> shareInvoiceText({
    required InvoiceModel invoice,
    required BusinessModel business,
  }) async {
    final customerPhone = invoice.customer['phone'] ?? '';
    if (customerPhone.isEmpty) return;

    // Format phone number (Indian Standard)
    String cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final dateStr =
        "${invoice.date.day}/${invoice.date.month}/${invoice.date.year}";

    // User Requested Template (EXACT MATCH)
    final message =
        '''
Hello *${invoice.customer['name']}*,

This is a bill from *${business.businessName}*.

*Invoice Detail:*
Invoice No: #${invoice.invoiceNumber}
Date: $dateStr
*Status: ${invoice.status.toUpperCase()}*

*Summary:*
Subtotal: ₹${invoice.subTotal.toStringAsFixed(2)}
GST: ₹${invoice.totalTax.toStringAsFixed(2)}
*Total Amount: ₹${invoice.grandTotal.toStringAsFixed(2)}*

*Payment Detail:*
Mode: ${invoice.paymentMode}

Thank you for your business!
''';

    final whatsappUrl = Uri.parse(
      "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}",
    );
    final whatsappNativeUrl = Uri.parse(
      "whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}",
    );

    try {
      if (kIsWeb) {
        await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
      } else if (await canLaunchUrl(whatsappNativeUrl)) {
        await launchUrl(whatsappNativeUrl);
      } else {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
    }
  }

  static Future<String?> sendInvoiceWithPdf({
    required InvoiceModel invoice,
    required BusinessModel business,
    Uint8List? pdfBytes,
  }) async {
    // We still keep this old method if needed for background tasks,
    // but the main button will call shareInvoiceText for instant action.
    final customerPhone = invoice.customer['phone'] ?? '';
    if (customerPhone.isEmpty) return null;

    String downloadUrl = invoice.pdfUrl ?? '';

    if (downloadUrl.isEmpty && pdfBytes != null) {
      try {
        final storageRef = FirebaseStorage.instance.ref().child(
          'invoices/${business.uid}/${invoice.id}.pdf',
        );

        final uploadTask = await storageRef.putData(
          pdfBytes,
          SettableMetadata(contentType: 'application/pdf'),
        );

        downloadUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        print('Storage Error: $e');
      }
    }

    // Prepare message with PDF link if available
    String cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final dateStr =
        "${invoice.date.day}/${invoice.date.month}/${invoice.date.year}";
    final message =
        '''
Hello *${invoice.customer['name']}*,

This is a bill from *${business.businessName}*.

*Invoice Detail:*
Invoice No: #${invoice.invoiceNumber}
Date: $dateStr
*Status: ${invoice.status.toUpperCase()}*

*Summary:*
Subtotal: ₹${invoice.subTotal.toStringAsFixed(2)}
GST: ₹${invoice.totalTax.toStringAsFixed(2)}
*Total Amount: ₹${invoice.grandTotal.toStringAsFixed(2)}*

*Payment Detail:*
Mode: ${invoice.paymentMode}

Download Invoice PDF:
${downloadUrl.isNotEmpty ? downloadUrl : 'Generating link...'}

Thank you for your business!
''';

    final whatsappUrl = Uri.parse(
      "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}",
    );

    try {
      await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
    } catch (e) {
      print('Launch Error: $e');
    }

    return downloadUrl;
  }

  static Future<String?> uploadPdfOnly({
    required String businessId,
    required String invoiceId,
    required Uint8List pdfBytes,
  }) async {
    try {
      print('Background PDF Upload started...');
      final storageRef = FirebaseStorage.instance.ref().child(
        'invoices/$businessId/$invoiceId.pdf',
      );

      final uploadTask = await storageRef.putData(
        pdfBytes,
        SettableMetadata(contentType: 'application/pdf'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('Background PDF Upload success: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Background PDF Upload failed: $e');
      return null;
    }
  }

  static Future<void> sendInvoiceSummary({
    required InvoiceModel invoice,
    required BusinessModel business,
  }) async {
    // Legacy method for backward compatibility
    final customerPhone = invoice.customer['phone'] ?? '';
    if (customerPhone.isEmpty) return;

    String cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final message =
        '''
Hello *${invoice.customer['name']}*,

This is a bill from *${business.businessName}*.
Invoice No: #${invoice.invoiceNumber}
Total: ₹${invoice.grandTotal.toStringAsFixed(2)}

Thank you!
''';

    final whatsappUrl = Uri.parse(
      "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }
}
