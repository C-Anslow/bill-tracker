// url: 'https://axarumiwsfaiydrhnsqm.supabase.co',
// publishableKey: 'sb_publishable_17Zrz8q7f4D0dULHieSjyQ_ASByHgSz',

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://axarumiwsfaiydrhnsqm.supabase.co',
    publishableKey: 'sb_publishable_17Zrz8q7f4D0dULHieSjyQ_ASByHgSz',
  );

  runApp(const BillTrackerApp());
}

class BillTrackerApp extends StatelessWidget {
  const BillTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bill_tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const DashboardView(),
    );
  }
}