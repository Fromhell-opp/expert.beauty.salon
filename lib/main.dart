import 'package:beauty_salon_app/presentation/admin/clients_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';

// AUTH
import 'presentation/auth/create_salon_screen.dart';
import 'presentation/auth/welcome_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/booking/booking_category_screen.dart';
import 'presentation/booking/booking_service_screen.dart';
import 'presentation/admin/masters_screen.dart';



// MAIN
import 'presentation/main_screen.dart';

// BOOKING (клиент по ссылке)
import 'presentation/booking/booking_home_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      debugLogDiagnostics: true,

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

      routes: [
        /// ✅ КЛИЕНТСКАЯ ССЫЛКА
        /// пример: https://site/#/s/expert312

        GoRoute(
          path: '/s/:slug',
          builder: (context, state) {
            final slug = state.pathParameters['slug']!;
            debugPrint('✅ OPEN BOOKING slug=$slug');
            return BookingHomeScreen(slug: slug);
          },
        ),
        GoRoute(
          path: '/masters',
          builder: (context, state) => const MastersScreen(salonId: '',),
        ),


        /// ✅ Главная точка входа
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthGate(),
        ),

        /// ✅ AUTH routes (для кнопок WelcomeScreen)
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

        /// ✅ MAIN (после входа)
        GoRoute(
          path: '/main',
          builder: (context, state) => const MainScreen(),
        ),

        /// ✅ OWNER/ADMIN: список клиентов
        GoRoute(
          path: '/clients',
          builder: (context, state) => const ClientsScreen(),
        ),
        GoRoute(
          path: '/s/:slug/categories',
          builder: (context, state) {
            final slug = state.pathParameters['slug']!;
            return BookingCategoryScreen(slug: slug, salonId: '',);
          },
        ),
        GoRoute(
          path: '/s/:slug/services/:category',
          builder: (context, state) {
            final slug = state.pathParameters['slug']!;
            final category = state.pathParameters['category']!;
            return BookingServiceScreen(slug: slug, category: category, salonId: '',);
          },
        ),

      ],
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

      ),
      routerConfig: router,
    );
  }
}

/// 🔐 AUTH GATE
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _routeUser(User user) async {
    final db = FirebaseFirestore.instance;
    final snap = await db.collection('users').doc(user.uid).get();

    final data = snap.data();
    final role = (data?['role'] as String?) ?? 'client';
    final salonId = (data?['salonId'] as String?);

    // owner/admin без салона → создать салон
    if ((role == 'owner' || role == 'admin') &&
        (salonId == null || salonId.isEmpty)) {
      return const CreateSalonScreen();
    }

    return const MainScreen();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) return const WelcomeScreen();

        return FutureBuilder<Widget>(
          future: _routeUser(user),
          builder: (context, routeSnap) {
            if (routeSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (routeSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Ошибка: ${routeSnap.error}'),
                ),
              );
            }
            return routeSnap.data ?? const MainScreen();
          },
        );
      },
    );
  }
}
