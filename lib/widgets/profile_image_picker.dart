// widgets/profile_image_picker.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/constants.dart';
import '../services/storage_service.dart';

class ProfileImagePicker extends StatefulWidget {
  final Function(String) onImageSelected;
  final String? currentImagePath;
  final String userInitial;

  const ProfileImagePicker({
    super.key,
    required this.onImageSelected,
    this.currentImagePath,
    required this.userInitial,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Profile image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: _buildProfileImage(),
          ),
        ),

        // Edit button
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
              onPressed: _pickImage,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
          strokeWidth: 2,
        ),
      );
    }

    if (widget.currentImagePath != null &&
        widget.currentImagePath!.isNotEmpty) {
      // Check if it's a network image or local file
      if (widget.currentImagePath!.startsWith('http') || kIsWeb) {
        return Image.network(
          widget.currentImagePath!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar();
          },
        );
      } else {
        // Local file
        return Image.file(
          File(widget.currentImagePath!),
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar();
          },
        );
      }
    }

    // No image, show initials
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        widget.userInitial.toUpperCase(),
        style: TextStyle(
          fontSize: 50,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    // Show options for camera or gallery
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb) // Camera only available on mobile
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.camera);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Save to local storage
        final storageService = StorageService();
        final savedPath = await storageService.saveProfileImage(
          pickedFile.path,
        );

        if (savedPath.isNotEmpty) {
          // Call callback with the saved path
          widget.onImageSelected(savedPath);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
