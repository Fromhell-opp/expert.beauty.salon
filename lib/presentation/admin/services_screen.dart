import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ServicesScreen extends StatefulWidget {
  final String salonId;
  const ServicesScreen({super.key, this.salonId = ''});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
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

    final servicesStream = FirebaseFirestore.instance
        .collection('salons')
        .doc(_salonId)
        .collection('services')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Услуги')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: servicesStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Ошибка: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Услуг пока нет.\nДобавь услуги в Firestore.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final name = (d['name'] ?? 'Услуга').toString();
              final category = (d['category'] ?? '').toString();
              final durationMin = (d['durationMin'] is int)
                  ? d['durationMin'] as int
                  : int.tryParse('${d['durationMin'] ?? ''}') ?? 0;
              final active = d['active'] == true;

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('cat=$category • ${durationMin} мин • active=$active'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
