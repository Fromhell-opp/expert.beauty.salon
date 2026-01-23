import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  Future<Map<String, dynamic>?> _loadMe() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final snap =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return snap.data();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.go('/'); // вернёмся в AuthGate -> Welcome
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadMe(),
      builder: (context, snap) {
        final data = snap.data ?? {};
        final role = (data['role'] ?? 'client').toString();
        final name = (data['name'] ?? 'Пользователь').toString();
        final salonId = (data['salonId'] ?? '').toString();

        final pages = [
          _DashboardTab(
            role: role,
            name: name,
            salonId: salonId,
            onLogout: _logout,

          ),
          _ClientsTab(
            role: role,
            salonId: salonId,
          ),
          _SettingsTab(
            role: role,
            onLogout: _logout,
          ),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (v) => setState(() => _index = v),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Главная',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Клиенты',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Настройки',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final String role;
  final String name;
  final String salonId;
  final VoidCallback onLogout;

  const _DashboardTab({
    required this.role,
    required this.name,
    required this.salonId,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = role == 'owner' || role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwner ? 'Панель салона' : 'Кабинет клиента'),
        actions: [
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
          ),
        ],

      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(
            title: 'Привет, $name 👋',
            subtitle: isOwner
                ? 'Управляй салоном и принимай записи'
                : 'Записывайся на услуги в пару кликов',
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.badge,
            title: 'Мастера',
            subtitle: 'Добавить и настроить мастеров',
            onTap: () {
              context.go('/masters');
            },
          ),
          const SizedBox(height: 12),


          if (isOwner) ...[
            _ActionCard(
              icon: Icons.link,
              title: 'Ссылка для Instagram/2GIS',
              subtitle: 'Скопировать ссылку онлайн-записи',
              onTap: () {
                // позже сделаем генерацию slug и копирование
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Скоро: генерация ссылки')),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.design_services,
              title: 'Услуги',
              subtitle: 'Добавить/редактировать услуги',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Скоро: управление услугами')),
                );
              },

            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.calendar_month,
              title: 'Записи',
              subtitle: 'Список записей клиентов',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Скоро: список записей')),
                );
              },
            ),
          ] else ...[
            _ActionCard(
              icon: Icons.search,
              title: 'Найти салон',
              subtitle: 'Открыть запись по ссылке',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Открывай через /#/s/slug')),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.history,
              title: 'Мои записи',
              subtitle: 'История и будущие визиты',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Скоро: мои записи')),
                );
              },
            ),
          ],

          const SizedBox(height: 16),
          if (salonId.isNotEmpty)
            Text('salonId: $salonId', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ClientsTab extends StatelessWidget {
  final String role;
  final String salonId;

  const _ClientsTab({required this.role, required this.salonId});

  @override
  Widget build(BuildContext context) {
    final isOwner = role == 'owner' || role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Клиенты')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isOwner
            ? _OwnerClientsList(salonId: salonId)
            : const _EmptyState(
          title: 'Клиенты доступны владельцу',
          subtitle: 'Этот раздел видит только owner/admin.',
        ),
      ),
    );
  }
}

class _OwnerClientsList extends StatelessWidget {
  final String salonId;
  const _OwnerClientsList({required this.salonId});

  @override
  Widget build(BuildContext context) {
    if (salonId.isEmpty) {
      return const _EmptyState(
        title: 'Салон не найден',
        subtitle: 'Сначала создай салон, потом появятся клиенты.',
      );
    }

    // ✅ Простой список клиентов: salons/{salonId}/clients
    final stream = FirebaseFirestore.instance
        .collection('salons')
        .doc(salonId)
        .collection('clients')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
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
          return const _EmptyState(
            title: 'Клиентов пока нет',
            subtitle: 'Когда клиенты начнут записываться — появятся здесь.',
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final type = (data['type'] ?? 'client').toString();
            final uid = docs[i].id;

            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('Client: $uid'),
                subtitle: Text('type: $type'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Откроем профиль клиента: $uid')),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final String role;
  final VoidCallback onLogout;
  const _SettingsTab({required this.role, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final isOwner = role == 'owner' || role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(isOwner ? 'Роль: Владелец' : 'Роль: Клиент'),
              subtitle: const Text('Потом добавим переключения и профиль'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Выйти'),
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 56),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
