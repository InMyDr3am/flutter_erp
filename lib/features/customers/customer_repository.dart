import '../../core/config/supabase_client.dart';
import 'customer_model.dart';

class CustomerRepository {
  Future<List<Customer>> fetchAll() async {
    final rows = await supabase.from('customers').select().order('name');
    return rows.map((row) => Customer.fromMap(row)).toList();
  }

  Future<Customer> create({
    required String name,
    String? phone,
    String? address,
    String? notes,
  }) async {
    final row = await supabase
        .from('customers')
        .insert({
          'name': name,
          'phone': phone,
          'address': address,
          'notes': notes,
        })
        .select()
        .single();
    return Customer.fromMap(row);
  }

  Future<void> update({
    required String id,
    required String name,
    String? phone,
    String? address,
    String? notes,
  }) async {
    await supabase.from('customers').update({
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from('customers').delete().eq('id', id);
  }
}

final customerRepository = CustomerRepository();
