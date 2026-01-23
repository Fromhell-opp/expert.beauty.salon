import 'package:flutter/material.dart';
import 'booking_categories.dart';
import 'booking_services_screen.dart';

class BookingCategoryScreen extends StatelessWidget {
  final String salonId;
  final String slug;

  const BookingCategoryScreen({
    super.key,
    required this.salonId,
    required this.slug,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Запись • $slug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите категорию',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.separated(
                itemCount: bookingCategories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = bookingCategories[i];

                  return Card(
                    child: ListTile(
                      leading: Text(c.emoji, style: const TextStyle(fontSize: 24)),
                      title: Text(c.title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingServicesScreen(
                              salonId: salonId,
                              slug: slug,
                              categoryKey: c.key,
                              categoryTitle: c.title,
                            ),
                          ),
                        );
                      },

                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
