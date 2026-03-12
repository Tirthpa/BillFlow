import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/customer_model.dart';
import '../../../models/product_model.dart';
import '../../../models/invoice_model.dart';
import '../../../services/database_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../customers/customer_list_screen.dart'; // To reuse _AddCustomerSheet
import '../../products/product_list_screen.dart'; // To reuse _AddProductSheet

import '../../../services/pdf_service.dart';
import '../../../services/whatsapp_service.dart';
import '../../auth/repository/auth_repository.dart';
import '../../../core/theme/app_theme.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final InvoiceModel? invoice;
  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _invoiceNumberController = TextEditingController(text: '1001');
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();
  final _discountController = TextEditingController(text: '0');

  CustomerModel? _selectedCustomer;
  List<InvoiceItem> _items = [];
  bool _isLoading = false;
  bool _isGstEnabled = true;
  String _selectedPaymentMode = 'Cash';

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _invoiceNumberController.text = widget.invoice!.invoiceNumber;
      _items = List.from(widget.invoice!.items);
      _discountController.text = widget.invoice!.discount.toString();
      _notesController.text = widget.invoice!.notes ?? '';
      _termsController.text = widget.invoice!.terms ?? '';
      _selectedPaymentMode = widget.invoice!.paymentMode;
    }
  }

  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddItemSheet(
        isGstEnabled: _isGstEnabled,
        onAdd: (item) => setState(() => _items.add(item)),
      ),
    );
  }

  void _addCustomer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCustomerSheet(),
    );
  }

  void _createInvoice() async {
    if (_selectedCustomer == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer and add at least one item'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final subTotal = _items.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.price),
    );
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final totalTax = _isGstEnabled
        ? _items.fold(
            0.0,
            (sum, item) =>
                sum + (item.quantity * item.price * item.gstRate / 100),
          )
        : 0.0;
    final grandTotal = subTotal + totalTax - discount;

    final invoice = InvoiceModel(
      id: widget.invoice?.id ?? const Uuid().v4(),
      businessId:
          widget.invoice?.businessId ??
          FirebaseAuth.instance.currentUser?.uid ??
          '',
      invoiceNumber: _invoiceNumberController.text,
      customer: _selectedCustomer!.toMap(),
      items: _items,
      subTotal: subTotal,
      totalTax: totalTax,
      grandTotal: grandTotal,
      discount: discount,
      date: widget.invoice?.date ?? DateTime.now(),
      status: widget.invoice?.status ?? 'Pending',
      paymentMode: _selectedPaymentMode,
      notes: _notesController.text,
      terms: _termsController.text,
      pdfUrl: widget.invoice?.pdfUrl,
    );

    try {
      if (widget.invoice == null) {
        await ref.read(databaseRepositoryProvider).createInvoice(invoice);
      } else {
        await ref.read(databaseRepositoryProvider).updateInvoice(invoice);
      }

      // BACKGROUND PRE-GENERATION: Non-blocking so the screen closes instantly!
      _generateAndUploadBackground(invoice);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice saved! PDF is generating in background...'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Non-blocking background upload
  void _generateAndUploadBackground(InvoiceModel invoice) async {
    try {
      final business = ref.read(businessProfileProvider).value;
      if (business != null) {
        final pdfBytes = await PdfService.generateInvoiceBytes(
          invoice,
          business,
        );
        final pdfUrl = await WhatsAppService.uploadPdfOnly(
          businessId: business.uid,
          invoiceId: invoice.id,
          pdfBytes: pdfBytes,
        );
        if (pdfUrl != null) {
          await ref
              .read(databaseRepositoryProvider)
              .updateInvoicePdfUrl(invoice.id, pdfUrl);
        }
      }
    } catch (e) {
      debugPrint('Background PDF task failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersStream = ref.watch(customersProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'New Invoice' : 'Edit Invoice'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            _StepCard(
              title: 'Invoice Details',
              icon: Icons.info_outline,
              child: Column(
                children: [
                  TextField(
                    controller: _invoiceNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Number',
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: customersStream.when(
                          data: (customers) {
                            return DropdownButtonFormField<CustomerModel>(
                              value:
                                  _selectedCustomer ??
                                  (widget.invoice != null
                                      ? customers.firstWhere(
                                          (c) =>
                                              c.phone ==
                                              widget.invoice!.customer['phone'],
                                          orElse: () => customers.first,
                                        )
                                      : null),
                              items: customers
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedCustomer = val),
                              decoration: const InputDecoration(
                                hintText: 'Select Customer',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, st) => Text('Error: $e'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _addCustomer,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Items Card
            _StepCard(
              title: 'Line Items',
              icon: Icons.shopping_basket_outlined,
              trailing: IconButton(
                onPressed: _addItem,
                icon: const Icon(
                  Icons.add_circle,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
              child: _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_shopping_cart,
                              size: 48,
                              color: Colors.grey[isDark ? 700 : 300],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No items added yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.quantity.toStringAsFixed(0)} x ₹${item.price} (+${item.gstRate}% GST)',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _items.removeAt(index)),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 32),
            // Totals Section
            if (_items.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _TotalRow(
                      label: 'Sub Total',
                      value: _items.fold(
                        0.0,
                        (sum, item) => sum + (item.quantity * item.price),
                      ),
                      isLight: true,
                    ),
                    const SizedBox(height: 8),
                    _TotalRow(
                      label: 'Total Tax',
                      value: _items.fold(
                        0.0,
                        (sum, item) =>
                            sum +
                            (item.quantity * item.price * item.gstRate / 100),
                      ),
                      isLight: true,
                    ),
                    _TotalRow(
                      label: 'Discount',
                      value: double.tryParse(_discountController.text) ?? 0.0,
                      isLight: true,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white24),
                    ),
                    _TotalRow(
                      label: 'Grand Total',
                      value: _items.fold(0.0, (sum, item) => sum + item.total),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _createInvoice,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Generate & Save'),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _StepCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isLight;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isLight = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isLight ? Colors.white70 : Colors.white,
            fontSize: isBold ? 20 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: isBold ? 24 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _AddItemSheet extends ConsumerStatefulWidget {
  final bool isGstEnabled;
  final Function(InvoiceItem) onAdd;
  const _AddItemSheet({required this.isGstEnabled, required this.onAdd});

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final nameController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final priceController = TextEditingController();
  final gstController = TextEditingController(text: '18');
  ProductModel? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    final productsStream = ref.watch(productsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Line Item',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddProductSheet(),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('New Product'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          productsStream.when(
            data: (products) {
              return DropdownButtonFormField<ProductModel>(
                value: _selectedProduct,
                items: products
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedProduct = val;
                    if (val != null) {
                      nameController.text = val.name;
                      priceController.text = val.price.toString();
                      gstController.text = val.gstRate.toString();
                    }
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search or Select Product',
                  prefixIcon: Icon(Icons.search),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => Text('Error loading products: $e'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name (Manual Override)',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: qtyController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Price',
                    prefixText: '₹',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          if (widget.isGstEnabled) ...[
            const SizedBox(height: 16),
            TextField(
              controller: gstController,
              decoration: const InputDecoration(labelText: 'GST Rate (%)'),
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0;
              final gstRate = widget.isGstEnabled
                  ? (double.tryParse(gstController.text) ?? 0)
                  : 0.0;
              final itemTotal = (qty * price) + (qty * price * gstRate / 100);

              widget.onAdd(
                InvoiceItem(
                  productId: _selectedProduct?.id ?? const Uuid().v4(),
                  productName: nameController.text,
                  quantity: qty,
                  price: price,
                  gstRate: gstRate,
                  total: itemTotal,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Add to Invoice'),
          ),
        ],
      ),
    );
  }
}
