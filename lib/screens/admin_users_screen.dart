
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<AppUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthNotifier>().loadUsers();
  }

  void _reload() {
    setState(() {
      _future = context.read<AuthNotifier>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Пользователи и роли'),
          actions: [
            IconButton(
              tooltip: 'Обновить',
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'На главную',
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
            ),
          ],
        ),
        body: FutureBuilder<List<AppUser>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Не удалось загрузить пользователей. '
                    'Возможно, сервер запретил операцию (403).\n'
                    '${snapshot.error}',
                  ),
                ),
              );
            }

            final users = snapshot.data ?? [];

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final user = users[index];

                return ListTile(
                  title: Text(user.fullName),
                  subtitle: Text(
                    '${user.username} · ${user.email}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        value: user.role,
                        items: const [
                          DropdownMenuItem(
                            value: 'customer',
                            child: Text('Покупатель'),
                          ),
                          DropdownMenuItem(
                            value: 'manager',
                            child: Text('Менеджер'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Администратор'),
                          ),
                        ],
                        onChanged: (role) async {
                          if (role == null) return;

                          try {
                            await context
                                .read<AuthNotifier>()
                                .updateUser(
                                  id: user.id,
                                  role: role,
                                );

                            if (context.mounted) {
                              _reload();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text('$e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      Switch(
                        value: user.active,
                        onChanged: (active) async {
                          try {
                            await context
                                .read<AuthNotifier>()
                                .updateUser(
                                  id: user.id,
                                  active: active,
                                );

                            if (context.mounted) {
                              _reload();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text('$e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
}
