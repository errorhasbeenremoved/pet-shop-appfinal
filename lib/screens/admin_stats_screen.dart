
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthNotifier>().loadStats();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Статистика магазина'),
          actions: [
            IconButton(
              tooltip: 'На главную',
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
            ),
            IconButton(
              tooltip: 'Обновить статистику',
              onPressed: () => setState(
                () => _future =
                    context.read<AuthNotifier>().loadStats(),
              ),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Не удалось получить статистику. '
                  'Сервер мог вернуть 403.\n${snapshot.error}',
                ),
              );
            }

            final data = snapshot.data ?? {};
            final stats = Map<String, dynamic>.from(
              data['stats'] as Map? ?? {},
            );

            final labels = {
              'products': 'Товары',
              'brands': 'Бренды',
              'categories': 'Категории',
              'suppliers': 'Поставщики',
              'customers': 'Клиенты',
              'orders': 'Заказы',
            };

            final userStats = Map<String, dynamic>.from(
              data['users'] as Map? ?? {},
            );

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Состояние базы данных',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entry in labels.entries)
                      _statCard(
                        context,
                        entry.value,
                        stats[entry.key],
                      ),
                    _statCard(context, 'Пользователи', userStats),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Статистика формируется сервером. '
                  'Клиентская подмена роли не предоставляет '
                  'доступ к этому endpoint.',
                ),
              ],
            );
          },
        ),
      );

  Widget _statCard(
    BuildContext context,
    String title,
    Object? raw,
  ) {
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text('Всего: ${data['total'] ?? 0}'),
              Text('Активных: ${data['active'] ?? 0}'),
              Text(
                'Удалённых/заблокированных: '
                '${data['deleted'] ?? data['blocked'] ?? 0}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
