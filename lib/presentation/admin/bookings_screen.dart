import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum BookingFilter { today, tomorrow, week, all }

class BookingsScreen extends StatefulWidget {
  final String salonId;
  const BookingsScreen({super.key, this.salonId = ''});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _salonId = '';
  bool _loading = true;

  BookingFilter filter = BookingFilter.today;

  @override
  void initState() {
    super.initState();
    _loadSalonId();
  }

  Future<void> _loadSalonId() async {
    if (widget.salonId.trim().isNotEmpty) {
      setState(() {
        _salonId = widget.salonId.trim();
        _loading = false;
      });
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data() ?? {};
      setState(() {
        _salonId = (data['salonId'] ?? '').toString();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  CollectionReference<Map<String, dynamic>> get _bookingsCol =>
      FirebaseFirestore.instance.collection('salons').doc(_salonId).collection('bookings');

  CollectionReference<Map<String, dynamic>> get _servicesCol =>
      FirebaseFirestore.instance.collection('salons').doc(_salonId).collection('services');

  CollectionReference<Map<String, dynamic>> get _mastersCol =>
      FirebaseFirestore.instance.collection('salons').doc(_salonId).collection('masters');

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 0, 0);
  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  (DateTime? min, DateTime? max) _rangeForFilter() {
    final now = DateTime.now();
    final today = _startOfDay(now);

    switch (filter) {
      case BookingFilter.today:
        return (_startOfDay(today), _endOfDay(today));
      case BookingFilter.tomorrow:
        final t = today.add(const Duration(days: 1));
        return (_startOfDay(t), _endOfDay(t));
      case BookingFilter.week:
        final min = _startOfDay(today);
        final max = _endOfDay(today.add(const Duration(days: 7)));
        return (min, max);
      case BookingFilter.all:
        return (null, null);
    }
  }

  Query<Map<String, dynamic>> _query() {
    final r = _rangeForFilter();
    final min = r.$1;
    final max = r.$2;

    Query<Map<String, dynamic>> q = _bookingsCol;

    if (min != null && max != null) {
      q = q
          .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(min))
          .where('startAt', isLessThanOrEqualTo: Timestamp.fromDate(max));
    }

    return q.orderBy('startAt', descending: false);
  }

  String _statusText(String s) {
    switch (s) {
      case 'booked':
        return 'booked (ожидает)';
      case 'confirmed':
        return 'confirmed (подтверждено)';
      case 'done':
        return 'done (выполнено)';
      case 'cancelled':
        return 'cancelled (отменено)';
      default:
        return s;
    }
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

  Future<void> _setStatus(String bookingId, String status) async {
    await _bookingsCol.doc(bookingId).update({
      'status': status,
      if (status == 'confirmed') 'confirmedAt': FieldValue.serverTimestamp(),
      if (status == 'done') 'doneAt': FieldValue.serverTimestamp(),
      if (status == 'cancelled') 'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _confirmDelete(BuildContext context, String bookingId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text('Удаление навсегда. Лучше отменять статусом cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Нет')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) await _bookingsCol.doc(bookingId).delete();
  }

  // ------------------------------
  // ✅ Slot helpers
  // ------------------------------
  String _dayKey(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'mon';
      case 2:
        return 'tue';
      case 3:
        return 'wed';
      case 4:
        return 'thu';
      case 5:
        return 'fri';
      case 6:
        return 'sat';
      case 7:
        return 'sun';
      default:
        return 'mon';
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

  DateTime _dateAtTime(DateTime date, TimeOfDay t) =>
      DateTime(date.year, date.month, date.day, t.hour, t.minute);

  bool _overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
    return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
  }

  Future<List<Map<String, dynamic>>> _loadBookingsForMasterDay({
    required String masterId,
    required DateTime date,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day, 0, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // ⚠️ может попросить индекс (masterId + range startAt)
    final snap = await _bookingsCol
        .where('masterId', isEqualTo: masterId)
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
    required int serviceDurationMin,
    required List<Map<String, dynamic>> existingBookings,
    int stepMin = 15,
  }) {
    final key = _dayKey(date);
    final daySchedule = schedule[key];

    if (daySchedule == null) return []; // выходной
    if (daySchedule is! Map) return [];

    final from = _parseHHmm((daySchedule['from'] ?? '').toString());
    final to = _parseHHmm((daySchedule['to'] ?? '').toString());
    if (from == null || to == null) return [];

    final workStart = _dateAtTime(date, from);
    final workEnd = _dateAtTime(date, to);
    if (!workEnd.isAfter(workStart)) return [];

    final duration = Duration(minutes: serviceDurationMin <= 0 ? 60 : serviceDurationMin);

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
        slots.add(TimeOfDay(hour: slotStart.hour, minute: slotStart.minute));
      }

      cursor = cursor.add(Duration(minutes: stepMin));
    }

    return slots;
  }

  // ------------------------------
  // ✅ Create Booking (admin) with free slots
  // ------------------------------
  Future<void> _openCreateBookingDialog(BuildContext context) async {
    final clientNameCtrl = TextEditingController();
    final clientPhoneCtrl = TextEditingController();

    String? serviceId;
    Map<String, dynamic>? serviceData;

    String? masterId;
    Map<String, dynamic>? masterData;

    DateTime? selectedDate;
    TimeOfDay? selectedSlot;

    List<TimeOfDay> freeSlots = [];

    final servicesSnap = await _servicesCol.where('active', isEqualTo: true).get();
    final mastersSnap = await _mastersCol.where('active', isEqualTo: true).get();

    final services = servicesSnap.docs;
    final masters = mastersSnap.docs;

    if (services.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сначала добавь услуги (active=true).')),
        );
      }
      return;
    }
    if (masters.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сначала добавь мастеров (active=true).')),
        );
      }
      return;
    }

