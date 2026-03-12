import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceItem {
  final String productId;
  final String productName;
  final double quantity;
  final double price;
  final double gstRate;
  final double total;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.gstRate,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'gstRate': gstRate,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      gstRate: (map['gstRate'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
    );
  }

  InvoiceItem copyWith({
    String? productId,
    String? productName,
    double? quantity,
    double? price,
    double? gstRate,
    double? total,
  }) {
    return InvoiceItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
      total: total ?? this.total,
    );
  }
}

class InvoiceModel {
  final String id;
  final String businessId;
  final String invoiceNumber;
  final Map<String, dynamic> customer;
  final List<InvoiceItem> items;
  final double subTotal;
  final double totalTax; // GST
  final double grandTotal;
  final DateTime date;
  final String status; // Pending, Paid, Overdue
  final String paymentMode; // Cash, Bank Transfer, UPI, Online
  final double discount;
  final String? notes;
  final String? terms;
  final String? pdfUrl;

  InvoiceModel({
    required this.id,
    required this.businessId,
    required this.invoiceNumber,
    required this.customer,
    required this.items,
    required this.subTotal,
    required this.totalTax,
    required this.grandTotal,
    required this.date,
    required this.status,
    this.paymentMode = 'Cash',
    this.discount = 0.0,
    this.notes,
    this.terms,
    this.pdfUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'invoiceNumber': invoiceNumber,
      'customer': customer,
      'items': items.map((x) => x.toMap()).toList(),
      'subTotal': subTotal,
      'totalTax': totalTax,
      'grandTotal': grandTotal,
      'date': Timestamp.fromDate(date),
      'status': status,
      'paymentMode': paymentMode,
      'discount': discount,
      'notes': notes,
      'terms': terms,
      'pdfUrl': pdfUrl,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      customer: Map<String, dynamic>.from(map['customer'] ?? {}),
      items: List<InvoiceItem>.from(
        (map['items'] as List? ?? []).map((x) => InvoiceItem.fromMap(x)),
      ),
      subTotal: (map['subTotal'] ?? 0).toDouble(),
      totalTax: (map['totalTax'] ?? 0).toDouble(),
      grandTotal: (map['grandTotal'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'] ?? 'Pending',
      paymentMode: map['paymentMode'] ?? 'Cash',
      discount: (map['discount'] ?? 0).toDouble(),
      notes: map['notes'],
      terms: map['terms'],
      pdfUrl: map['pdfUrl'],
    );
  }

  InvoiceModel copyWith({
    String? id,
    String? businessId,
    String? invoiceNumber,
    Map<String, dynamic>? customer,
    List<InvoiceItem>? items,
    double? subTotal,
    double? totalTax,
    double? grandTotal,
    DateTime? date,
    String? status,
    String? paymentMode,
    double? discount,
    String? notes,
    String? terms,
    String? pdfUrl,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      subTotal: subTotal ?? this.subTotal,
      totalTax: totalTax ?? this.totalTax,
      grandTotal: grandTotal ?? this.grandTotal,
      date: date ?? this.date,
      status: status ?? this.status,
      paymentMode: paymentMode ?? this.paymentMode,
      discount: discount ?? this.discount,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }
}
