import '../../core/config/supabase_client.dart';
import 'product_model.dart';

class ProductRepository {
  Future<List<Category>> fetchCategories() async {
    final rows = await supabase.from('categories').select().order('name');
    return rows.map((row) => Category.fromMap(row)).toList();
  }

  Future<Category> createCategory(String name) async {
    final row =
        await supabase.from('categories').insert({'name': name}).select().single();
    return Category.fromMap(row);
  }

  Future<List<Product>> fetchAll() async {
    final rows = await supabase
        .from('products')
        .select('*, categories(name)')
        .order('name');
    return rows.map((row) => Product.fromMap(row)).toList();
  }

  Future<void> create({
    required String name,
    required String? categoryId,
    required num purchasePrice,
    required num sellPrice,
    required String unit,
    required num stock,
    required num minStock,
  }) async {
    await supabase.from('products').insert({
      'name': name,
      'category_id': categoryId,
      'purchase_price': purchasePrice,
      'sell_price': sellPrice,
      'unit': unit,
      'stock': stock,
      'min_stock': minStock,
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String? categoryId,
    required num purchasePrice,
    required num sellPrice,
    required String unit,
    required num stock,
    required num minStock,
  }) async {
    await supabase.from('products').update({
      'name': name,
      'category_id': categoryId,
      'purchase_price': purchasePrice,
      'sell_price': sellPrice,
      'unit': unit,
      'stock': stock,
      'min_stock': minStock,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from('products').delete().eq('id', id);
  }
}

final productRepository = ProductRepository();
