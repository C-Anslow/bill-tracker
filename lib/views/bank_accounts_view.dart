import 'package:flutter/material.dart';
import '../models/bank_account.dart';
import '../models/bill_detail.dart';
import '../services/bill_repository.dart';

class BankAccountsView extends StatefulWidget {
  const BankAccountsView({super.key});

  @override
  State<BankAccountsView> createState() => _BankAccountsViewState();
}

class _BankAccountsViewState extends State<BankAccountsView> {
  final _repository = BillRepository();
  List<BankAccount> _accounts = [];
  List<BillDetail> _unpaidBills = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await _repository.fetchAllBankAccounts();
      final bills = await _repository.fetchUnpaidBills();

      // Ensure ascending sort by due date
      bills.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      setState(() {
        _accounts = accounts;
        _unpaidBills = bills;
      });
    } catch (e) {
      _showSnackBar('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _totalBalance {
    return _accounts.fold(0.0, (sum, acc) => sum + acc.currentBalance);
  }

  double get _totalUnpaidBills {
    return _unpaidBills.fold(0.0, (sum, bill) => sum + bill.amountSnapshot);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _togglePaidStatus(BillDetail bill, bool newValue) async {
    try {
      await _repository.updateBillDetail(
        id: bill.id,
        isPaid: newValue,
        amount: bill.amountSnapshot,
        dueDate: bill.dueDate,
      );
      _showSnackBar(
          '${bill.nameSnapshot} marked as ${newValue ? "paid" : "unpaid"}');
      await _loadData();
    } catch (e) {
      _showSnackBar('Failed to update paid status: $e');
    }
  }

  void _openEditBillDialog(BillDetail bill) {
    final amountController = TextEditingController(
      text: bill.amountSnapshot.toStringAsFixed(2),
    );
    DateTime selectedDate = bill.dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${bill.nameSnapshot}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newAmount =
                    double.tryParse(amountController.text.trim());
                    if (newAmount == null) {
                      _showSnackBar('Please enter a valid amount');
                      return;
                    }

                    Navigator.pop(context);
                    try {
                      await _repository.updateBillDetail(
                        id: bill.id,
                        isPaid: bill.isPaid,
                        amount: newAmount,
                        dueDate: selectedDate,
                      );
                      _showSnackBar('Bill updated!');
                      await _loadData();
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

  void _openAddCustomBillDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Custom Bill'),
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
                      _showSnackBar('Please enter valid bill details');
                      return;
                    }

                    Navigator.pop(context);
                    try {
                      await _repository.addCustomBill(
                        name: name,
                        amount: amount,
                        dueDate: selectedDate,
                        headerId: null, // Custom bills exist independently of standard schedules
                      );
                      _showSnackBar('Custom bill added!');
                      await _loadData();
                    } catch (e) {
                      _showSnackBar('Failed to add custom bill: $e');
                    }
                  },
                  child: const Text('Add Bill'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openEditAccountDialog(BankAccount account) {
    final nameController = TextEditingController(text: account.name);
    final balanceController = TextEditingController(
      text: account.currentBalance.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${account.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Current Balance (£)',
                  prefixText: '£ ',
                  border: OutlineInputBorder(),
                ),
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
                final newName = nameController.text.trim();
                final newBalance =
                double.tryParse(balanceController.text.trim());

                if (newName.isEmpty || newBalance == null) {
                  _showSnackBar('Please enter valid details');
                  return;
                }

                Navigator.pop(context);
                try {
                  await _repository.updateBankAccount(
                    id: account.id,
                    name: newName,
                    currentBalance: newBalance,
                  );
                  _showSnackBar('Account updated!');
                  await _loadData();
                } catch (e) {
                  _showSnackBar('Failed to update account: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Current Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP SUMMARY BANNER ---
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Bank Funds',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '£${_totalBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Unpaid Bills Total',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '£${_totalUnpaidBills.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- BANK ACCOUNTS SECTION ---
            const Text(
              'Bank Accounts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: _accounts.isEmpty
                  ? const Center(child: Text('No accounts found'))
                  : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _accounts.length,
                separatorBuilder: (context, index) =>
                const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final acc = _accounts[index];
                  return SizedBox(
                    width: 260,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  acc.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      size: 18),
                                  onPressed: () =>
                                      _openEditAccountDialog(acc),
                                ),
                              ],
                            ),
                            Text(
                              '£${acc.currentBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // --- UNPAID BILLS SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unpaid Bills (${_unpaidBills.length})',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _openAddCustomBillDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Custom Bill'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Card(
              child: _unpaidBills.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No unpaid bills remaining!',
                    style:
                    TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _unpaidBills.length,
                separatorBuilder: (context, index) =>
                const Divider(height: 1),
                itemBuilder: (context, index) {
                  final bill = _unpaidBills[index];
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
                      style: const TextStyle(
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('Due: $dateStr'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '£${bill.amountSnapshot.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }
}