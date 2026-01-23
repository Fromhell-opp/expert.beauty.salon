import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ВХОД (Email/Password)
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user;
    if (user == null) throw Exception('Не удалось войти');
    return user;
  }

  /// РЕГИСТРАЦИЯ (Email/Password)
  Future<User> registerWithEmailAndPassword(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user;
    if (user == null) throw Exception('Не удалось зарегистрироваться');
    return user;
  }

  /// ВХОД через Google
  Future<User> signInWithGoogle() async {
    // запускаем Google аккаунт-пикер
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Вход отменён');
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);

    final user = userCred.user;
    if (user == null) throw Exception('Не удалось войти через Google');
    return user;
  }

  /// ВЫХОД
  Future<void> signOut() async {
    // если входили через Google — разлогинимся и там тоже
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
