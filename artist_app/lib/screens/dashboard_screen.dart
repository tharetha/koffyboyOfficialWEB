import 'package:flutter/material.dart';
import 'bookings_manager_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock data for now, will connect to API later
  final Map<String, dynamic> metrics = {
    'totalRevenue': 4500.00,
    'ticketSales': 150,
    'upcomingBookings': 3,
  };

  late IO.Socket socket;
  List<Map<String, dynamic>> _recentNotifications = [];

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    // Connect to WebSocket server on port 80
    socket = IO.io('http://98.91.230.252', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'path': '/socket.io/'
    });

    socket.onConnect((_) {
      print('Connected to WebSocket server');
    });

    socket.on('booking_update', (data) {
      if (mounted) {
        setState(() {
          _recentNotifications.insert(0, data); // FIFO, newest at top
          metrics['upcomingBookings'] = (metrics['upcomingBookings'] as int) + 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00E676),
            content: Row(
              children: [
                const Icon(Icons.event, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(child: Text('New ${data['event_type']} booking at ${data['location']}!', style: const TextStyle(color: Colors.black))),
              ],
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.black,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookingsManagerScreen()),
                );
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0), // Padding for nav bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back, Koffyboy!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Metrics Row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RevenueDetailsScreen()),
                    );
                  },
                  child: _buildMetricCard(
                    'Revenue',
                    'ZMW ${metrics['totalRevenue']}',
                    Icons.attach_money,
                    const Color(0xFF00E676),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Tickets',
                  '${metrics['ticketSales']}',
                  Icons.confirmation_number_outlined,
                  const Color(0xFFFF9900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookingsManagerScreen()),
              );
            },
            child: _buildMetricCard(
              'Upcoming Bookings',
              '${metrics['upcomingBookings']} Events',
              Icons.event,
              Colors.blueAccent,
            ),
          ),
          
          if (_recentNotifications.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Recent Live Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._recentNotifications.map((notif) => Card(
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.notifications_active, color: Color(0xFF00E676)),
                title: Text('New ${notif['event_type']} Request'),
                subtitle: Text('${notif['event_date']} @ ${notif['location']}'),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BookingsManagerScreen()),
                  );
                },
              ),
            )),
          ],
          
          const SizedBox(height: 32),
          
          // AI Insights Section
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Text(
                'AI Insights',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Trend Detected',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                SizedBox(height: 8),
                Text(
                  'Ticket sales for the "Lusaka Summer Fest" are up 20% this week. Consider promoting premium merchandise at this event to maximize revenue.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Powered by Gemini ✨',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class RevenueDetailsScreen extends StatelessWidget {
  const RevenueDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Breakdown'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRevenueSourceCard('Merchandise Sales', 'ZMW 1,200', Icons.shopping_bag, const Color(0xFF00E676)),
          const SizedBox(height: 12),
          _buildRevenueSourceCard('Event Tickets', 'ZMW 2,500', Icons.confirmation_number, const Color(0xFFFF9900)),
          const SizedBox(height: 12),
          _buildRevenueSourceCard('Direct Bookings', 'ZMW 800', Icons.event_available, Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildRevenueSourceCard(String title, String amount, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

