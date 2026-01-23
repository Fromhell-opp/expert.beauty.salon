import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingMasterScreen extends StatelessWidget {
  final String slug;       // salonSlug (например expert312)
  final String category;   // manicure / pedicure / lashes / brows
  final String serviceName;
  final int duration;

  const BookingMasterScreen({
    super.key,
    required this.slug,
    required this.category,
    required this.serviceName,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мастера • $slug'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('masters') // ищем мастеров в любых подколлекциях masters
            .where('salonSlug', isEqualTo: slug)
            .where('active', isEqualTo: true)
            .where('categories', arrayContains: category)
            .orderBy('rating', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'Нет мастеров для категории: $category\n(проверь salonSlug и categories)',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString();
              final rating = (data['rating'] ?? 0).toDouble();

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('⭐ $rating • $serviceName • $duration мин'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Выбран мастер: $name')),
                    );

                    // Следующий шаг: выбор даты/времени (сделаем после проверки мастеров)
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
