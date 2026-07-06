import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../customers/customer_model.dart';
import '../products/product_model.dart';

class CartItem {
  const CartItem({required this.product, required this.qty});

  final Product product;
  final num qty;

  num get subtotal => product.sellPrice * qty;

  CartItem copyWith({num? qty}) => CartItem(product: product, qty: qty ?? this.qty);
}

class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addProduct(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      state = [...state, CartItem(product: product, qty: 1)];
      return;
    }
    setQty(product.id, state[index].qty + 1);
  }

  void setQty(String productId, num qty) {
    if (qty <= 0) {
      removeItem(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId) item.copyWith(qty: qty) else item,
    ];
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() {
    state = [];
  }
}

final cartProvider = NotifierProvider<CartController, List<CartItem>>(CartController.new);

final cartTotalProvider = Provider<num>((ref) {
  return ref.watch(cartProvider).fold<num>(0, (sum, item) => sum + item.subtotal);
});

final cartCustomerProvider = StateProvider<Customer?>((ref) => null);
final cartNeedsShippingProvider = StateProvider<bool>((ref) => false);
final cartShippingNoteProvider = StateProvider<String>((ref) => '');
