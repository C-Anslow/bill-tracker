class BankAccount {
  final String id;
  final String name;
  final double currentBalance;

  BankAccount({
    required this.id,
    required this.name,
    required this.currentBalance,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      currentBalance: (json['current_balance'] as num).toDouble(),
    );
  }
}