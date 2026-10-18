class BillDetail {
  final String id;
  final String headerId;
  final String? defaultBillId;
  final String nameSnapshot;
  final DateTime dueDate;
  final double amountSnapshot;
  final bool isPaid;

  BillDetail({
    required this.id,
    required this.headerId,
    this.defaultBillId,
    required this.nameSnapshot,
    required this.dueDate,
    required this.amountSnapshot,
    required this.isPaid,
  });

  factory BillDetail.fromJson(Map<String, dynamic> json) {
    return BillDetail(
      id: json['id'] as String,
      headerId: json['header_id'] as String,
      defaultBillId: json['default_bill_id'] as String?,
      nameSnapshot: json['name_snapshot'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      amountSnapshot: (json['amount_snapshot'] as num).toDouble(),
      isPaid: json['is_paid'] as bool? ?? false,
    );
  }
}