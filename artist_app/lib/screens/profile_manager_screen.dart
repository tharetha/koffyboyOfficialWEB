import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/firebase_storage_service.dart';
import 'dart:convert';
import 'settings_screen.dart';

class ProfileManagerScreen extends StatefulWidget {
  const ProfileManagerScreen({super.key});

  @override
  State<ProfileManagerScreen> createState() => _ProfileManagerScreenState();
}

class _ProfileManagerScreenState extends State<ProfileManagerScreen> {
  final _bioController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      // In a real app, you'd fetch the current profile from a GET endpoint
      // For now, we leave it empty to be filled by the user
    } catch (e) {
      print('Error fetching profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final socialLinks = {
        'facebook': _facebookController.text,
        'instagram': _instagramController.text,
        'twitter': _twitterController.text,
      };

      final response = await ApiService().post('/artist-mgmt/profile', {
        'bio': _bioController.text,
        'social_links': jsonEncode(socialLinks),
      });

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated on website!')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addHighlight() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Show dialog for caption
    String? caption = await showDialog<String>(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Add Caption'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Enter highlight caption'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Upload', style: TextStyle(color: Color(0xFFFF9900))),
            ),
          ],
        );
      },
    );

    if (caption == null) return;

    setState(() => _isLoading = true);
    try {
      final file = File(image.path);
      final url = await FirebaseStorageService().uploadFile(file, 'highlights');
      
      if (url != null) {
        final response = await ApiService().post('/artist-mgmt/highlights', {
          'image_url': url,
          'caption': caption,
        });

        if (response.statusCode == 201) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Highlight added to website!')));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9900)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Website Biography', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _bioController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Enter your bio for the website...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFF1E1E1E),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Social Links', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _facebookController,
            decoration: const InputDecoration(
              labelText: 'Facebook URL',
              prefixIcon: Icon(Icons.facebook),
              filled: true,
              fillColor: Color(0xFF1E1E1E),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instagramController,
            decoration: const InputDecoration(
              labelText: 'Instagram URL',
              prefixIcon: Icon(Icons.camera_alt_outlined),
              filled: true,
              fillColor: Color(0xFF1E1E1E),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _twitterController,
            decoration: const InputDecoration(
              labelText: 'Twitter (X) URL',
              prefixIcon: Icon(Icons.alternate_email),
              filled: true,
              fillColor: Color(0xFF1E1E1E),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
              onPressed: _saveProfile,
              child: const Text('Update Website Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 40),
          const Divider(color: Colors.white24),
          const SizedBox(height: 24),

          const Text('Website Highlights Slider', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Upload images to feature on the homepage slider.', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_photo_alternate, color: Color(0xFFFF9900)),
              label: const Text('Add New Highlight', style: TextStyle(color: Color(0xFFFF9900))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF9900)),
              ),
              onPressed: _addHighlight,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFFFF9900)),
            title: const Text('App Settings & Account', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Theme, Password, App Info'),
            trailing: const Icon(Icons.chevron_right),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 100), // padding for bottom nav
        ],
      ),
    );
  }
}
