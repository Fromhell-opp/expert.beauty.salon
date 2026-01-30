import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingSlotsScreen extends StatefulWidget {
  final String salonId;
  final String slug;

  final String category;
  final String serviceName;
  final int durationMin;

  final String masterId;
  final String masterName;
  final Map<String, dynamic> masterSchedule;

  final DateTime date;

  const BookingSlotsScreen({
    super.key,
    required this.salonId,
    required this.slug,
    required this.category,
    required this.serviceName,
    required this.durationMin,
    required this.masterId,
    required this.masterName,
    required this.masterSchedule,
    required this.date,
  });

  @override
  State<BookingSlotsScreen> createState() => _BookingSlotsScreenState();
}

class _BookingSlotsScreenState extends State<BookingSlotsScreen> {
  bool loading = true;
  String? error;

  List<TimeOfDay> freeSlots = [];
  TimeOfDay? selected;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

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

  TimeOfDay? _parseHHmm(String s) {
    final parts = s.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _dateAtTime(DateTime date, TimeOfDay t) =>
      DateTime(date.year, date.month, date.day, t.hour, t.minute);

  bool _overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
    return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
  }

  Future<List<Map<String, dynamic>>> _loadBookingsForDay() async {
    final dayStart = DateTime(widget.date.year, widget.date.month, widget.date.day, 0, 0);
    final dayEnd = DateTime(widget.date.year, widget.date.month, widget.date.day, 23, 59, 59);

    // ⚠️ может попросить индекс (masterId + range startAt)
    final snap = await FirebaseFirestore.instance
        .collection('salons')
        .doc(widget.salonId)
        .collection('bookings')
        .where('masterId', isEqualTo: widget.masterId)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('startAt', isLessThanOrEqualTo: Timestamp.fromDate(dayEnd))
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      DateTime? startAt;
      DateTime? endAt;

      final s = data['startAt'];
      if (s is Timestamp) startAt = s.toDate();

      final e = data['endAt'];
      if (e is Timestamp) endAt = e.toDate();

      return <String, dynamic>{
        ...data,
        'startAt': startAt,
        'endAt': endAt,
      };
    }).toList();
  }

  List<TimeOfDay> _buildSlots({
    required DateTime date,
    required Map<String, dynamic> schedule,
    required int durationMin,
    required List<Map<String, dynamic>> existingBookings,
    int stepMin = 15,
  }) {
    final key = _dayKey(date);
    final daySchedule = schedule[key];

    // null => выходной
    if (daySchedule == null) return [];
    if (daySchedule is! Map) return [];

    final from = _parseHHmm((daySchedule['from'] ?? '').toString());
    final to = _parseHHmm((daySchedule['to'] ?? '').toString());
    if (from == null || to == null) return [];

    final workStart = _dateAtTime(date, from);
    final workEnd = _dateAtTime(date, to);
    if (!workEnd.isAfter(workStart)) return [];

    final duration = Duration(minutes: durationMin <= 0 ? 60 : durationMin);

    // занятые интервалы
    final busy = <(DateTime, DateTime)>[];
    for (final b in existingBookings) {
      final s = b['startAt'] as DateTime?;
      if (s == null) continue;

      DateTime end;
      final e = b['endAt'] as DateTime?;
      if (e != null) {
        end = e;
      } else {
        final dm = (b['durationMin'] is int)
            ? b['durationMin'] as int
            : int.tryParse('${b['durationMin'] ?? ''}') ?? 60;
        end = s.add(Duration(minutes: dm <= 0 ? 60 : dm));
      }
      busy.add((s, end));
    }

    final slots = <TimeOfDay>[];
    DateTime cursor = workStart;

    while (cursor.add(duration).isBefore(workEnd) || cursor.add(duration).isAtSameMomentAs(workEnd)) {
      final slotStart = cursor;
      final slotEnd = cursor.add(duration);

      final conflict = busy.any((it) => _overlaps(slotStart, slotEnd, it.$1, it.$2));
      if (!conflict) {
        // запрет на прошлое время "сегодня"
        final now = DateTime.now();
        if (date.year == now.year && date.month == now.month && date.day == now.day) {
          if (!slotStart.isAfter(now)) {
            cursor = cursor.add(Duration(minutes: stepMin));
            continue;
          }
        }

        slots.add(TimeOfDay(hour: slotStart.hour, minute: slotStart.minute));
      }

      cursor = cursor.add(Duration(minutes: stepMin));
    }

    return slots;
  }

  Future<void> _loadSlots() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final existing = await _loadBookingsForDay();
      final slots = _buildSlots(
        date: widget.date,
        schedule: widget.masterSchedule,
        durationMin: widget.durationMin,
        existingBookings: existing,
        stepMin: 15,
      );

      setState(() {
        freeSlots = slots;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  Future<void> _createBooking() async {
    final clientName = nameCtrl.text.trim();
    final clientPhone = phoneCtrl.text.trim();

    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите имя')));
      return;
    }
    if (clientPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите телефон')));
      return;
    }
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите время')));
      return;
    }

    final t = selected!;
    final startAt = DateTime(widget.date.year, widget.date.month, widget.date.day, t.hour, t.minute);
    final endAt = startAt.add(Duration(minutes: widget.durationMin <= 0 ? 60 : widget.durationMin));

    // финальная защита от двойной записи
    final existing = await _loadBookingsForDay();
    final conflict = existing.any((b) {
      final s = b['startAt'] as DateTime?;
      DateTime? e = b['endAt'] as DateTime?;
      if (s == null) return false;
      if (e == null) {
        final dm = (b['durationMin'] is int)
            ? b['durationMin'] as int
            : int.tryParse('${b['durationMin'] ?? ''}') ?? 60;
        e = s.add(Duration(minutes: dm <= 0 ? 60 : dm));
      }
      return _overlaps(startAt, endAt, s, e);
    });

    if (conflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Этот слот уже занят. Выбери другое время.')),
      );
      await _loadSlots();
      return;
    }

    final dateStr = _fmtDate(widget.date);
    final timeStr = _fmtTime(t);

    final bookingRef = await FirebaseFirestore.instance
        .collection('salons')
        .doc(widget.salonId)
        .collection('bookings')
        .add({
      'clientName': clientName,
      'clientPhone': clientPhone,
      'category': widget.category,
      'serviceName': widget.serviceName,
      'durationMin': widget.durationMin <= 0 ? 60 : widget.durationMin,
      'masterId': widget.masterId,
      'masterName': widget.masterName,
      'date': dateStr,
      'time': timeStr,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'status': 'booked',
      'source': 'client',
      'createdAt': FieldValue.serverTimestamp(),
    });

