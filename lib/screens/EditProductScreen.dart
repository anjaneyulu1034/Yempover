import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/api_constants.dart';
import '../models/my_post_model.dart';
import '../services/add_post_service.dart';
import '../services/category_service.dart';
import '../services/my_posts_service.dart';

class EditProductScreen extends StatefulWidget {
  final MyPost post;
  final Function() onProductUpdated;

  const EditProductScreen({
    super.key,
    required this.post,
    required this.onProductUpdated,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final MyPostsService _postsService = MyPostsService();
  final AddPostService _addPostService = AddPostService();
  final CategoryService _categoryService = CategoryService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;

  late String _selectedStatus;
  late String _selectedBarterStatus;
  late String _selectedCategoryId;
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  late String _postType;
  late bool _isListed;
  late List<String> _images;

  List<Map<String, dynamic>> _mainCategories = [];
  List<Map<String, dynamic>> _subCategories = [];
  bool _isLoadingCategories = false;
  String? _categoryLoadError;

  bool _isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCategories();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.post.title);
    _descriptionController = TextEditingController(
      text: widget.post.description,
    );
    _priceController = TextEditingController(
      text: widget.post.price != null ? widget.post.price.toString() : '',
    );
    _locationController = TextEditingController(
      text: widget.post.location ?? '',
    );

    _selectedStatus = widget.post.status;
    _selectedBarterStatus = _normalizeBarterStatus(widget.post.barterStatus);
    _selectedCategoryId = widget.post.categoryId;
    _postType = widget.post.type;
    _isListed = widget.post.isListed;
    _images = List.from(widget.post.images);
    _validateStatus();
  }

