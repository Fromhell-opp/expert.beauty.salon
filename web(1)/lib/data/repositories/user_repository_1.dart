import '../models/user.dart';

class UserRepository {
  final List<User> _users = [];

  void addUser(User user) {
    _users.add(user);
  }

  User? getUserByPhone(String phone) {
    final filtered = _users.where((u) => u.phone == phone);
    return filtered.isNotEmpty ? filtered.first : null;
  }
}
