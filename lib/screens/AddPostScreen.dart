import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Yempover_app/models/my_post_model.dart';
import 'dart:io';
import 'package:Yempover_app/services/category_service.dart';
import 'package:Yempover_app/services/add_post_service.dart';
import 'package:Yempover_app/models/add_post_model.dart';
import 'package:Yempover_app/services/token_service.dart';
import 'package:Yempover_app/services/location_service.dart';

class AddPostScreen extends StatefulWidget {
  final Function()? onPostAdded;
  final MyPost? post;

  const AddPostScreen({super.key, this.onPostAdded, this.post});

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
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _willPayAmountController =
      TextEditingController();

  // Category data - Two level selection
  List<Map<String, dynamic>> _mainCategories = [];
  List<Map<String, dynamic>> _subCategories = [];
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  bool _isLoadingCategories = false;
  bool _isLoadingSubCategories = false;
  String? _categoryError;

  // Image upload variables
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  // Location variables
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadMainCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _willPayAmountController.dispose();
    _addPostService.dispose();
    super.dispose();
  }

  Future<void> _checkLoginAndLoadMainCategories() async {
    final isLoggedIn = await TokenService().isLoggedIn();
    if (!isLoggedIn) {
      _showLoginDialog();
      return;
    }
    _loadMainCategories();
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

  Future<void> _loadMainCategories() async {
    if (_postType.isEmpty) return;

    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
      _mainCategories = [];
      _subCategories = [];
      _selectedMainCategoryId = null;
      _selectedSubCategoryId = null;
    });

    try {
      final type = _postType.toLowerCase();
      final response = await _categoryService.getCategories(type: type);

      // Get only main categories (parent categories)
      final allCategories = _categoryService.getAllChildCategories(response);

      // Extract unique parent categories
      final Map<String, Map<String, dynamic>> mainCategoryMap = {};

      for (var category in allCategories) {
        if (category['parentId'] != null && category['parentName'] != null) {
          // This is a subcategory, add its parent
          final parentId = category['parentId'];
          final parentName = category['parentName'];

          if (!mainCategoryMap.containsKey(parentId)) {
            mainCategoryMap[parentId] = {
              'id': parentId,
              'name': parentName,
              'type': type,
            };
          }
        } else {
          // This might be a main category itself
          if (!mainCategoryMap.containsKey(category['id'])) {
            mainCategoryMap[category['id']] = {
              'id': category['id'],
              'name': category['name'],
              'type': type,
            };
          }
        }
      }

      setState(() {
        _mainCategories = mainCategoryMap.values.toList();
        _isLoadingCategories = false;
      });

      debugPrint('✅ Loaded ${_mainCategories.length} main categories');
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _categoryError = e.toString().replaceAll('Exception: ', '');
      });
      _showErrorSnackBar('Failed to load categories: ${e.toString()}');
    }
  }

  Future<void> _loadSubCategories(String mainCategoryId) async {
    setState(() {
      _isLoadingSubCategories = true;
      _subCategories = [];
      _selectedSubCategoryId = null;
    });

    try {
      final type = _postType.toLowerCase();
      final response = await _categoryService.getCategories(type: type);

      // Get all child categories
      final allCategories = _categoryService.getAllChildCategories(response);

      // Filter subcategories that belong to the selected main category
      final filteredSubCategories = allCategories.where((category) {
        return category['parentId'] == mainCategoryId;
      }).toList();

      setState(() {
        _subCategories = filteredSubCategories;
        _isLoadingSubCategories = false;
      });

      debugPrint('✅ Loaded ${_subCategories.length} subcategories');
    } catch (e) {
      setState(() {
        _isLoadingSubCategories = false;
      });
      _showErrorSnackBar('Failed to load subcategories: ${e.toString()}');
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

  // Image picker with compression
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
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

  // Image upload section
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
          onTap: _showImageSourceDialog,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
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
                      color: _selectedImages.isEmpty ? Colors.red : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Looking For image upload section
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
          onTap: _showImageSourceDialog,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
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

  // Category Selection - Two level dropdown
  Widget _buildCategorySelection() {
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

        // Main Category Dropdown
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
                  onPressed: _loadMainCategories,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_mainCategories.isEmpty)
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
                  onPressed: _loadMainCategories,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Category Dropdown
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedMainCategoryId != null
                      ? _mainCategories.firstWhere(
                          (cat) => cat['id'] == _selectedMainCategoryId,
                          orElse: () => _mainCategories.first,
                        )
                      : null,
                  decoration: InputDecoration(
                    hintText: 'Select main category',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: _mainCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        category['name'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMainCategoryId = value['id'];
                        _selectedSubCategoryId = null;
                      });
                      _loadSubCategories(value['id']);
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Sub Category Dropdown (shown only after main category is selected)
              if (_selectedMainCategoryId != null) ...[
                const Text(
                  'Sub Category',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),

                if (_isLoadingSubCategories)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_subCategories.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'No subcategories available',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedSubCategoryId != null
                          ? _subCategories.firstWhere(
                              (cat) => cat['id'] == _selectedSubCategoryId,
                              orElse: () => _subCategories.first,
                            )
                          : null,
                      decoration: InputDecoration(
                        hintText: 'Select sub category',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down),
                      items: _subCategories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedSubCategoryId = value['id'];
                          });
                        }
                      },
                    ),
                  ),
              ],
            ],
          ),
      ],
    );
  }

  // Location field
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

  // Price field
  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _selectedOption == 1 ? 'Price' : 'Will Pay Amount',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
          controller: _selectedOption == 1
              ? _priceController
              : _willPayAmountController,
          decoration: InputDecoration(
            hintText: _selectedOption == 1
                ? _postType == 'Product'
                      ? 'Enter product price'
                      : 'Enter service price'
                : 'Enter amount you are willing to pay',
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

  @override
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Container(
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

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Your Post Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
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

                      if (_selectedOption == 1) _buildStep1(),
                      if (_selectedOption == 2) _buildLookingForStep1(),

                      const SizedBox(height: 100), // space for bottom buttons
                    ],
                  ),
                ),
              ),

              // Bottom Buttons (SAFE FIX)
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
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
                          onPressed: _isSubmitting ? null : _validateAndSubmit,
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
              ),
            ],
          ),
        ),
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
                    _selectedMainCategoryId = null;
                    _selectedSubCategoryId = null;
                  });
                  _loadMainCategories();
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
                    _selectedMainCategoryId = null;
                    _selectedSubCategoryId = null;
                  });
                  _loadMainCategories();
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

        // Category - Two level selection
        _buildCategorySelection(),

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

        const SizedBox(height: 24),

        // Price
        _buildPriceField(),
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
                    _selectedMainCategoryId = null;
                    _selectedSubCategoryId = null;
                  });
                  _loadMainCategories();
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
                    _selectedMainCategoryId = null;
                    _selectedSubCategoryId = null;
                  });
                  _loadMainCategories();
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

        // Category - Two level selection
        _buildCategorySelection(),

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
        _buildPriceField(),
      ],
    );
  }

  void _validateAndSubmit() {
    // Validate required fields
    if (_titleController.text.isEmpty) {
      _showError('Please enter a title');
      return;
    }

    if (_selectedMainCategoryId == null) {
      _showError('Please select a main category');
      return;
    }

    if (_selectedSubCategoryId == null) {
      _showError('Please select a sub category');
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
    }

    // For all posts, require location
    if (_locationController.text.isEmpty && _postType == 'Product') {
      _showError('Please enter a location');
      return;
    }

    // Price validation
    if (_selectedOption == 1) {
      if (_priceController.text.isEmpty) {
        _showError('Please enter a price');
        return;
      }
      if (double.tryParse(_priceController.text) == null) {
        _showError('Please enter a valid price');
        return;
      }
    } else {
      if (_willPayAmountController.text.isEmpty) {
        _showError('Please enter the amount you are willing to pay');
        return;
      }
      if (double.tryParse(_willPayAmountController.text) == null) {
        _showError('Please enter a valid amount');
        return;
      }
    }

    // Submit directly without step 2 dialog
    _submitPost();
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

      // Convert images to base64 data URLs
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        debugPrint(
          '📤 Converting ${_selectedImages.length} images to base64...',
        );

        imageUrls = await _addPostService.getImageUrlsFromBase64(
          _selectedImages,
        );

        debugPrint('✅ Converted ${imageUrls.length} images to base64');
      }

      double price = _selectedOption == 1
          ? double.parse(_priceController.text)
          : double.parse(_willPayAmountController.text);

      if (_selectedOption == 1) {
        // Create product/service post
        if (_postType == 'Product') {
          final request = CreateProductRequest(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            categoryId: _selectedSubCategoryId!,
            images: imageUrls,
            location: _locationController.text.trim(),
            barterStatus: 'NO_BARTER', // Default value
            price: price,
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
            categoryId: _selectedSubCategoryId!,
            images: imageUrls,
            status: 'PROVIDE_SERVICE',
            price: price,
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
            categoryId: _selectedSubCategoryId!,
            images: imageUrls,
            location: _locationController.text.trim(),
            barterStatus: 'LOOKING_FOR',
            price: price,
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
            categoryId: _selectedSubCategoryId!,
            images: imageUrls,
            status: 'LOOKING_FOR_SERVICE',
            price: price,
          );

          debugPrint(
            '📦 Creating looking for service post with ${imageUrls.length} images',
          );
          final response = await _addPostService.createServicePost(request);
          debugPrint('✅ Looking for service created');
        }
      }

      // Close add post screen
      Navigator.pop(context);

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
        });
      }
    }
  }
}
