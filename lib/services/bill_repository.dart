import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bank_account.dart';
import '../models/bill_detail.dart';

class BillRepository {
  final SupabaseClient _supabase;

  BillRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  /// Fetches all bill headers for filtering dropdowns
  Future<List<Map<String, dynamic>>> fetchBillHeaders() async {
    final response = await _supabase
        .from('bill_header')
        .select('id, period_name')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetches bill details with optional status and header filters
  Future<List<BillDetail>> fetchFilteredBills({
    required String statusFilter, // 'unpaid', 'paid', 'all'
    String? headerIdFilter, // null for 'all'
  }) async {
    dynamic query = _supabase.from('bill_detail').select();

    if (statusFilter == 'unpaid') {
      query = query.eq('is_paid', false);
    } else if (statusFilter == 'paid') {
      query = query.eq('is_paid', true);
    }

    if (headerIdFilter != null && headerIdFilter.isNotEmpty) {
      query = query.eq('header_id', headerIdFilter);
    }

    final response = await query.order('due_date', ascending: true);

    return (response as List)
        .map((json) => BillDetail.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Full update function for editing bill fields
  Future<void> updateFullBillDetail({
    required String id,
    required String name,
    required double amount,
    required DateTime dueDate,
    required bool isPaid,
  }) async {
    await _supabase.from('bill_detail').update({
      'name_snapshot': name,
      'amount_snapshot': amount,
      'due_date': dueDate.toIso8601String().split('T').first,
      'is_paid': isPaid,
    }).eq('id', id);
  }

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

  /// Fetches all registered bank accounts
  Future<List<BankAccount>> fetchAllBankAccounts() async {
    final response = await _supabase
        .from('bank_accounts')
        .select()
        .order('account_name', ascending: true);

    return (response as List)
        .map((json) => BankAccount.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Updates an existing bank account's name and current balance
  Future<void> updateBankAccount({
    required String id,
    required String name,
    required double currentBalance,
  }) async {
    await _supabase.from('bank_accounts').update({
      'account_name': name,
      'current_balance': currentBalance,
      'last_updated': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Fetches all unpaid bill_detail records ordered by due_date ascending
  Future<List<BillDetail>> fetchUnpaidBills() async {
    final response = await _supabase
        .from('bill_detail')
        .select()
        .eq('is_paid', false)
        .order('due_date', ascending: true);

    return (response as List)
        .map((json) => BillDetail.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Updates an existing bill's fields (is_paid, amount_snapshot, due_date)
  Future<void> updateBillDetail({
    required String id,
    required bool isPaid,
    required double amount,
    required DateTime dueDate,
  }) async {
    await _supabase.from('bill_detail').update({
      'is_paid': isPaid,
      'amount_snapshot': amount,
      'due_date': dueDate.toIso8601String().split('T').first,
    }).eq('id', id);
  }

  /// Adds a custom manual bill entry into bill_detail
  Future<void> addCustomBill({
    required String name,
    required double amount,
    required DateTime dueDate,
    String? headerId,
  }) async {
    await _supabase.from('bill_detail').insert({
      'name_snapshot': name,
      'amount_snapshot': amount,
      'due_date': dueDate.toIso8601String().split('T').first,
      'is_paid': false,
      if (headerId != null) 'header_id': headerId,
    });
  }
}