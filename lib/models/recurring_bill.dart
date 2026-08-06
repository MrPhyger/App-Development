class RecurringBill {
  RecurringBill({this.id, required this.name, required this.amount, required this.category, required this.dueDay, required this.reminderDays});
  final int? id; final String name, category; final double amount; final int dueDay, reminderDays;
  Map<String,Object?> toMap()=>{'id':id,'name':name,'amount':amount,'category':category,'dueDay':dueDay,'reminderDays':reminderDays};
  factory RecurringBill.fromMap(Map<String,Object?> m)=>RecurringBill(id:m['id'] as int?,name:m['name'] as String,amount:(m['amount'] as num).toDouble(),category:m['category'] as String,dueDay:m['dueDay'] as int,reminderDays:m['reminderDays'] as int);
}
