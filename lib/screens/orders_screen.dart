import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _orders = [];

  Dio get _dio => context.read<AuthNotifier>().dio;

  bool get _staff {
    final auth = context.read<AuthNotifier>();
    return auth.hasRole('admin') || auth.hasRole('manager');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _dio.get('orders');
      final data = response.data as Map;

      if (!mounted) return;

      setState(() {
        _orders = (data['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.response?.data is Map
            ? '${e.response?.data['message'] ?? 'Ошибка загрузки заказов'}'
            : 'Не удалось связаться с сервером. '
                'Проверьте, запущен ли API.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Не удалось прочитать ответ сервера.';
      });
    }
  }

  Future<void> _changeStatus(
    Map<String, dynamic> order,
    String status,
  ) async {
    try {
      await _dio.patch(
        'orders/${order['id']}',
        data: {'status': status},
      );

      await _load();
    } on DioException catch (e) {
      if (!mounted) return;

      final data = e.response?.data;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data is Map
                ? '${data['message'] ?? 'Не удалось изменить статус'}'
                : 'Не удалось изменить статус',
          ),
        ),
      );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'new':
        return 'Новый';
      case 'processing':
        return 'В обработке';
      case 'ready':
        return 'Готов к выдаче';
      case 'completed':
        return 'Завершён';
      case 'cancelled':
        return 'Отменён';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = _staff;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        actions: [
          IconButton(
            tooltip: 'На главную',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
          ),
          IconButton(
            tooltip: 'Обновить',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Повторить'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff ? 'Все заказы' : 'Мои заказы',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            if (_orders.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: Text('Заказов пока нет.'),
                                ),
                              ),
                            ..._orders.map((order) {
                              final rawItems = order['items'] as List? ?? [];

                              final items = rawItems
                                  .whereType<Map>()
                                  .map(
                                    (item) => '${item['name'] ?? 'Товар'} '
                                        '× ${item['quantity'] ?? 1}',
                                  )
                                  .join(', ');

                              final status = '${order['status'] ?? 'new'}';

                              final total = double.tryParse(
                                    '${order['total'] ?? 0}',
                                  ) ??
                                  0;

                              return Card(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Заказ #${order['id']} · '
                                              '${order['createdAt'] ?? ''}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${total.toStringAsFixed(2)} €',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        items.isEmpty
                                            ? 'Состав заказа не указан'
                                            : items,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(
                                              _statusLabel(status),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (staff)
                                            PopupMenuButton<String>(
                                              tooltip: 'Изменить статус',
                                              onSelected: (value) =>
                                                  _changeStatus(
                                                order,
                                                value,
                                              ),
                                              itemBuilder: (_) => const [
                                                PopupMenuItem(
                                                  value: 'new',
                                                  child: Text('Новый'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'processing',
                                                  child: Text(
                                                    'В обработке',
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'ready',
                                                  child: Text(
                                                    'Готов к выдаче',
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'completed',
                                                  child: Text('Завершён'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'cancelled',
                                                  child: Text('Отменён'),
                                                ),
                                              ],
                                              child: const Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Icon(
                                                  Icons.edit_note,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    if (staff)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Менеджер и администратор могут '
                          'просматривать и менять статусы заказов.',
                        ),
                      ),
                  ],
                ),
    );
  }
}
