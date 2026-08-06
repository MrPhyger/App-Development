class Expense {
  Expense({this.id, required this.amount, required this.category, required this.date, this.note});
  final int? id; final double amount; final String category; final DateTime date; final String? note;
  Map<String, Object?> toMap() => {'id': id, 'amount': amount, 'category': category, 'date': date.toIso8601String(), 'note': note};
  factory Expense.fromMap(Map<String, Object?> m) => Expense(id: m['id'] as int?, amount: (m['amount'] as num).toDouble(), category: m['category'] as String, date: DateTime.parse(m['date'] as String), note: m['note'] as String?);
}
