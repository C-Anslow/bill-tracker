import 'package:flutter/material.dart';
import '../services/bill_repository.dart';

class GenerateScheduleView extends StatefulWidget {
  const GenerateScheduleView({super.key});

  @override
  State<GenerateScheduleView> createState() => _GenerateScheduleViewState();
}

class _GenerateScheduleViewState extends State<GenerateScheduleView> {
  final _repository = BillRepository();
  final _periodNameController = TextEditingController();

  DateTime _startDate = DateTime.now();
  late DateTime _endDate;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Default end date to 28 days after start date
    _endDate = _startDate.add(const Duration(days: 28));
    _setDefaultPeriodName();
  }

  void _setDefaultPeriodName() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final currentMonthName = months[_startDate.month - 1];
    _periodNameController.text = '$currentMonthName ${_startDate.year}';
  }

  void _updateStartDate(DateTime newDate) {
    setState(() {
      _startDate = newDate;
      _endDate = newDate.add(const Duration(days: 28));
      _setDefaultPeriodName();
    });
  }

  Future<void> _handleGenerateSchedule() async {
    final periodName = _periodNameController.text.trim();
    if (periodName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a period name')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final headerId = await _repository.generateSchedule(
        periodName: periodName,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;
      setState(() => _isGenerating = false);

      _showSuccessDialog(headerId, periodName);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate schedule: $e')),
      );
    }
  }

  void _showSuccessDialog(String headerId, String periodName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 54,
          ),
          title: const Text('Schedule Created Successfully!'),
          content: Text(
            'The bill schedule for "$periodName" has been generated and populated in the database.\n\nHeader ID: ${headerId.substring(0, 8)}...',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to Main Menu
              },
              child: const Text('Return to Menu'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Shift start date forward 28 days for next addition
                _updateStartDate(_endDate.add(const Duration(days: 1)));
              },
              child: const Text('Add Additional Schedule'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final startDateStr = _startDate.toIso8601String().split('T').first;
    final endDateStr = _endDate.toIso8601String().split('T').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Bill Schedule'),
      ),
      body: _isGenerating
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating schedule and populating recurring bills...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Schedule Period',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the window for projecting recurring bills into bill_detail.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 28),

                    // 1. Period Name Input
                    TextField(
                      controller: _periodNameController,
                      decoration: const InputDecoration(
                        labelText: 'Period Name / Label',
                        hintText: 'e.g., November 2026',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Start Date Selector
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Start Date'),
                      subtitle: Text(
                        startDateStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          _updateStartDate(picked);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // 3. Editable End Date Selector (Defaults to Start Date + 28 Days)
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      leading: const Icon(Icons.event),
                      title: const Text('End Date (Suggested: +28 Days)'),
                      subtitle: Text(
                        endDateStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    // 4. Generate Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: _handleGenerateSchedule,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text(
                          'Generate Schedule',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}