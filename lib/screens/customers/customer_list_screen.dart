import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/customer_model.dart';
import 'add_customer_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddCustomerScreen(),
                ),
              ).then((_) {
                Provider.of<CustomerProvider>(context, listen: false)
                    .fetchCustomers(
                  Provider.of<AuthProvider>(context, listen: false).user!.uid,
                );
              });
            },
          ),
        ],
      ),
      body: Consumer2<CustomerProvider, AuthProvider>(
        builder: (context, customerProvider, authProvider, _) {
          final customers = customerProvider.customers;

          return customers.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No customers found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return _buildCustomerCard(context, customer);
                },
              );
        },
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1976D2),
          child: Text(
            customer.name.isNotEmpty ? customer.name[0] : 'C',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(customer.phoneNumber),
            const SizedBox(height: 2),
            Text(
              customer.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Edit'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCustomerScreen(customer: customer),
                  ),
                );
              },
            ),
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Customer'),
                    content: const Text(
                      'Are you sure you want to delete this customer?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Provider.of<CustomerProvider>(context, listen: false)
                              .deleteCustomer(customer.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Customer deleted')),
                          );
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
