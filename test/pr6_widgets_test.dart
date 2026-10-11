import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop_app/widgets/async_state_panel.dart';
import 'package:pet_shop_app/widgets/role_visibility.dart';
import 'package:pet_shop_app/widgets/validators.dart';

Widget host(Widget child, {double width = 800}) => MaterialApp(
      home: MediaQuery(
          data: MediaQueryData(size: Size(width, 900)),
          child: Scaffold(body: child)),
    );

void main() {
  testWidgets('shows progress during loading', (tester) async {
    await tester.pumpWidget(host(const AsyncStatePanel(
        loading: true,
        error: null,
        empty: false,
        onRetry: _noop,
        child: Text('data'))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('data'), findsNothing);
  });
  testWidgets('shows empty state instead of spinner', (tester) async {
    await tester.pumpWidget(host(const AsyncStatePanel(
        loading: false,
        error: null,
        empty: true,
        emptyMessage: 'Товаров нет',
        onRetry: _noop,
        child: Text('data'))));
    expect(find.text('Товаров нет'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  testWidgets('error state exposes retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(host(AsyncStatePanel(
        loading: false,
        error: 'Нет соединения с сервером',
        empty: false,
        onRetry: () => retried = true,
        child: const Text('data'))));
    expect(find.text('Нет соединения с сервером'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(retried, isTrue);
  });
  testWidgets('required form field shows validation message', (tester) async {
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(host(Material(
      child: Form(
          key: key,
          child: Column(children: [
            TextFormField(
                key: const Key('product-name'),
                validator: (v) => requiredText(v, 'Название')),
            ElevatedButton(
                onPressed: () => key.currentState!.validate(),
                child: const Text('Сохранить')),
          ])),
    )));
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    expect(find.text('Название обязательно'), findsOneWidget);
  });
  testWidgets('restricted action is hidden for insufficient role',
      (tester) async {
    await tester.pumpWidget(host(
        const RoleVisibility(allowed: false, child: Text('Удалить навсегда'))));
    expect(find.text('Удалить навсегда'), findsNothing);
  });
  testWidgets('allowed action is visible for permitted role', (tester) async {
    await tester.pumpWidget(host(
        const RoleVisibility(allowed: true, child: Text('Добавить товар'))));
    expect(find.text('Добавить товар'), findsOneWidget);
  });
}

void _noop() {}
