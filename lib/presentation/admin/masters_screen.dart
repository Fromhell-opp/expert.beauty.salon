import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MastersScreen extends StatelessWidget {
  final String salonId;

  const MastersScreen({super.key, required this.salonId});

  @override
  Widget build(BuildContext context) {
    if (salonId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Salon ID not found')),
      );
    }

    final mastersStream = FirebaseFirestore.instance
        .collection('salons')
        .doc(salonId)
        .collection('masters')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мастера'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: mastersStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text('Ошибка: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Мастеров пока нет\nДобавь первого',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Без имени';
              final active = data['active'] ?? false;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      active ? Icons.person : Icons.person_off,
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text(active ? 'Работает' : 'Отключён'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Откроем график мастера: $name'),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Следующий шаг: добавление мастера')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
