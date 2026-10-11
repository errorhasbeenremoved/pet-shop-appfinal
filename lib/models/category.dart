class Category {
  final int id;
  final String name;
  final int brandId;
  final String description;
  final DateTime? deletedAt;
  const Category(
      {required this.id,
      required this.name,
      required this.brandId,
      required this.description,
      this.deletedAt});
  bool get isDeleted => deletedAt != null;
  Category copyWith(
          {String? name,
          int? brandId,
          String? description,
          DateTime? deletedAt,
          bool clearDeletedAt = false}) =>
      Category(
          id: id,
          name: name ?? this.name,
          brandId: brandId ?? this.brandId,
          description: description ?? this.description,
          deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt));
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brandId': brandId,
        'description': description,
        'deletedAt': deletedAt?.toIso8601String()
      };
  factory Category.fromJson(Map<String, dynamic> j) => Category(
      id: j['id'] is int
          ? j['id'] as int
          : int.tryParse('${j['id'] ?? 0}') ?? 0,
      name: j['name']?.toString() ?? '',
      brandId: j['brandId'] is int
          ? j['brandId'] as int
          : int.tryParse('${j['brandId'] ?? 0}') ?? 0,
      description: j['description']?.toString() ?? '',
      deletedAt: j['deletedAt'] == null
          ? null
          : DateTime.tryParse(j['deletedAt'].toString()));
}
