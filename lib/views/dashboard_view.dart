import 'package:flutter/material.dart';
import '../models/bank_account.dart';
import '../models/bill_detail.dart';
import '../services/bill_repository.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _repository = BillRepository();

  BankAccount? _account;
  List<BillDetail> _bills = [];
  bool _isLoading = false;
  String? _currentHeaderId;

  // Default date window: November 2026
  DateTime _startDate = DateTime(2026, 11, 1);
  DateTime _endDate = DateTime(2026, 11, 30);
  String _periodName = 'November 2026';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final account = await _repository.fetchCurrentBankAccount();
      setState(() => _account = account);
    } catch (e) {
      _showSnackBar('Error loading account: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAndFetchSchedule() async {
    setState(() => _isLoading = true);
    try {
      final headerId = await _repository.generateSchedule(
        periodName: _periodName,
        startDate: _startDate,
        endDate: _endDate,
      );
      final details = await _repository.fetchBillDetails(headerId);

      setState(() {
        _currentHeaderId = headerId;
        _bills = details;
      });

      _showSnackBar('Schedule generated successfully!');
    } catch (e) {
      _showSnackBar('Error generating schedule: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('bill_tracker — PC Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Balance',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP SUMMARY CARDS ---
            _buildSummarySection(),
            const SizedBox(height: 24),

            // --- CONTROLS BAR ---
            _buildControlsBar(),
            const SizedBox(height: 24),

            // --- BILLS DATA TABLE ---
            Expanded(
              child: _buildBillsTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Row(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Bank Balance',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  _account != null
                      ? '£${_account!.currentBalance.toStringAsFixed(2)}'
                      : '£0.00',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _account?.name ?? 'No account linked',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsBar() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _generateAndFetchSchedule,
          icon: const Icon(Icons.auto_awesome),
          label: Text('Generate Schedule ($_periodName)'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
        if (_currentHeaderId != null) ...[
          const SizedBox(width: 16),
          Chip(
            label: Text('Active Header: ${_currentHeaderId!.substring(0, 8)}...'),
            avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
          ),
        ],
      ],
    );
  }

  Widget _buildBillsTable() {
    if (_bills.isEmpty) {
      return const Center(
        child: Text(
          'No bills generated yet. Click "Generate Schedule" above.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        itemCount: _bills.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final bill = _bills[index];
          final dateStr = bill.dueDate.toIso8601String().split('T').first;

          return ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(
              bill.nameSnapshot,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Due: $dateStr'),
            trailing: Text(
              '£${bill.amountSnapshot.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}