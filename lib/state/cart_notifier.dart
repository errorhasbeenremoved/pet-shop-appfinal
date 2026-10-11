import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartNotifier extends ChangeNotifier {
  CartNotifier._();

  static final CartNotifier instance = CartNotifier._();

  static const _storageKey = 'pet_shop_cart_v1';

  final Map<int, Map<String, dynamic>> _items = {};
  SharedPreferences? _prefs;

  bool _loaded = false;
  Future<void>? _loading;

  Map<int, Map<String, dynamic>> get items => Map.unmodifiable(_items);

  bool get isLoaded => _loaded;

  int get itemCount => _items.values.fold<int>(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );

  double get total => _items.values.fold<double>(
        0,
        (sum, item) =>
            sum +
            (double.tryParse('${item['price']}') ?? 0) *
                (item['quantity'] as int),
      );

  Future<void> load() async {
    if (_loaded) return;
    if (_loading != null) return _loading!;

    _loading = _restore();
    try {
      await _loading;
    } finally {
      _loading = null;
    }
  }

  Future<void> _restore() async {
    _prefs = await SharedPreferences.getInstance();

    final raw = _prefs!.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List;

        for (final value in decoded) {
          final item = Map<String, dynamic>.from(value as Map);
          final id = int.tryParse('${item['id']}');
          final quantity = int.tryParse('${item['quantity']}') ?? 0;

          if (id != null && quantity > 0) {
            item['id'] = id;
            item['quantity'] = quantity;
            _items[id] = item;
          }
        }
      } catch (_) {
        _items.clear();
        await _prefs!.remove(_storageKey);
      }
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    await load();

    await _prefs!.setString(
      _storageKey,
      jsonEncode(_items.values.toList()),
    );
  }

  Future<void> add(Map<String, dynamic> product) async {
    await load();

    final id = int.tryParse('${product['id']}');
    if (id == null) return;

    final stock = int.tryParse('${product['stock']}') ?? 0;
    if (stock <= 0) return;

    final current = _items[id]?['quantity'] as int? ?? 0;
    if (current >= stock) return;

    _items[id] = {
      ...product,
      'id': id,
      'quantity': current + 1,
    };

    notifyListeners();
    await _save();
  }

  Future<void> setQuantity(int id, int quantity) async {
    await load();

    if (!_items.containsKey(id)) return;

    if (quantity <= 0) {
      await remove(id);
      return;
    }

    final stock = int.tryParse('${_items[id]!['stock']}') ?? 0;

    if (quantity > stock) return;

    _items[id] = {
      ..._items[id]!,
      'quantity': quantity,
    };

    notifyListeners();
    await _save();
  }

  Future<void> remove(int id) async {
    await load();
    _items.remove(id);
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    await load();
    _items.clear();
    notifyListeners();
    await _save();
  }
}
