import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

class EntityListNotifier<T> extends ChangeNotifier {
  final CrudRepository<T> repository;
  ListQuery query;
  PageResult<T> result = PageResult<T>(
    items: <T>[],
    page: 1,
    size: 10,
    total: 0,
  );
  bool loading = true;
  String? error;
  final Set<int> selected = {};
  int _loadVersion = 0;

  EntityListNotifier(this.repository, {ListQuery? initialQuery})
      : query = initialQuery ?? const ListQuery();

  Future<void> load() async {
    final version = ++_loadVersion;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final next = await repository.find(query);
      if (version != _loadVersion) return;
      result = next;
    } catch (e) {
      if (version != _loadVersion) return;
      error = _friendlyError(e);
    } finally {
      if (version == _loadVersion) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> apply(ListQuery q) async {
    query = q;
    selected.clear();
    await load();
  }

  void toggle(int id) {
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    notifyListeners();
  }

  Future<void> softDelete(int id) async {
    await repository.softDelete(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await repository.hardDelete(id);
    await load();
  }

  Future<void> restore(int id) async {
    await repository.restore(id);
    await load();
  }

  Future<void> deleteSelected() async {
    if (selected.isEmpty) return;
    await repository.deleteMany(selected.toList());
    selected.clear();
    await load();
  }
}

String _friendlyError(Object error) {
  if (error is DioException && error.response == null) {
    return 'Не удалось связаться с сервером. Проверьте подключение и адрес API, затем нажмите «Повторить».';
  }
  if (error is DioException && error.response?.statusCode == 403) {
    return 'Доступ запрещён (403). Для этой операции недостаточно прав.';
  }
  if (error is DioException && error.response?.statusCode == 500) {
    return 'На сервере произошла ошибка (500). Попробуйте повторить запрос позже.';
  }
  return 'Не удалось загрузить данные: $error';
}
