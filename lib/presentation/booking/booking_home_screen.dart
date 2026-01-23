import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class BookingHomeScreen extends StatelessWidget {
  final String slug;
  const BookingHomeScreen({super.key, required this.slug});

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findSalon() async {
    final db = FirebaseFirestore.instance;

    // ✅ 1) пробуем как docId = slug (у тебя так и есть: salons/expert312)
    final doc = await db.collection('salons').doc(slug).get();
    if (doc.exists) return doc;

    // ✅ 2) fallback: если вдруг позже будешь хранить поле slug
    final q = await db.collection('salons').where('slug', isEqualTo: slug).limit(1).get();
    if (q.docs.isEmpty) return null;

    return q.docs.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      future: _findSalon(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Ошибка: ${snap.error}')));
        }

        final salonDoc = snap.data;
        if (salonDoc == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Запись')),
            body: Center(
              child: Text('Салон не найден\nslug=$slug', textAlign: TextAlign.center),
            ),
          );
        }

        final salonId = salonDoc.id;
        final data = salonDoc.data() ?? {};
        final salonName = (data['name'] as String?) ?? slug;
        final city = (data['city'] as String?) ?? '';

        return Scaffold(
          appBar: AppBar(title: Text('Запись • $salonName')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          salonName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        if (city.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(city, textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: () {
                            // ✅ Переходим на экран категорий через роут
                            // Тебе нужно добавить этот route (см ниже в пункте B)
                            context.push('/s/$slug/categories');
                          },
                          child: const Text('Выбрать категорию услуг'),
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
