import '../../core/config/supabase_client.dart';
import 'restock_model.dart';

class RestockRepository {
  Future<List<Restock>> fetchAll({DateTime? from, DateTime? to}) async {
    var query = supabase.from('restocks').select('*, products(name)');

    if (from != null) {
      query = query.gte('restock_date', from.toIso8601String().substring(0, 10));
    }
    if (to != null) {
      query = query.lte('restock_date', to.toIso8601String().substring(0, 10));
    }

    final rows = await query.order('restock_date', ascending: false);
    return rows.map((row) => Restock.fromMap(row)).toList();
  }

  /// Records the purchase and bumps the product's stock. Not wrapped in a
  /// database transaction since this is a single-admin, low-concurrency
  /// action (unlike checkout, which uses the `create_sale` RPC).
  Future<void> create({
    required String productId,
    required num qty,
    required num purchasePrice,
    required DateTime restockDate,
    String? supplier,
  }) async {
    await supabase.from('restocks').insert({
      'product_id': productId,
      'qty': qty,
      'purchase_price': purchasePrice,
      'restock_date': restockDate.toIso8601String().substring(0, 10),
      'supplier': supplier,
      'created_by': supabase.auth.currentUser?.id,
    });

    final product = await supabase.from('products').select('stock').eq('id', productId).single();
    final currentStock = product['stock'] as num;

    await supabase.from('products').update({
      'stock': currentStock + qty,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', productId);
  }

  Future<void> delete(String id) async {
    await supabase.from('restocks').delete().eq('id', id);
  }
}

final restockRepository = RestockRepository();
