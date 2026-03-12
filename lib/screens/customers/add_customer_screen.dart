import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/customer_model.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _gstinController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.customer?.email ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    _cityController = TextEditingController(text: widget.customer?.city ?? '');
    _stateController = TextEditingController(text: widget.customer?.state ?? '');
    _zipCodeController = TextEditingController(text: widget.customer?.zipCode ?? '');
    _gstinController = TextEditingController(text: widget.customer?.gstin ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customer != null ? 'Edit Customer' : 'Add Customer',
        ),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Customer Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _stateController,
              decoration: InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _zipCodeController,
              decoration: InputDecoration(
                labelText: 'Zip Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gstinController,
              decoration: InputDecoration(
                labelText: 'GST ID (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                    onPressed: _handleSaveCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Customer',
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

  void _handleSaveCustomer() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);

    if (authProvider.user != null) {
      if (widget.customer != null) {
        // Update existing customer
        await customerProvider.updateCustomer(
          customerId: widget.customer!.id,
          name: _nameController.text,
          phoneNumber: _phoneController.text,
          email: _emailController.text,
          address: _addressController.text,
          city: _cityController.text,
          state: _stateController.text,
          zipCode: _zipCodeController.text,
          gstin: _gstinController.text.isEmpty ? null : _gstinController.text,
        );
      } else {
        // Add new customer
        await customerProvider.addCustomer(
          userId: authProvider.user!.uid,
          name: _nameController.text,
          phoneNumber: _phoneController.text,
          email: _emailController.text,
          address: _addressController.text,
          city: _cityController.text,
          state: _stateController.text,
          zipCode: _zipCodeController.text,
          gstin: _gstinController.text.isEmpty ? null : _gstinController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.customer != null
                  ? 'Customer updated successfully'
                  : 'Customer added successfully',
            ),
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}
