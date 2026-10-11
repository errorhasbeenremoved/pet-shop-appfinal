import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/models.dart';

abstract class CrudRepository<T> {
  Future<PageResult<T>> find(ListQuery query);
  Future<T?> findById(int id);
  Future<T> create(T item);
  Future<T> update(T item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<bool> existsBy(String field, Object value, {int? exceptId});
  void cancelPendingReads();
}

class ApiCrudRepository<T> implements CrudRepository<T> {
  final Dio dio;
  final String path;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  CancelToken? _readToken;

  ApiCrudRepository(this.dio, this.path, this.fromJson, this.toJson);

  Map<String, dynamic> _query(ListQuery q) => {
        if (q.search.isNotEmpty) 'search': q.search,
        if (q.sortField != 'name' || !q.sortAscending)
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'deleted': '1',
        if (q.filter != null && q.filter!.isNotEmpty) 'filter': q.filter,
      };

  Map<String, dynamic> _unwrap(Object? data) {
    if (data is Map && data['item'] is Map) {
      return Map<String, dynamic>.from(data['item'] as Map);
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Некорректный ответ сервера');
  }

  @override
  void cancelPendingReads() {
    _readToken?.cancel('Устаревший запрос');
    _readToken = null;
  }

  @override
  Future<PageResult<T>> find(ListQuery q) async {
    cancelPendingReads();

    final token = CancelToken();
    _readToken = token;

    try {
      final response = await apiGuard(
        () => dio.get(
          path,
          queryParameters: _query(q),
          cancelToken: token,
        ),
        retries: 2,
      );

      if (token.isCancelled) {
        throw DioException(
          requestOptions: response.requestOptions,
          type: DioExceptionType.cancel,
        );
      }

      final data = response.data;

      if (data is! Map) {
        throw const FormatException('Некорректный формат списка');
      }

      final raw = data['items'];

      if (raw is! List) {
        throw const FormatException('В ответе нет массива items');
      }

      final List<T> items = raw
          .whereType<Map>()
          .map<T>(
            (item) => fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      return PageResult<T>(
        items: items,
        page: int.tryParse('${data['page'] ?? q.page}') ?? q.page,
        size: int.tryParse('${data['size'] ?? q.size}') ?? q.size,
        total: int.tryParse('${data['total'] ?? items.length}') ?? items.length,
      );
    } finally {
      if (identical(_readToken, token)) {
        _readToken = null;
      }
    }
  }

  @override
  Future<T?> findById(int id) async {
    try {
      final response = await apiGuard(() => dio.get('$path/$id'), retries: 2);
      return fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<T> create(T item) async {
    final response = await apiGuard(() => dio.post(path, data: toJson(item)));
    return fromJson(_unwrap(response.data));
  }

  @override
  Future<T> update(T item) async {
    final id = _id(toJson(item));
    final response =
        await apiGuard(() => dio.put('$path/$id', data: toJson(item)));
    return fromJson(_unwrap(response.data));
  }

  @override
  Future<void> softDelete(int id) async {
    await apiGuard(() => dio.delete('$path/$id'));
  }

  @override
  Future<void> hardDelete(int id) async {
    await apiGuard(
      () => dio.delete('$path/$id', queryParameters: const {'hard': true}),
    );
  }

  @override
  Future<void> restore(int id) async {
    await apiGuard(() => dio.patch('$path/$id/restore'));
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final response = await apiGuard(
      () => dio.post('$path/bulk-delete', data: {'ids': ids}),
    );
    final data = response.data;
    return data is Map
        ? int.tryParse('${data['count'] ?? ids.length}') ?? ids.length
        : ids.length;
  }

  @override
  Future<bool> existsBy(String field, Object value, {int? exceptId}) async {
    final q = <String, dynamic>{'field': field, 'value': value.toString()};
    if (exceptId != null) q['exceptId'] = exceptId;
    final response = await apiGuard(
      () => dio.get('$path/exists', queryParameters: q),
      retries: 2,
    );
    final data = response.data;
    return data is Map && data['exists'] == true;
  }

  int _id(Map<String, dynamic> data) => int.tryParse('${data['id'] ?? 0}') ?? 0;
}

class ReferenceCache {
  final BrandRepository brands;
  final CategoryRepository categories;
  final SupplierRepository suppliers;
  Future<PageResult<Brand>>? _brands;
  Future<PageResult<Category>>? _categories;
  Future<PageResult<Supplier>>? _suppliers;

  ReferenceCache(this.brands, this.categories, this.suppliers);

  Future<PageResult<Brand>> getBrands() =>
      _brands ??= brands.find(const ListQuery(size: 100));

  Future<PageResult<Category>> getCategories() =>
      _categories ??= categories.find(const ListQuery(size: 100));

  Future<PageResult<Supplier>> getSuppliers() =>
      _suppliers ??= suppliers.find(const ListQuery(size: 100));

  void clear() {
    _brands = null;
    _categories = null;
    _suppliers = null;
  }
}

class ProductRepository extends ApiCrudRepository<Product> {
  ProductRepository(Dio dio)
      : super(dio, 'products', Product.fromJson, (e) => e.toJson());
}

class BrandRepository extends ApiCrudRepository<Brand> {
  BrandRepository(Dio dio)
      : super(dio, 'brands', Brand.fromJson, (e) => e.toJson());
}

class CategoryRepository extends ApiCrudRepository<Category> {
  CategoryRepository(Dio dio)
      : super(dio, 'categories', Category.fromJson, (e) => e.toJson());
}

class SupplierRepository extends ApiCrudRepository<Supplier> {
  SupplierRepository(Dio dio)
      : super(dio, 'suppliers', Supplier.fromJson, (e) => e.toJson());
}

class CustomerRepository extends ApiCrudRepository<Customer> {
  CustomerRepository(Dio dio)
      : super(dio, 'customers', Customer.fromJson, (e) => e.toJson());
}