    serviceId = services.first.id;
    serviceData = services.first.data();

    masterId = masters.first.id;
    masterData = masters.first.data();

    Map<String, dynamic> masterSchedule() {
      final s = masterData?['schedule'];
      if (s is Map) return Map<String, dynamic>.from(s);
      return <String, dynamic>{};
    }

    int serviceDuration() {
      final d = serviceData?['durationMin'];
      if (d is int) return d;
      return int.tryParse('${d ?? ''}') ?? 60;
    }

    String dateText() {
      if (selectedDate == null) return 'Выбрать дату';
      final d = selectedDate!;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    Future<void> recalcSlots(StateSetter setState) async {
      if (selectedDate == null || masterId == null) {
        setState(() => freeSlots = []);
        return;
      }
      final bookings = await _loadBookingsForMasterDay(masterId: masterId!, date: selectedDate!);

      final slots = _buildSlots(
        date: selectedDate!,
        schedule: masterSchedule(),
        serviceDurationMin: serviceDuration(),
        existingBookings: bookings,
        stepMin: 15,
      );

      setState(() {
        freeSlots = slots;
        if (selectedSlot != null &&
            !freeSlots.any((t) => t.hour == selectedSlot!.hour && t.minute == selectedSlot!.minute)) {
          selectedSlot = null;
        }
      });
    }

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          String serviceName() => (serviceData?['name'] ?? '').toString();
          String masterName() => (masterData?['name'] ?? '').toString();

          return AlertDialog(
            title: const Text('Создать запись'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: clientNameCtrl,
                    decoration: const InputDecoration(labelText: 'Имя клиента'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: clientPhoneCtrl,
                    decoration: const InputDecoration(labelText: 'Телефон'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: serviceId,
                    items: services
                        .map((d) => DropdownMenuItem(
                      value: d.id,
                      child: Text((d.data()['name'] ?? 'Услуга').toString()),
                    ))
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      final found = services.firstWhere((e) => e.id == v);
                      setState(() {
                        serviceId = v;
                        serviceData = found.data();
                        selectedSlot = null;
                      });
                      await recalcSlots(setState);
                    },
                    decoration: const InputDecoration(labelText: 'Услуга'),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: masterId,
                    items: masters
                        .map((d) => DropdownMenuItem(
                      value: d.id,
                      child: Text((d.data()['name'] ?? 'Мастер').toString()),
                    ))
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      final found = masters.firstWhere((e) => e.id == v);
                      setState(() {
                        masterId = v;
                        masterData = found.data();
                        selectedSlot = null;
                      });
                      await recalcSlots(setState);
                    },
                    decoration: const InputDecoration(labelText: 'Мастер'),
                  ),
                  const SizedBox(height: 14),

                  OutlinedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: DateTime(now.year + 1, 12, 31),
                        initialDate: selectedDate ?? now,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                          selectedSlot = null;
                        });
                        await recalcSlots(setState);
                      }
                    },
                    child: Text(dateText()),
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Выбрано:\n• ${serviceName()}\n• ${masterName()}\n• Длительность: ${serviceDuration()} мин',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Свободные слоты', style: Theme.of(context).textTheme.titleSmall),
                  ),
                  const SizedBox(height: 8),

                  if (selectedDate == null)
                    const Align(alignment: Alignment.centerLeft, child: Text('Сначала выбери дату.'))
                  else if (freeSlots.isEmpty)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Нет свободных слотов (или мастер не работает).'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: freeSlots.map((t) {
                        final label =
                            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        final selected = selectedSlot != null &&
                            selectedSlot!.hour == t.hour &&
                            selectedSlot!.minute == t.minute;

                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) => setState(() => selectedSlot = t),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
              FilledButton(
                onPressed: () async {
                  final clientName = clientNameCtrl.text.trim();
                  final clientPhone = clientPhoneCtrl.text.trim();

                  if (clientName.isEmpty) return;
                  if (serviceId == null || masterId == null) return;
                  if (selectedDate == null || selectedSlot == null) return;

                  final d = selectedDate!;
                  final t = selectedSlot!;
                  final startAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);

                  final durationMin = serviceDuration();
                  final endAt = startAt.add(Duration(minutes: durationMin));

                  // ✅ финальная защита от двойной записи
                  final existing = await _loadBookingsForMasterDay(masterId: masterId!, date: d);
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Этот слот уже занят. Выбери другое время.')),
                      );
                    }
                    return;
                  }

                  final dateStr =
                      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                  final timeStr =
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

                  await _bookingsCol.add({
                    'clientName': clientName,
                    'clientPhone': clientPhone,
                    'serviceId': serviceId,
                    'serviceName': (serviceData?['name'] ?? '').toString(),
                    'durationMin': durationMin,
                    'masterId': masterId,
                    'masterName': (masterData?['name'] ?? '').toString(),
                    'date': dateStr,
                    'time': timeStr,
                    'startAt': Timestamp.fromDate(startAt),
                    'endAt': Timestamp.fromDate(endAt),
                    'status': 'booked',
                    'source': 'admin',
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Создать'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ------------------------------
  // UI
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_salonId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Салон не найден.\nСначала создай салон (Create Salon).', textAlign: TextAlign.center),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Записи'),
        actions: [
          PopupMenuButton<BookingFilter>(
            onSelected: (v) => setState(() => filter = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: BookingFilter.today, child: Text('Сегодня')),
              PopupMenuItem(value: BookingFilter.tomorrow, child: Text('Завтра')),
              PopupMenuItem(value: BookingFilter.week, child: Text('Неделя')),
              PopupMenuItem(value: BookingFilter.all, child: Text('Все')),
            ],
            icon: const Icon(Icons.filter_alt),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openCreateBookingDialog(context),
            tooltip: 'Создать запись',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Ошибка: ${snap.error}\n\n'
                    'Если пишет про индекс — нажми Create index в Firestore.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'Записей нет.\nФильтр: ${filter.name}',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();

              final clientName = (d['clientName'] ?? 'Клиент').toString();
              final phone = (d['clientPhone'] ?? '').toString();
              final service = (d['serviceName'] ?? '').toString();
              final master = (d['masterName'] ?? '').toString();
              final status = (d['status'] ?? 'booked').toString();
              final startAt = d['startAt'] is Timestamp ? d['startAt'] as Timestamp : null;

              final cancelled = status == 'cancelled';
              final done = status == 'done';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fmtTs(startAt), style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text('👤 $clientName ${phone.isEmpty ? '' : '• 📞 $phone'}'),
                      Text('🧾 $service'),
                      Text('👩‍🎨 $master'),
                      const SizedBox(height: 6),
                      Text('🔖 ${_statusText(status)}'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (!cancelled && !done)
                            OutlinedButton(
                              onPressed: () => _setStatus(doc.id, 'confirmed'),
                              child: const Text('Подтвердить'),
                            ),
                          if (!cancelled && !done)
                            OutlinedButton(
                              onPressed: () => _setStatus(doc.id, 'done'),
                              child: const Text('Завершить'),
                            ),
                          if (!cancelled)
                            OutlinedButton(
                              onPressed: () => _setStatus(doc.id, 'cancelled'),
                              child: const Text('Отменить'),
                            ),
                          IconButton(
                            onPressed: () => _confirmDelete(context, doc.id),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Удалить',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateBookingDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
