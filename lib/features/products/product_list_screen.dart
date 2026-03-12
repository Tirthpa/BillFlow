import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../../../services/database_repository.dart';
import '../../../core/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Products & Services'),
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
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          productsAsync.when(
            data: (rawProducts) {
              final products = rawProducts.where((p) {
                return p.name.toLowerCase().contains(_searchQuery);
              }).toList();

              if (products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No products yet'
                              : 'No products found',
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
                    (context, index) => _ProductCard(product: products[index]),
                    childCount: products.length,
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
        onPressed: () => _showAddProductSheet(context),
        label: const Text('Add Product'),
        icon: const Icon(Icons.add_box_outlined),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showAddProductSheet(BuildContext context, {ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => AddProductSheet(product: product),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

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
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: AppTheme.secondaryColor,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text(
              '₹${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'GST: ${product.gstRate}%',
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') {
              // Accessing _ProductListScreenState through context is tricky,
              // but we can find it if we structure it.
              // For now, let's just trigger a dialog.
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
      builder: (context) => AddProductSheet(product: product),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) => AlertDialog(
          title: const Text('Delete Product?'),
          content: Text('Are you sure you want to delete ${product.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(databaseRepositoryProvider)
                    .deleteProduct(product.id);
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

class AddProductSheet extends ConsumerStatefulWidget {
  final ProductModel? product;
  final Function(ProductModel)? onAdd;
  const AddProductSheet({super.key, this.product, this.onAdd});

  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController gstController;
  late TextEditingController unitController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product?.name ?? '');
    priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    gstController = TextEditingController(
      text: widget.product?.gstRate.toString() ?? '18',
    );
    unitController = TextEditingController(text: widget.product?.unit ?? 'Pcs');
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
                widget.product == null ? 'Add New Product' : 'Edit Product',
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
              labelText: 'Product/Service Name',
              prefixIcon: Icon(Icons.shopping_bag_outlined),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
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
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit (e.g. Hrs, Kg)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: gstController,
            decoration: const InputDecoration(
              labelText: 'Standard GST Rate (%)',
              prefixIcon: Icon(Icons.percent),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name and Price are required')),
                );
                return;
              }
              final product = ProductModel(
                id: widget.product?.id ?? const Uuid().v4(),
                businessId: widget.product?.businessId ?? '',
                name: nameController.text,
                price: double.tryParse(priceController.text) ?? 0,
                gstRate: double.tryParse(gstController.text) ?? 0,
                unit: unitController.text,
              );

              if (widget.onAdd != null) {
                widget.onAdd!(product);
              } else {
                if (widget.product == null) {
                  await ref
                      .read(databaseRepositoryProvider)
                      .addProduct(product);
                } else {
                  await ref
                      .read(databaseRepositoryProvider)
                      .updateProduct(product);
                }
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              widget.product == null ? 'Save Product' : 'Update Product',
            ),
          ),
        ],
      ),
    );
  }
}
