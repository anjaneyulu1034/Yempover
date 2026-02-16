// lib/screens/AddPostScreen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yempover_app/models/my_post_model.dart';
import 'dart:io';
import 'dart:convert';
import 'package:yempover_app/services/category_service.dart';
import 'package:yempover_app/services/add_post_service.dart';
import 'package:yempover_app/models/add_post_model.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/services/location_service.dart';

class AddPostScreen extends StatefulWidget {
  final Function()? onPostAdded;
  final MyPost? post; // ✅ ADD THIS

  const AddPostScreen({
    super.key,
    this.onPostAdded,
    this.post, // ✅ ADD THIS
  });

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  // Services
  final CategoryService _categoryService = CategoryService();
  final AddPostService _addPostService = AddPostService();
  final LocationService _locationService = LocationService();

  // Step 1 variables
  int _selectedOption = 1;
  String _postType = 'Product';

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _barterWishController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _willPayAmountController =
      TextEditingController();

  // Category data
  List<Map<String, dynamic>> _childCategories = [];
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isLoadingCategories = false;
  String? _categoryError;

  // Step 2 variables
  bool _barterAvailable = false;
  String? _barterCategoryId;
  String? _barterCategoryName;
  bool _canClubItems = true;
  bool _soldForMoney = false;
  String _transportationOption = 'transport_desired';

