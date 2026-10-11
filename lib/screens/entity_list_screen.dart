import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import '../state/auth_notifier.dart';
import '../state/cart_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/async_state_panel.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/responsive_card_list.dart';

typedef RepoBuilder<T> = CrudRepository<T> Function(BuildContext context);
typedef ColumnsBuilder<T> = List<TableColumnSpec<T>> Function(
  BuildContext context,
);
typedef CardBuilder<T> = Widget Function(BuildContext context, T item);
typedef ActionsBuilder<T> = List<Widget> Function(
  BuildContext context,
  T item,
  EntityListNotifier<T> notifier,
);

class EntityListScreen<T> extends StatefulWidget {
  final RepoBuilder<T> repoBuilder;
  final String title;
  final String path;
  final ListQuery initialQuery;
  final ColumnsBuilder<T> columns;
  final CardBuilder<T> card;
  final int Function(T item) idOf;
  final ActionsBuilder<T> actions;
  final Widget Function(BuildContext, ListQuery)? filterBuilder;

  const EntityListScreen({
    super.key,
    required this.repoBuilder,
    required this.title,
    required this.path,
    required this.initialQuery,
    required this.columns,
    required this.card,
    required this.idOf,
    required this.actions,
    this.filterBuilder,
  });

  static Widget product({required ListQuery initialQuery}) =>
      EntityListScreen<Product>(
        repoBuilder: (c) => c.read<ProductRepository>(),
        title: 'Товары',
        path: '/products',
        initialQuery: initialQuery,
        columns: (_) => [
          TableColumnSpec(
            label: 'Название',
            sortField: 'name',
            build: (e) => Text(e.name),
          ),
          TableColumnSpec(
            label: 'SKU',
            sortField: 'sku',
            build: (e) => Text(e.sku),
          ),
          TableColumnSpec(
            label: 'Бренд',
            build: (e) => Text('${e.brandId}'),
          ),
          TableColumnSpec(
            label: 'Цена',
            sortField: 'price',
            numeric: true,
            build: (e) => Text('${e.price.toStringAsFixed(2)} €'),
          ),
          TableColumnSpec(
            label: 'Остаток',
            sortField: 'stock',
            numeric: true,
            build: (e) => Text('${e.stock}'),
          ),
        ],
        card: (_, e) => _card(
          e.name,
          'SKU: ${e.sku}',
          '${e.price.toStringAsFixed(2)} € · остаток ${e.stock}',
          e.isDeleted,
        ),
        idOf: (e) => e.id,
        actions: (c, e, n) =>
            _actions(c, '/products/${e.id}/edit', e.isDeleted, n, e.id),
        filterBuilder: (c, q) => FutureBuilder<PageResult<Brand>>(
          future: c.read<BrandRepository>().find(const ListQuery(size: 50)),
          builder: (c, s) {
            final items = s.data?.items ?? const <Brand>[];
            return SizedBox(
              width: 220,
              child: DropdownButton<String?>(
                isExpanded: true,
                value:
                    items.any((e) => '${e.id}' == q.filter) ? q.filter : null,
                hint: const Text('Фильтр бренда'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все бренды'),
                  ),
                  ...items.map(
                    (e) => DropdownMenuItem<String?>(
                      value: '${e.id}',
                      child: Text(e.name),
                    ),
                  ),
                ],
                onChanged: (v) {
                  final state = c.findAncestorStateOfType<
                      _EntityListScreenState<Product>>();
                  state?.apply(q.copyWith(filter: v));
                },
              ),
            );
          },
        ),
      );

  static Widget brand({required ListQuery initialQuery}) =>
      EntityListScreen<Brand>(
        repoBuilder: (c) => c.read<BrandRepository>(),
        title: 'Бренды',
        path: '/brands',
        initialQuery: initialQuery,
        columns: (_) => [
          TableColumnSpec(
            label: 'Название',
            sortField: 'name',
            build: (e) => Text(e.name),
          ),
          TableColumnSpec(
            label: 'Страна',
            sortField: 'country',
            build: (e) => Text(e.country),
          ),
          TableColumnSpec(
            label: 'Описание',
            build: (e) => Text(e.description),
          ),
        ],
        card: (context, e) => _browseCard(
          context,
          e.name,
          e.country,
          e.description,
          e.isDeleted,
          e.id,
        ),
        idOf: (e) => e.id,
        actions: (c, e, n) =>
            _actions(c, '/brands/${e.id}/edit', e.isDeleted, n, e.id),
      );

  static Widget category({required ListQuery initialQuery}) =>
      EntityListScreen<Category>(
        repoBuilder: (c) => c.read<CategoryRepository>(),
        title: 'Категории',
        path: '/categories',
        initialQuery: initialQuery,
        columns: (_) => [
          TableColumnSpec(
            label: 'Название',
            sortField: 'name',
            build: (e) => Text(e.name),
          ),
          TableColumnSpec(
            label: 'Бренд',
            sortField: 'brandId',
            build: (e) => Text('${e.brandId}'),
          ),
          TableColumnSpec(
            label: 'Описание',
            build: (e) => Text(e.description),
          ),
        ],
        card: (context, e) => _browseCard(
          context,
          e.name,
          'Категория товаров',
          e.description,
          e.isDeleted,
          e.id,
        ),
        idOf: (e) => e.id,
        actions: (c, e, n) =>
            _actions(c, '/categories/${e.id}/edit', e.isDeleted, n, e.id),
        filterBuilder: (c, q) => FutureBuilder<PageResult<Brand>>(
          future: c.read<BrandRepository>().find(const ListQuery(size: 50)),
          builder: (c, s) {
            final items = s.data?.items ?? const <Brand>[];
            return SizedBox(
              width: 220,
              child: DropdownButton<String?>(
                isExpanded: true,
                value:
                    items.any((e) => '${e.id}' == q.filter) ? q.filter : null,
                hint: const Text('Фильтр бренда'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все бренды'),
                  ),
                  ...items.map(
                    (e) => DropdownMenuItem<String?>(
                      value: '${e.id}',
                      child: Text(e.name),
                    ),
                  ),
                ],
                onChanged: (v) {
                  final state = c.findAncestorStateOfType<
                      _EntityListScreenState<Category>>();
                  state?.apply(q.copyWith(filter: v));
                },
              ),
            );
          },
        ),
      );

  static Widget supplier({required ListQuery initialQuery}) =>
      EntityListScreen<Supplier>(
        repoBuilder: (c) => c.read<SupplierRepository>(),
        title: 'Поставщики',
        path: '/suppliers',
        initialQuery: initialQuery,
        columns: (_) => [
          TableColumnSpec(
            label: 'Название',
            sortField: 'name',
            build: (e) => Text(e.name),
          ),
          TableColumnSpec(
            label: 'Email',
            sortField: 'email',
            build: (e) => Text(e.email),
          ),
          TableColumnSpec(
            label: 'Телефон',
            build: (e) => Text(e.phone),
          ),
        ],
        card: (_, e) => _card(
          e.name,
          e.email,
          e.phone,
          e.isDeleted,
        ),
        idOf: (e) => e.id,
        actions: (c, e, n) =>
            _actions(c, '/suppliers/${e.id}/edit', e.isDeleted, n, e.id),
        filterBuilder: (c, q) => FutureBuilder<PageResult<Brand>>(
          future: c.read<BrandRepository>().find(const ListQuery(size: 50)),
          builder: (c, s) {
            final items = s.data?.items ?? const <Brand>[];
            return SizedBox(
              width: 220,
              child: DropdownButton<String?>(
                isExpanded: true,
                value:
                    items.any((e) => '${e.id}' == q.filter) ? q.filter : null,
                hint: const Text('Фильтр бренда'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все бренды'),
                  ),
                  ...items.map(
                    (e) => DropdownMenuItem<String?>(
                      value: '${e.id}',
                      child: Text(e.name),
                    ),
                  ),
                ],
                onChanged: (v) {
                  final state = c.findAncestorStateOfType<
                      _EntityListScreenState<Supplier>>();
                  state?.apply(q.copyWith(filter: v));
                },
              ),
            );
          },
        ),
      );

  static Widget customer({required ListQuery initialQuery}) =>
      EntityListScreen<Customer>(
        repoBuilder: (c) => c.read<CustomerRepository>(),
        title: 'Клиенты',
        path: '/customers',
        initialQuery: initialQuery,
        columns: (_) => [
          TableColumnSpec(
            label: 'Имя',
            sortField: 'name',
            build: (e) => Text(e.name),
          ),
          TableColumnSpec(
            label: 'Email',
            sortField: 'email',
            build: (e) => Text(e.email),
          ),
          TableColumnSpec(
            label: 'Карта',
            build: (e) => Text(e.card.number),
          ),
          TableColumnSpec(
            label: 'Баллы',
            sortField: 'points',
            numeric: true,
            build: (e) => Text('${e.card.bonusPoints}'),
          ),
        ],
        card: (_, e) => _card(
          e.name,
          e.email,
          'Карта: ${e.card.number} · ${e.card.level}',
          e.isDeleted,
        ),
        idOf: (e) => e.id,
        actions: (c, e, n) =>
            _actions(c, '/customers/${e.id}/edit', e.isDeleted, n, e.id),
      );

  @override
  State<EntityListScreen<T>> createState() => _EntityListScreenState<T>();
}

