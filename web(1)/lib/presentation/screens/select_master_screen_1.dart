import 'package:flutter/material.dart';

class SelectMasterScreen extends StatefulWidget {
  const SelectMasterScreen({super.key});

  @override
  State<SelectMasterScreen> createState() => _SelectMasterScreenState();
}

class _SelectMasterScreenState extends State<SelectMasterScreen> {
  String? selectedMaster;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[300]!, Colors.pink[100]!],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Выберите мастера',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      MasterCard(
                        name: 'Айзада',
                        icon: Icons.person, // Замените на AssetImage для фото, если есть
                        isSelected: selectedMaster == 'Айзада',
                        onTap: () {
                          setState(() {
                            selectedMaster = 'Айзада';
                          });
                        },
                      ),
                      MasterCard(
                        name: 'Элина',
                        icon: Icons.person,
                        isSelected: selectedMaster == 'Элина',
                        onTap: () {
                          setState(() {
                            selectedMaster = 'Элина';
                          });
                        },
                      ),
                      // Добавьте больше мастеров
                    ],
                  ),
                ),
                if (selectedMaster != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        // Переход к следующему экрану, например, к выбору времени
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => SelectDateTimeScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text(
                        'Продолжить',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MasterCard extends StatelessWidget {
  final String name;
  final IconData icon; // Или используйте Image для фото
  final bool isSelected;
  final VoidCallback onTap;

  const MasterCard({
    super.key,
    required this.name,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: isSelected ? Border.all(color: Colors.purple, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}