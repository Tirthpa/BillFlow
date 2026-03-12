import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/invoice_model.dart';
import '../../../services/database_repository.dart';
import '../../../features/auth/repository/auth_repository.dart';
import '../../../services/pdf_service.dart';
import '../../../core/theme/app_theme.dart';
import 'create_invoice_screen.dart';
import '../../customers/customer_list_screen.dart';
import '../../products/product_list_screen.dart';

import '../../../services/whatsapp_service.dart';
import '../../settings/views/settings_screen.dart';
import '../../../models/business_model.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';
  final Set<String> _loadingInvoices = {};
  // Session-wide tracker to prevent redundant background work
  static final Set<String> _ghostUploadedIds = {};
  static final Set<String> _processingIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // UI Build logic...
    // The ghost uploader is now managed via ref.listen to be more efficient
    ref.listen(invoicesProvider, (previous, next) {
      next.whenData((invoices) {
        final toUpload = invoices
            .take(5) // Only prep the most recent ones
            .where(
              (i) =>
                  (i.pdfUrl == null || i.pdfUrl!.isEmpty) &&
                  !_ghostUploadedIds.contains(i.id) &&
                  !_processingIds.contains(i.id),
            );

        for (final inv in toUpload) {
          _ghostUpload(ref, inv, silent: true);
        }
      });
    });

    final invoicesAsync = ref.watch(invoicesProvider);

    // UI Build logic...

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200), // Better for Web
          child: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                floating: true,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  'Dashboard',
                  style: TextStyle(color: theme.textTheme.titleLarge?.color),
                ),
                actions: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ),
                    icon: Icon(
                      Icons.settings_outlined,
                      color: theme.iconTheme.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: invoicesAsync.when(
                  data: (invoices) {
                    final paidRevenue = invoices
                        .where((i) => i.status == 'Paid')
                        .fold(0.0, (sum, i) => sum + i.grandTotal);
                    final pendingDues = invoices
                        .where((i) => i.status == 'Pending')
                        .fold(0.0, (sum, i) => sum + i.grandTotal);

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Advanced Stats View
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _StatCard(
                                  title: 'Revenue',
                                  value: '₹${paidRevenue.toStringAsFixed(0)}',
                                  icon: Icons.keyboard_double_arrow_up_rounded,
                                  color: AppTheme.secondaryColor,
                                  subtitle: 'Paid Invoices',
                                ),
                                const SizedBox(width: 12),
                                _StatCard(
                                  title: 'Receivables',
                                  value: '₹${pendingDues.toStringAsFixed(0)}',
                                  icon: Icons.watch_later_outlined,
                                  color: AppTheme.accentColor,
                                  subtitle: 'Awaiting Payment',
                                ),
                                const SizedBox(width: 12),
                                _StatCard(
                                  title: 'Volume',
                                  value: invoices.length.toString(),
                                  icon: Icons.receipt_long_outlined,
                                  color: AppTheme.primaryColor,
                                  subtitle: 'Total Invoices',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(
                              () => _searchQuery = val.toLowerCase(),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search by customer name...',
                              prefixIcon: const Icon(Icons.search),
                              fillColor: isDark
                                  ? AppTheme.darkSurfaceColor
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Activities',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PopupMenuButton<String>(
                                initialValue: _filterStatus,
                                icon: const Icon(
                                  Icons.filter_list,
                                  color: AppTheme.primaryColor,
                                ),
                                onSelected: (val) =>
                                    setState(() => _filterStatus = val),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'All',
                                    child: Text('Show All'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'Paid',
                                    child: Text('Paid Only'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'Pending',
                                    child: Text('Pending Only'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
              ...invoicesAsync.when(
                data: (rawInvoices) {
                  var invoices = rawInvoices;
                  // Apply Query Filter
                  if (_searchQuery.isNotEmpty) {
                    invoices = invoices.where((i) {
                      final name = (i.customer['name'] ?? '')
                          .toString()
                          .toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();
                  }
                  // Apply Status Filter
                  if (_filterStatus != 'All') {
                    invoices = invoices
                        .where((i) => i.status == _filterStatus)
                        .toList();
                  }

                  if (invoices.isEmpty) {
                    return [
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 80,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No invoices yet'
                                    : 'No matches found',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  }

                  return [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final invoice = invoices[index];
                          return _InvoiceCard(
                            invoice: invoice,
                            ref: ref,
                            isUploading: _loadingInvoices.contains(invoice.id),
                            onStartUpload: () => setState(
                              () => _loadingInvoices.add(invoice.id),
                            ),
                            onEndUpload: () => setState(
                              () => _loadingInvoices.remove(invoice.id),
                            ),
                          );
                        }, childCount: invoices.length),
                      ),
                    ),
                  ];
                },
                loading: () => [
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (e, st) => [
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Database Error: $e',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please check your internet or Firestore indexes.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      drawer: _AppDrawer(ref: ref),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
        ),
        label: const Text('New Invoice'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  static bool _isProcessingQueue = false;

  static void _ghostUpload(
    WidgetRef ref,
    InvoiceModel invoice, {
    bool silent = true,
  }) async {
    if (_isProcessingQueue) return;
    if (_processingIds.contains(invoice.id)) return;
    if (_ghostUploadedIds.contains(invoice.id)) return;

    _isProcessingQueue = true;
    _processingIds.add(invoice.id);

    try {
      final business = await ref
          .read(authRepositoryProvider)
          .getCurrentBusiness();
      if (business == null) throw 'Business not found';

      final pdfBytes = await PdfService.generateInvoiceBytes(invoice, business);
      final url = await WhatsAppService.uploadPdfOnly(
        businessId: business.uid,
        invoiceId: invoice.id,
        pdfBytes: pdfBytes,
      );

      if (url != null) {
        await ref
            .read(databaseRepositoryProvider)
            .updateInvoicePdfUrl(invoice.id, url);
        _ghostUploadedIds.add(invoice.id);
      }
    } catch (e) {
      debugPrint('Ghost upload task failed for ${invoice.id}: $e');
    } finally {
      _processingIds.remove(invoice.id);
      _isProcessingQueue = false;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : color.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final WidgetRef ref;
  final bool isUploading;
  final VoidCallback onStartUpload;
  final VoidCallback onEndUpload;

  const _InvoiceCard({
    required this.invoice,
    required this.ref,
    required this.isUploading,
    required this.onStartUpload,
    required this.onEndUpload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = invoice.status == 'Paid'
        ? AppTheme.secondaryColor
        : AppTheme.accentColor;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_outlined,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (invoice.customer['name'] ?? 'Unknown Customer')
                            .toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '#${invoice.invoiceNumber} • ${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${invoice.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        invoice.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  onTap: () async {
                    final business = await ref
                        .read(authRepositoryProvider)
                        .getCurrentBusiness();
                    if (business != null) {
                      await PdfService.generateAndShareInvoice(
                        invoice,
                        business,
                      );
                    }
                  },
                ),
                _QuickAction(
                  icon: isUploading
                      ? Icons.hourglass_top
                      : Icons.share_outlined,
                  label: isUploading ? 'Saving...' : 'WhatsApp',
                  onTap: () async {
                    // INSTANT ACTION: Match user request for simple direct text
                    final business =
                        ref.read(businessProfileProvider).value ??
                        await ref
                            .read(authRepositoryProvider)
                            .getCurrentBusiness();

                    if (business != null) {
                      // 1. Launch WhatsApp immediately with text
                      await WhatsAppService.shareInvoiceText(
                        invoice: invoice,
                        business: business,
                      );

                      // 2. Silent background prep if link is missing
                      if (invoice.pdfUrl == null || invoice.pdfUrl!.isEmpty) {
                        _InvoiceListScreenState._ghostUpload(
                          ref,
                          invoice,
                          silent: true,
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Business profile not found.'),
                        ),
                      );
                    }
                  },
                ),
                _QuickAction(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateInvoiceScreen(invoice: invoice),
                    ),
                  ),
                ),
                _QuickAction(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onTap: () => _showDeleteDialog(context, ref),
                ),
                const Spacer(),
                if (invoice.status == 'Pending')
                  TextButton.icon(
                    onPressed: () => ref
                        .read(databaseRepositoryProvider)
                        .updateInvoice(invoice.copyWith(status: 'Paid')),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark Paid'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: Text(
          'Are you sure you want to delete Invoice #${invoice.invoiceNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(databaseRepositoryProvider)
                  .deleteInvoice(invoice.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final WidgetRef ref;
  const _AppDrawer({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, const Color(0xFF818CF8)],
              ),
            ),
            child: FutureBuilder<BusinessModel?>(
              future: ref.read(authRepositoryProvider).getCurrentBusiness(),
              builder: (context, snapshot) {
                final name = snapshot.data?.businessName ?? 'BillFlow Pro';
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt, color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Customers'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerListScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Products'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListScreen(),
                ),
              );
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => ref.read(authRepositoryProvider).logout(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
