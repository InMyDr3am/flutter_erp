import '../../core/config/supabase_client.dart';
import 'cart_provider.dart';
import 'sale_model.dart';

class SaleRepository {
  // `sales` has three FKs into `profiles` (cashier_id, assigned_to,
  // delivered_by), so each embed must be aliased to avoid an
  // ambiguous-relationship error.
  static const _selectWithRelations =
      '*, customers(name), cashier:profiles!sales_cashier_id_fkey(full_name), '
      'assignee:profiles!sales_assigned_to_fkey(full_name), '
      'deliverer:profiles!sales_delivered_by_fkey(full_name), sale_items(*)';

  Future<String> createSale({
    required String? customerId,
    required List<CartItem> items,
    required bool needsShipping,
    String? shippingNote,
    required String paymentMethod,
    num? amountPaid,
  }) async {
    final id = await supabase.rpc('create_sale', params: {
      'p_customer_id': customerId,
      'p_items': items
          .map((item) => {'product_id': item.product.id, 'qty': item.qty})
          .toList(),
      'p_needs_shipping': needsShipping,
      'p_shipping_note': shippingNote,
      'p_payment_method': paymentMethod,
      'p_amount_paid': amountPaid,
    });
    return id as String;
  }

  Future<Sale> fetchDetail(String saleId) async {
    final row = await supabase
        .from('sales')
        .select(_selectWithRelations)
        .eq('id', saleId)
        .single();
    return Sale.fromMap(row);
  }

  Future<List<Sale>> fetchHistory({
    DateTime? from,
    DateTime? to,
    String? customerId,
    String? cashierId,
  }) async {
    var query = supabase.from('sales').select(_selectWithRelations);

    if (from != null) {
      query = query.gte('created_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('created_at', to.toIso8601String());
    }
    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }
    if (cashierId != null) {
      query = query.eq('cashier_id', cashierId);
    }

    final rows = await query.order('created_at', ascending: false);
    return rows.map((row) => Sale.fromMap(row)).toList();
  }

  Future<List<({String id, String fullName})>> fetchCashiers() async {
    final rows = await supabase.from('profiles').select('id, full_name').order('full_name');
    return rows
        .map((row) => (id: row['id'] as String, fullName: (row['full_name'] as String?) ?? '-'))
        .toList();
  }

  Future<List<({String id, String fullName})>> fetchPegawai() async {
    final rows = await supabase
        .from('profiles')
        .select('id, full_name')
        .eq('role', 'pegawai')
        .order('full_name');
    return rows
        .map((row) => (id: row['id'] as String, fullName: (row['full_name'] as String?) ?? '-'))
        .toList();
  }

  Future<List<Sale>> fetchShipments() async {
    final rows = await supabase
        .from('sales')
        .select(_selectWithRelations)
        .eq('needs_shipping', true)
        .order('created_at', ascending: false);
    return rows.map((row) => Sale.fromMap(row)).toList();
  }

  Future<void> assignPegawai({required String saleId, required String? pegawaiId}) async {
    await supabase.from('sales').update({'assigned_to': pegawaiId}).eq('id', saleId);
  }

  Future<void> updateShippingStatus({
    required String saleId,
    required String status,
    String? note,
    bool recordDeliverer = false,
  }) async {
    await supabase.from('sales').update({
      'shipping_status': status,
      'shipping_note': ?note,
      if (recordDeliverer) 'delivered_by': supabase.auth.currentUser?.id,
      if (recordDeliverer) 'delivered_at': DateTime.now().toIso8601String(),
    }).eq('id', saleId);
  }
}

final saleRepository = SaleRepository();
