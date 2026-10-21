import 'package:flutter/material.dart';
import 'bank_accounts_view.dart';
import 'generate_schedule_view.dart';
import 'all_bills_view.dart';
import 'manage_templates_view.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CMA Solutions - Bill Tracker'
            ''),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Main Menu',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an action to get started',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: ListView(
                children: [
                  // 1. Review Current Bills
                  _buildMenuItem(
                    context: context,
                    icon: Icons.receipt_long,
                    title: 'Review Current Bills',
                    subtitle: 'View account balances, unpaid bills, and manage details.',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BankAccountsView(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Generate Schedule
                  _buildMenuItem(
                    context: context,
                    icon: Icons.auto_awesome,
                    title: 'Generate Bill Schedule',
                    subtitle: 'Select dates and create a new set of projected bills using database templates.',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GenerateScheduleView(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. All Bills Explorer (NEW)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.filter_alt,
                    title: 'All Bills Explorer',
                    subtitle: 'View, filter by status or schedule period, and edit all bill entries.',
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllBillsView(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Placeholder for future expansion
                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings_suggest,
                    title: 'Manage Bill Templates',
                    subtitle: 'Configure default recurring bills, frequencies, and baseline amounts.',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageTemplatesView(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return Card(
      elevation: isEnabled ? 2 : 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: isEnabled ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
          child: Icon(
            icon,
            size: 28,
            color: isEnabled ? color : Colors.grey,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isEnabled ? null : Colors.grey,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isEnabled ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isEnabled ? color : Colors.grey[700],
        ),
        onTap: onTap,
      ),
    );
  }
}