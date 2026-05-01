import 'package:flutter/material.dart';

class AiInsightsScreen extends StatelessWidget {
  const AiInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Insights',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9900).withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFFF9900)),
                    SizedBox(width: 10),
                    Text('Gemini Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                SizedBox(height: 16),
                Text('• Your bookings have increased by 20% this month. Consider slightly raising rates for private events.'),
                SizedBox(height: 10),
                Text('• "Zaazuu Vibe" has the highest preview completion rate. You should promote it more on social media.'),
                SizedBox(height: 10),
                Text('• You have an open weekend next month. Consider hosting a virtual show or pushing merchandise discounts to active users.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
