import 'package:flutter/material.dart';
import '../../core/auto_translate.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<String>(
        future: AutoTranslate.translateText('Reports'),
        builder: (context, snapshot) {
          return Text(
            snapshot.data ?? 'Reports',
            style: const TextStyle(fontSize: 24),
          );
        },
      ),
    );
  }
}
