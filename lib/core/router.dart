import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_notifier.dart';
import '../models/list_query.dart';

import '../screens/home_screen.dart';
import '../screens/entity_list_screen.dart';
import '../screens/product_form_screen.dart';
import '../screens/brand_form_screen.dart';
import '../screens/category_form_screen.dart';
import '../screens/supplier_form_screen.dart';
import '../screens/customer_form_screen.dart';
import '../screens/auth_screens.dart';
import '../screens/admin_users_screen.dart';
import '../screens/admin_stats_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/cart_screen.dart';

GoRouter createRouter(AuthNotifier auth) => GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        if (auth.restoring) return null;

        final path = state.matchedLocation;
        final isPublic = path == '/login' || path == '/register';

        if (!auth.isAuthenticated && !isPublic) {
          return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
        }

        if (auth.isAuthenticated && isPublic) {
          return state.uri.queryParameters['from'] ?? '/';
        }

        if (path == '/customers' || path.startsWith('/customers/')) {
          return auth.hasRole('manager') ? null : '/forbidden';
        }

        if (path == '/admin/users' || path == '/admin/stats') {
          return auth.hasRole('admin') ? null : '/forbidden';
        }

        if (path.endsWith('/new') || path.endsWith('/edit')) {
          return auth.hasRole('manager') ? null : '/forbidden';
        }

        // Корзина доступна только покупателю.
        if (path == '/cart') {
          return auth.user?.role == 'customer' ? null : '/forbidden';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, s) => LoginScreen(from: s.uri.queryParameters['from']),
        ),
        GoRoute(
          path: '/register',
          builder: (_, __) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (_, __) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/cart',
          builder: (_, __) => const CartScreen(),
        ),
        GoRoute(
          path: '/forbidden',
          builder: (_, __) => const ForbiddenScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (_, __) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: '/admin/stats',
          builder: (_, __) => const AdminStatsScreen(),
        ),
        GoRoute(
          path: '/products',
          builder: (_, s) => EntityListScreen.product(
            initialQuery: ListQuery.fromUri(s.uri),
          ),
        ),
        GoRoute(
          path: '/products/new',
          builder: (_, __) => const ProductFormScreen(),
        ),
        GoRoute(
          path: '/products/:id/edit',
          builder: (_, s) => ProductFormScreen(
            id: int.tryParse(s.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/brands',
          builder: (_, s) => EntityListScreen.brand(
            initialQuery: ListQuery.fromUri(s.uri),
          ),
        ),
        GoRoute(
          path: '/brands/new',
          builder: (_, __) => const BrandFormScreen(),
        ),
        GoRoute(
          path: '/brands/:id/edit',
          builder: (_, s) => BrandFormScreen(
            id: int.tryParse(s.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/categories',
          builder: (_, s) => EntityListScreen.category(
            initialQuery: ListQuery.fromUri(s.uri),
          ),
        ),
        GoRoute(
          path: '/categories/new',
          builder: (_, __) => const CategoryFormScreen(),
        ),
        GoRoute(
          path: '/categories/:id/edit',
          builder: (_, s) => CategoryFormScreen(
            id: int.tryParse(s.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/suppliers',
          builder: (_, s) => EntityListScreen.supplier(
            initialQuery: ListQuery.fromUri(s.uri),
          ),
        ),
        GoRoute(
          path: '/suppliers/new',
          builder: (_, __) => const SupplierFormScreen(),
        ),
        GoRoute(
          path: '/suppliers/:id/edit',
          builder: (_, s) => SupplierFormScreen(
            id: int.tryParse(s.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/customers',
          builder: (_, s) => EntityListScreen.customer(
            initialQuery: ListQuery.fromUri(s.uri),
          ),
        ),
        GoRoute(
          path: '/customers/new',
          builder: (_, __) => const CustomerFormScreen(),
        ),
        GoRoute(
          path: '/customers/:id/edit',
          builder: (_, s) => CustomerFormScreen(
            id: int.tryParse(s.pathParameters['id']!),
          ),
        ),
      ],
      errorBuilder: (_, s) => Scaffold(
        body: Center(
          child: Text('Страница не найдена: ${s.uri}'),
        ),
      ),
    );
