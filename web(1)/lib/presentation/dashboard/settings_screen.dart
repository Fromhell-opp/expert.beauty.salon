import 'package:flutter/material.dart';
import '../../core/auto_translate.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedRole = 'Truck Driver';

  final roles = ['Truck Driver', 'Courier', 'Taxi Driver'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<String>(
            future: AutoTranslate.translateText('Settings'),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? 'Settings',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 20),
          FutureBuilder<String>(
            future: AutoTranslate.translateText('Select Role'),
            builder: (context, snapshot) {
              return Text(snapshot.data ?? 'Select Role', style: const TextStyle(fontSize: 20));
            },
          ),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: selectedRole,
            items: roles.map((role) => DropdownMenuItem(
              value: role,
              child: Text(role),
            )).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedRole = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
