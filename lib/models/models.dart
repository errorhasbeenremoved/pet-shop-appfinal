export 'brand.dart';
export 'category.dart';
export 'customer.dart';
export 'product.dart';
export 'supplier.dart';
export 'list_query.dart';
export 'page_result.dart';

import 'brand.dart';
import 'category.dart';
import 'customer.dart';
import 'product.dart';
import 'supplier.dart';

const seedBrands = <Brand>[
  Brand(
      id: 1,
      name: 'Royal Pet',
      country: 'Нидерланды',
      description: 'Корма и товары для собак и кошек.'),
  Brand(
      id: 2,
      name: 'Happy Tail',
      country: 'Германия',
      description: 'Повседневные товары для домашних животных.'),
  Brand(
      id: 3,
      name: 'PawCare',
      country: 'Польша',
      description: 'Гигиена и уход за питомцами.'),
  Brand(
      id: 4,
      name: 'AquaLife',
      country: 'Чехия',
      description: 'Аквариумистика и товары для рыб.'),
  Brand(
      id: 5,
      name: 'Feather Home',
      country: 'Франция',
      description: 'Корм и аксессуары для птиц.'),
];

const seedCategories = <Category>[
  Category(
      id: 1,
      name: 'Корм',
      brandId: 1,
      description: 'Полнорационные и специализированные корма.'),
  Category(
      id: 2,
      name: 'Игрушки',
      brandId: 1,
      description: 'Игрушки для домашних животных.'),
  Category(
      id: 3,
      name: 'Уход',
      brandId: 3,
      description: 'Шампуни, средства гигиены и ухода.'),
  Category(
      id: 4,
      name: 'Аквариумистика',
      brandId: 4,
      description: 'Товары для аквариумов и рыб.'),
  Category(
      id: 5,
      name: 'Птицы',
      brandId: 5,
      description: 'Корм и аксессуары для птиц.'),
  Category(
      id: 6,
      name: 'Лакомства',
      brandId: 2,
      description: 'Натуральные лакомства.'),
];

const seedSuppliers = <Supplier>[
  Supplier(
      id: 1,
      name: 'ZooSupply',
      brandId: 1,
      email: 'sales@zoosupply.lv',
      phone: '+37120000001',
      description: 'Оптовый поставщик кормов.'),
  Supplier(
      id: 2,
      name: 'PetTrade',
      brandId: 2,
      email: 'info@pettrade.lv',
      phone: '+37120000002',
      description: 'Поставщик товаров повседневного спроса.'),
  Supplier(
      id: 3,
      name: 'VetMarket',
      brandId: 3,
      email: 'orders@vetmarket.lv',
      phone: '+37120000003',
      description: 'Профессиональные средства ухода.'),
  Supplier(
      id: 4,
      name: 'AquaPartner',
      brandId: 4,
      email: 'sales@aquapartner.lv',
      phone: '+37120000004',
      description: 'Товары для аквариумистики.'),
  Supplier(
      id: 5,
      name: 'BirdWorld',
      brandId: 5,
      email: 'hello@birdworld.lv',
      phone: '+37120000005',
      description: 'Товары для птиц.'),
];

const seedProducts = <Product>[
  Product(
      id: 1,
      name: 'Royal Pet Adult',
      sku: 'RP-001',
      brandId: 1,
      categoryIds: [1],
      supplierIds: [1],
      price: 42.9,
      stock: 18,
      description: 'Сбалансированный корм для взрослых собак.'),
  Product(
      id: 2,
      name: 'Royal Pet Toy Ball',
      sku: 'RP-002',
      brandId: 1,
      categoryIds: [2],
      supplierIds: [1],
      price: 8.5,
      stock: 35,
      description: 'Прочная игрушка для активных игр.'),
  Product(
      id: 3,
      name: 'Happy Tail Beef',
      sku: 'HT-003',
      brandId: 2,
      categoryIds: [1, 6],
      supplierIds: [2],
      price: 18.9,
      stock: 32,
      description: 'Сухой корм с говядиной.'),
  Product(
      id: 4,
      name: 'PawCare Shampoo',
      sku: 'PC-004',
      brandId: 3,
      categoryIds: [3],
      supplierIds: [3],
      price: 9.9,
      stock: 24,
      description: 'Мягкий шампунь для регулярного ухода.'),
  Product(
      id: 5,
      name: 'AquaLife Flakes',
      sku: 'AQ-005',
      brandId: 4,
      categoryIds: [4],
      supplierIds: [4],
      price: 7.5,
      stock: 41,
      description: 'Хлопья для тропических рыб.'),
  Product(
      id: 6,
      name: 'Feather Home Mix',
      sku: 'FH-006',
      brandId: 5,
      categoryIds: [5],
      supplierIds: [5],
      price: 6.9,
      stock: 37,
      description: 'Зерновая смесь для попугаев.'),
  Product(
      id: 7,
      name: 'Happy Tail Dental',
      sku: 'HT-007',
      brandId: 2,
      categoryIds: [3, 6],
      supplierIds: [2],
      price: 11.4,
      stock: 26,
      description: 'Лакомство для ежедневного ухода.'),
  Product(
      id: 8,
      name: 'Royal Pet Treats',
      sku: 'RP-008',
      brandId: 1,
      categoryIds: [1, 6],
      supplierIds: [1],
      price: 12.3,
      stock: 44,
      description: 'Мясные лакомства для собак.'),
  Product(
      id: 9,
      name: 'AquaLife Granules',
      sku: 'AQ-009',
      brandId: 4,
      categoryIds: [4],
      supplierIds: [4],
      price: 10.2,
      stock: 29,
      description: 'Гранулированный корм для рыб.'),
  Product(
      id: 10,
      name: 'PawCare Ear Cleaner',
      sku: 'PC-010',
      brandId: 3,
      categoryIds: [3],
      supplierIds: [3],
      price: 8.4,
      stock: 26,
      description: 'Средство для деликатной очистки ушей.'),
  Product(
      id: 11,
      name: 'Feather Home Swing',
      sku: 'FH-011',
      brandId: 5,
      categoryIds: [5, 2],
      supplierIds: [5],
      price: 13.2,
      stock: 17,
      description: 'Жёрдочка-игрушка для птиц.'),
  Product(
      id: 12,
      name: 'Happy Tail Cat Food',
      sku: 'HT-012',
      brandId: 2,
      categoryIds: [1],
      supplierIds: [2],
      price: 28.7,
      stock: 22,
      description: 'Корм с лососем для взрослых кошек.'),
];

const seedCustomers = <Customer>[
  Customer(
      id: 1,
      name: 'Анна Петрова',
      email: 'anna@example.com',
      phone: '+37121111111',
      card:
          LoyaltyCard(number: 'CARD-1001', level: 'Silver', bonusPoints: 420)),
  Customer(
      id: 2,
      name: 'Иван Смирнов',
      email: 'ivan@example.com',
      phone: '+37122222222',
      card: LoyaltyCard(number: 'CARD-1002', level: 'Gold', bonusPoints: 980)),
  Customer(
      id: 3,
      name: 'Мария Озолина',
      email: 'maria@example.com',
      phone: '+37123333333',
      card:
          LoyaltyCard(number: 'CARD-1003', level: 'Bronze', bonusPoints: 120)),
];
