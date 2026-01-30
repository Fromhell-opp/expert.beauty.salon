import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingHomeScreen extends StatefulWidget {
  final String slug;
  const BookingHomeScreen({super.key, required this.slug});

  @override
  State<BookingHomeScreen> createState() => _BookingHomeScreenState();
}

class _BookingHomeScreenState extends State<BookingHomeScreen> {
  Future<void> _ensureAnon() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  Future<Map<String, dynamic>?> _loadSalonBySlug() async {
    await _ensureAnon();

    final db = FirebaseFirestore.instance;

    final slugDoc = await db.collection('slugs').doc(widget.slug).get();
    if (!slugDoc.exists) return null;

    final salonId = (slugDoc.data()?['salonId'] ?? '').toString();
    if (salonId.isEmpty) return null;

    final salonDoc = await db.collection('salons').doc(salonId).get();
    if (!salonDoc.exists) return null;

    return {
      'salonId': salonId,
      ...?salonDoc.data(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadSalonBySlug(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Ошибка: ${snap.error}')));
        }

        final data = snap.data;
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Онлайн-запись')),
            body: Center(child: Text('Салон не найден\nslug=${widget.slug}', textAlign: TextAlign.center)),
          );
        }

        final salonName = (data['name'] ?? widget.slug).toString();
        final city = (data['city'] ?? '').toString();
        final address = (data['address'] ?? '').toString();

        return Scaffold(
          appBar: AppBar(title: Text('Запись • $salonName')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(salonName, textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        if (city.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(city, textAlign: TextAlign.center),
                        ],
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(address, textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Дальше: категории/услуги/слоты')),
                            );
                          },
                          child: const Text('Выбрать услугу'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
