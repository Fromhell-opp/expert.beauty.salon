import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyBookingsScreen extends StatefulWidget {
  final String salonId;
  final String slug;

  const MyBookingsScreen({
    super.key,
    required this.salonId,
    required this.slug,
  });

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final phoneCtrl = TextEditingController();
  String phone = '';

  @override
  void dispose() {
    phoneCtrl.dispose();
    super.dispose();
  }

  String _fmtTs(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd $hh:$mi';
  }

  Future<void> _cancelBooking(String bookingId) async {
    final bookingRef = FirebaseFirestore.instance
        .collection('salons')
        .doc(widget.salonId)
        .collection('bookings')
        .doc(bookingId);

    final snap = await bookingRef.get();
    final data = snap.data() ?? {};

    await bookingRef.update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    final clientName = (data['clientName'] ?? '').toString();
    final clientPhone = (data['clientPhone'] ?? '').toString();
    final serviceName = (data['serviceName'] ?? '').toString();
    final masterName = (data['masterName'] ?? '').toString();
    final date = (data['date'] ?? '').toString();
    final time = (data['time'] ?? '').toString();
    final startAt = data['startAt'] is Timestamp ? data['startAt'] as Timestamp : null;

    // ✅ уведомление админу
    await FirebaseFirestore.instance
        .collection('salons')
        .doc(widget.salonId)
        .collection('notifications')
        .add({
      'type': 'booking_cancelled',
      'title': 'Отмена записи',
      'message': '$clientName отменил(а) запись: $serviceName • $masterName • $date $time',
      'bookingId': bookingId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'serviceName': serviceName,
      'masterName': masterName,
      if (startAt != null) 'startAt': startAt,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись отменена')),
      );
    }
  }


  Future<void> _confirmCancel(String bookingId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Отменить запись?'),
        content: const Text('Статус станет cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Нет')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Да, отменить')),
        ],
      ),
    );

    if (ok == true) {
      await _cancelBooking(bookingId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = phone.trim().isNotEmpty;

    Query<Map<String, dynamic>> query() {
      return FirebaseFirestore.instance
          .collection('salons')
          .doc(widget.salonId)
          .collection('bookings')
          .where('clientPhone', isEqualTo: phone.trim())
          .orderBy('startAt', descending: true);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Мои записи • ${widget.slug}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Введите телефон, который вы указали при записи:'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Телефон'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      setState(() => phone = phoneCtrl.text.trim());
                    },
                    child: const Text('Показать мои записи'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (!canSearch)
            const Center(child: Text('Введите телефон и нажмите “Показать мои записи”.'))
          else
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query().snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Text(
                    'Ошибка: ${snap.error}\n\nЕсли просит index — нажми Create index в Firestore.',
                    textAlign: TextAlign.center,
                  );
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Записей не найдено по этому телефону.'));
                }

                return Column(
                  children: docs.map((doc) {
                    final d = doc.data();

                    final service = (d['serviceName'] ?? '').toString();
                    final master = (d['masterName'] ?? '').toString();
                    final status = (d['status'] ?? 'booked').toString();

                    final startAt = d['startAt'] is Timestamp ? d['startAt'] as Timestamp : null;
                    final date = (d['date'] ?? '').toString();
                    final time = (d['time'] ?? '').toString();

                    final cancelled = status == 'cancelled';
                    final done = status == 'done';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fmtTs(startAt).isNotEmpty ? _fmtTs(startAt) : '$date $time',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text('🧾 $service'),
                              Text('👩‍🎨 $master'),
                              const SizedBox(height: 6),
                              Text('🔖 статус: $status'),
                              const SizedBox(height: 10),

                              if (!cancelled && !done)
                                OutlinedButton(
                                  onPressed: () => _confirmCancel(doc.id),
                                  child: const Text('Отменить запись'),
                                ),

                              if (cancelled)
                                const Text('Запись отменена', style: TextStyle(fontWeight: FontWeight.w600)),
                              if (done)
                                const Text('Запись выполнена', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}
