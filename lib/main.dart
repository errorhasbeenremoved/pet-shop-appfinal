import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router.dart';
import 'repositories/repositories.dart';
import 'state/auth_notifier.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  final auth = AuthNotifier(prefs);
  await auth.restore();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<AuthNotifier>.value(value: auth),
    Provider<Dio>.value(value: auth.dio),
    ProxyProvider<Dio, ProductRepository>(
        update: (c, dio, previous) => ProductRepository(dio)),
    ProxyProvider<Dio, BrandRepository>(
        update: (c, dio, previous) => BrandRepository(dio)),
    ProxyProvider<Dio, CategoryRepository>(
        update: (c, dio, previous) => CategoryRepository(dio)),
    ProxyProvider<Dio, SupplierRepository>(
        update: (c, dio, previous) => SupplierRepository(dio)),
    ProxyProvider<Dio, CustomerRepository>(
        update: (c, dio, previous) => CustomerRepository(dio)),
    ProxyProvider3<BrandRepository, CategoryRepository, SupplierRepository,
        ReferenceCache>(update: (_, b, c, s, __) => ReferenceCache(b, c, s)),
  ], child: const PetShopApp()));
}

class PetShopApp extends StatelessWidget {
  const PetShopApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
      title: 'Зоомаркет',
      debugShowCheckedModeBanner: false,
      routerConfig: createRouter(context.read<AuthNotifier>()),
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF236B55), brightness: Brightness.light),
          scaffoldBackgroundColor: const Color(0xFFF6F8F5),
          appBarTheme: const AppBarTheme(
              centerTitle: false,
              backgroundColor: Color(0xFFF6F8F5),
              surfaceTintColor: Colors.transparent),
          inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
          cardTheme: CardThemeData(
              margin: EdgeInsets.zero,
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)))),
      builder: (context, child) =>
          InactivityWatcher(child: child ?? const SizedBox.shrink()));
}
