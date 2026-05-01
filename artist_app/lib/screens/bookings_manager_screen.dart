import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';

class BookingsManagerScreen extends StatefulWidget {
  const BookingsManagerScreen({super.key});

  @override
  State<BookingsManagerScreen> createState() => _BookingsManagerScreenState();
}

class _BookingsManagerScreenState extends State<BookingsManagerScreen> {
  bool _isLoading = false;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('/artist-mgmt/bookings');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _bookings = data['bookings'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching bookings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().patch('/artist-mgmt/bookings/$id', {'status': newStatus});
      if (response.statusCode == 200) {
        _fetchBookings();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings & Events'),
      ),
      body: _isLoading && _bookings.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9900)))
          : _bookings.isEmpty
              ? const Center(child: Text('No bookings found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final b = _bookings[index];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  b['event_type']?.toUpperCase() ?? 'EVENT',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                _buildStatusBadge(b['status']),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Date: ${b['event_date']}'),
                            Text('Location: ${b['location']}'),
                            Text('Client: ${b['client_name'] ?? 'Unknown'} (${b['client_phone'] ?? 'N/A'})'),
                            if (b['notes'] != null && b['notes'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('Notes: ${b['notes']}', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                              ),
                            
                            if (b['is_ticketed'] == true) ...[
                              const Divider(color: Colors.white24, height: 24),
                              const Text('Ticketing Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                              Text('Title: ${b['title']}'),
                              Text('Tickets Sold: ${b['tickets_sold']} / ${b['capacity']}'),
                              Text('Price: ZMW ${b['ticket_price']}'),
                            ],

                            const Divider(color: Colors.white24, height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (b['status'] == 'pending') ...[
                                  TextButton(
                                    onPressed: () => _updateStatus(b['id'], 'cancelled'),
                                    child: const Text('Reject', style: TextStyle(color: Colors.red)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                                    onPressed: () => _updateStatus(b['id'], 'confirmed'),
                                    child: const Text('Accept', style: TextStyle(color: Colors.black)),
                                  ),
                                ] else if (b['status'] == 'confirmed') ...[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    onPressed: () => _updateStatus(b['id'], 'completed'),
                                    child: const Text('Mark Completed'),
                                  ),
                                ],
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color bg = Colors.grey;
    if (status == 'pending') bg = Colors.orange;
    if (status == 'confirmed') bg = const Color(0xFF00E676);
    if (status == 'completed') bg = Colors.blue;
    if (status == 'cancelled') bg = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg),
      ),
      child: Text(
        (status ?? 'UNKNOWN').toUpperCase(),
        style: TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
