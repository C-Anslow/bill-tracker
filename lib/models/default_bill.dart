class DefaultBill {
  final String id;
  final String description;
  final double defaultAmount;
  final DateTime startDate;
  final DateTime? endDate;
  final int? frequencyId;
  final String? frequencyDescription;

  DefaultBill({
    required this.id,
    required this.description,
    required this.defaultAmount,
    required this.startDate,
    this.endDate,
    this.frequencyId,
    this.frequencyDescription,
  });

  factory DefaultBill.fromJson(Map<String, dynamic> json) {
    // Check if frequency details were joined in the query
    final frequencyData = json['bill_frequency'] as Map<String, dynamic>?;

    return DefaultBill(
      id: json['id'] as String,
      description: json['description'] as String,
      defaultAmount: (json['default_amount'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      frequencyId: json['frequency_id'] as int?,
      frequencyDescription: frequencyData != null
          ? frequencyData['frequency_description'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'default_amount': defaultAmount,
      'start_date': startDate.toIso8601String().split('T').first,
      if (endDate != null)
        'end_date': endDate!.toIso8601String().split('T').first,
      if (frequencyId != null) 'frequency_id': frequencyId,
    };
  }
}