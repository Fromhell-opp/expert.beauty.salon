import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';



class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'EXPERT Beauty Salon',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Онлайн запись на услуги салона',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 28),

                // ✅ Войти
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Войти'),
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ Регистрация клиента
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Регистрация клиента'),
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ Создать салон (владелец)
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => context.go('/create_salon'),
                    child: const Text('Создать салон (владелец)'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
