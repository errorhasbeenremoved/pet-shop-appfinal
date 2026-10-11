class Brand {
  final int id;
  final String name;
  final String country;
  final String description;
  final DateTime? deletedAt;
  const Brand(
      {required this.id,
      required this.name,
      required this.country,
      required this.description,
      this.deletedAt});
  bool get isDeleted => deletedAt != null;
  Brand copyWith(
          {String? name,
          String? country,
          String? description,
          DateTime? deletedAt,
          bool clearDeletedAt = false}) =>
      Brand(
          id: id,
          name: name ?? this.name,
          country: country ?? this.country,
          description: description ?? this.description,
          deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt));
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'description': description,
        'deletedAt': deletedAt?.toIso8601String()
      };
  factory Brand.fromJson(Map<String, dynamic> j) => Brand(
      id: j['id'] is int
          ? j['id'] as int
          : int.tryParse('${j['id'] ?? 0}') ?? 0,
      name: j['name']?.toString() ?? '',
      country: j['country']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      deletedAt: j['deletedAt'] == null
          ? null
          : DateTime.tryParse(j['deletedAt'].toString()));
}
