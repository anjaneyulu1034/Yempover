import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerUtils {
  static final ImagePicker _picker = ImagePicker();

  static Future<List<File>> pickImagesFromGallery({
    int maxImages = 10,
    bool allowMultiple = true,
  }) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        return pickedFiles.map((file) => File(file.path)).toList();
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
    return [];
  }

  static Future<File?> takePhotoWithCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (photo != null) {
        return File(photo.path);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
    return null;
  }

  static Future<File?> pickSingleImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('Error picking single image: $e');
    }
    return null;
  }
}

class ImageUploadWidget extends StatefulWidget {
  final ValueChanged<List<File>> onImagesSelected;
  final int maxImages;
  final bool allowMultiple;

  const ImageUploadWidget({
    super.key,
    required this.onImagesSelected,
    this.maxImages = 10,
    this.allowMultiple = true,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  List<File> _selectedImages = [];

  Future<void> _pickImagesFromGallery() async {
    final images = await ImagePickerUtils.pickImagesFromGallery(
      maxImages: widget.maxImages,
      allowMultiple: widget.allowMultiple,
    );

    if (images.isNotEmpty) {
      final newImages = [..._selectedImages, ...images];
      if (newImages.length <= widget.maxImages) {
        setState(() {
          _selectedImages = newImages;
        });
        widget.onImagesSelected(_selectedImages);
      } else {
        _showMaxImagesAlert();
      }
    }
  }

  Future<void> _takePhotoWithCamera() async {
    final photo = await ImagePickerUtils.takePhotoWithCamera();
    if (photo != null) {
      if (_selectedImages.length < widget.maxImages) {
        setState(() {
          _selectedImages.add(photo);
        });
        widget.onImagesSelected(_selectedImages);
      } else {
        _showMaxImagesAlert();
      }
    }
  }

  void _showMaxImagesAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Images Reached'),
        content: Text('You can only upload up to ${widget.maxImages} images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onImagesSelected(_selectedImages);
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImagesFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhotoWithCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showImageSourceOptions,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Images'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_selectedImages.length} image(s) selected',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
