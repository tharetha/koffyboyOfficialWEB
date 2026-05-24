import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
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
  
  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _fetchMusic();
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingUrl = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchMusic() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService()
          .get('/music/albums')
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timed out'),
          );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _albums = data['albums'] ?? [];
        });
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error: ${response.statusCode}')),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not load music: $e')));
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
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
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
                                Icon(
                                  Icons.album,
                                  color: Colors.white54,
                                  size: 32,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Cover Art',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, {
                    'title': titleCtrl.text,
                    'image': coverImage,
                  }),
                  child: const Text(
                    'Create',
                    style: TextStyle(color: Color(0xFFFF9900)),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result != null) {
        setState(() => _isLoading = true);
        try {
          String? url;
          if (result['image'] != null) {
            url = await FirebaseStorageService().uploadFile(
              result['image'] as File,
              'album_covers',
            );
          }

          final response = await ApiService().post('/artist-mgmt/albums', {
            'title': result['title'],
            'cover_image_url': url,
          });

          if (response.statusCode == 201) {
            if (mounted)
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Album created!')));
            _fetchMusic();
          }
        } catch (e) {
          if (mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
                      decoration: const InputDecoration(
                        labelText: 'Track Title',
                      ),
                    ),
                    TextField(
                      controller: numberCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Track Number',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.audio_file),
                      label: Text(
                        audioFile == null
                            ? 'Select Audio File'
                            : 'Audio Selected',
                      ),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(type: FileType.audio);
                        if (result != null) {
                          setStateDialog(
                            () => audioFile = File(result.files.single.path!),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Is Sample?'),
                      subtitle: const Text(
                        'Feature this as a free full track on the website homepage.',
                      ),
                      value: isSample,
                      activeColor: const Color(0xFFFF9900),
                      onChanged: (val) =>
                          setStateDialog(() => isSample = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, {
                    'title': titleCtrl.text,
                    'number': numberCtrl.text,
                    'audio': audioFile,
                    'is_sample': isSample,
                  }),
                  child: const Text(
                    'Upload',
                    style: TextStyle(color: Color(0xFFFF9900)),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result != null) {
        if (result['audio'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio file is required.')),
          );
          return;
        }

        setState(() => _isLoading = true);
        try {
          final url = await FirebaseStorageService().uploadFile(
            result['audio'] as File,
            'tracks',
          );

          if (url != null) {
            final response = await ApiService().post('/artist-mgmt/tracks', {
              'album_id': albumId,
              'title': result['title'],
              'audio_url': url,
              'preview_url':
                  url, // For now, preview is the same file. In prod, you'd slice it.
              'track_number': int.tryParse(result['number']) ?? 1,
              'is_sample': result['is_sample'],
            });

            if (response.statusCode == 201) {
              if (mounted)
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Track added!')));
              _fetchMusic();
            }
          }
        } catch (e) {
          if (mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _showAddSingleDialog() async {
    final titleCtrl = TextEditingController();
    bool isSample = false;
    File? audioFile;
    File? coverImage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Add Single'),
              content: SingleChildScrollView(
                child: Column(
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
                        height: 100,
                        width: 100,
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
                                  Icon(Icons.image, color: Colors.white54, size: 24),
                                  SizedBox(height: 8),
                                  Text('Cover', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Single Title'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.audio_file),
                      label: Text(audioFile == null ? 'Select Audio File' : 'Audio Selected'),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
                        if (result != null) {
                          setStateDialog(() => audioFile = File(result.files.single.path!));
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Is Sample?'),
                      subtitle: const Text('Feature this as a free full track.'),
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
                    'audio': audioFile,
                    'cover': coverImage,
                    'is_sample': isSample,
                  }),
                  child: const Text('Upload Single', style: TextStyle(color: Color(0xFFFF9900))),
                ),
              ],
            );
          },
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
          final audioUrl = await FirebaseStorageService().uploadFile(result['audio'] as File, 'tracks');
          String? coverUrl;
          if (result['cover'] != null) {
             coverUrl = await FirebaseStorageService().uploadFile(result['cover'] as File, 'album_covers');
          }

          if (audioUrl != null) {
            final response = await ApiService().post('/artist-mgmt/singles', {
              'title': result['title'],
              'audio_url': audioUrl,
              'preview_url': audioUrl,
              'cover_image_url': coverUrl,
              'is_sample': result['is_sample'],
            });

            if (response.statusCode == 201) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Single added!')));
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'single',
                  onPressed: _showAddSingleDialog,
                  backgroundColor: const Color(0xFF1E1E1E),
                  icon: const Icon(Icons.music_note, color: Color(0xFFFF9900)),
                  label: const Text('New Single', style: TextStyle(color: Color(0xFFFF9900), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'album',
                  onPressed: _showAddAlbumDialog,
                  backgroundColor: const Color(0xFFFF9900),
                  icon: const Icon(Icons.album, color: Colors.white),
                  label: const Text('New Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
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
                                ? DecorationImage(
                                    image: NetworkImage(
                                      album['cover_image_url'],
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: album['cover_image_url'] == null
                              ? const Icon(Icons.album, color: Colors.white24)
                              : null,
                        ),
                        title: Text(
                          album['title'] ?? 'Unknown Album',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${tracks.length} Tracks'),
                        children: [
                          ...tracks
                              .map(
                                (track) {
                                  final bool isCurrentTrack = _currentlyPlayingUrl == track['audio_url'];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isCurrentTrack ? const Color(0xFFFF9900) : Colors.black26,
                                      child: isCurrentTrack && _isPlaying 
                                          ? const Icon(Icons.graphic_eq, color: Colors.white, size: 16)
                                          : Text('${track['track_number']}', style: TextStyle(color: isCurrentTrack ? Colors.white : Colors.white70)),
                                    ),
                                    title: Text(track['title']),
                                    subtitle: track['is_sample'] == true ? const Text('Sample / Free', style: TextStyle(color: Colors.amber, fontSize: 12)) : null,
                                    trailing: IconButton(
                                      icon: Icon(
                                        isCurrentTrack && _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                        color: const Color(0xFFFF9900),
                                        size: 32,
                                      ),
                                      onPressed: () async {
                                        if (isCurrentTrack && _isPlaying) {
                                          await _audioPlayer.pause();
                                        } else {
                                          await _audioPlayer.play(UrlSource(track['audio_url']));
                                          setState(() => _currentlyPlayingUrl = track['audio_url']);
                                        }
                                      },
                                    ),
                                  );
                                }
                              )
                              .toList(),
                          ListTile(
                            leading: const Icon(
                              Icons.add,
                              color: Color(0xFFFF9900),
                            ),
                            title: const Text(
                              'Add Track',
                              style: TextStyle(color: Color(0xFFFF9900)),
                            ),
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
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9900)),
            ),
          ),
      ],
    );
  }
}
