class Product {
  final int id;
  final String name;
  final String sku;
  final int brandId;
  final List<int> categoryIds;
  final List<int> supplierIds;
  final double price;
  final int stock;
  final String description;
  final DateTime? deletedAt;
  const Product(
      {required this.id,
      required this.name,
      required this.sku,
      required this.brandId,
      required this.categoryIds,
      required this.supplierIds,
      required this.price,
      required this.stock,
      required this.description,
      this.deletedAt});
  bool get isDeleted => deletedAt != null;
  Product copyWith(
          {String? name,
          String? sku,
          int? brandId,
          List<int>? categoryIds,
          List<int>? supplierIds,
          double? price,
          int? stock,
          String? description,
          DateTime? deletedAt,
          bool clearDeletedAt = false}) =>
      Product(
          id: id,
          name: name ?? this.name,
          sku: sku ?? this.sku,
          brandId: brandId ?? this.brandId,
          categoryIds: categoryIds ?? this.categoryIds,
          supplierIds: supplierIds ?? this.supplierIds,
          price: price ?? this.price,
          stock: stock ?? this.stock,
          description: description ?? this.description,
          deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt));
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'brandId': brandId,
        'categoryIds': categoryIds,
        'supplierIds': supplierIds,
        'price': price,
        'stock': stock,
        'description': description,
        'deletedAt': deletedAt?.toIso8601String()
      };
  factory Product.fromJson(Map<String, dynamic> j) => Product(
      id: j['id'] is int
          ? j['id'] as int
          : int.tryParse('${j['id'] ?? 0}') ?? 0,
      name: j['name']?.toString() ?? '',
      sku: j['sku']?.toString() ?? '',
      brandId: j['brandId'] is int
          ? j['brandId'] as int
          : int.tryParse('${j['brandId'] ?? 0}') ?? 0,
      categoryIds:
          (j['categoryIds'] is List ? j['categoryIds'] as List : const [])
              .map((e) => e is int ? e : int.tryParse('$e') ?? 0)
              .toList(),
      supplierIds:
          (j['supplierIds'] is List ? j['supplierIds'] as List : const [])
              .map((e) => e is int ? e : int.tryParse('$e') ?? 0)
              .toList(),
      price: j['price'] is num
          ? (j['price'] as num).toDouble()
          : double.tryParse('${j['price'] ?? 0}') ?? 0,
      stock: j['stock'] is int
          ? j['stock'] as int
          : int.tryParse('${j['stock'] ?? 0}') ?? 0,
      description: j['description']?.toString() ?? '',
      deletedAt: j['deletedAt'] == null
          ? null
          : DateTime.tryParse(j['deletedAt'].toString()));
}
