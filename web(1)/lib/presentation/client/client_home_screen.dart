import 'package:flutter/material.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() =>
      _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  int _index = 0;

  final _screens = const [
    _BookScreen(),
    _MyBookingsScreen(),
    _ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Запись',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Мои записи',
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

class _BookScreen extends StatelessWidget {
  const _BookScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Экран записи клиента'),
    );
  }
}

class _MyBookingsScreen extends StatelessWidget {
  const _MyBookingsScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Мои записи'),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Профиль клиента'),
    );
  }
}

