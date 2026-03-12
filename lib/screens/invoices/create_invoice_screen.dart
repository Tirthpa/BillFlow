import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/invoice_model.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoiceToEdit;

  const CreateInvoiceScreen({super.key, this.invoiceToEdit});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  late TextEditingController _notesController;
  late TextEditingController _discountController;
  late TextEditingController _dueDateController;

  Customer? _selectedCustomer;
  List<InvoiceItem> _items = [];
  double _taxRate = 0;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _discountController = TextEditingController(text: '0');
    _dueDateController = TextEditingController();

    if (widget.invoiceToEdit != null) {
      _selectedCustomer = Provider.of<CustomerProvider>(context, listen: false)
          .getCustomerById(widget.invoiceToEdit!.customerId);
      _items = widget.invoiceToEdit!.items;
      _taxRate = widget.invoiceToEdit!.taxRate;
      _discountController.text = widget.invoiceToEdit!.discount.toString();
      _notesController.text = widget.invoiceToEdit!.notes;
      _dueDateController.text = widget.invoiceToEdit!.dueDate?.toString().split(' ')[0] ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoiceToEdit != null ? 'Edit Invoice' : 'Create Invoice'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Selection
            Text(
              'Select Customer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<CustomerProvider>(
              builder: (context, customerProvider, _) {
                return DropdownButton<Customer>(
                  isExpanded: true,
                  hint: const Text('Select a customer'),
                  value: _selectedCustomer,
                  items: customerProvider.customers
                      .map((customer) => DropdownMenuItem(
                        value: customer,
                        child: Text(customer.name),
                      ))
                      .toList(),
                  onChanged: (customer) {
                    setState(() {
                      _selectedCustomer = customer;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Invoice Items
            Text(
              'Invoice Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<ProductProvider>(
              builder: (context, productProvider, _) {
                return Column(
                  children: [
                    ..._items.asMap().entries.map((entry) {
                      int index = entry.key;
                      InvoiceItem item = entry.value;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: ${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)} = \$${item.subtotal.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _items.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddItemDialog(context, productProvider.products),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Additional Details
            Text(
              'Additional Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dueDateController,
              decoration: InputDecoration(
                labelText: 'Due Date',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  _dueDateController.text = date.toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _discountController,
              decoration: InputDecoration(
                labelText: 'Discount (\$)',
                prefixIcon: const Icon(Icons.discount),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text(
                          '\$${_calculateSubtotal().toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text(
                          '-\$${_discountController.text}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax:'),
                        Text(
                          '\$${_calculateTax().toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '\$${_calculateTotal().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF1976D2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSaveInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Invoice',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateSubtotal() {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  double _calculateTax() {
    return _items.fold(0, (sum, item) => sum + item.taxAmount);
  }

  double _calculateTotal() {
    double subtotal = _calculateSubtotal();
    double tax = _calculateTax();
    double discount = double.tryParse(_discountController.text) ?? 0;
    return subtotal + tax - discount;
  }

  void _showAddItemDialog(BuildContext context, List<Product> products) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        products: products,
        onAdd: (item) {
          setState(() {
            _items.add(item);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _handleSaveInvoice() {
    if (_selectedCustomer == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer and add items')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);

    if (authProvider.user != null) {
      invoiceProvider.createInvoice(
        userId: authProvider.user!.uid,
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        customerPhone: _selectedCustomer!.phoneNumber,
        customerEmail: _selectedCustomer!.email,
        items: _items,
        discount: double.tryParse(_discountController.text) ?? 0,
        taxRate: _taxRate,
        notes: _notesController.text,
        dueDate: DateTime.tryParse(_dueDateController.text) ?? DateTime.now().add(const Duration(days: 30)),
      ).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice created successfully')),
        );
        Navigator.pop(context);
      });
    }
  }
}

class AddItemDialog extends StatefulWidget {
  final List<Product> products;
  final Function(InvoiceItem) onAdd;

  const AddItemDialog({
    super.key,
    required this.products,
    required this.onAdd,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  late TextEditingController _quantityController;
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<Product>(
              isExpanded: true,
              hint: const Text('Select product'),
              value: _selectedProduct,
              items: widget.products
                  .map((product) => DropdownMenuItem(
                    value: product,
                    child: Text(product.name),
                  ))
                  .toList(),
              onChanged: (product) {
                setState(() {
                  _selectedProduct = product;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _handleAddItem,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _handleAddItem() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    int quantity = int.tryParse(_quantityController.text) ?? 1;

    InvoiceItem item = InvoiceItem(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      quantity: quantity,
      unitPrice: _selectedProduct!.price,
      taxRate: _selectedProduct!.taxRate,
      discount: 0,
    );

    widget.onAdd(item);
  }
}