  String _normalizeBarterStatus(String? status) {
    final normalized = (status ?? '').trim().toUpperCase();
    if (normalized == 'OPEN_FOR_BARTER' || normalized == 'BARTER') {
      return 'OPEN_FOR_BARTER';
    }
    return 'NO_BARTER';
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryLoadError = null;
    });

    try {
      final response = await _categoryService.getCategories(type: _postType);

      final mainCategories = response.data
          .map(
            (parent) => {
              'id': parent.id,
              'name': parent.name,
              'children': parent.children,
            },
          )
          .toList();

      String? mappedMainCategoryId;
      String? mappedSubCategoryId;
      List<Map<String, dynamic>> mappedSubCategories = [];

      for (final main in mainCategories) {
        final String mainId = main['id'] as String;
        final children = main['children'] as List<dynamic>;

        if (_selectedCategoryId == mainId) {
          mappedMainCategoryId = mainId;
          mappedSubCategoryId = null;
          mappedSubCategories = children
              .map((child) => {'id': child.id, 'name': child.name})
              .toList();
          break;
        }

        for (final child in children) {
          if (_selectedCategoryId == child.id) {
            mappedMainCategoryId = mainId;
            mappedSubCategoryId = child.id;
            mappedSubCategories = children
                .map((sub) => {'id': sub.id, 'name': sub.name})
                .toList();
            break;
          }
        }

        if (mappedMainCategoryId != null) {
          break;
        }
      }

      if (mappedMainCategoryId == null && mainCategories.isNotEmpty) {
        final firstMain = mainCategories.first;
        mappedMainCategoryId = firstMain['id'] as String;
        final firstChildren = firstMain['children'] as List<dynamic>;
        mappedSubCategories = firstChildren
            .map((child) => {'id': child.id, 'name': child.name})
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _mainCategories = mainCategories
            .map((main) => {'id': main['id'], 'name': main['name']})
            .toList();
        _selectedMainCategoryId = mappedMainCategoryId;
        _subCategories = mappedSubCategories;
        _selectedSubCategoryId = mappedSubCategoryId;
        _selectedCategoryId =
            mappedSubCategoryId ?? mappedMainCategoryId ?? _selectedCategoryId;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
        _categoryLoadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _onMainCategoryChanged(String? value) async {
    if (value == null) return;

    setState(() {
      _selectedMainCategoryId = value;
      _selectedSubCategoryId = null;
      _selectedCategoryId = value;
      _subCategories = [];
      _isLoadingCategories = true;
    });

    try {
      final response = await _categoryService.getCategories(type: _postType);
      final parent = response.data.where((category) => category.id == value);

      if (!mounted) return;

      if (parent.isNotEmpty) {
        final children = parent.first.children
            .map((child) => {'id': child.id, 'name': child.name})
            .toList();

        setState(() {
          _subCategories = children;
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _subCategories = [];
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  void _validateStatus() {
    final validStatuses = _getValidStatuses();

    if (!validStatuses.contains(_selectedStatus)) {
      _selectedStatus = _postType == 'service' ? 'PROVIDE_SERVICE' : 'FOR_SALE';
    }
  }

  List<String> _getValidStatuses() {
    if (_postType == 'service') {
      return ['PROVIDE_SERVICE', 'SOLD'];
    } else {
      return ['FOR_SALE', 'SOLD'];
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'FOR_SALE':
        return 'For Sale';
      case 'PROVIDE_SERVICE':
        return 'Providing Service';
      case 'SOLD':
        return 'Sold';
      default:
        return status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (!mounted) return;

      if (image != null) {
        setState(() {
          // Keep local file path for preview and convert to base64 during save.
          _images.add(image.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected successfully'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final List<String> existingImages = [];
      final List<String> newBase64Images = [];

      for (final image in _images) {
        if (_isLocalImagePath(image)) {
          final file = File(image);
          if (!await file.exists()) {
            continue;
          }

          final base64Image = await _addPostService.imageToBase64Url(file);
          newBase64Images.add(base64Image);
        } else if (image.trim().startsWith('data:image/')) {
          newBase64Images.add(image);
        } else {
          existingImages.add(image);
        }
      }

      final uploadedImageUrls = newBase64Images.isNotEmpty
          ? await _postsService.uploadPostImagesBase64(newBase64Images)
          : <String>[];

      final List<String> preparedImages = [
        ...existingImages,
        ...uploadedImageUrls,
      ];

      if (preparedImages.isEmpty) {
        throw Exception('Please add at least one image');
      }

      // Create request with type explicitly set
      final requestData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'images': preparedImages,
        'status': _selectedStatus,
        'barterStatus': _normalizeBarterStatus(_selectedBarterStatus),
        'categoryId': _selectedCategoryId,
        'isListed': _isListed,
        'type': _postType, // IMPORTANT: Include the post type
      };

      // Add price if present
      if (_priceController.text.isNotEmpty) {
        requestData['price'] = double.parse(_priceController.text);
      }

      // Add location if present
      if (_locationController.text.trim().isNotEmpty) {
        requestData['location'] = _locationController.text.trim();
      }

      debugPrint('📦 Sending update request with type: $_postType');
      debugPrint('📦 Request data: $requestData');

      final response = await _postsService.updatePost(
        widget.post.id,
        requestData,
      );

      if (!mounted) return;

      if (response.status == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _postType == 'service'
                  ? 'Service updated successfully'
                  : 'Product updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onProductUpdated();
        Navigator.pop(context, true);
      } else {
        throw Exception(
          response.message.isNotEmpty ? response.message : 'Update failed',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          _postType == 'service' ? 'Edit Service' : 'Edit Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? Colors.grey : Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).viewInsets.bottom +
                        MediaQuery.of(context).padding.bottom +
                        20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Type Indicator
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _postType == 'service'
                              ? Colors.purple.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _postType == 'service'
                                ? Colors.purple.shade200
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _postType == 'service'
                                  ? Icons.build_circle
                                  : Icons.shopping_bag,
                              color: _postType == 'service'
                                  ? Colors.purple.shade700
                                  : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _postType == 'service'
                                        ? 'Service Post'
                                        : 'Product Post',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _postType == 'service'
                                          ? Colors.purple.shade700
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                  Text(
                                    _postType == 'service'
                                        ? 'You are offering a service'
                                        : 'You are selling a product',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _postType == 'service'
                                          ? Colors.purple.shade600
                                          : Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Images Section
                      _buildImagesSection(),

                      const SizedBox(height: 20),

                      _buildTextField(
                        label: 'Title',
                        controller: _titleController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Description',
                        controller: _descriptionController,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildDropdownField(
                        label: 'Category',
                        value: _selectedMainCategoryId,
                        items: _mainCategories.map<DropdownMenuItem<String>>((
                          category,
                        ) {
                          return DropdownMenuItem<String>(
                            value: category['id'] as String,
                            child: Text(category['name'] as String),
                          );
                        }).toList(),
                        onChanged: _isLoadingCategories
                            ? (_) {}
                            : (value) {
                                _onMainCategoryChanged(value);
                              },
                        hint: _isLoadingCategories
                            ? 'Loading categories...'
                            : 'Select a category',
                      ),

                      if (_subCategories.isNotEmpty) const SizedBox(height: 16),

                      if (_subCategories.isNotEmpty)
                        _buildDropdownField(
                          label: 'Sub Category',
                          value: _selectedSubCategoryId,
                          items: _subCategories.map<DropdownMenuItem<String>>((
                            category,
                          ) {
                            return DropdownMenuItem<String>(
                              value: category['id'] as String,
                              child: Text(category['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSubCategoryId = value;
                              _selectedCategoryId =
                                  value ?? (_selectedMainCategoryId ?? '');
                            });
                          },
                          hint: 'Select a sub category',
                        ),

                      if (_categoryLoadError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _categoryLoadError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _loadCategories,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Price',
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        prefix: '\$ ',
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildDropdownField(
                        label: 'Status',
                        value: _selectedStatus,
                        items: _getValidStatuses().map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_getStatusDisplayName(status)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value.toString();
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildDropdownField(
                        label: 'Barter Status',
                        value: _selectedBarterStatus,
                        items: const [
                          DropdownMenuItem(
                            value: 'NO_BARTER',
                            child: Text('No Barter'),
                          ),
                          DropdownMenuItem(
                            value: 'OPEN_FOR_BARTER',
                            child: Text('Open for Barter'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedBarterStatus = _normalizeBarterStatus(
                              value,
                            );
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Location (Optional)',
                        controller: _locationController,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      // Listed Switch
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Listed Publicly',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Switch(
                              value: _isListed,
                              onChanged: (value) {
                                setState(() {
                                  _isListed = value;
                                });
                              },
                              activeThumbColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Images',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length + 1,
              itemBuilder: (context, index) {
                if (index == _images.length) {
                  return _buildAddImageButton();
                }
                return _buildImageItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(int index) {
    final image = _images[index];
    final isLocalFile = _isLocalImagePath(image);
    final displayUrl = _normalizeImageUrl(image);

    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isLocalFile
                ? Image.file(
                    File(image),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Image.network(
                    displayUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
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
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isLocalImagePath(String path) {
    final value = path.trim();
    if (value.isEmpty) return false;
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:image/')) {
      return false;
    }
    return value.contains('\\') ||
        value.startsWith('/') ||
        value.contains(':/');
  }

  String _normalizeImageUrl(String value) {
    final image = value.trim();
    if (image.isEmpty) return image;
    if (image.startsWith('http://') ||
        image.startsWith('https://') ||
        image.startsWith('data:image/')) {
      return image;
    }

    final baseUri = Uri.parse(ApiConstants.baseUrl);
    final origin =
        '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';

    if (image.startsWith('/')) {
      return '$origin$image';
    }

    return '$origin/${image.replaceFirst(RegExp(r'^/+'), '')}';
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              'Add Image',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefix,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              prefixText: prefix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    String? hint,
  }) {
    final hasMatchingValue =
        value != null && items.any((item) => item.value == value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: hasMatchingValue ? value : null,
            items: items,
            onChanged: onChanged,
            hint: hint != null ? Text(hint) : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
