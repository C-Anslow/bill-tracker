import 'package:flutter/material.dart';
import '../models/default_bill.dart';
import '../services/bill_repository.dart';

class ManageTemplatesView extends StatefulWidget {
  const ManageTemplatesView({super.key});

  @override
  State<ManageTemplatesView> createState() => _ManageTemplatesViewState();
}

class _ManageTemplatesViewState extends State<ManageTemplatesView> {
  final _repository = BillRepository();
  List<DefaultBill> _templates = [];
  List<Map<String, dynamic>> _frequencies = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final frequencies = await _repository.fetchFrequencies();
      final templates = await _repository.fetchDefaultBills();
      setState(() {
        _frequencies = frequencies;
        _templates = templates;
      });
    } catch (e) {
      _showSnackBar('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openTemplateDialog([DefaultBill? template]) {
    final isEditing = template != null;
    final descriptionController =
    TextEditingController(text: isEditing ? template.description : '');
    final amountController = TextEditingController(
        text: isEditing ? template.defaultAmount.toStringAsFixed(2) : '');
    DateTime startDate = isEditing ? template.startDate : DateTime.now();
    DateTime? endDate = isEditing ? template.endDate : null;
    int? selectedFrequencyId = isEditing
        ? template.frequencyId
        : (_frequencies.isNotEmpty ? _frequencies.first['id'] as int : null);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final startDateStr = startDate.toIso8601String().split('T').first;
            final endDateStr = endDate != null
                ? endDate!.toIso8601String().split('T').first
                : 'None (Indefinite)';

            return AlertDialog(
              title: Text(isEditing ? 'Edit Template' : 'Add Bill Template'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description / Bill Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Baseline Amount (£)',
                        prefixText: '£ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedFrequencyId,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(),
                      ),
                      items: _frequencies.map((f) {
                        return DropdownMenuItem<int>(
                          value: f['id'] as int,
                          child: Text(f['frequency_description'] as String),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedFrequencyId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      title: const Text('Start Date'),
                      subtitle: Text(startDateStr),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => startDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      title: const Text('End Date (Optional)'),
                      subtitle: Text(endDateStr),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (endDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setDialogState(() => endDate = null),
                            ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ??
                              startDate.add(const Duration(days: 365)),
                          firstDate: startDate,
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => endDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final description = descriptionController.text.trim();
                    final amount =
                    double.tryParse(amountController.text.trim());

                    if (description.isEmpty || amount == null) {
                      _showSnackBar(
                          'Please enter a valid description and amount');
                      return;
                    }

                    Navigator.pop(context);
                    try {
                      if (isEditing) {
                        await _repository.updateDefaultBill(
                          id: template.id,
                          description: description,
                          defaultAmount: amount,
                          startDate: startDate,
                          endDate: endDate,
                          frequencyId: selectedFrequencyId,
                        );
                        _showSnackBar('Template updated!');
                      } else {
                        await _repository.addDefaultBill(
                          description: description,
                          defaultAmount: amount,
                          startDate: startDate,
                          endDate: endDate,
                          frequencyId: selectedFrequencyId,
                        );
                        _showSnackBar('Template added!');
                      }
                      final updated = await _repository.fetchDefaultBills();
                      setState(() => _templates = updated);
                    } catch (e) {
                      _showSnackBar('Operation failed: $e');
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Template'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTemplate(DefaultBill template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${template.description}?'),
        content: const Text(
          'This will remove it from future schedule generations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteDefaultBill(template.id);
        _showSnackBar('${template.description} deleted');
        final updated = await _repository.fetchDefaultBills();
        setState(() => _templates = updated);
      } catch (e) {
        _showSnackBar('Failed to delete: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bill Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Text(
                  'Recurring Bill Templates (${_templates.length})',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openTemplateDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Template'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: _templates.isEmpty
                    ? const Center(
                  child: Text(
                    'No recurring bill templates configured.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.separated(
                  itemCount: _templates.length,
                  separatorBuilder: (context, index) =>
                  const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    final startStr = template.startDate
                        .toIso8601String()
                        .split('T')
                        .first;
                    final freqStr = template.frequencyDescription ?? 'Custom';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            child: Icon(Icons.receipt, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        template.description,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '£${template.defaultAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$freqStr • From $startStr',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              size: 20),
                                          onPressed: () =>
                                              _openTemplateDialog(
                                                  template),
                                          tooltip: 'Edit Template',
                                          visualDensity:
                                          VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints:
                                          const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color:
                                              Colors.redAccent),
                                          onPressed: () =>
                                              _deleteTemplate(
                                                  template),
                                          tooltip: 'Delete Template',
                                          visualDensity:
                                          VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints:
                                          const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
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