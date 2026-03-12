import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/customer_model.dart';
import '../../../services/database_repository.dart';
import '../../../core/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Customers'),
            floating: true,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          customersAsync.when(
            data: (rawCustomers) {
              final customers = rawCustomers.where((c) {
                return c.name.toLowerCase().contains(_searchQuery) ||
                    c.phone.contains(_searchQuery);
              }).toList();

              if (customers.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No customers yet'
                              : 'No customers found',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _CustomerCard(customer: customers[index]),
                    childCount: customers.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerSheet(context),
        label: const Text('Add Customer'),
        icon: const Icon(Icons.person_add_outlined),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showAddCustomerSheet(BuildContext context, {CustomerModel? customer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => AddCustomerSheet(customer: customer),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            customer.name[0].toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
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
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(customer.phone, style: const TextStyle(fontSize: 12)),
              ],
            ),
            if (customer.gstNumber != null &&
                customer.gstNumber!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'GST: ${customer.gstNumber}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') {
              _showEditDialog(context);
            } else if (val == 'delete') {
              _showDeleteDialog(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => AddCustomerSheet(customer: customer),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) => AlertDialog(
          title: const Text('Delete Customer?'),
          content: Text('Are you sure you want to delete ${customer.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(databaseRepositoryProvider)
                    .deleteCustomer(customer.id);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class AddCustomerSheet extends ConsumerStatefulWidget {
  final CustomerModel? customer;
  final Function(CustomerModel)? onAdd;
  const AddCustomerSheet({super.key, this.customer, this.onAdd});

  @override
  ConsumerState<AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends ConsumerState<AddCustomerSheet> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController gstController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.customer?.name ?? '');
    phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    emailController = TextEditingController(text: widget.customer?.email ?? '');
    addressController = TextEditingController(
      text: widget.customer?.address ?? '',
    );
    gstController = TextEditingController(
      text: widget.customer?.gstNumber ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.customer == null ? 'Add New Customer' : 'Edit Customer',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Customer Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email (Optional)',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: gstController,
            decoration: const InputDecoration(
              labelText: 'GST Number (Optional)',
              prefixIcon: Icon(Icons.assignment_outlined),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name and Phone are required')),
                );
                return;
              }
              final customer = CustomerModel(
                id: widget.customer?.id ?? const Uuid().v4(),
                businessId: widget.customer?.businessId ?? '',
                name: nameController.text,
                email: emailController.text,
                phone: phoneController.text,
                address: addressController.text,
                gstNumber: gstController.text,
              );

              if (widget.onAdd != null) {
                widget.onAdd!(customer);
              } else {
                if (widget.customer == null) {
                  await ref
                      .read(databaseRepositoryProvider)
                      .addCustomer(customer);
                } else {
                  await ref
                      .read(databaseRepositoryProvider)
                      .updateCustomer(customer);
                }
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              widget.customer == null ? 'Save Customer' : 'Update Customer',
            ),
          ),
        ],
      ),
    );
  }
}