  // Image upload variables
  List<File> _selectedImages = [];
  bool _isUploadingImages = false;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  // Location variables
  bool _isGettingLocation = false;
  double? _currentLatitude;
  double? _currentLongitude;

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _barterWishController.dispose();
    _priceController.dispose();
    _willPayAmountController.dispose();
    _categoryService.dispose();
    _addPostService.dispose();
    super.dispose();
  }

  Future<void> _checkLoginAndLoadCategories() async {
    final isLoggedIn = await TokenService().isLoggedIn();
    if (!isLoggedIn) {
      _showLoginDialog();
      return;
    }
    _loadCategories();
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Please login again to continue.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close AddPostScreen
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCategories() async {
    if (_postType.isEmpty) return;

    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final type = _postType.toLowerCase();
      final response = await _categoryService.getCategories(type: type);

      setState(() {
        _childCategories = _categoryService.getAllChildCategories(response);
        _isLoadingCategories = false;
      });

      debugPrint('✅ Loaded ${_childCategories.length} child categories');
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _categoryError = e.toString().replaceAll('Exception: ', '');
      });
      _showErrorSnackBar('Failed to load categories: ${e.toString()}');
    }
  }

  // Location Methods
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      Position? position = await _locationService.getCurrentLocation();

      if (position == null) {
        _showError('Unable to get your current location');
        return;
      }

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      String? address = await _locationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      if (address != null && address.isNotEmpty) {
        setState(() {
          _locationController.text = address;
        });
        _showSuccessSnackBar('Location updated successfully');
      } else {
        setState(() {
          _locationController.text =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      debugPrint('🔴 Error getting location: $e');
      _showError('Failed to get location: ${e.toString()}');
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Updated image picker with compression
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70, // Reduced quality for smaller payload
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
        debugPrint('✅ Image selected: ${image.path}');
      }
    } catch (e) {
      debugPrint('🔴 Error picking image: $e');
      _showErrorSnackBar('Failed to pick image');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Choose Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Updated image upload section with better UI feedback
  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Upload Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    _postType == 'Product' &&
                        _selectedOption == 1 &&
                        _selectedImages.isEmpty
                    ? Colors.red
                    : Colors.black,
              ),
            ),
            if (_postType == 'Product' && _selectedOption == 1)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Selected Images Grid
        if (_selectedImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
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
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        if (_selectedImages.isNotEmpty) const SizedBox(height: 8),

        // Upload Button
        GestureDetector(
          onTap: _isUploadingImages ? null : _showImageSourceDialog,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    _postType == 'Product' &&
                        _selectedOption == 1 &&
                        _selectedImages.isEmpty
                    ? Colors.red
                    : Colors.grey.shade300,
                width:
                    _postType == 'Product' &&
                        _selectedOption == 1 &&
                        _selectedImages.isEmpty
                    ? 2
                    : 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isUploadingImages
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Uploading images...'),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_upload,
                        size: 40,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload your Images',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to upload',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (_postType == 'Product' && _selectedOption == 1)
                        Text(
                          _selectedImages.isEmpty
                              ? '*At least 1 image required'
                              : 'Add more images (optional)',
                          style: TextStyle(
                            fontSize: 11,
                            color: _selectedImages.isEmpty
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLookingForImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Photos (Optional)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // Selected Images Grid
        if (_selectedImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
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
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        if (_selectedImages.isNotEmpty) const SizedBox(height: 8),

        // Upload Button
        GestureDetector(
          onTap: _isUploadingImages ? null : _showImageSourceDialog,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isUploadingImages
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Uploading images...'),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_upload,
                        size: 40,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add reference images (optional)',
                        style: TextStyle(color: Colors.grey),
                      ),
                      if (_selectedImages.isEmpty) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Tap to upload',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Category',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_isLoadingCategories)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_categoryError != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _categoryError!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                TextButton(
                  onPressed: _loadCategories,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_childCategories.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'No categories available for $_postType',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadCategories,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedCategoryId != null
                ? _childCategories.firstWhere(
                    (cat) => cat['id'] == _selectedCategoryId,
                    orElse: () => _childCategories.first,
                  )
                : null,
            decoration: InputDecoration(
              hintText: 'Select a category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: _childCategories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['name'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      category['parentName'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategoryId = value['id'];
                  _selectedCategoryName = value['name'];
                });
              }
            },
            validator: (value) {
              if (_selectedCategoryId == null) {
                return 'Please select a category';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildBarterCategoryDropdown() {
    if (_childCategories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Barter Category',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _barterCategoryId != null
              ? _childCategories.firstWhere(
                  (cat) => cat['id'] == _barterCategoryId,
                  orElse: () => _childCategories.first,
                )
              : null,
          decoration: InputDecoration(
            hintText: 'What do you want in return?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: _childCategories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    category['parentName'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _barterCategoryId = value['id'];
                _barterCategoryName = value['name'];
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Enter Product Location',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Tap location icon to get current location',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
            suffixIcon: _isGettingLocation
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.blue),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Get current location',
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your current location will be used to find nearby items',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Post',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Your Post Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    1,
                    'You want to add your product/service to barter/sell in Marketplace.',
                  ),
                  const SizedBox(height: 12),
                  _buildOptionCard(
                    2,
                    'You need (or are you looking for) a specific product or service in the Marketplace.',
                  ),
                  const SizedBox(height: 24),

                  // Step 1: Basic Details
                  if (_selectedOption == 1) _buildStep1(),
                  if (_selectedOption == 2) _buildLookingForStep1(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _validateAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E5BFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Next',
                            style: TextStyle(color: Colors.white),
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

  Widget _buildOptionCard(int option, String description) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedOption == option
              ? const Color(0xFF2E5BFF)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedOption = option),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedOption == option
                        ? const Color(0xFF2E5BFF)
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: _selectedOption == option
                    ? const Icon(
                        Icons.circle,
                        size: 12,
                        color: Color(0xFF2E5BFF),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(description, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create a New Post',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),

        // Post Type
        const Text(
          'Post Type',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Product'),
                selected: _postType == 'Product',
                onSelected: (selected) {
                  setState(() {
                    _postType = 'Product';
                    _selectedCategoryId = null;
                    _selectedCategoryName = null;
                    _barterCategoryId = null;
                    _barterCategoryName = null;
                  });
                  _loadCategories();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ChoiceChip(
                label: const Text('Service'),
                selected: _postType == 'Service',
                onSelected: (selected) {
                  setState(() {
                    _postType = 'Service';
                    _selectedCategoryId = null;
                    _selectedCategoryName = null;
                    _barterCategoryId = null;
                    _barterCategoryName = null;
                  });
                  _loadCategories();
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Title
        Row(
          children: [
            const Text(
              'Title',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: _postType == 'Product'
                ? 'Enter product title'
                : 'Enter service title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Category
        _buildCategoryDropdown(),

        const SizedBox(height: 24),

        // Description
        Row(
          children: [
            const Text(
              'Description',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: _postType == 'Product'
                ? 'Describe your product'
                : 'Describe your service',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Upload Photos
        _buildImageUploadSection(),

        if (_postType == 'Product') ...[
          const SizedBox(height: 24),

          // Location with current location feature
          _buildLocationField(),
        ],
      ],
    );
  }

  Widget _buildLookingForStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Looking For',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),

        // Post Type
        const Text(
          'Post Type',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Product'),
                selected: _postType == 'Product',
                onSelected: (selected) {
                  setState(() {
                    _postType = 'Product';
                    _selectedCategoryId = null;
                    _selectedCategoryName = null;
                  });
                  _loadCategories();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ChoiceChip(
                label: const Text('Service'),
                selected: _postType == 'Service',
                onSelected: (selected) {
                  setState(() {
                    _postType = 'Service';
                    _selectedCategoryId = null;
                    _selectedCategoryName = null;
                  });
                  _loadCategories();
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Title
        Row(
          children: [
            const Text(
              'Title',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'What are you looking for?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Category
        _buildCategoryDropdown(),

        const SizedBox(height: 24),

        // Description
        Row(
          children: [
            const Text(
              'Description',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe what you are looking for',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Upload Photos
        _buildLookingForImageUploadSection(),

        const SizedBox(height: 24),

        // Location
        _buildLocationField(),

        const SizedBox(height: 24),

        // Will Pay Amount
        Row(
          children: [
            const Text(
              'Will Pay Amount',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _willPayAmountController,
          decoration: InputDecoration(
            hintText: 'Enter amount you are willing to pay',
            prefixText: '\$ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  void _validateAndProceed() {
    // Validate required fields
    if (_titleController.text.isEmpty) {
      _showError('Please enter a title');
      return;
    }

    if (_selectedCategoryId == null) {
      _showError('Please select a category');
      return;
    }

    if (_descriptionController.text.isEmpty) {
      _showError('Please enter a description');
      return;
    }

    // For product posts (selling), require at least one image
    if (_postType == 'Product' && _selectedOption == 1) {
      if (_selectedImages.isEmpty) {
        _showError('Please upload at least one image for products');
        return;
      }
      if (_locationController.text.isEmpty) {
        _showError('Please enter a location');
        return;
      }
    }

    // For "Looking For" posts, require location
    if (_selectedOption == 2) {
      if (_locationController.text.isEmpty) {
        _showError('Please enter a location');
        return;
      }
      if (_willPayAmountController.text.isEmpty) {
        _showError('Please enter the amount you are willing to pay');
        return;
      }
    }

    // For service posts (selling), no image required
    if (_postType == 'Service' && _selectedOption == 1) {
      // Location is optional for services
    }

    // Show step 2 dialog
    _showStep2Dialog();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showStep2Dialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStep2Dialog(),
    );
  }

  Widget _buildStep2Dialog() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Additional Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barter Available - Only show for selling posts
                      if (_selectedOption == 1) ...[
                        Row(
                          children: [
                            Checkbox(
                              value: _barterAvailable,
                              onChanged: (value) =>
                                  setState(() => _barterAvailable = value!),
                            ),
                            const Text('Barter Available'),
                          ],
                        ),

                        if (_barterAvailable) ...[
                          const SizedBox(height: 16),
                          _buildBarterCategoryDropdown(),

                          const SizedBox(height: 16),

                          const Text(
                            'Describe Barter Wish',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _barterWishController,
                            decoration: InputDecoration(
                              hintText: 'Describe what you want in return',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                      ],

                      // Club Items Option - Only for selling posts
                      if (_selectedOption == 1) ...[
                        const Text(
                          'Item Clubbing Option',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            RadioListTile<bool>(
                              title: const Text(
                                'This item can be clubbed with other items in your list while users make an offer',
                              ),
                              value: true,
                              groupValue: _canClubItems,
                              onChanged: (value) =>
                                  setState(() => _canClubItems = value!),
                            ),
                            RadioListTile<bool>(
                              title: const Text(
                                'No, this item cannot be clubbed and traded as a single product',
                              ),
                              value: false,
                              groupValue: _canClubItems,
                              onChanged: (value) =>
                                  setState(() => _canClubItems = value!),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],

                      // Sold for Money
                      Row(
                        children: [
                          Checkbox(
                            value: _soldForMoney,
                            onChanged: (value) =>
                                setState(() => _soldForMoney = value!),
                          ),
                          const Text('This item is sold for money'),
                        ],
                      ),

                      if (_soldForMoney) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            hintText: 'Enter price',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Transportation Flexibility - Only for product posts
                      if (_postType == 'Product' && _selectedOption == 1) ...[
                        const Text(
                          'Transportation Flexibility',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            RadioListTile<String>(
                              title: const Text(
                                'This item can be transported to desired location',
                              ),
                              value: 'transport_desired',
                              groupValue: _transportationOption,
                              onChanged: (value) => setState(
                                () => _transportationOption = value!,
                              ),
                            ),
                            RadioListTile<String>(
                              title: const Text(
                                'This item has to be picked from location',
                              ),
                              value: 'pickup_only',
                              groupValue: _transportationOption,
                              onChanged: (value) => setState(
                                () => _transportationOption = value!,
                              ),
                            ),
                            RadioListTile<String>(
                              title: const Text(
                                'This item can be transported with a delivery charge',
                              ),
                              value: 'transport_with_charge',
                              groupValue: _transportationOption,
                              onChanged: (value) => setState(
                                () => _transportationOption = value!,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E5BFF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitPost() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Check login status
      final isLoggedIn = await TokenService().isLoggedIn();
      if (!isLoggedIn) {
        _showLoginDialog();
        return;
      }

      // Show processing status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Converting images...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Convert images to base64 data URLs - NO SEPARATE UPLOAD
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
        });

        debugPrint(
          '📤 Converting ${_selectedImages.length} images to base64...',
        );

        // Direct conversion to base64 - bypass the broken upload endpoint
        imageUrls = await _addPostService.getImageUrlsFromBase64(
          _selectedImages,
        );

        debugPrint('✅ Converted ${imageUrls.length} images to base64');

        setState(() {
          _isUploadingImages = false;
        });
      }

      if (_selectedOption == 1) {
        // Create product/service post
        if (_postType == 'Product') {
          final request = CreateProductRequest(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            categoryId: _selectedCategoryId!,
            images: imageUrls, // Send base64 images directly
            location: _locationController.text.trim(),
            barterStatus: _barterAvailable ? 'OPEN_FOR_BARTER' : 'NO_BARTER',
            price: double.tryParse(_priceController.text) ?? 0.0,
          );

          debugPrint(
            '📦 Creating product post with ${imageUrls.length} images',
          );
          final response = await _addPostService.createProductPost(request);
          debugPrint('✅ Product created successfully');
        } else {
          // Create service
          final request = CreateServiceRequest(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            categoryId: _selectedCategoryId!,
            images: imageUrls, // Send base64 images directly
            status: 'PROVIDE_SERVICE',
            price: double.tryParse(_priceController.text) ?? 0.0,
          );

          debugPrint(
            '📦 Creating service post with ${imageUrls.length} images',
          );
          final response = await _addPostService.createServicePost(request);
          debugPrint('✅ Service created successfully');
        }
      } else {
        // Handle "Looking For" posts
        if (_postType == 'Product') {
          final request = CreateProductRequest(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            categoryId: _selectedCategoryId!,
            images: imageUrls, // Send base64 images directly
            location: _locationController.text.trim(),
            barterStatus: 'LOOKING_FOR',
            price: double.tryParse(_willPayAmountController.text) ?? 0.0,
          );

          debugPrint(
            '📦 Creating looking for product post with ${imageUrls.length} images',
          );
          final response = await _addPostService.createProductPost(request);
          debugPrint('✅ Looking for product created');
        } else {
          final request = CreateServiceRequest(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            categoryId: _selectedCategoryId!,
            images: imageUrls, // Send base64 images directly
            status: 'LOOKING_FOR_SERVICE',
            price: double.tryParse(_willPayAmountController.text) ?? 0.0,
          );

          debugPrint(
            '📦 Creating looking for service post with ${imageUrls.length} images',
          );
          final response = await _addPostService.createServicePost(request);
          debugPrint('✅ Looking for service created');
        }
      }

      // Close all dialogs
      Navigator.pop(context); // Close step 2 dialog
      Navigator.pop(context); // Close add post screen

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post added successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Callback to refresh posts
        widget.onPostAdded?.call();
      }
    } catch (e) {
      debugPrint('🔴 Error submitting post: $e');

      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('400')) {
          errorMessage =
              'Failed to create post: Please check all required fields';
        } else if (errorMessage.contains('401')) {
          errorMessage = 'Session expired. Please login again.';
        } else if (errorMessage.contains('images')) {
          errorMessage =
              'Failed to process images. Please try again with smaller images.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploadingImages = false;
        });
      }
    }
  }
}
