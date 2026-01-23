import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  Future<String?> _mySalonSlug() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data();

    // ✅ поддерживаем оба варианта поля (как у тебя может быть)
    final salonId = (data?['salonId'] as String?) ?? (data?['salonSlug'] as String?);
    return salonId;
  }

  String _fmtDateTime(DateTime dt) {
    final d = dt.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yy $hh:$min';
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
          return const Center(child: Text('Не найден salonId у текущего пользователя (users/{uid}.salonId)'));
        }

        final q = FirebaseFirestore.instance
            .collection('salons')
            .doc(salonSlug)
            .collection('bookings')
            .orderBy('startAt', descending: true);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Записи клиентов',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // ✅ кнопка: добавить тестовую запись (чтобы сразу увидеть список)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        await FirebaseFirestore.instance
                            .collection('salons')
                            .doc(salonSlug)
                            .collection('bookings')
                            .add({
                          'clientName': 'Тестовый клиент',
                          'clientPhone': '+996 000 000 000',
                          'serviceName': 'Маникюр классический',
                          'duration': 60,
                          'price': 1200,
                          'status': 'new',
                          'startAt': Timestamp.fromDate(now.add(const Duration(hours: 2))),
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить тестовую запись'),
                    ),
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
                            child: Text(
                              'Пока записей нет.\nНажми “Добавить тестовую запись” или создай booking в Firestore.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final d = docs[i].data();
                            final clientName = (d['clientName'] ?? 'Без имени').toString();
                            final phone = (d['clientPhone'] ?? '').toString();
                            final service = (d['serviceName'] ?? '').toString();
                            final status = (d['status'] ?? 'new').toString();
                            final price = (d['price'] ?? '').toString();
                            final duration = (d['duration'] ?? '').toString();

                            DateTime? startAt;
                            final ts = d['startAt'];
                            if (ts is Timestamp) startAt = ts.toDate();

                            return Card(
                              child: ListTile(
                                title: Text(clientName),
                                subtitle: Text(
                                  [
                                    if (service.isNotEmpty) 'Услуга: $service',
                                    if (startAt != null) 'Время: ${_fmtDateTime(startAt)}',
                                    if (phone.isNotEmpty) 'Тел: $phone',
                                    if (duration.isNotEmpty || price.isNotEmpty) 'Длительность: $duration мин • Цена: $price',
                                  ].join('\n'),
                                ),
                                trailing: Chip(label: Text(status)),
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
