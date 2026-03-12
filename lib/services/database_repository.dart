import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/customer_model.dart';
import '../../../models/product_model.dart';
import '../../../models/invoice_model.dart';
import '../features/auth/repository/auth_repository.dart';

final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid ?? '';
  return DatabaseRepository(
    firestore: FirebaseFirestore.instance,
    userId: userId,
  );
});

final invoicesProvider = StreamProvider<List<InvoiceModel>>((ref) {
  return ref.watch(databaseRepositoryProvider).getInvoices();
});

final recentInvoicesProvider = StreamProvider.family<List<InvoiceModel>, int>((
  ref,
  limit,
) {
  return ref.watch(databaseRepositoryProvider).getRecentInvoices(limit: limit);
});

final customersProvider = StreamProvider<List<CustomerModel>>((ref) {
  return ref.watch(databaseRepositoryProvider).getCustomers();
});

final productsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(databaseRepositoryProvider).getProducts();
});

class DatabaseRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  DatabaseRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId;

  // Customers
  Stream<List<CustomerModel>> getCustomers() {
    return _firestore
        .collection('customers')
        .where('businessId', isEqualTo: _userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CustomerModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> addCustomer(CustomerModel customer) async {
    final updatedCustomer = customer.copyWith(businessId: _userId);
    await _firestore
        .collection('customers')
        .doc(updatedCustomer.id)
        .set(updatedCustomer.toMap());
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    await _firestore
        .collection('customers')
        .doc(customer.id)
        .set(customer.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCustomer(String customerId) async {
    await _firestore.collection('customers').doc(customerId).delete();
  }

  // Products
  Stream<List<ProductModel>> getProducts() {
    return _firestore
        .collection('products')
        .where('businessId', isEqualTo: _userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> addProduct(ProductModel product) async {
    final updatedProduct = product.copyWith(businessId: _userId);
    await _firestore
        .collection('products')
        .doc(updatedProduct.id)
        .set(updatedProduct.toMap());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .set(product.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  // Invoices
  Stream<List<InvoiceModel>> getInvoices({String? status}) {
    var query = _firestore
        .collection('invoices')
        .where('businessId', isEqualTo: _userId)
        .orderBy('date', descending: true);

    if (status != null && status != 'All') {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => InvoiceModel.fromMap(doc.data())).toList(),
    );
  }

  Stream<List<InvoiceModel>> getRecentInvoices({int limit = 5}) {
    return _firestore
        .collection('invoices')
        .where('businessId', isEqualTo: _userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InvoiceModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> createInvoice(InvoiceModel invoice) async {
    final updatedInvoice = invoice.copyWith(businessId: _userId);
    await _firestore
        .collection('invoices')
        .doc(updatedInvoice.id)
        .set(updatedInvoice.toMap());
  }

  Future<void> updateInvoicePdfUrl(String invoiceId, String pdfUrl) async {
    await _firestore.collection('invoices').doc(invoiceId).update({
      'pdfUrl': pdfUrl,
    });
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    await _firestore
        .collection('invoices')
        .doc(invoice.id)
        .set(invoice.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await _firestore.collection('invoices').doc(invoiceId).delete();
  }
}
