import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/firebase_storage_service.dart';
import 'dart:convert';

class MusicManagerScreen extends StatefulWidget {
  const MusicManagerScreen({super.key});

  @override
  State<MusicManagerScreen> createState() => _MusicManagerScreenState();
}

class _MusicManagerScreenState extends State<MusicManagerScreen> {
  bool _isLoading = false;
  List<dynamic> _albums = [];

  @override
  void initState() {
    super.initState();
    _fetchMusic();
  }

  Future<void> _fetchMusic() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('/store/albums'); // Reusing store's album fetch for simplicity, or we can make an artist specific one
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _albums = data['albums'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching music: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddAlbumDialog() async {
    final titleCtrl = TextEditingController();
    File? coverImage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Create Album'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setStateDialog(() => coverImage = File(picked.path));
                      }
                    },
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: coverImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(coverImage!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.album, color: Colors.white54, size: 32),
                                SizedBox(height: 8),
                                Text('Cover Art', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Album Title'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, {'title': titleCtrl.text, 'image': coverImage}),
                  child: const Text('Create', style: TextStyle(color: Color(0xFFFF9900))),
                ),
              ],
            );
          }
        );
      },
    ).then((result) async {
      if (result != null) {
        setState(() => _isLoading = true);
        try {
          String? url;
          if (result['image'] != null) {
            url = await FirebaseStorageService().uploadFile(result['image'] as File, 'album_covers');
          }
          
          final response = await ApiService().post('/artist-mgmt/albums', {
            'title': result['title'],
            'cover_image_url': url,
          });

          if (response.statusCode == 201) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Album created!')));
            _fetchMusic();
          }
        } catch (e) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _showAddTrackDialog(int albumId) async {
    final titleCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    bool isSample = false;
    File? audioFile;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Add Track'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Track Title'),
                    ),
                    TextField(
                      controller: numberCtrl,
                      decoration: const InputDecoration(labelText: 'Track Number'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.audio_file),
                      label: Text(audioFile == null ? 'Select Audio File' : 'Audio Selected'),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.pickFiles(type: FileType.audio);
                        if (result != null) {
                          setStateDialog(() => audioFile = File(result.files.single.path!));
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Is Sample?'),
                      subtitle: const Text('Feature this as a free full track on the website homepage.'),
                      value: isSample,
                      activeColor: const Color(0xFFFF9900),
                      onChanged: (val) => setStateDialog(() => isSample = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, {
                    'title': titleCtrl.text,
                    'number': numberCtrl.text,
                    'audio': audioFile,
                    'is_sample': isSample,
                  }),
                  child: const Text('Upload', style: TextStyle(color: Color(0xFFFF9900))),
                ),
              ],
            );
          }
        );
      },
    ).then((result) async {
      if (result != null) {
        if (result['audio'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio file is required.')));
          return;
        }
        
        setState(() => _isLoading = true);
        try {
          final url = await FirebaseStorageService().uploadFile(result['audio'] as File, 'tracks');
          
          if (url != null) {
            final response = await ApiService().post('/artist-mgmt/tracks', {
              'album_id': albumId,
              'title': result['title'],
              'audio_url': url,
              'preview_url': url, // For now, preview is the same file. In prod, you'd slice it.
              'track_number': int.tryParse(result['number']) ?? 1,
              'is_sample': result['is_sample'],
            });

            if (response.statusCode == 201) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Track added!')));
              _fetchMusic();
            }
          }
        } catch (e) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: FloatingActionButton.extended(
              onPressed: _showAddAlbumDialog,
              backgroundColor: const Color(0xFFFF9900),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          body: _albums.isEmpty && !_isLoading
              ? const Center(child: Text('No albums found. Start releasing!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0).copyWith(bottom: 120),
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    final tracks = album['tracks'] as List<dynamic>? ?? [];
                    
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            image: album['cover_image_url'] != null
                                ? DecorationImage(image: NetworkImage(album['cover_image_url']), fit: BoxFit.cover)
                                : null,
                          ),
                          child: album['cover_image_url'] == null ? const Icon(Icons.album, color: Colors.white24) : null,
                        ),
                        title: Text(album['title'] ?? 'Unknown Album', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${tracks.length} Tracks'),
                        children: [
                          ...tracks.map((track) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.black26,
                                  child: Text('${track['track_number']}'),
                                ),
                                title: Text(track['title']),
                                trailing: track['is_sample'] == true
                                    ? const Icon(Icons.star, color: Colors.amber, size: 16)
                                    : null,
                              )).toList(),
                          ListTile(
                            leading: const Icon(Icons.add, color: Color(0xFFFF9900)),
                            title: const Text('Add Track', style: TextStyle(color: Color(0xFFFF9900))),
                            onTap: () => _showAddTrackDialog(album['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF9900))),
          ),
      ],
    );
  }
}
