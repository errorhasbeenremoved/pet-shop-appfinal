import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';
import '../state/cart_notifier.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _sending = false;

  CartNotifier get cart => CartNotifier.instance;

  @override
  void initState() {
    super.initState();
    cart.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _checkout() async {
    if (_sending || cart.items.isEmpty) return;

    setState(() => _sending = true);

    try {
      final dio = context.read<AuthNotifier>().dio;

      await dio.post(
        'orders',
        data: {
          'items': cart.items.entries.map((entry) {
            return {
              'productId': entry.key,
              'quantity': entry.value['quantity'],
            };
          }).toList(),
        },
      );

      await cart.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Заказ оформлен! Оплата не выполнялась.',
          ),
        ),
      );

      context.go('/orders');
    } on DioException catch (e) {
      if (!mounted) return;

      final data = e.response?.data;
      final message = data is Map
          ? '${data['message'] ?? 'Не удалось оформить заказ'}'
          : 'Ошибка соединения с сервером';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Моя корзина'),
            actions: [
              IconButton(
                tooltip: 'В каталог',
                onPressed: () => context.go('/products'),
                icon: const Icon(Icons.storefront_outlined),
              ),
              IconButton(
                tooltip: 'На главную',
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
              ),
            ],
          ),
          body: !cart.isLoaded
              ? const Center(child: CircularProgressIndicator())
              : cart.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                          ),
                          const SizedBox(height: 12),
                          const Text('Корзина пока пуста'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => context.go('/products'),
                            icon: const Icon(Icons.storefront),
                            label: const Text('Перейти в каталог'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        ...cart.items.entries.map((entry) {
                          final id = entry.key;
                          final item = entry.value;
                          final quantity = item['quantity'] as int;
                          final price =
                              double.tryParse('${item['price']}') ?? 0;

                          return Card(
                            child: ListTile(
                              title: Text('${item['name'] ?? 'Товар'}'),
                              subtitle: Text(
                                '${price.toStringAsFixed(2)} € за шт.\n'
                                'Сумма: ${(price * quantity).toStringAsFixed(2)} €',
                              ),
                              isThreeLine: true,
                              leading: IconButton(
                                tooltip: 'Убрать товар',
                                onPressed: () => cart.remove(id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                              trailing: SizedBox(
                                width: 144,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          cart.setQuantity(id, quantity - 1),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    Text('$quantity'),
                                    IconButton(
                                      onPressed: () =>
                                          cart.setQuantity(id, quantity + 1),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        Text(
                          'Итого: ${cart.total.toStringAsFixed(2)} €',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _sending ? null : _checkout,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.shopping_cart_checkout,
                                ),
                          label: Text(
                            _sending
                                ? 'Оформляем...'
                                : 'Оформление заказа',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Успешно',
                        ),
                      ],
                    ),
        );
      },
    );
  }
}
