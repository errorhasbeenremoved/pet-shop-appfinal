import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop_app/state/permissions.dart';

void main() {
  test(
      'покупатель может смотреть каталог',
      () => expect(
          PermissionPolicy.allows(ShopRole.customer, ShopOperation.viewCatalog),
          isTrue));
  test(
      'покупатель не может менять каталог',
      () => expect(
          PermissionPolicy.allows(ShopRole.customer, ShopOperation.editCatalog),
          isFalse));
  test(
      'менеджер может управлять каталогом',
      () => expect(
          PermissionPolicy.allows(ShopRole.manager, ShopOperation.editCatalog),
          isTrue));
  test(
      'менеджер не может физически удалять записи',
      () => expect(
          PermissionPolicy.allows(ShopRole.manager, ShopOperation.hardDelete),
          isFalse));
  test(
      'только администратор управляет пользователями',
      () => expect(
          PermissionPolicy.allows(ShopRole.admin, ShopOperation.manageUsers),
          isTrue));
  test(
      'покупатель не видит список клиентов',
      () => expect(
          PermissionPolicy.allows(
              ShopRole.customer, ShopOperation.viewCustomers),
          isFalse));
  test(
      'только администратор восстанавливает записи',
      () => expect(
          PermissionPolicy.allows(ShopRole.admin, ShopOperation.restore),
          isTrue));
}
