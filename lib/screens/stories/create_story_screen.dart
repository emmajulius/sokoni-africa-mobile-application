import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../services/story_api_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/file_helper.dart' show createFile;

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final TextEditingController _captionController = TextEditingController();
  XFile? _selectedMedia;
  bool _isUploading = false;
  bool _isImage = true;
  VideoPlayerController? _videoController;
  final ImagePicker _picker = ImagePicker();
  final StoryApiService _storyApiService = StoryApiService();
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      // Show dialog to choose between image and video
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select from Gallery'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('Image'),
                onTap: () => Navigator.pop(context, 'image'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.red),
                title: const Text('Video'),
                onTap: () => Navigator.pop(context, 'video'),
              ),
            ],
          ),
        ),
      );

      if (choice == null) return;

      if (choice == 'image') {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );

        if (image != null) {
          _setMedia(image, isImage: true);
        }
      } else if (choice == 'video') {
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(seconds: 60),
        );

        if (video != null) {
          _setMedia(video, isImage: false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking from gallery: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        _setMedia(image, isImage: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60),
      );

      if (video != null) {
        _setMedia(video, isImage: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording video: $e')),
        );
      }
    }
  }

  void _setMedia(XFile file, {required bool isImage}) {
    // Dispose previous video controller
    _videoController?.dispose();
    _videoController = null;

    setState(() {
      _selectedMedia = file;
      _isImage = isImage;
    });

    // Initialize video player if it's a video
    if (!isImage) {
      _initializeVideoPlayer(file.path);
    }
  }

  Future<void> _initializeVideoPlayer(String videoPath) async {
    try {
      if (kIsWeb) {
        // For web, read the file as bytes and create a data URL
        final bytes = await _selectedMedia!.readAsBytes();
        // Create a data URL for web video playback
        final base64 = base64Encode(bytes);
        final mimeType = _selectedMedia!.mimeType ?? 'video/mp4';
        final dataUrl = 'data:$mimeType;base64,$base64';
        _videoController = VideoPlayerController.networkUrl(Uri.parse(dataUrl));
      } else {
        // For mobile, use file path
        // File is only available on non-web platforms
        final file = createFile(videoPath);
        if (file != null) {
          _videoController = VideoPlayerController.file(file);
        }
      }
      
      if (_videoController != null) {
        await _videoController!.initialize();
        _videoController!.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
        setState(() {});
        _videoController!.setLooping(true);
        _videoController!.play();
      }
    } catch (e) {
      print('Error initializing video player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  Future<void> _postStory() async {
    if (_selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image or video')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authService = AuthService();
      await authService.initialize();
      if (!authService.isAuthenticated || authService.authToken == null) {
        throw Exception('User not authenticated');
      }

      // Upload media
      final uploadResult = await _apiService.uploadStoryMedia(_selectedMedia!);
      final mediaUrl = uploadResult['url'] as String;
      final mediaType = uploadResult['media_type'] as String;

      // Create story via API
      await _storyApiService.createStory(
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        caption: _captionController.text.isEmpty
            ? null
            : _captionController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting story: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Story'),
        actions: [
          if (_selectedMedia != null)
            TextButton(
              onPressed: _isUploading ? null : _postStory,
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Media Preview
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: _selectedMedia != null
                  ? _isImage
                      ? FutureBuilder<Uint8List>(
                          future: _selectedMedia!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.contain,
                              );
                            }
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          },
                        )
                      : _videoController != null &&
                              _videoController!.value.isInitialized
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _videoController!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 64,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_videoController!.value.isPlaying) {
                                        _videoController!.pause();
                                      } else {
                                        _videoController!.play();
                                      }
                                    });
                                  },
                                ),
                              ],
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Select an image or video',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          // Caption Input
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: 'Add a caption...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
          // Upload Button
          if (_selectedMedia != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _postStory,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Upload Story',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _recordVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Video'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}