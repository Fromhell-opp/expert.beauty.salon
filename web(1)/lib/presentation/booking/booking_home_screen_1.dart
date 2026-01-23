import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_category_screen.dart';

class BookingHomeScreen extends StatelessWidget {
  final String slug;
  const BookingHomeScreen({super.key, required this.slug});

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findSalonBySlug() async {
    final q = await FirebaseFirestore.instance
        .collection('salons')
        .where('slug', isEqualTo: slug)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;
    return q.docs.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      future: _findSalonBySlug(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Ошибка: ${snap.error}')),
          );
        }

        final salonDoc = snap.data;
        if (salonDoc == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Запись')),
            body: Center(
              child: Text(
                'Салон не найден\nslug=$slug',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final salonId = salonDoc.id;
        final data = salonDoc.data() ?? {};
        final salonName = (data['name'] as String?) ?? slug;

        return Scaffold(
          appBar: AppBar(title: Text('Запись • $salonName')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Онлайн запись',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('Салон: $salonName'),
                const SizedBox(height: 8),
                Text('slug: $slug'),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingCategoryScreen(
                          salonId: salonId,
                          slug: slug,
                        ),
                      ),
                    );
                  },
                  child: const Text('Выбрать категорию услуг'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
