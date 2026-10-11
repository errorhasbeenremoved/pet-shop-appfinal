class LoyaltyCard {
  final String number;
  final String level;
  final int bonusPoints;
  const LoyaltyCard(
      {required this.number, required this.level, required this.bonusPoints});
  Map<String, dynamic> toJson() =>
      {'number': number, 'level': level, 'bonusPoints': bonusPoints};
  factory LoyaltyCard.fromJson(Map<String, dynamic> j) => LoyaltyCard(
      number: j['number']?.toString() ?? '',
      level: j['level']?.toString() ?? 'Bronze',
      bonusPoints: j['bonusPoints'] is int
          ? j['bonusPoints'] as int
          : int.tryParse('${j['bonusPoints'] ?? 0}') ?? 0);
}

class Customer {
  final int id;
  final String name;
  final String email;
  final String phone;
  final LoyaltyCard card;
  final DateTime? deletedAt;
  const Customer(
      {required this.id,
      required this.name,
      required this.email,
      required this.phone,
      required this.card,
      this.deletedAt});
  bool get isDeleted => deletedAt != null;
  Customer copyWith(
          {String? name,
          String? email,
          String? phone,
          LoyaltyCard? card,
          DateTime? deletedAt,
          bool clearDeletedAt = false}) =>
      Customer(
          id: id,
          name: name ?? this.name,
          email: email ?? this.email,
          phone: phone ?? this.phone,
          card: card ?? this.card,
          deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt));
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'card': card.toJson(),
        'deletedAt': deletedAt?.toIso8601String()
      };
  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
      id: j['id'] is int
          ? j['id'] as int
          : int.tryParse('${j['id'] ?? 0}') ?? 0,
      name: j['name']?.toString() ?? '',
      email: j['email']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      card: LoyaltyCard.fromJson(j['card'] is Map
          ? Map<String, dynamic>.from(j['card'] as Map)
          : const {}),
      deletedAt: j['deletedAt'] == null
          ? null
          : DateTime.tryParse(j['deletedAt'].toString()));
}
