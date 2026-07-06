class SaleItem {
  const SaleItem({
    required this.productName,
    required this.qty,
    required this.price,
    required this.subtotal,
  });

  final String productName;
  final num qty;
  final num price;
  final num subtotal;

  factory SaleItem.fromMap(Map<String, dynamic> map) => SaleItem(
        productName: map['product_name'] as String,
        qty: map['qty'] as num,
        price: map['price'] as num,
        subtotal: map['subtotal'] as num,
      );
}

class Sale {
  const Sale({
    required this.id,
    required this.invoiceNo,
    required this.customerName,
    required this.cashierName,
    required this.assignedToId,
    required this.assignedToName,
    required this.deliveredByName,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.needsShipping,
    required this.shippingStatus,
    required this.shippingNote,
    required this.createdAt,
    this.items = const [],
  });

  final String id;
  final String invoiceNo;
  final String? customerName;
  final String? cashierName;
  final String? assignedToId;
  final String? assignedToName;
  final String? deliveredByName;
  final num total;
  final String paymentMethod;
  final num? amountPaid;
  final bool needsShipping;
  final String shippingStatus;
  final String? shippingNote;
  final DateTime createdAt;
  final List<SaleItem> items;

  num? get change => (paymentMethod == 'cash' && amountPaid != null) ? amountPaid! - total : null;

  factory Sale.fromMap(Map<String, dynamic> map) => Sale(
        id: map['id'] as String,
        invoiceNo: map['invoice_no'] as String,
        customerName: (map['customers'] as Map<String, dynamic>?)?['name'] as String?,
        cashierName: (map['cashier'] as Map<String, dynamic>?)?['full_name'] as String?,
        assignedToId: map['assigned_to'] as String?,
        assignedToName: (map['assignee'] as Map<String, dynamic>?)?['full_name'] as String?,
        deliveredByName: (map['deliverer'] as Map<String, dynamic>?)?['full_name'] as String?,
        total: map['total'] as num,
        paymentMethod: map['payment_method'] as String? ?? 'cash',
        amountPaid: map['amount_paid'] as num?,
        needsShipping: map['needs_shipping'] as bool? ?? false,
        shippingStatus: map['shipping_status'] as String? ?? 'tidak_perlu',
        shippingNote: map['shipping_note'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        items: (map['sale_items'] as List<dynamic>?)
                ?.map((item) => SaleItem.fromMap(item as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
