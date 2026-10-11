class Supplier {
  final int id;
  final String name;
  final int brandId;
  final String email;
  final String phone;
  final String description;
  final DateTime? deletedAt;
  const Supplier(
      {required this.id,
      required this.name,
      required this.brandId,
      required this.email,
      required this.phone,
      required this.description,
      this.deletedAt});
  bool get isDeleted => deletedAt != null;
  Supplier copyWith(
          {String? name,
          int? brandId,
          String? email,
          String? phone,
          String? description,
          DateTime? deletedAt,
          bool clearDeletedAt = false}) =>
      Supplier(
          id: id,
          name: name ?? this.name,
          brandId: brandId ?? this.brandId,
          email: email ?? this.email,
          phone: phone ?? this.phone,
          description: description ?? this.description,
          deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt));
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brandId': brandId,
        'email': email,
        'phone': phone,
        'description': description,
        'deletedAt': deletedAt?.toIso8601String()
      };
  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
      id: j['id'] is int
          ? j['id'] as int
          : int.tryParse('${j['id'] ?? 0}') ?? 0,
      name: j['name']?.toString() ?? '',
      brandId: j['brandId'] is int
          ? j['brandId'] as int
          : int.tryParse('${j['brandId'] ?? 0}') ?? 0,
      email: j['email']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      deletedAt: j['deletedAt'] == null
          ? null
          : DateTime.tryParse(j['deletedAt'].toString()));
}
