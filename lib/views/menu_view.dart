import 'package:flutter/material.dart';
import 'dashboard_view.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('bill_tracker'),
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

            // --- MENU ITEMS GRID / LIST ---
            Expanded(
              child: ListView(
                children: [
                  // 1. Review Current Bills (Primary Action)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.receipt_long,
                    title: 'Review Current Bills',
                    subtitle: 'View account balance, generate bill schedules, and inspect detailed outgoings.',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardView(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Placeholder item for future expansion
                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings_suggest,
                    title: 'Manage Bill Templates',
                    subtitle: 'Configure default recurring bills, frequencies, and baseline amounts.',
                    color: Colors.grey,
                    onTap: null, // Disabled until implemented
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