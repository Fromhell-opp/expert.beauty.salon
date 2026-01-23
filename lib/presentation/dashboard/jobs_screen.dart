import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  Future<String?> _mySalonSlug() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data();
    // ✅ у тебя в users хранится salonId / salonSlug — если у тебя другое имя, скажи
    final salonId = (data?['salonId'] as String?) ?? (data?['salonSlug'] as String?);
    return salonId;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _mySalonSlug(),
      builder: (context, slugSnap) {
        if (slugSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final salonSlug = slugSnap.data;
        if (salonSlug == null || salonSlug.isEmpty) {
          return const Center(child: Text('Не найден salonId у текущего пользователя'));
        }

        final q = FirebaseFirestore.instance
            .collection('salons')
            .doc(salonSlug)
            .collection('services')
            .orderBy('createdAt', descending: true);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Услуги',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                          return const Center(
                            child: Text('Пока нет услуг. Добавь первую услугу в Firestore.'),
                          );
                        }

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final d = docs[i].data();
                            final name = (d['name'] ?? '').toString();
                            final category = (d['category'] ?? '').toString();
                            final price = (d['price'] ?? '').toString();
                            final duration = (d['duration'] ?? '').toString();
                            final active = (d['active'] as bool?) ?? true;

                            return Card(
                              child: ListTile(
                                title: Text(name.isEmpty ? 'Без названия' : name),
                                subtitle: Text('Категория: $category • $duration мин • $price'),
                                trailing: Chip(
                                  label: Text(active ? 'active' : 'off'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
