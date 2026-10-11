import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pet_shop_app/core/api_exceptions.dart';
import 'package:pet_shop_app/models/models.dart';
import 'package:pet_shop_app/repositories/repositories.dart';

class MockDio extends Mock implements Dio {
  Future<Response<dynamic>> Function(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  })? getHandler;

  Future<Response<dynamic>> Function(
    String path, {
    Object? data,
  })? postHandler;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final handler = getHandler;
    if (handler == null) {
      throw StateError('Для GET $path не настроен обработчик');
    }
    return await handler(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ) as Response<T>;
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final handler = postHandler;
    if (handler == null) {
      throw StateError('Для POST $path не настроен обработчик');
    }
    return await handler(path, data: data) as Response<T>;
  }
}

void main() {
  late MockDio dio;
  late ProductRepository repo;

  setUp(() {
    dio = MockDio();
    repo = ProductRepository(dio);
  });

  Response<dynamic> response(
    Object data, {
    int status = 200,
  }) {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: 'products'),
      statusCode: status,
      data: data,
    );
  }

  Map<String, dynamic> productJson({
    int id = 1,
    String name = 'Food',
    String sku = 'F-1',
    double price = 10,
    int stock = 5,
    String description = 'desc',
  }) {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'brandId': 1,
      'categoryIds': [1],
      'supplierIds': [1],
      'price': price,
      'stock': stock,
      'description': description,
      'deletedAt': null,
    };
  }

  Product testProduct({String sku = 'T-1'}) {
    return Product(
      id: 0,
      name: 'Toy',
      sku: sku,
      brandId: 1,
      categoryIds: const [2],
      supplierIds: const [1],
      price: 8.5,
      stock: 4,
      description: 'toy',
    );
  }

  test('разбирает постраничный ответ сервера', () async {
    dio.getHandler = (path, {queryParameters, cancelToken}) async {
      expect(path, 'products');
      return response({
        'items': [productJson()],
        'page': 2,
        'size': 10,
        'total': 21,
        'totalPages': 3,
      });
    };

    final result = await repo.find(const ListQuery(page: 2));

    expect(result.page, 2);
    expect(result.total, 21);
    expect(result.items.single.sku, 'F-1');
  });

  test('передаёт JSON при создании товара', () async {
    Map<String, dynamic>? sentData;

    dio.postHandler = (path, {data}) async {
      expect(path, 'products');
      sentData = data as Map<String, dynamic>;
      return response(
        productJson(
          id: 10,
          name: 'Toy',
          sku: 'T-10',
          price: 8.5,
          stock: 4,
          description: 'toy',
        ),
        status: 201,
      );
    };

    await repo.create(testProduct(sku: 'T-10'));

    expect(sentData, isNotNull);
    expect(sentData!['sku'], 'T-10');
    expect(sentData!['name'], 'Toy');
  });

  test('422 превращается в ValidationException', () async {
    dio.postHandler = (path, {data}) async {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: response({
          'message': 'Ошибка валидации',
          'errors': {'sku': 'SKU уже занят'},
        }, status: 422),
      );
    };

    await expectLater(
      repo.create(testProduct()),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.errors['sku'],
          'sku',
          'SKU уже занят',
        ),
      ),
    );
  });

  test('сетевой сбой чтения повторяется не более трёх раз', () async {
    var calls = 0;

    dio.getHandler = (path, {queryParameters, cancelToken}) async {
      calls++;
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
      );
    };

    await expectLater(
      repo.find(const ListQuery()),
      throwsA(isA<NetworkException>()),
    );

    expect(calls, 3);
  });

  test('сетевой сбой записи не повторяется', () async {
    var calls = 0;

    dio.postHandler = (path, {data}) async {
      calls++;
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
      );
    };

    await expectLater(
      repo.create(testProduct()),
      throwsA(isA<NetworkException>()),
    );

    expect(calls, 1);
  });

  test('поиск отправляет параметры фильтрации, сортировки и страницы',
      () async {
    dio.getHandler = (path, {queryParameters, cancelToken}) async {
      expect(queryParameters, isNotNull);
      expect(queryParameters!['search'], 'корм');
      expect(queryParameters['filter'], '2');
      expect(queryParameters['sort'], 'price,desc');
      expect(queryParameters['page'], 2);
      expect(queryParameters['size'], 25);

      return response({
        'items': [],
        'page': 2,
        'size': 25,
        'total': 0,
        'totalPages': 1,
      });
    };

    await repo.find(
      const ListQuery(
        search: 'корм',
        filter: '2',
        sortField: 'price',
        sortAscending: false,
        page: 2,
        size: 25,
      ),
    );
  });
}
