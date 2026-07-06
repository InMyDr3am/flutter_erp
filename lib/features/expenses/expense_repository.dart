import '../../core/config/supabase_client.dart';
import 'expense_model.dart';

class ExpenseRepository {
  Future<List<Expense>> fetchAll({DateTime? from, DateTime? to}) async {
    var query = supabase.from('expenses').select();

    if (from != null) {
      query = query.gte('expense_date', from.toIso8601String().substring(0, 10));
    }
    if (to != null) {
      query = query.lte('expense_date', to.toIso8601String().substring(0, 10));
    }

    final rows = await query.order('expense_date', ascending: false);
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  Future<void> create({
    required String category,
    required num amount,
    required DateTime expenseDate,
    String? note,
  }) async {
    await supabase.from('expenses').insert({
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().substring(0, 10),
      'note': note,
      'created_by': supabase.auth.currentUser?.id,
    });
  }

  Future<void> update({
    required String id,
    required String category,
    required num amount,
    required DateTime expenseDate,
    String? note,
  }) async {
    await supabase.from('expenses').update({
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().substring(0, 10),
      'note': note,
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from('expenses').delete().eq('id', id);
  }
}

final expenseRepository = ExpenseRepository();
