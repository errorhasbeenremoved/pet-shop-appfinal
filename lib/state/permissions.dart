enum ShopRole { customer, manager, admin }

enum ShopOperation {
  viewCatalog,
  viewCustomers,
  editCatalog,
  softDelete,
  restore,
  hardDelete,
  manageUsers,
  viewStatistics
}

class PermissionPolicy {
  static bool allows(ShopRole role, ShopOperation op) => switch (op) {
        ShopOperation.viewCatalog => true,
        ShopOperation.viewCustomers ||
        ShopOperation.editCatalog ||
        ShopOperation.softDelete =>
          role == ShopRole.manager || role == ShopRole.admin,
        ShopOperation.restore ||
        ShopOperation.hardDelete ||
        ShopOperation.manageUsers ||
        ShopOperation.viewStatistics =>
          role == ShopRole.admin,
      };
}
