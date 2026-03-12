import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/repository/auth_repository.dart';
import '../../../models/business_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle app theme'),
            secondary: Icon(
              themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
              color: AppTheme.primaryColor,
            ),
            value: themeMode == ThemeMode.dark,
            onChanged: (val) {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          const Divider(),
          _SectionHeader(title: 'Business Profile'),
          FutureBuilder<BusinessModel?>(
            future: ref.read(authRepositoryProvider).getCurrentBusiness(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final business = snapshot.data;
              if (business == null)
                return const ListTile(title: Text('No business found'));

              return Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.business,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(business.businessName),
                    subtitle: const Text('Business Name'),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _editField(
                      context,
                      ref,
                      'Business Name',
                      business.businessName,
                      'businessName',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(business.address),
                    subtitle: const Text('Business Address'),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _editField(
                      context,
                      ref,
                      'Address',
                      business.address,
                      'address',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.account_balance_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(business.bankName ?? 'Not Set'),
                    subtitle: const Text('Bank Name'),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _editField(
                      context,
                      ref,
                      'Bank Name',
                      business.bankName ?? '',
                      'bankName',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.qr_code_scanner,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(business.upiId ?? 'Not Set'),
                    subtitle: const Text('UPI ID'),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _editField(
                      context,
                      ref,
                      'UPI ID',
                      business.upiId ?? '',
                      'upiId',
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(),
          _SectionHeader(title: 'About'),
          const ListTile(
            title: Text('BillFlow Pro'),
            subtitle: Text('Version 1.0.0-Saas'),
            trailing: Icon(Icons.info_outline),
          ),
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'A complete platform to manage your business invoices and payments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _editField(
    BuildContext context,
    WidgetRef ref,
    String label,
    String currentVal,
    String fieldKey,
  ) {
    final controller = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final business = await ref
                  .read(authRepositoryProvider)
                  .getCurrentBusiness();
              if (business != null) {
                final map = business.toMap();
                map[fieldKey] = controller.text;
                await ref
                    .read(authRepositoryProvider)
                    .updateBusiness(BusinessModel.fromMap(map));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$label updated!')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor.withOpacity(0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
