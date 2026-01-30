import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_master_screen.dart';

class BookingServiceScreen extends StatelessWidget {
  final String salonId; // ✅ теперь реально используется
  final String slug;    // оставим для UI
  final String category;

  const BookingServiceScreen({
    super.key,
    required this.salonId,
    required this.slug,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (category) {
      'manicure' => 'Маникюр',
      'pedicure' => 'Педикюр',
      'lashes' => 'Ресницы',
      'brows' => 'Брови',
      'hair' => 'Волосы',
      'massage' => 'Массаж',
      _ => 'Услуги',
    };

    return Scaffold(
      appBar: AppBar(title: Text('$title • $slug')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('salons')
            .doc(salonId)
            .collection('services')
            .where('active', isEqualTo: true)
            .where('category', isEqualTo: category)
            .orderBy('createdAt', descending: true)
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
                'Услуг нет для категории: $category\n\n'
                    'Проверь в Firestore:\n'
                    'salons/$salonId/services\n'
                    'category="$category"\nactive=true',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final name = (data['name'] ?? 'Услуга').toString();

              final durationMin = (data['durationMin'] is int)
                  ? data['durationMin'] as int
                  : int.tryParse('${data['durationMin'] ?? ''}') ?? 60;

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('$durationMin мин'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingMasterScreen(
                          salonId: salonId,
                          slug: slug,
                          category: category,
                          serviceName: name,
                          duration: durationMin,
                        ),
                      ),
                    );
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