// ✅ уведомление админу
    await FirebaseFirestore.instance
        .collection('salons')
        .doc(widget.salonId)
        .collection('notifications')
        .add({
      'type': 'booking_created',
      'title': 'Новая запись',
      'message': '$clientName записался(лась) на ${widget.serviceName} к ${widget.masterName} • $dateStr $timeStr',
      'bookingId': bookingRef.id,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'serviceName': widget.serviceName,
      'masterName': widget.masterName,
      'startAt': Timestamp.fromDate(startAt),
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });


    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запись создана ✅')));
      Navigator.pop(context); // назад к мастерам
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Время • ${widget.masterName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSlots,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Салон: ${widget.slug}'),
                  Text('Услуга: ${widget.serviceName} (${widget.durationMin} мин)'),
                  Text('Дата: ${_fmtDate(widget.date)}'),
                  Text('Мастер: ${widget.masterName}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (loading) const Center(child: CircularProgressIndicator()),
          if (!loading && error != null)
            Text(
              'Ошибка: $error\n\nЕсли пишет про index — нажми Create index в Firestore.',
              textAlign: TextAlign.center,
            ),

          if (!loading && error == null) ...[
            Text('Свободное время', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),

            if (freeSlots.isEmpty)
              const Text('Нет свободных слотов (или мастер не работает).')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: freeSlots.map((t) {
                  final label = _fmtTime(t);
                  final sel = selected != null && selected!.hour == t.hour && selected!.minute == t.minute;

                  return ChoiceChip(
                    label: Text(label),
                    selected: sel,
                    onSelected: (_) => setState(() => selected = t),
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Ваше имя'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Телефон'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),

            FilledButton(
              onPressed: _createBooking,
              child: const Text('Записаться'),
            ),
          ],
        ],
      ),
    );
  }
}
