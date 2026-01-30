import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';

// AUTH
import 'presentation/auth/welcome_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/auth/create_salon_screen.dart';

// MAIN
import 'presentation/main_screen.dart';

// ADMIN
import 'presentation/admin/clients_screen.dart';
import 'presentation/admin/masters_screen.dart';
import 'presentation/admin/services_screen.dart';
import 'presentation/admin/bookings_screen.dart';
import 'presentation/admin/notifications_screen.dart';


// CLIENT BOOKING (по ссылке)
import 'presentation/booking/booking_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

/// 🔐 AUTH GATE: решает куда отправить пользователя после входа
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _routeUser(User user) async {
    final db = FirebaseFirestore.instance;
    final snap = await db.collection('users').doc(user.uid).get();
    final data = snap.data();

    final role = (data?['role'] as String?) ?? 'client';
    final salonId = (data?['salonId'] as String?) ?? '';

    // owner/admin без салона → создать салон
    if ((role == 'owner' || role == 'admin') && salonId.isEmpty) {
      return const CreateSalonScreen();
    }

    // всё остальное → MainScreen
    return const MainScreen();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snap.data;
        if (user == null) return const WelcomeScreen();

        return FutureBuilder<Widget>(
          future: _routeUser(user),
          builder: (context, routeSnap) {
            if (routeSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (routeSnap.hasError) {
              return Scaffold(body: Center(child: Text('Ошибка: ${routeSnap.error}')));
            }
            return routeSnap.data ?? const MainScreen();
          },
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      debugLogDiagnostics: true,
      routes: [
        /// ✅ Главная точка входа (AuthGate)
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthGate(),
        ),

        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),

        /// ✅ AUTH routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => RegisterScreen(),
        ),
        GoRoute(
          path: '/create_salon',
          builder: (context, state) => const CreateSalonScreen(),
        ),

        /// ✅ MAIN
        GoRoute(
          path: '/main',
          builder: (context, state) => const MainScreen(),
        ),

        /// ✅ ADMIN routes
        GoRoute(
          path: '/clients',
          builder: (context, state) => const ClientsScreen(),
        ),
        GoRoute(
          path: '/masters',
          builder: (context, state) => const MastersScreen(), // salonId подтянем сами
        ),
        GoRoute(
          path: '/services',
          builder: (context, state) => const ServicesScreen(), // salonId подтянем сами
        ),
        GoRoute(
          path: '/bookings',
          builder: (context, state) => const BookingsScreen(), // salonId подтянем сами
        ),

        /// ✅ КЛИЕНТСКАЯ ССЫЛКА (по QR/ссылке)
        /// пример: /s/expert312
        GoRoute(
          path: '/s/:slug',
          builder: (context, state) {
            final slug = state.pathParameters['slug']!;
            return BookingHomeScreen(slug: slug);
          },
        ),
      ],

      errorBuilder: (context, state) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'ROUTE ERROR\n\nuri: ${state.uri}\nerror: ${state.error}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EXPERT Beauty Salon',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.pink,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(centerTitle: true),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      routerConfig: router,
    );
  }
}
