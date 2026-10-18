import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bank_account.dart';
import '../models/bill_detail.dart';

class BillRepository {
  final SupabaseClient _supabase;

  BillRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  /// Calls the PL/pgSQL function to generate a schedule and return the header UUID
  Future<String> generateSchedule({
    required String periodName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _supabase.rpc(
      'generate_bill_schedule',
      params: {
        'p_period_name': periodName,
        'p_start_date': startDate.toIso8601String().split('T').first,
        'p_end_date': endDate.toIso8601String().split('T').first,
      },
    );

    return response as String;
  }

  /// Fetches bill_detail instances created under a specific header_id
  Future<List<BillDetail>> fetchBillDetails(String headerId) async {
    final response = await _supabase
        .from('bill_detail')
        .select()
        .eq('header_id', headerId)
        .order('due_date', ascending: true);

    return (response as List)
        .map((json) => BillDetail.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves the current primary bank account balance
  Future<BankAccount?> fetchCurrentBankAccount() async {
    final response = await _supabase
        .from('bank_accounts')
        .select()
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return BankAccount.fromJson(response);
  }
}