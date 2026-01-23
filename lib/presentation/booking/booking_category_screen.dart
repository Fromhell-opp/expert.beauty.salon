import 'package:flutter/material.dart';
import 'booking_service_screen.dart';

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
      appBar: AppBar(
        title: const Text('Онлайн запись'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CategoryTile(
            title: 'Маникюр',
            icon: Icons.back_hand,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingServiceScreen(
                    salonId: salonId,
                    slug: slug,
                    category: 'manicure',
                  ),
                ),
              );
            },
          ),

          _CategoryTile(
            title: 'Педикюр',
            icon: Icons.directions_walk,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingServiceScreen(
                    salonId: salonId,
                    slug: slug,
                    category: 'pedicure',
                  ),
                ),
              );
            },
          ),

          _CategoryTile(
            title: 'Ресницы',
            icon: Icons.visibility,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingServiceScreen(
                    salonId: salonId,
                    slug: slug,
                    category: 'lashes',
                  ),
                ),
              );
            },
          ),

          _CategoryTile(
            title: 'Брови',
            icon: Icons.face,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingServiceScreen(
                    salonId: salonId,
                    slug: slug,
                    category: 'brows',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
