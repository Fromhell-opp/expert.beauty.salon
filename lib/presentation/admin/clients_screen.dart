import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  Future<String?> _getMySalonId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data();
    final salonId = data?['salonId'] as String?;
    if (salonId == null || salonId.isEmpty) return null;
    return salonId;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _clientsStream(String salonId) {
    return FirebaseFirestore.instance
        .collection('salons')
        .doc(salonId)
        .collection('clients')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getMySalonId(),
      builder: (context, salonSnap) {
        if (salonSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final salonId = salonSnap.data;
        if (salonId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Не найден salonId у текущего пользователя.\n'
                      'Зайди как owner/admin и проверь users/{uid}.salonId',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Клиенты'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Верхняя панель-статистика
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Салон',
                        value: salonId,
                        icon: Icons.storefront,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _clientsStream(salonId),
                        builder: (context, snap) {
                          final count = snap.data?.docs.length ?? 0;
                          return _StatCard(
                            title: 'Клиентов',
                            value: '$count',
                            icon: Icons.people,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _clientsStream(salonId),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('Ошибка: ${snap.error}'));
                      }

                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return _EmptyState(
                          title: 'Клиентов пока нет',
                          subtitle: 'Создай первого клиента в Firestore:\n'
                              'salons/$salonId/clients',
                        );
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final d = docs[i].data();
                          final name = (d['name'] as String?) ?? 'Без имени';
                          final phone = (d['phone'] as String?) ?? '';
                          final email = (d['email'] as String?) ?? '';

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (phone.isNotEmpty) Text('📞 $phone'),
                                  if (email.isNotEmpty) Text('✉️ $email'),
                                ],
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              // Быстрое добавление тест-клиента
              final now = Timestamp.now();
              await FirebaseFirestore.instance
                  .collection('salons')
                  .doc(salonId)
                  .collection('clients')
                  .add({
                'name': 'Новый клиент',
                'phone': '',
                'email': '',
                'createdAt': now,
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Клиент добавлен')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Добавить клиента'),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox_outlined, size: 44),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(subtitle, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
