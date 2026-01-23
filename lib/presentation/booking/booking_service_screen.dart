import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_master_screen.dart';

class BookingServiceScreen extends StatelessWidget {
  final String salonId; // можешь пока не использовать, но оставим
  final String slug;    // это salonSlug, например "expert312"
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
      _ => 'Услуги',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('$title • $slug'),
      ),

      // ✅ ВОТ ТУТ ВСТАВЛЕН .where('salonSlug', isEqualTo: slug)
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('salonSlug', isEqualTo: slug)
            .where('category', isEqualTo: category)
            .where('active', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'Услуги пока не добавлены\n\nПроверь в Firestore:\nservices -> salonSlug="$slug"\ncategory="$category"\nactive=true',
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
              final duration = (data['duration'] ?? 0);
              final durationInt =
              duration is int ? duration : int.tryParse(duration.toString()) ?? 0;

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('$durationInt мин'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingMasterScreen(
                          slug: slug,
                          category: category,
                          serviceName: name,
                          duration: durationInt,
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
