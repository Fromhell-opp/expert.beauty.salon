import 'package:flutter/material.dart';

class MasterDashboardScreen extends StatefulWidget {
  const MasterDashboardScreen({super.key});

  @override
  State<MasterDashboardScreen> createState() =>
      _MasterDashboardScreenState();
}

class _MasterDashboardScreenState extends State<MasterDashboardScreen> {
  int _index = 0;

  final _screens = const [
    _ScheduleScreen(),
    _ClientsScreen(),
    _MasterProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мастер')),
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Расписание',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Клиенты',
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

class _ScheduleScreen extends StatelessWidget {
  const _ScheduleScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Расписание мастера'));
  }
}

class _ClientsScreen extends StatelessWidget {
  const _ClientsScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Клиенты мастера'));
  }
}

class _MasterProfileScreen extends StatelessWidget {
  const _MasterProfileScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Профиль мастера'));
  }
}

