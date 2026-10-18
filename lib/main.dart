import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client
  await Supabase.initialize(
    url: 'https://axarumiwsfaiydrhnsqm.supabase.co',
    publishableKey: 'sb_publishable_17Zrz8q7f4D0dULHieSjyQ_ASByHgSz',
  );

  runApp(const BillTrackerApp());
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