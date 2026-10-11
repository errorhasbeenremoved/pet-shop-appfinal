import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

String authError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return '${data['message']}';
    if (error.response?.statusCode == 403) return 'Доступ запрещён (403).';
    if (error.response?.statusCode == 422) return 'Проверьте введённые данные.';
    if (error.response == null) {
      return 'Сервер недоступен. Проверьте соединение.';
    }
  }
  return error.toString().replaceFirst('Exception: ', '');
}

class LoginScreen extends StatefulWidget {
  final String? from;
  const LoginScreen({super.key, this.from});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await context.read<AuthNotifier>().login(_username.text, _password.text);
      if (mounted) {
        context.go(widget.from?.startsWith('/') == true ? widget.from! : '/');
      }
    } catch (e) {
      if (mounted) setState(() => _error = authError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.pets, size: 54),
                    const SizedBox(height: 12),
                    Text('Вход в Зоомаркет',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 22),
                    if (auth.sessionMessage != null)
                      Text(auth.sessionMessage!,
                          style: const TextStyle(color: Colors.deepOrange)),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(
                          labelText: 'Логин', prefixIcon: Icon(Icons.person)),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Введите логин'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off))),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Введите пароль' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red))),
                    const SizedBox(height: 18),
                    FilledButton(
                        onPressed: auth.busy ? null : _submit,
                        child: auth.busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator())
                            : const Text('Войти')),
                    TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('Создать аккаунт')),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final password = _password.text;
    final checks = [
      password.length >= 8,
      password.contains(RegExp(r'\d')),
      password.contains(RegExp(r'[^A-Za-z0-9]'))
    ];
    return Scaffold(
      appBar: AppBar(
          title: const Text('Регистрация'),
          leading: IconButton(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Создать аккаунт покупателя',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 18),
                      TextFormField(
                          controller: _name,
                          decoration:
                              const InputDecoration(labelText: 'Имя и фамилия'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Укажите имя'
                              : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _username,
                          decoration: const InputDecoration(labelText: 'Логин'),
                          validator: (v) => v == null ||
                                  !RegExp(r'^[a-zA-Z0-9_.-]{3,32}$').hasMatch(v)
                              ? '3–32 символа: латиница, цифры, . _ -'
                              : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) => v == null ||
                                  !RegExp(r'^\S+@\S+\.\S+$').hasMatch(v)
                              ? 'Введите корректный email'
                              : null),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        onChanged: (_) => setState(() => _error = null),
                        decoration: InputDecoration(
                            labelText: 'Пароль',
                            suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off))),
                        validator: (v) => v == null ||
                                v.length < 8 ||
                                !v.contains(RegExp(r'\d')) ||
                                !v.contains(RegExp(r'[^A-Za-z0-9]'))
                            ? 'Нужно 8+ символов, цифра и спецсимвол'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < checks.length; i++)
                        Row(children: [
                          Icon(
                              checks[i]
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: checks[i] ? Colors.green : Colors.grey,
                              size: 18),
                          const SizedBox(width: 8),
                          Text([
                            'Не менее 8 символов',
                            'Есть цифра',
                            'Есть специальный символ'
                          ][i])
                        ]),
                      if (_error != null)
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: auth.busy
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                try {
                                  await auth.register(
                                      username: _username.text,
                                      password: _password.text,
                                      email: _email.text,
                                      fullName: _name.text);
                                  if (context.mounted) context.go('/');
                                } catch (e) {
                                  if (mounted) {
                                    setState(() => _error = authError(e));
                                  }
                                }
                              },
                        child: auth.busy
                            ? const CircularProgressIndicator()
                            : const Text('Зарегистрироваться'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Доступ запрещён')),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.gpp_bad_outlined,
                      size: 72, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Недостаточно прав (403)',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Text('Ваша роль не позволяет открыть эту страницу.'),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Text('На главную')),
                ]))),
      );
}
