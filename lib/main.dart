import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/bill_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client
  await Supabase.initialize(
    url: 'https://axarumiwsfaiydrhnsqm.supabase.co',
    publishableKey: 'sb_publishable_17Zrz8q7f4D0dULHieSjyQ_ASByHgSz',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              print('--- STARTING RPC TEST ---');
              final repo = BillRepository();

              try {
                // 1. Fetch current bank balance
                final bank = await repo.fetchCurrentBankAccount();
                print('Bank Balance: £${bank?.currentBalance.toStringAsFixed(2)}');

                // 2. Call the PL/pgSQL function via RPC
                final headerId = await repo.generateSchedule(
                  periodName: 'November 2026',
                  startDate: DateTime(2026, 11, 1),
                  endDate: DateTime(2026, 11, 30),
                );
                print('Schedule Header Generated ID: $headerId');

                // 3. Query the generated bill details
                final bills = await repo.fetchBillDetails(headerId);
                print('Retrieved ${bills.length} bills from bill_detail:');
                for (var b in bills) {
                  print(' - ${b.dueDate.toIso8601String().split('T').first}: ${b.nameSnapshot} (£${b.amountSnapshot})');
                }
                print('--- RPC TEST COMPLETE ---');
              } catch (e, stack) {
                print('Error running RPC test: $e');
                print(stack);
              }
            },
            child: const Text('Run Bill Schedule Test'),
          ),
        ),
      ),
    );
  }
}

final supabase = Supabase.instance.client;

class BillTrackerApp extends StatelessWidget {
  const BillTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bill Tracker Test',
      home: Scaffold(
        appBar: AppBar(title: const Text('Supabase Connection Test')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: supabase.from('bill_frequency').select().order('sort_order'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final data = snapshot.data ?? [];
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final row = data[index];
                return ListTile(
                  title: Text('Sort Order: ${row['sort_order']}'),
                  subtitle: Text('Unit: ${row['date_part']} | Multiplier: ${row['multiplier']}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}