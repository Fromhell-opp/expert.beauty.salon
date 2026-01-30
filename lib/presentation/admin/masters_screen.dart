import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MastersScreen extends StatefulWidget {
  final String salonId;
  const MastersScreen({super.key, this.salonId = ''});

  @override
  State<MastersScreen> createState() => _MastersScreenState();
}

class _MastersScreenState extends State<MastersScreen> {
  String _salonId = '';
  bool _loading = true;

  static const List<Map<String, String>> kCategories = [
    {'key': 'manicure', 'label': 'Маникюр'},
    {'key': 'pedicure', 'label': 'Педикюр'},
    {'key': 'lashes', 'label': 'Ресницы'},
    {'key': 'brows', 'label': 'Брови'},
    {'key': 'hair', 'label': 'Волосы'},
    {'key': 'massage', 'label': 'Массаж'},
  ];

  static const List<Map<String, String>> kDays = [
    {'key': 'mon', 'label': 'Пн'},
    {'key': 'tue', 'label': 'Вт'},
    {'key': 'wed', 'label': 'Ср'},
    {'key': 'thu', 'label': 'Чт'},
    {'key': 'fri', 'label': 'Пт'},
    {'key': 'sat', 'label': 'Сб'},
    {'key': 'sun', 'label': 'Вс'},
  ];

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

    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data() ?? {};
    setState(() {
      _salonId = (data['salonId'] ?? '').toString();
      _loading = false;
    });
  }

  CollectionReference<Map<String, dynamic>> get _mastersCol =>
      FirebaseFirestore.instance.collection('salons').doc(_salonId).collection('masters');

  String _catLabel(String key) {
    return kCategories.firstWhere(
          (c) => c['key'] == key,
      orElse: () => {'label': key},
    )['label']!;
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

  Map<String, dynamic> _defaultSchedule() {
    // по умолчанию: Пн-Пт 09:00-20:00, сб/вс выходной
    return {
      'mon': {'from': '09:00', 'to': '20:00'},
      'tue': {'from': '09:00', 'to': '20:00'},
      'wed': {'from': '09:00', 'to': '20:00'},
      'thu': {'from': '09:00', 'to': '20:00'},
      'fri': {'from': '09:00', 'to': '20:00'},
      'sat': null,
      'sun': null,
    };
  }

  Future<void> _openUpsertDialog({
    String? docId,
    Map<String, dynamic>? initial,
  }) async {
    final isEdit = docId != null;

    final nameCtrl = TextEditingController(text: (initial?['name'] ?? '').toString());
    bool active = (initial?['active'] == true);

    final initSpecsRaw = (initial?['specialties'] is List) ? (initial?['specialties'] as List) : [];
    final initSpecs = initSpecsRaw.map((e) => e.toString()).toSet();

    final selectedSpecs = <String>{...initSpecs};

    Map<String, dynamic> schedule = {};
    final s = initial?['schedule'];
    if (s is Map) {
      schedule = Map<String, dynamic>.from(s);
    } else {
      schedule = _defaultSchedule();
    }

    Future<void> pickTime(
        StateSetter setState,
        String dayKey,
        String field, // from/to
        ) async {
      final day = schedule[dayKey];
      if (day == null) return;

      final current = day is Map ? day[field]?.toString() : null;
      final parsed = current == null ? null : _parseHHmm(current);

      final picked = await showTimePicker(
        context: context,
        initialTime: parsed ?? const TimeOfDay(hour: 9, minute: 0),
      );
      if (picked == null) return;

      setState(() {
        schedule = Map<String, dynamic>.from(schedule);
        final dayMap = Map<String, dynamic>.from(schedule[dayKey] as Map);
        dayMap[field] = _fmtTime(picked);
        schedule[dayKey] = dayMap;
      });
    }

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEdit ? 'Редактировать мастера' : 'Добавить мастера'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Имя мастера'),
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    value: active,
                    onChanged: (v) => setState(() => active = v),
                    title: const Text('Активен'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 6),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Специализации',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ✅ Dropdown/Chip выбор specialties
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kCategories.map((c) {
                      final key = c['key']!;
                      final label = c['label']!;
                      final selected = selectedSpecs.contains(key);

                      return FilterChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              selectedSpecs.add(key);
                            } else {
                              selectedSpecs.remove(key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Расписание',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ✅ расписание по дням: выходной / from-to
                  Column(
                    children: kDays.map((day) {
                      final dayKey = day['key']!;
                      final dayLabel = day['label']!;
                      final value = schedule[dayKey]; // null или {from,to}

                      final isOff = value == null;

                      String fromText = '';
                      String toText = '';

                      if (!isOff && value is Map) {
                        fromText = (value['from'] ?? '').toString();
                        toText = (value['to'] ?? '').toString();
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(dayLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Switch(
                                    value: !isOff,
                                    onChanged: (v) {
                                      setState(() {
                                        schedule = Map<String, dynamic>.from(schedule);
                                        if (!v) {
                                          schedule[dayKey] = null;
                                        } else {
                                          schedule[dayKey] = {'from': '09:00', 'to': '20:00'};
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (isOff)
                                const Text('Выходной')
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => pickTime(setState, dayKey, 'from'),
                                        child: Text(fromText.isEmpty ? 'с' : 'с $fromText'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => pickTime(setState, dayKey, 'to'),
                                        child: Text(toText.isEmpty ? 'до' : 'до $toText'),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
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
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  if (selectedSpecs.isEmpty) return;

                  final payload = <String, dynamic>{
                    'name': name,
                    'active': active,
                    'specialties': selectedSpecs.toList(),
                    'schedule': schedule,
                    if (!isEdit) 'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (isEdit) {
                    await _mastersCol.doc(docId).update(payload);
                  } else {
                    await _mastersCol.add(payload);
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(isEdit ? 'Сохранить' : 'Добавить'),
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
  }

  Future<void> _toggleActive(String id, bool v) async {
    await _mastersCol.doc(id).update({
      'active': v,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteMaster(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить мастера?'),
        content: const Text('Удалится навсегда. Обычно лучше выключать active=false.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Нет')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );

    if (ok == true) {
      await _mastersCol.doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_salonId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Salon ID not found.\nСначала создай салон.')),
      );
    }

    final stream = _mastersCol.orderBy('createdAt', descending: true).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мастера'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openUpsertDialog(),
            tooltip: 'Добавить мастера',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Ошибка: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Мастеров пока нет.\nНажми + чтобы добавить.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();

              final name = (d['name'] ?? 'Мастер').toString();
              final active = d['active'] == true;
              final specs = (d['specialties'] is List) ? (d['specialties'] as List) : [];
              final specsText = specs.map((e) => _catLabel(e.toString())).join(', ');

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(specsText.isEmpty ? '—' : specsText),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      Switch(
                        value: active,
                        onChanged: (v) => _toggleActive(doc.id, v),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openUpsertDialog(docId: doc.id, initial: d),
                        tooltip: 'Редактировать',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteMaster(doc.id),
                        tooltip: 'Удалить',
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
        onPressed: () => _openUpsertDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
