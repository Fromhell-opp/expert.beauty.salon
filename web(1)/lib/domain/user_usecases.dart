import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';

class UserUseCases {
  final UserRepository repository;

  UserUseCases(this.repository);

  User? login(String phone) {
    return repository.getUserByPhone(phone);
  }

  void register(User user) {
    repository.addUser(user);
  }
}

