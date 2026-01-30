import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_slots_screen.dart';

class BookingMasterScreen extends StatefulWidget {
  final String salonId;    // ✅ нужен для правильного пути
  final String slug;       // только для UI
  final String category;   // manicure/pedicure/...
  final String serviceName;
  final int duration;

  const BookingMasterScreen({
    super.key,
    required this.salonId,
    required this.slug,
    required this.category,
    required this.serviceName,
    required this.duration,
  });

  @override
  State<BookingMasterScreen> createState() => _BookingMasterScreenState();
}

class _BookingMasterScreenState extends State<BookingMasterScreen> {
  DateTime _date = DateTime.now();

  String _dayKey(DateTime date) {
    switch (date.weekday) {
      case 1: return 'mon';
      case 2: return 'tue';
      case 3: return 'wed';
      case 4: return 'thu';
      case 5: return 'fri';
      case 6: return 'sat';
      case 7: return 'sun';
      default: return 'mon';
    }
  }

  bool _isWorkingThatDay(Map<String, dynamic> master, DateTime date) {
    final schedule = master['schedule'];
    if (schedule is! Map) return false;

    final day = schedule[_dayKey(date)];

    // ✅ null => выходной
    if (day == null) return false;

    // ✅ если криво записано — считаем что не работает
    if (day is! Map) return false;

    final from = (day['from'] ?? '').toString();
    final to = (day['to'] ?? '').toString();
    if (from.isEmpty || to.isEmpty) return false;

    return true;
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final mastersStream = FirebaseFirestore.instance
        .collection('salons')
        .doc(widget.salonId)
        .collection('masters')
        .where('active', isEqualTo: true)
    // ✅ теперь поле называется specialties (мы так сделали в админке)
        .where('specialties', arrayContains: widget.category)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text('Мастера • ${widget.slug}')),
      body: Column(
        children: [
          // ✅ выбор даты прямо на экране мастеров
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text('Дата: ${_fmtDate(_date)} (показать кто работает)'),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: DateTime(now.year + 1, 12, 31),
                  initialDate: _date,
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: mastersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }

                final all = snapshot.data?.docs ?? [];

                // ✅ ГЛАВНОЕ: фильтр по расписанию выбранного дня
                final filtered = all.where((doc) {
                  final data = doc.data();
                  return _isWorkingThatDay(data, _date);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Нет мастеров, которые работают в эту дату:\n${_fmtDate(_date)}\n\n'
                          'Проверь schedule у мастеров (day=null => выходной).',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = filtered[index].data();
                    final name = (data['name'] ?? '').toString();

                    return Card(
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text('${widget.serviceName} • ${widget.duration} мин'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingSlotsScreen(
                                salonId: widget.salonId,
                                slug: widget.slug,
                                category: widget.category,
                                serviceName: widget.serviceName,
                                durationMin: widget.duration,
                                masterId: filtered[index].id,
                                masterName: name,
                                masterSchedule: Map<String, dynamic>.from((data['schedule'] as Map)),
                                date: _date,
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
          ),
        ],
      ),
    );
  }
}
