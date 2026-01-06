import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static const String _cartKey = "cart_items";

  // 🔥 CART COUNT NOTIFIER
  static final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);

  /// Get all cart items
  static Future<List<Map<String, dynamic>>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartString = prefs.getString(_cartKey);
    if (cartString == null) return [];
    final List decoded = jsonDecode(cartString);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// 🔔 INTERNAL: Update cart count
  static Future<void> _updateCartCount() async {
    final cart = await getCart();
    final count = cart.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 1),
    );
    cartCountNotifier.value = count;
  }

  /// Add item or increment quantity
  static Future<void> addToCart(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final cart = await getCart();

    // Compare by book ID (docId) not uuid
    final index = cart.indexWhere((e) => e['id'] == item['id']);
    if (index != -1) {
      // If already exists, only increase quantity
      int currentQty = cart[index]['quantity'] ?? 1;
      cart[index]['quantity'] = currentQty < 10 ? currentQty + 1 : 10;
    } else {
      // If new item, generate uuid and set quantity = 1
      item['uuid'] = DateTime.now().millisecondsSinceEpoch.toString();
      item['quantity'] = 1;
      cart.add(item);
    }

    await prefs.setString(_cartKey, jsonEncode(cart));
    await _updateCartCount(); // 🔥
  }

  /// Remove item from cart by index
  static Future<void> removeFromCart(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final cart = await getCart();
    if (index >= 0 && index < cart.length) {
      cart.removeAt(index);
      await prefs.setString(_cartKey, jsonEncode(cart));
      await _updateCartCount();
    }
  }

  /// Remove item from cart by uuid
  static Future<void> removeItemByUuid(String uuid) async {
    final prefs = await SharedPreferences.getInstance();
    final cart = await getCart();
    final index = cart.indexWhere((e) => e['uuid'] == uuid);
    if (index != -1) {
      cart.removeAt(index);
      await prefs.setString(_cartKey, jsonEncode(cart));
      await _updateCartCount();
    }
  }

  /// Update quantity of a cart item using uuid
  static Future<void> updateQuantity(String uuid, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final cart = await getCart();
    final index = cart.indexWhere((e) => e['uuid'] == uuid);

    if (index != -1) {
      cart[index]['quantity'] = quantity.clamp(1, 10);
      await prefs.setString(_cartKey, jsonEncode(cart));
      await _updateCartCount();
    }
  }

  /// Clear cart
  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
    cartCountNotifier.value = 0;
  }

  /// Initial load (call once at app start)
  static Future<void> loadInitialCartCount() async {
    await _updateCartCount();
  }
}