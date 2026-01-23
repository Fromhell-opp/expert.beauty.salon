import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  bool _loading = false;

  Future<void> _register() async {
    if (_email.text.isEmpty || _password.text.isEmpty || _name.text.isEmpty) {
      _show('Заполни все поля');
      return;
    }

    try {
      setState(() => _loading = true);

      // 1️⃣ Firebase Auth
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = cred.user!.uid;

      // 🔴 ВРЕМЕННО: клиент всегда привязан к expert312
      // позже сделаем выбор салона
      const salonSlug = 'expert312';

      // 2️⃣ users/{uid}
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': 'client',
        'salonSlug': salonSlug,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3️⃣ salons/{slug}/clients
      await FirebaseFirestore.instance
          .collection('salons')
          .doc(salonSlug)
          .collection('clients')
          .add({
        'uid': uid,
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) context.go('/main');
    } catch (e) {
      _show(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: SizedBox(
          width: 420,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Имя'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Пароль'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Зарегистрироваться'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
