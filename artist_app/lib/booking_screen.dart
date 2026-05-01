import 'package:flutter/material.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 3, // Simulated data
      itemBuilder: (context, index) {
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 16.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            title: const Text('Wedding Event', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Text('Date: 2026-05-15'),
                Text('Location: Lusaka, Zambia'),
                Text('Price: \$1000.00'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Pending', style: TextStyle(color: Colors.orange)),
            ),
            onTap: () {
              // Show bottom sheet to change status
            },
          ),
        );
      },
    );
  }
}
