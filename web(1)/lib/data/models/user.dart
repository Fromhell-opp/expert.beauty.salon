enum UserRole { client, master, admin }

class User {
  final String id;
  final String name;
  final String phone;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });
}

