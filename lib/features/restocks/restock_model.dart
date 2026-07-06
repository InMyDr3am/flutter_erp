class Restock {
  const Restock({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.purchasePrice,
    required this.supplier,
    required this.restockDate,
  });

  final String id;
  final String productId;
  final String productName;
  final num qty;
  final num purchasePrice;
  final String? supplier;
  final DateTime restockDate;

  num get subtotal => qty * purchasePrice;

  factory Restock.fromMap(Map<String, dynamic> map) => Restock(
        id: map['id'] as String,
        productId: map['product_id'] as String,
        productName: (map['products'] as Map<String, dynamic>?)?['name'] as String? ?? '-',
        qty: map['qty'] as num,
        purchasePrice: map['purchase_price'] as num,
        supplier: map['supplier'] as String?,
        restockDate: DateTime.parse(map['restock_date'] as String),
      );
}
