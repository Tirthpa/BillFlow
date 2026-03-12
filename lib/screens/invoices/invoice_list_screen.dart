import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/invoice_model.dart';
import 'invoice_detail_screen.dart';
import 'create_invoice_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateInvoiceScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<InvoiceProvider, AuthProvider>(
        builder: (context, invoiceProvider, authProvider, _) {
          List<Invoice> invoices = invoiceProvider.invoices;
          
          if (_filterStatus != 'all') {
            invoices = invoices.where((inv) => inv.status == _filterStatus).toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', 'all'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Draft', 'draft'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Sent', 'sent'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Paid', 'paid'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Pending', 'pending'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: invoices.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No invoices found',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return _buildInvoiceCard(context, invoice);
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    return FilterChip(
      label: Text(label),
      selected: _filterStatus == status,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? status : 'all';
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF1976D2),
      labelStyle: TextStyle(
        color: _filterStatus == status ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice) {
    Color statusColor = invoice.status == 'paid'
        ? Colors.green
        : invoice.status == 'pending'
            ? Colors.orange
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceDetailScreen(invoice: invoice),
            ),
          );
        },
        title: Text(
          'Invoice #${invoice.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(invoice.customerName),
            const SizedBox(height: 4),
            Text(
              'Due: ${invoice.dueDate?.toString().split(' ')[0] ?? 'N/A'}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${invoice.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                invoice.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
