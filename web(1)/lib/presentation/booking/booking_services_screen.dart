import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingServicesScreen extends StatelessWidget {
  final String salonId;
  final String slug;
  final String categoryKey; // manicure/pedicure/lashes/brows
  final String categoryTitle;

  const BookingServicesScreen({
    super.key,
    required this.salonId,
    required this.slug,
    required this.categoryKey,
    required this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('salons')
        .doc(salonId)
        .collection('services')
        .where('category', isEqualTo: categoryKey)
        .where('active', isEqualTo: true)
        .orderBy('sort');

    return Scaffold(
      appBar: AppBar(title: Text('Запись • $categoryTitle')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text('Ошибка: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Нет услуг в этой категории',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('category=$categoryKey'),
                  const SizedBox(height: 12),
                  const Text('Добавь документы в:'),
                  Text('salons/$salonId/services'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final name = (d['name'] as String?) ?? 'Без названия';
              final price = (d['price'] as num?)?.toInt();
              final duration = (d['durationMin'] as num?)?.toInt();

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text([
                    if (duration != null) '$duration мин',
                    if (price != null) '$price сом',
                  ].join(' • ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // ✅ следующий шаг: выбор мастера и времени
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Выбрана услуга: $name')),
                    );

                    // позже сделаем:
                    // Navigator.push(... BookingMastersScreen(serviceId: docs[i].id, ...));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
