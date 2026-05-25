enum UserRole {
  customer('customer'),
  shopOwner('shop_owner'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.customer,
    );
  }
}
