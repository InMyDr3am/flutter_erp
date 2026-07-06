import '../../core/config/supabase_client.dart';
import 'cart_provider.dart';
import 'sale_model.dart';

class SaleRepository {
  Future<String> createSale({
    required String? customerId,
    required List<CartItem> items,
    required bool needsShipping,
    String? shippingNote,
  }) async {
    final id = await supabase.rpc('create_sale', params: {
      'p_customer_id': customerId,
      'p_items': items
          .map((item) => {'product_id': item.product.id, 'qty': item.qty})
          .toList(),
      'p_needs_shipping': needsShipping,
      'p_shipping_note': shippingNote,
    });
    return id as String;
  }

  Future<Sale> fetchDetail(String saleId) async {
    final row = await supabase
        .from('sales')
        .select('*, customers(name), profiles(full_name), sale_items(*)')
        .eq('id', saleId)
        .single();
    return Sale.fromMap(row);
  }

  Future<List<Sale>> fetchHistory({
    DateTime? from,
    DateTime? to,
    String? customerId,
  }) async {
    var query = supabase
        .from('sales')
        .select('*, customers(name), profiles(full_name), sale_items(*)');

    if (from != null) {
      query = query.gte('created_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('created_at', to.toIso8601String());
    }
    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }

    final rows = await query.order('created_at', ascending: false);
    return rows.map((row) => Sale.fromMap(row)).toList();
  }

  Future<void> updateShippingStatus({
    required String saleId,
    required String status,
    String? note,
  }) async {
    await supabase.from('sales').update({
      'shipping_status': status,
      'shipping_note': ?note,
    }).eq('id', saleId);
  }
}

final saleRepository = SaleRepository();