class _EntityListScreenState<T> extends State<EntityListScreen<T>> {
  late final EntityListNotifier<T> notifier;
  late final TextEditingController search;

  @override
  void initState() {
    super.initState();
    notifier = EntityListNotifier<T>(
      widget.repoBuilder(context),
      initialQuery: widget.initialQuery,
    )..load();
    search = TextEditingController(text: widget.initialQuery.search);
  }

  @override
  void dispose() {
    search.dispose();
    notifier.dispose();
    super.dispose();
  }

  void apply(ListQuery q) {
    notifier.apply(q);
    final uri = q.toUri(widget.path);
    if (mounted && GoRouterState.of(context).uri.toString() != uri.toString()) {
      context.go(uri.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: notifier,
      child: Consumer<EntityListNotifier<T>>(
        builder: (context, n, _) => Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              if (T == Product &&
                  context.read<AuthNotifier>().user?.role == 'customer')
                AnimatedBuilder(
                  animation: CartNotifier.instance,
                  builder: (context, _) {
                    final count = CartNotifier.instance.itemCount;
                    return IconButton(
                      tooltip: 'Корзина',
                      onPressed: () => context.go('/cart'),
                      icon: Badge(
                        label: Text('$count'),
                        isLabelVisible: count > 0,
                        child: const Icon(Icons.shopping_cart_outlined),
                      ),
                    );
                  },
                ),
              IconButton(
                tooltip: 'На главную',
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
              ),
              if (context.watch<AuthNotifier>().hasRole('manager'))
                IconButton(
                  tooltip: 'Добавить',
                  onPressed: () => context.go('${widget.path}/new'),
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, viewport) {
              final compact = viewport.maxWidth < 600;
              return Row(
                children: [
                  if (!compact)
                    NavigationRail(
                      selectedIndex: _navIndex(widget.path),
                      extended: viewport.maxWidth >= 1200,
                      labelType: viewport.maxWidth >= 1200
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      onDestinationSelected: (index) =>
                          context.go(_navPath(index)),
                      destinations: [
                        const NavigationRailDestination(
                          icon: Icon(Icons.pets_outlined),
                          selectedIcon: Icon(Icons.pets),
                          label: Text('Товары'),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.sell_outlined),
                          selectedIcon: Icon(Icons.sell),
                          label: Text('Бренды'),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.category_outlined),
                          selectedIcon: Icon(Icons.category),
                          label: Text('Категории'),
                        ),
                        if (context.watch<AuthNotifier>().hasRole('manager'))
                          const NavigationRailDestination(
                            icon: Icon(Icons.local_shipping_outlined),
                            selectedIcon: Icon(Icons.local_shipping),
                            label: Text('Поставщики'),
                          ),
                      ],
                    ),
                  if (!compact) const VerticalDivider(width: 1),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 300,
                                child: TextField(
                                  controller: search,
                                  decoration: const InputDecoration(
                                    labelText: 'Поиск',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                  onChanged: (value) {
                                    Future.delayed(
                                      const Duration(milliseconds: 350),
                                      () {
                                        if (mounted && value == search.text) {
                                          apply(n.query.copyWith(
                                            search: value,
                                          ));
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                              if (widget.filterBuilder != null)
                                widget.filterBuilder!(context, n.query),
                              if (context
                                  .watch<AuthNotifier>()
                                  .hasRole('admin'))
                                FilterChip(
                                  label: const Text('Показывать удалённые'),
                                  selected: n.query.includeDeleted,
                                  onSelected: (value) => apply(
                                    n.query.copyWith(includeDeleted: value),
                                  ),
                                ),
                              if (n.selected.isNotEmpty &&
                                  context
                                      .watch<AuthNotifier>()
                                      .hasRole('admin'))
                                FilledButton.tonalIcon(
                                  onPressed: () async {
                                    final ok = await _confirm(
                                      context,
                                      'Удалить выбранные записи?',
                                      'Записи будут логически удалены.',
                                    );
                                    if (ok) await n.deleteSelected();
                                  },
                                  icon: const Icon(Icons.delete_sweep),
                                  label: Text(
                                    'Удалить выбранные (${n.selected.length})',
                                  ),
                                ),
                              if (context
                                  .watch<AuthNotifier>()
                                  .hasRole('manager'))
                                OutlinedButton(
                                  onPressed: () =>
                                      context.go('${widget.path}/new'),
                                  child: const Text('Добавить'),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: AsyncStatePanel(
                            loading: n.loading,
                            error: n.error,
                            empty: n.result.items.isEmpty,
                            emptyMessage:
                                'Ничего не найдено. Измените поисковый запрос или фильтры.',
                            onRetry: n.load,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final auth = context.read<AuthNotifier>();
                                final isBuyer = !auth.hasRole('manager') &&
                                    !auth.hasRole('admin');

                                if (isBuyer && (T == Brand || T == Category)) {
                                  final columns = constraints.maxWidth >= 1100
                                      ? 3
                                      : constraints.maxWidth >= 700
                                          ? 2
                                          : 1;

                                  return GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      8,
                                      20,
                                      24,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 18,
                                      mainAxisSpacing: 18,
                                      mainAxisExtent: 205,
                                    ),
                                    itemCount: n.result.items.length,
                                    itemBuilder: (context, index) =>
                                        widget.card(
                                      context,
                                      n.result.items[index],
                                    ),
                                  );
                                }

                                if (constraints.maxWidth < 600 &&
                                    !(T == Product && isBuyer)) {
                                  return ResponsiveCardList(
                                    items: n.result.items,
                                    itemBuilder: (item) =>
                                        widget.card(context, item),
                                  );
                                }

                                if (T == Product && isBuyer) {
                                  final products =
                                      n.result.items.cast<Product>();
                                  final columns = constraints.maxWidth >= 1150
                                      ? 4
                                      : constraints.maxWidth >= 820
                                          ? 3
                                          : constraints.maxWidth < 520
                                              ? 1
                                              : 2;

                                  return GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      8,
                                      20,
                                      20,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio:
                                          constraints.maxWidth < 520
                                              ? 0.95
                                              : 0.78,
                                    ),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      final product = products[index];

                                      return Card(
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                child: Icon(
                                                  Icons.pets,
                                                  size: 76,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    'Артикул: ${product.sku}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '${product.price.toStringAsFixed(2)} €',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    product.stock > 0
                                                        ? 'В наличии: ${product.stock}'
                                                        : 'Нет в наличии',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      OutlinedButton.icon(
                                                        onPressed: () =>
                                                            showDialog<void>(
                                                          context: context,
                                                          builder:
                                                              (dialogContext) =>
                                                                  AlertDialog(
                                                            title: Text(
                                                              product.name,
                                                            ),
                                                            content:
                                                                SingleChildScrollView(
                                                              child: Text(
                                                                '${product.description}\n\n'
                                                                'Артикул: ${product.sku}\n'
                                                                'Цена: ${product.price.toStringAsFixed(2)} €\n'
                                                                'Остаток: ${product.stock}',
                                                              ),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator
                                                                        .pop(
                                                                  dialogContext,
                                                                ),
                                                                child:
                                                                    const Text(
                                                                  'Закрыть',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        icon: const Icon(
                                                          Icons
                                                              .visibility_outlined,
                                                        ),
                                                        label: const Text(
                                                          'Подробнее',
                                                        ),
                                                      ),
                                                      FilledButton.tonalIcon(
                                                        onPressed:
                                                            product.stock > 0
                                                                ? () async {
                                                                    await CartNotifier
                                                                        .instance
                                                                        .add({
                                                                      'id': product
                                                                          .id,
                                                                      'name': product
                                                                          .name,
                                                                      'sku': product
                                                                          .sku,
                                                                      'price':
                                                                          product
                                                                              .price,
                                                                      'stock':
                                                                          product
                                                                              .stock,
                                                                      'description':
                                                                          product
                                                                              .description,
                                                                    });

                                                                    if (!context
                                                                        .mounted) {
                                                                      return;
                                                                    }

                                                                    ScaffoldMessenger
                                                                        .of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text(
                                                                          '${product.name} добавлен в корзину',
                                                                        ),
                                                                        action:
                                                                            SnackBarAction(
                                                                          label:
                                                                              'Открыть',
                                                                          onPressed: () =>
                                                                              context.go('/cart'),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                : null,
                                                        icon: const Icon(
                                                          Icons
                                                              .add_shopping_cart,
                                                        ),
                                                        label: const Text(
                                                          'В корзину',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }

                                return SingleChildScrollView(
                                  child: EntityTable(
                                    columns: widget.columns(context),
                                    items: n.result.items,
                                    idOf: widget.idOf,
                                    selected: n.selected,
                                    onToggleSelect: n.toggle,
                                    sortField: n.query.sortField,
                                    sortAscending: n.query.sortAscending,
                                    onSort: (field) => apply(
                                      n.query.copyWith(
                                        sortField: field,
                                        sortAscending:
                                            n.query.sortField == field
                                                ? !n.query.sortAscending
                                                : true,
                                      ),
                                    ),
                                    actions: (item) =>
                                        widget.actions(context, item, n),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: PaginationBar(
                            page: n.result.page,
                            totalPages: n.result.totalPages,
                            total: n.result.total,
                            size: n.result.size,
                            onPageChanged: (page) =>
                                apply(n.query.copyWith(page: page)),
                            onSizeChanged: (size) =>
                                apply(n.query.copyWith(size: size)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          bottomNavigationBar: MediaQuery.sizeOf(context).width < 600
              ? NavigationBar(
                  selectedIndex: _navIndex(widget.path),
                  onDestinationSelected: (index) => context.go(_navPath(index)),
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.pets_outlined),
                      selectedIcon: Icon(Icons.pets),
                      label: 'Товары',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.sell_outlined),
                      selectedIcon: Icon(Icons.sell),
                      label: 'Бренды',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.category_outlined),
                      selectedIcon: Icon(Icons.category),
                      label: 'Категории',
                    ),
                    if (context.watch<AuthNotifier>().hasRole('manager'))
                      const NavigationDestination(
                        icon: Icon(Icons.local_shipping_outlined),
                        selectedIcon: Icon(Icons.local_shipping),
                        label: 'Поставщики',
                      ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

int _navIndex(String path) => path.startsWith('/brands')
    ? 1
    : path.startsWith('/categories')
        ? 2
        : path.startsWith('/suppliers')
            ? 3
            : 0;

String _navPath(int index) {
  if (index == 1) return '/brands';
  if (index == 2) return '/categories';
  if (index == 3) return '/suppliers';
  return '/products';
}

Widget _card(
  String title,
  String line1,
  String line2,
  bool deleted,
) =>
    Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text('$line1\n$line2'),
        isThreeLine: true,
        trailing: deleted ? const Icon(Icons.delete_outline) : null,
      ),
    );

List<Widget> _actions<T>(
  BuildContext context,
  String editPath,
  bool deleted,
  EntityListNotifier<T> notifier,
  int id,
) {
  final auth = context.read<AuthNotifier>();
  final canManage = auth.hasRole('manager');
  final isAdmin = auth.hasRole('admin');

  return [
    if (canManage && !deleted)
      IconButton(
        tooltip: 'Редактировать',
        onPressed: () => context.go(editPath),
        icon: const Icon(Icons.edit),
      ),
    if (canManage && !deleted)
      IconButton(
        tooltip: 'Удалить',
        onPressed: () => notifier.softDelete(id),
        icon: const Icon(Icons.delete_outline),
      ),
    if (isAdmin && deleted)
      IconButton(
        tooltip: 'Восстановить',
        onPressed: () => notifier.restore(id),
        icon: const Icon(Icons.restore),
      ),
    if (isAdmin && deleted)
      IconButton(
        tooltip: 'Физически удалить',
        onPressed: () async {
          final ok = await _confirm(
            context,
            'Физически удалить?',
            'Запись нельзя будет восстановить.',
          );
          if (!ok) return;

          try {
            await notifier.hardDelete(id);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
        icon: const Icon(Icons.delete_forever),
      ),
  ];
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    ) ??
    false;

Widget _browseCard(
  BuildContext context,
  String title,
  String line1,
  String line2,
  bool deleted,
  int id,
) {
  final isCategory = line1 == 'Категория товаров';
  final theme = Theme.of(context);
  final icon = isCategory ? Icons.category_outlined : Icons.verified_outlined;
  final description =
      line2.trim().isEmpty ? 'Откройте подборку товаров' : line2;

  return Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: deleted ? null : () => context.go('/products?filter=$id'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_outward_rounded,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              line1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            Row(
              children: [
                Text(
                  deleted ? 'Недоступно' : 'Смотреть товары',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
