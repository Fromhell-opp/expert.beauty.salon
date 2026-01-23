import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Assuming the BookingsScreen is defined in a separate file, import it here.
// For this example, I'll include the BookingsScreen code for completeness,
// but in your project, you should import it from the correct path, e.g.:
// import 'package:beauty_salon_app/screens/bookings_screen.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Мои записи',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          BookingCard(
            service: 'Маникюр',
            master: 'Айзада',
            date: '12 Января',
            time: '14:00',
          ),
          SizedBox(height: 16),
          BookingCard(
            service: 'Ресницы',
            master: 'Элина',
            date: '15 Января',
            time: '11:30',
          ),
        ],
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String service;
  final String master;
  final String date;
  final String time;

  const BookingCard({
    super.key,
    required this.service,
    required this.master,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 64, 129, 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.pinkAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Мастер: $master',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $time',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('BookingsScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: BookingsScreen()));

    // Verify that the app bar title is present.
    expect(find.text('Мои записи'), findsOneWidget);

    // Verify that the first booking card texts are present.
    expect(find.text('Маникюр'), findsOneWidget);
    expect(find.text('Мастер: Айзада'), findsOneWidget);
    expect(find.text('12 Января • 14:00'), findsOneWidget);

    // Verify that the second booking card texts are present.
    expect(find.text('Ресницы'), findsOneWidget);
    expect(find.text('Мастер: Элина'), findsOneWidget);
    expect(find.text('15 Января • 11:30'), findsOneWidget);

    // Check for the icon in the booking cards.
    expect(find.byIcon(Icons.calendar_today), findsNWidgets(2));
  });
}