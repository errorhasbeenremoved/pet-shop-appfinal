import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    final isAdmin = auth.hasRole('admin');
    final isManager = auth.hasRole('manager');
    final theme = Theme.of(context);
    final tiles = <_DashboardItem>[
      const _DashboardItem('Каталог товаров', 'Карточки товаров, цены и поиск',
          '/products', Icons.pets, Color(0xFFE0F2E8)),
      const _DashboardItem('Заказы', 'Оформление и история заказов',
          '/orders', Icons.shopping_bag_outlined, Color(0xFFE0F2E8)),
      const _DashboardItem('Бренды', 'Производители товаров', '/brands',
          Icons.sell_outlined, Color(0xFFE5EAFB)),
      const _DashboardItem('Категории', 'Организация каталога', '/categories',
          Icons.category_outlined, Color(0xFFFFEBD7)),
      if (isManager)
        const _DashboardItem('Поставщики', 'Партнёры магазина', '/suppliers',
            Icons.local_shipping_outlined, Color(0xFFE7E2F7)),
      if (isManager)
        const _DashboardItem('Клиенты', 'Карточки покупателей', '/customers',
            Icons.people_outline, Color(0xFFDDF2F5)),
      if (isAdmin)
        const _DashboardItem(
            'Пользователи и роли',
            'Учётные записи и доступ',
            '/admin/users',
            Icons.admin_panel_settings_outlined,
            Color(0xFFFFE1E1)),
      if (isAdmin)
        const _DashboardItem('Статистика', 'Показатели магазина',
            '/admin/stats', Icons.query_stats, Color(0xFFE3EFD2)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.pets, size: 26),
          SizedBox(width: 10),
          Flexible(
              child: Text('Зоомаркет',
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                  child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text('${user.fullName} · ${auth.displayRoleLabel}',
                    overflow: TextOverflow.ellipsis),
              )),
            ),
          IconButton(
              tooltip: 'Выйти из аккаунта',
              onPressed: () => auth.logout(message: 'Вы вышли из системы.'),
              icon: const Icon(Icons.logout)),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.surfaceContainerHighest
                    ]),
                  ),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final compact = constraints.maxWidth < 560;
                    final text = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Всё для счастливых хвостиков',
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          Text(
                              'Добро пожаловать, ${user?.fullName ?? 'пользователь'}! ${isAdmin ? 'У вас полный доступ к управлению магазином.' : isManager ? 'Вы можете управлять каталогом и клиентами.' : 'Здесь можно посмотреть каталог товаров для питомцев.'}'),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                              onPressed: () => context.go('/products'),
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: const Text('Открыть каталог')),
                        ]);
                    final art = Icon(Icons.pets,
                        size: compact ? 54 : 100,
                        color: theme.colorScheme.primary);
                    return compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [art, const SizedBox(height: 16), text])
                        : Row(children: [
                            Expanded(child: text),
                            const SizedBox(width: 24),
                            art
                          ]);
                  }),
                ),
                const SizedBox(height: 28),
                Text('Рабочее пространство',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisExtent: 142,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  itemCount: tiles.length,
                  itemBuilder: (context, index) =>
                      _DashboardCard(item: tiles[index]),
                ),
                const SizedBox(height: 24),
                Text('Онлайн-магазин зоотоваров',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ]),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title, subtitle, path;
  final IconData icon;
  final Color tint;
  const _DashboardItem(
      this.title, this.subtitle, this.path, this.icon, this.tint);
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;
  const _DashboardCard({required this.item});
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go(item.path),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                      color: item.tint,
                      borderRadius: BorderRadius.circular(18)),
                  child: Icon(item.icon,
                      size: 28, color: const Color(0xFF245B49))),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  ])),
              const Icon(Icons.arrow_forward_ios, size: 15),
            ]),
          ),
        ),
      );
}
