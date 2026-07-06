class Category {
  const Category({required this.id, required this.name});

  final String id;
  final String name;

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
      );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.purchasePrice,
    required this.sellPrice,
    required this.unit,
    required this.stock,
    required this.minStock,
  });

  final String id;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final num purchasePrice;
  final num sellPrice;
  final String unit;
  final num stock;
  final num minStock;

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String,
        categoryId: map['category_id'] as String?,
        categoryName: (map['categories'] as Map<String, dynamic>?)?['name'] as String?,
        purchasePrice: map['purchase_price'] as num,
        sellPrice: map['sell_price'] as num,
        unit: map['unit'] as String,
        stock: map['stock'] as num,
        minStock: map['min_stock'] as num,
      );
}
