class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.note,
    required this.expenseDate,
  });

  final String id;
  final String category;
  final num amount;
  final String? note;
  final DateTime expenseDate;

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as String,
        category: map['category'] as String,
        amount: map['amount'] as num,
        note: map['note'] as String?,
        expenseDate: DateTime.parse(map['expense_date'] as String),
      );
}

const expenseCategorySuggestions = [
  'Listrik',
  'Gaji',
  'Transport',
  'Sewa',
  'Lainnya',
];
