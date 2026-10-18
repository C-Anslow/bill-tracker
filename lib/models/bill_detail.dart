class BillDetail {
  final String id;
  final String? headerId; // MUST be nullable (String?)
  final String nameSnapshot;
  final double amountSnapshot;
  final DateTime dueDate;
  final bool isPaid;

  BillDetail({
    required this.id,
    this.headerId,
    required this.nameSnapshot,
    required this.amountSnapshot,
    required this.dueDate,
    required this.isPaid,
  });

  factory BillDetail.fromJson(Map<String, dynamic> json) {
    return BillDetail(
      id: json['id'] as String,
      headerId: json['header_id'] as String?, // Updated to allow null
      nameSnapshot: json['name_snapshot'] as String,
      amountSnapshot: (json['amount_snapshot'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      isPaid: json['is_paid'] as bool? ?? false,
    );
  }
}