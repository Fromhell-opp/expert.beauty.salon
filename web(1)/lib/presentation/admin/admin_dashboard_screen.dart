import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _index = 0;

  final _screens = const [
    _AllBookingsScreen(),
    _EmployeesScreen(),
    _ServicesScreen(),
    _AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Админ-панель')),
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Записи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Сотрудники',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.design_services),
            label: 'Услуги',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

class _AllBookingsScreen extends StatelessWidget {
  const _AllBookingsScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Все записи клиентов'));
  }
}

class _EmployeesScreen extends StatelessWidget {
  const _EmployeesScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Список сотрудников'));
  }
}

class _ServicesScreen extends StatelessWidget {
  const _ServicesScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Услуги салона'));
  }
}

class _AdminProfileScreen extends StatelessWidget {
  const _AdminProfileScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Профиль администратора'));
  }
}
