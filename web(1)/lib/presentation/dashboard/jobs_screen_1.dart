import 'package:flutter/material.dart';
import '../../core/auto_translate.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<String>(
        future: AutoTranslate.translateText('Jobs'),
        builder: (context, snapshot) {
          return Text(
            snapshot.data ?? 'Jobs',
            style: const TextStyle(fontSize: 24),
          );
        },
      ),
    );
  }
}
