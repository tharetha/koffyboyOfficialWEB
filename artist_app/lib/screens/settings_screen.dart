import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // To access themeNotifier
import '../services/api_service.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useBiometric = prefs.getBool('use_biometric') ?? false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_biometric', value);
    setState(() {
      _useBiometric = value;
    });
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(labelText: 'Current Password'), obscureText: true),
              TextField(decoration: InputDecoration(labelText: 'New Password'), obscureText: true),
              TextField(decoration: InputDecoration(labelText: 'Confirm New Password'), obscureText: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement change password logic
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!')));
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showChangeNumberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Phone Number'),
          content: const TextField(
            decoration: InputDecoration(labelText: 'New Phone Number'),
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement change number logic
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number updated!')));
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showManageFeesDialog(BuildContext context) async {
    // Show loading initially
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF9900))),
    );

    try {
      // Fetch current pricing
      final response = await ApiService().get('/bookings/pricing');
      Navigator.pop(context); // Close loading

      if (response.statusCode == 200) {
        final currentFees = jsonDecode(response.body) as Map<String, dynamic>;
        final weddingCtrl = TextEditingController(text: currentFees['wedding']?.toString() ?? '1000');
        final showCtrl = TextEditingController(text: currentFees['show']?.toString() ?? '1500');
        final clubCtrl = TextEditingController(text: currentFees['club']?.toString() ?? '800');
        final privateCtrl = TextEditingController(text: currentFees['private']?.toString() ?? '500');

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Manage Event Fees'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: weddingCtrl, decoration: const InputDecoration(labelText: 'Wedding (ZMW)'), keyboardType: TextInputType.number),
                    TextField(controller: showCtrl, decoration: const InputDecoration(labelText: 'Public Show (ZMW)'), keyboardType: TextInputType.number),
                    TextField(controller: clubCtrl, decoration: const InputDecoration(labelText: 'Club Appearance (ZMW)'), keyboardType: TextInputType.number),
                    TextField(controller: privateCtrl, decoration: const InputDecoration(labelText: 'Private Event (ZMW)'), keyboardType: TextInputType.number),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    final updateResponse = await ApiService().post('/artist-mgmt/booking-pricing', {
                      'wedding': double.tryParse(weddingCtrl.text) ?? 1000.0,
                      'show': double.tryParse(showCtrl.text) ?? 1500.0,
                      'club': double.tryParse(clubCtrl.text) ?? 800.0,
                      'private': double.tryParse(privateCtrl.text) ?? 500.0,
                    });
                    if (updateResponse.statusCode == 200) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event fees updated!')));
                    } else {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update fees.')));
                    }
                  },
                  child: const Text('Save Fees'),
                ),
              ],
            );
          },
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load current fees')));
      }
    } catch (e) {
      Navigator.pop(context); // Close loading if error
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text('These are the terms of service for Koffyboy Official Artist App. You agree to use this platform responsibly and only upload content you have the rights to.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About App'),
        content: const Text('Koffyboy Official Artist App provides artists with a unified platform to manage their bookings, music, merchandise, and profile in real-time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: const Icon(Icons.dark_mode),
                activeColor: const Color(0xFFFF9900),
                value: currentMode == ThemeMode.dark,
                onChanged: (bool isDark) {
                  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
                },
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Change Phone Number'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangeNumberDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_outlined),
            title: const Text('Manage Event Fees'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showManageFeesDialog(context),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Security', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          SwitchListTile(
            title: const Text('Enable Biometric Login'),
            subtitle: const Text('Use fingerprint or face to login quickly.'),
            secondary: const Icon(Icons.fingerprint),
            activeColor: const Color(0xFFFF9900),
            value: _useBiometric,
            onChanged: _toggleBiometric,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Legal & Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () => _showTermsDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text('Version 1.0.0+1', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('Manufactured by: KTS Technologies Ltd.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
