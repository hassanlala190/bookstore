import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static const String _cartKey = "cart_items";

  /// Get all cart items
  static Future<List<Map<String, dynamic>>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartString = prefs.getString(_cartKey);
    if (cartString == null) return [];
    final List decoded = jsonDecode(cartString);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Add item or increment quantity
  static Future<void> addToCart(Map<String, dynamic> item) async {
  final prefs = await SharedPreferences.getInstance();
  final cart = await getCart();

  // Har entry ko unique treat karo, quantity increment sirf uuid match hone par
  final index = cart.indexWhere((e) => e['uuid'] == item['uuid']);
  if (index != -1) {
    int currentQty = cart[index]['quantity'] ?? 1;
    cart[index]['quantity'] = currentQty < 10 ? currentQty + 1 : 10;
  } else {
    item['quantity'] = 1;
    cart.add(item);
  }

  await prefs.setString(_cartKey, jsonEncode(cart));
}


  /// Remove item from cart
  static Future<void> removeFromCart(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final cart = await getCart();
    cart.removeAt(index);
    await prefs.setString(_cartKey, jsonEncode(cart));
  }

  /// Update quantity of a cart item using uuid
  static Future<void> updateQuantity(String uuid, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final cart = await getCart();
    final index = cart.indexWhere((e) => e['uuid'] == uuid);

    if (index != -1) {
      cart[index]['quantity'] = quantity.clamp(1, 10); // min 1, max 10
      await prefs.setString(_cartKey, jsonEncode(cart));
    }
  }

  /// Clear cart
  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_cartKey);
  }

  /// Total cart count (sum of quantities)
  static Future<int> getCartCount() async {
    final cart = await getCart();
    return cart.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 1),
    );
  }
}
