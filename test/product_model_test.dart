import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop_app/models/product.dart';
import 'package:pet_shop_app/models/page_result.dart';

void main() {
  test('Product.fromJson tolerates missing fields', () {
    final product = Product.fromJson({'id': '7'});
    expect(product.id, 7);
    expect(product.name, '');
    expect(product.categoryIds, isEmpty);
    expect(product.price, 0);
  });
  test('Product JSON round trip keeps key values', () {
    const source = Product(
        id: 3,
        name: 'Корм',
        sku: 'FOOD-3',
        brandId: 2,
        categoryIds: [1, 4],
        supplierIds: [8],
        price: 19.5,
        stock: 7,
        description: 'Для собак');
    final copy = Product.fromJson(source.toJson());
    expect(copy.name, source.name);
    expect(copy.categoryIds, [1, 4]);
    expect(copy.price, 19.5);
    expect(copy.stock, 7);
  });
  test('PageResult reports at least one page for empty result', () {
    const result = PageResult<String>(items: [], page: 1, size: 10, total: 0);
    expect(result.totalPages, 1);
  });
}
