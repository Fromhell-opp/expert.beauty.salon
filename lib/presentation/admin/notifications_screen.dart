import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  final String salonId;
  const NotificationsScreen({super.key, this.salonId = ''});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _salonId = '';
  bool _loading = true;

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

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance
      .collection('salons')
      .doc(_salonId)
      .collection('notifications');

  String _fmtTs(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd $hh:$mi';
  }

  Future<void> _markRead(String id, bool read) async {
    await _col.doc(id).update({
      'read': read,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _clearAllRead() async {
    final snap = await _col.where('read', isEqualTo: true).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_salonId.isEmpty) {
      return const Scaffold(body: Center(child: Text('Salon ID not found.')));
    }

    final stream = _col.orderBy('createdAt', descending: true).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          IconButton(
            onPressed: _clearAllRead,
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Удалить прочитанные',
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
          if (docs.isEmpty) return const Center(child: Text('Уведомлений нет.'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();

              final title = (d['title'] ?? 'Уведомление').toString();
              final msg = (d['message'] ?? '').toString();
              final read = d['read'] == true;
              final createdAt = d['createdAt'] is Timestamp ? d['createdAt'] as Timestamp : null;

              return Card(
                child: ListTile(
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(msg),
                      const SizedBox(height: 8),
                      Text(_fmtTs(createdAt), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  leading: Icon(read ? Icons.mark_email_read : Icons.notifications_active),
                  trailing: Switch(
                    value: read,
                    onChanged: (v) => _markRead(doc.id, v),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
