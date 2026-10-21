import 'package:flutter/material.dart';
import '../models/bill_detail.dart';
import '../services/bill_repository.dart';

class AllBillsView extends StatefulWidget {
  const AllBillsView({super.key});

  @override
  State<AllBillsView> createState() => _AllBillsViewState();
}

class _AllBillsViewState extends State<AllBillsView> {
  final _repository = BillRepository();

  List<BillDetail> _bills = [];
  List<Map<String, dynamic>> _headers = [];
  bool _isLoading = false;

  // Filters
  String _statusFilter = 'all'; // 'all', 'unpaid', 'paid'
  String? _selectedHeaderId; // null = Show All

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _repository.fetchBillHeaders();
      setState(() => _headers = headers);
      await _fetchBills();
    } catch (e) {
      _showSnackBar('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBills() async {
    try {
      final bills = await _repository.fetchFilteredBills(
        statusFilter: _statusFilter,
        headerIdFilter: _selectedHeaderId,
      );
      setState(() => _bills = bills);
    } catch (e) {
      _showSnackBar('Error fetching bills: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _togglePaidStatus(BillDetail bill, bool newValue) async {
    try {
      await _repository.updateFullBillDetail(
        id: bill.id,
        name: bill.nameSnapshot,
        amount: bill.amountSnapshot,
        dueDate: bill.dueDate,
        isPaid: newValue,
      );
      await _fetchBills();
    } catch (e) {
      _showSnackBar('Failed to update status: $e');
    }
  }

  void _openEditBillDialog(BillDetail bill) {
    final nameController = TextEditingController(text: bill.nameSnapshot);
    final amountController = TextEditingController(
      text: bill.amountSnapshot.toStringAsFixed(2),
    );
    DateTime selectedDate = bill.dueDate;
    bool isPaid = bill.isPaid;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Bill Entry'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Bill Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (£)',
                      prefixText: '£ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Due Date'),
                    subtitle: Text(
                      selectedDate.toIso8601String().split('T').first,
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Mark as Paid'),
                    value: isPaid,
                    onChanged: (val) {
                      setDialogState(() => isPaid = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final amount =
                    double.tryParse(amountController.text.trim());

                    if (name.isEmpty || amount == null) {
                      _showSnackBar('Please enter valid details');
                      return;
                    }

                    Navigator.pop(context);
                    try {
                      await _repository.updateFullBillDetail(
                        id: bill.id,
                        name: name,
                        amount: amount,
                        dueDate: selectedDate,
                        isPaid: isPaid,
                      );
                      _showSnackBar('Bill updated successfully');
                      await _fetchBills();
                    } catch (e) {
                      _showSnackBar('Failed to update bill: $e');
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bills Explorer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBills,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0), // Reduced padding for mobile
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CONTROLS BAR (FILTERS) ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column( // Changed from Row to Column for mobile responsiveness
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Status Segmented Toggle
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'all',
                            label: Text('Both'),
                            icon: Icon(Icons.list),
                          ),
                          ButtonSegment(
                            value: 'unpaid',
                            label: Text('Unpaid'),
                            icon: Icon(Icons.pending_actions),
                          ),
                          ButtonSegment(
                            value: 'paid',
                            label: Text('Paid'),
                            icon: Icon(Icons.task_alt),
                          ),
                        ],
                        selected: {_statusFilter},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _statusFilter = newSelection.first;
                          });
                          _fetchBills();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Schedule Header Title Dropdown
                    DropdownButtonFormField<String?>(
                      value: _selectedHeaderId,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Schedule Period',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Show All Periods'),
                        ),
                        ..._headers.map((h) {
                          return DropdownMenuItem<String?>(
                            value: h['id'] as String,
                            child: Text(h['period_name'] as String),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedHeaderId = val;
                        });
                        _fetchBills();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- BILLS LIST ---
            Text(
              'Matching Bills (${_bills.length})',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Card(
                child: _bills.isEmpty
                    ? const Center(
                  child: Text(
                    'No bills match the selected filters.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.separated(
                  itemCount: _bills.length,
                  separatorBuilder: (context, index) =>
                  const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final bill = _bills[index];
                    final dateStr = bill.dueDate
                        .toIso8601String()
                        .split('T')
                        .first;

                    return ListTile(
                      leading: Checkbox(
                        value: bill.isPaid,
                        onChanged: (val) {
                          if (val != null) {
                            _togglePaidStatus(bill, val);
                          }
                        },
                      ),
                      title: Text(
                        bill.nameSnapshot,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: bill.isPaid
                              ? TextDecoration.lineThrough
                              : null,
                          color: bill.isPaid ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Text('Due: $dateStr'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '£${bill.amountSnapshot.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: bill.isPaid
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () =>
                                _openEditBillDialog(bill),
                            tooltip: 'Edit Bill',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}