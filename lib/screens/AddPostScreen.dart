// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:YemPover_app/models/my_post_model.dart';
import 'dart:io';
import 'package:YemPover_app/services/category_service.dart';
import 'package:YemPover_app/services/add_post_service.dart';
import 'package:YemPover_app/models/add_post_model.dart';
import 'package:YemPover_app/screens/service/ServiceAvailabilityScreen.dart';
import 'package:YemPover_app/services/token_service.dart';
import 'package:YemPover_app/services/location_service.dart';
import 'package:YemPover_app/services/service_booking_service.dart';
import 'package:YemPover_app/utils/snackbar_utils.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:YemPover_app/widgets/coin_icon.dart';

class AddPostScreen extends StatefulWidget {
  final Function()? onPostAdded;
  final MyPost? post;

  const AddPostScreen({super.key, this.onPostAdded, this.post});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  static const int _maxAllowedImages = 5;
  static const int _minRequiredProductImages = 1;
  static const List<String> _expiryUnits = [
    'Minutes',
    'Hours',
    'Days',
    'Months',
    'No expiry',
  ];

  // Services
  final CategoryService _categoryService = CategoryService();
  final AddPostService _addPostService = AddPostService();
  final LocationService _locationService = LocationService();
  final ServiceBookingService _serviceBookingService = ServiceBookingService();

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
  final TextEditingController _expiryValueController = TextEditingController(
    text: '',
  );

  // Category data - Two level selection
  List<Map<String, dynamic>> _mainCategories = [];
  List<Map<String, dynamic>> _subCategories = [];
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  bool _isLoadingCategories = false;
  bool _isLoadingSubCategories = false;
  String? _categoryError;
  bool _barterAllowed = false;
  bool _canBeClubbed = true;

  // Image upload variables
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _showImageValidationError = false;
  String? _titleValidationError;
  String? _mainCategoryValidationError;
  String? _subCategoryValidationError;
  String? _descriptionValidationError;
  String? _locationValidationError;
  String? _priceValidationError;
  String? _expiryValidationError;

  // Location variables
  bool _isGettingLocation = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String _selectedExpiryUnit = 'No expiry';

  // Manual location search
  final FocusNode _locationFocusNode = FocusNode();
  bool _showLocationMinCharsHint = false;
  static const String _googleApiKey = 'AIzaSyAT3wIjV73qVXPAlgkyifnns38GztnbNF4';

  bool get _isImageRequiredForPost =>
      _selectedOption == 1 &&
      (_postType == 'Product' || _postType == 'Service');

  static const Color _primary = Color(0xFF2E5BFF);
  static const Color _primaryLight = Color(0xFFEFF4FF);
  static const Color _surfaceBg = Color(0xFFF8F9FF);
  static const Color _borderColor = Color(0xFFDDE6FF);
  static const Color _labelColor = Color(0xFF374151);
  static const double _fieldRadius = 12;

  Widget _modalDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    String? hintText,
    String? errorText,
    Widget? prefixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      errorText: errorText,
      prefixIcon: prefixIcon,
      prefixText: prefixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: _borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _fieldLabel(
    String label, {
    bool required = false,
    IconData? icon,
    bool useCoinIcon = false,
  }) {
    return Row(
      children: [
        if (useCoinIcon) ...[
          const CoinIcon(size: 18, iconSize: 11),
          const SizedBox(width: 6),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _labelColor,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPostTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(_fieldRadius),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: ['Product', 'Service'].map((type) {
          final selected = _postType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onCreatePostTypeChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  type,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? _primary : _labelColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _locationController.addListener(_onLocationTextChanged);
    _checkLoginAndLoadMainCategories();
  }

  @override
  void dispose() {
    _locationController.removeListener(_onLocationTextChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _willPayAmountController.dispose();
    _expiryValueController.dispose();
    _locationFocusNode.dispose();
    _addPostService.dispose();
    super.dispose();
  }

  void _onLocationTextChanged() {
    final query = _locationController.text.trim();
    final shouldShowHint = query.isNotEmpty && query.length < 4;

    if (shouldShowHint != _showLocationMinCharsHint) {
      setState(() {
        _showLocationMinCharsHint = shouldShowHint;
      });
    }

    if (query.length < 4 &&
        (_selectedLatitude != null || _selectedLongitude != null)) {
      setState(() {
        _selectedLatitude = null;
        _selectedLongitude = null;
      });
    }

    if (_locationValidationError != null && query.isNotEmpty) {
      setState(() {
        _locationValidationError = null;
      });
    }
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
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
          _selectedLatitude = position.latitude;
          _selectedLongitude = position.longitude;
          _locationController.text = address;
          _showLocationMinCharsHint = false;
        });
        _showSuccessSnackBar('Location updated successfully');
      } else {
        setState(() {
          _selectedLatitude = position.latitude;
          _selectedLongitude = position.longitude;
          _locationController.text =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _showLocationMinCharsHint = false;
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
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
      final remainingSlots = _maxAllowedImages - _selectedImages.length;
      if (remainingSlots <= 0) {
        _showErrorSnackBar('Maximum $_maxAllowedImages photos are allowed');
        return;
      }

      if (source == ImageSource.gallery) {
        final List<XFile> pickedImages = await _picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 70,
        );

        if (pickedImages.isEmpty) return;

        final imagesToAdd = pickedImages.take(remainingSlots).toList();

        setState(() {
          _selectedImages.addAll(
            imagesToAdd.map((image) => File(image.path)).toList(),
          );
          _showImageValidationError = false;
        });

        if (pickedImages.length > remainingSlots) {
          _showErrorSnackBar(
            'Only $remainingSlots image(s) added. Maximum $_maxAllowedImages photos are allowed.',
          );
        }
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
          _showImageValidationError = false;
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
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _labelColor,
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: _primary),
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: _primary),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 20),
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
    final hasError =
        _isImageRequiredForPost &&
        _showImageValidationError &&
        _selectedImages.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(
          'Upload Photos',
          required: _isImageRequiredForPost,
          icon: Icons.photo_library_outlined,
        ),
        const SizedBox(height: 10),

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
                      borderRadius: BorderRadius.circular(_fieldRadius),
                      border: Border.all(color: _borderColor),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        if (_selectedImages.isNotEmpty) const SizedBox(height: 10),

        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 130),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: hasError ? Colors.red.shade50 : _primaryLight,
              border: Border.all(
                color: hasError ? Colors.red : _primary.withValues(alpha: 0.35),
                width: hasError ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(_fieldRadius),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: hasError ? Colors.red : _primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap to add photos',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: hasError ? Colors.red : _labelColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Up to $_maxAllowedImages images',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 8),
                    Text(
                      'At least $_minRequiredProductImages image required',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ],
              ),
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
        _fieldLabel(
          'Upload Photos (Optional)',
          icon: Icons.photo_library_outlined,
        ),
        const SizedBox(height: 10),

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
                      borderRadius: BorderRadius.circular(_fieldRadius),
                      border: Border.all(color: _borderColor),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        if (_selectedImages.isNotEmpty) const SizedBox(height: 10),

        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _primaryLight,
              border: Border.all(color: _primary.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(_fieldRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 36,
                  color: _primary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add reference images (optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _labelColor,
                  ),
                ),
                if (_selectedImages.isEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Up to $_maxAllowedImages images',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
        _fieldLabel('Category', required: true, icon: Icons.category_outlined),
        const SizedBox(height: 10),

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
              DropdownButtonFormField<Map<String, dynamic>>(
                  initialValue: _selectedMainCategoryId != null
                      ? _mainCategories.firstWhere(
                          (cat) => cat['id'] == _selectedMainCategoryId,
                          orElse: () => _mainCategories.first,
                        )
                      : null,
                  decoration: _fieldDecoration(
                    hintText: 'Select main category',
                  ),
                  dropdownColor: Colors.white,
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
                        _mainCategoryValidationError = null;
                        _subCategoryValidationError = null;
                      });
                      _loadSubCategories(value['id']);
                    }
                  },
                ),

              if (_mainCategoryValidationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    _mainCategoryValidationError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 16),

              // Sub Category Dropdown (shown only after main category is selected)
              if (_selectedMainCategoryId != null) ...[
                _fieldLabel('Sub Category'),
                const SizedBox(height: 10),

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
                  DropdownButtonFormField<Map<String, dynamic>>(
                      initialValue: _selectedSubCategoryId != null
                          ? _subCategories.firstWhere(
                              (cat) => cat['id'] == _selectedSubCategoryId,
                              orElse: () => _subCategories.first,
                            )
                          : null,
                      decoration: _fieldDecoration(
                        hintText: 'Select sub category',
                      ),
                      dropdownColor: Colors.white,
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
                            _subCategoryValidationError = null;
                          });
                        }
                      },
                    ),

                if (_subCategoryValidationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      _subCategoryValidationError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
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
        _fieldLabel(
          _postType == 'Product'
              ? 'Product Location'
              : 'Service Location',
          required: true,
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor, width: 1.2),
            borderRadius: BorderRadius.circular(_fieldRadius),
            color: Colors.white,
          ),
          child: GooglePlaceAutoCompleteTextField(
            textEditingController: _locationController,
            focusNode: _locationFocusNode,
            googleAPIKey: _googleApiKey,
            debounceTime: 400,
            isCrossBtnShown: false,
            countries: const ['us', 'in', 'ca', 'gb', 'au'],
            isLatLngRequired: true,
            inputDecoration: InputDecoration(
              hintText: 'Search address (min 4 chars) or use GPS',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              border: InputBorder.none,
              errorText: _locationValidationError,
              prefixIcon: const Icon(Icons.place_outlined, color: _primary),
              suffixIcon: _isGettingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location, color: _primary),
                      onPressed: _getCurrentLocation,
                      tooltip: 'Get current location',
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            getPlaceDetailWithLatLng: (Prediction prediction) {
              final lat = prediction.lat;
              final lng = prediction.lng;
              if (lat != null && lng != null) {
                setState(() {
                  _selectedLatitude = double.tryParse(lat);
                  _selectedLongitude = double.tryParse(lng);
                });
              }
            },
            itemClick: (Prediction prediction) {
              _locationController.text = prediction.description ?? '';
              _locationController.selection = TextSelection.fromPosition(
                TextPosition(offset: _locationController.text.length),
              );
              setState(() {
                _showLocationMinCharsHint = false;
              });
              _locationFocusNode.unfocus();
            },
            itemBuilder: (context, index, prediction) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prediction.description ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            seperatedBuilder: const Divider(height: 1, thickness: 1),
            containerHorizontalPadding: 0,
          ),
        ),
        if (_showLocationMinCharsHint)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Enter at least 4 characters to see suggestions',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Type location manually and select suggestion (after 4+ chars), or use current location',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _onOptionSelected(int option) {
    setState(() {
      _selectedOption = option;

      // Option 1: add Product/Service
      // Option 2: looking for Service only
      if (option == 2) {
        _postType = 'Service';
      } else if (_postType != 'Product' && _postType != 'Service') {
        _postType = 'Product';
      }

      _selectedMainCategoryId = null;
      _selectedSubCategoryId = null;
      _subCategories = [];

      _titleValidationError = null;
      _mainCategoryValidationError = null;
      _subCategoryValidationError = null;
      _descriptionValidationError = null;
      _locationValidationError = null;
      _priceValidationError = null;
      _expiryValidationError = null;
    });

    _loadMainCategories();
  }

  void _onCreatePostTypeChanged(String type) {
    if (_selectedOption != 1) return;
    if (_postType == type) return;

    setState(() {
      _postType = type;
      _selectedMainCategoryId = null;
      _selectedSubCategoryId = null;
      _subCategories = [];

      _mainCategoryValidationError = null;
      _subCategoryValidationError = null;
      _expiryValidationError = null;
    });

    _loadMainCategories();
  }

  void _onExpiryUnitChanged(String value) {
    setState(() {
      _selectedExpiryUnit = value;
      _expiryValidationError = null;
      if (value == 'No expiry') {
        _expiryValueController.clear();
      } else if (_expiryValueController.text.trim().isEmpty) {
        if (value == 'Minutes') {
          _expiryValueController.text = '';
        } else if (value == 'Hours') {
          _expiryValueController.text = '';
        } else if (value == 'Days') {
          _expiryValueController.text = '';
        } else {
          _expiryValueController.text = '';
        }
      }
    });
  }

  DateTime? _computeExpiryDate() {
    if (_selectedExpiryUnit == 'No expiry') {
      return null;
    }

    final rawValue = _expiryValueController.text.trim();
    if (rawValue.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final value = int.tryParse(rawValue);
    if (value == null || value <= 0) {
      return null;
    }

    switch (_selectedExpiryUnit) {
      case 'Minutes':
        return now.add(Duration(minutes: value));
      case 'Hours':
        return now.add(Duration(hours: value));
      case 'Days':
        return now.add(Duration(days: value));
      case 'Months':
        return DateTime(
          now.year,
          now.month + value,
          now.day,
          now.hour,
          now.minute,
          now.second,
        );
      default:
        return null;
    }
  }

  Widget _buildTimelineExpirySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(
          'Post Expiry',
          icon: Icons.schedule_outlined,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
            initialValue: _selectedExpiryUnit,
            dropdownColor: Colors.white,
            decoration: _fieldDecoration(),
            items: _expiryUnits
                .map(
                  (unit) =>
                      DropdownMenuItem<String>(value: unit, child: Text(unit)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                _onExpiryUnitChanged(value);
              }
            },
          ),
        if (_selectedExpiryUnit != 'No expiry') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _expiryValueController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              if (_expiryValidationError != null) {
                setState(() {
                  _expiryValidationError = null;
                });
              }
            },
            decoration: _fieldDecoration(
              hintText: _selectedExpiryUnit == 'Minutes'
                  ? 'Enter minutes'
                  : _selectedExpiryUnit == 'Hours'
                  ? 'Enter hours'
                  : _selectedExpiryUnit == 'Days'
                  ? 'Enter days'
                  : 'Enter months',
              errorText: _expiryValidationError,
            ),
          ),
        ],
      ],
    );
  }

  // Price field
  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(
          _selectedOption == 1 ? 'Price (coins)' : 'Will Pay Amount (coins)',
          required: true,
          useCoinIcon: true,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _selectedOption == 1
              ? _priceController
              : _willPayAmountController,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (_) {
            if (_priceValidationError != null) {
              setState(() {
                _priceValidationError = null;
              });
            }
          },
          decoration: _fieldDecoration(
            hintText: _selectedOption == 1
                ? _postType == 'Product'
                      ? 'Enter product price'
                      : 'Enter service price'
                : 'Enter amount you are willing to pay',
            prefixIcon: coinInputPrefix(),
            errorText: _priceValidationError,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildBarterStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Barter Status', icon: Icons.swap_horiz),
        const SizedBox(height: 10),
        DropdownButtonFormField<bool>(
          value: _barterAllowed,
          decoration: _fieldDecoration(),
          items: const [
            DropdownMenuItem<bool>(value: false, child: Text('Not Allowed')),
            DropdownMenuItem<bool>(value: true, child: Text('Allowed')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _barterAllowed = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildClubbingOptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Clubbing Option', icon: Icons.layers_outlined),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _primaryLight,
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(_fieldRadius),
          ),
          child: SwitchListTile(
            value: _canBeClubbed,
            activeThumbColor: Colors.white,
            activeTrackColor: _primary,
            onChanged: (value) {
              setState(() {
                _canBeClubbed = value;
              });
            },
            title: const Text(
              'Can be clubbed with other seller items',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _labelColor,
              ),
            ),
            subtitle: Text(
              'Buyers can add your other items to a bundle offer.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.92;

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Scaffold(
          backgroundColor: _surfaceBg,
          resizeToAvoidBottomInset: true,
          body: Container(
            decoration: const BoxDecoration(
              color: _surfaceBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
                  child: Column(
                    children: [
                      _modalDragHandle(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add Post',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedOption == 1
                                      ? 'List a product or service'
                                      : 'Looking for a service',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: _borderColor),
                            ),
                            icon: const Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedOption == 1) _buildStep1(),
                        if (_selectedOption == 2) _buildLookingForStep1(),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(top: BorderSide(color: _borderColor)),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _primaryLight,
                            foregroundColor: const Color(0xFF1F3D7A),
                            side: const BorderSide(
                              color: Color(0xFF9AB4FF),
                              width: 1.4,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _validateAndSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            elevation: 0,
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(int option, String description) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedOption == option
              ? const Color(0xFF2E5BFF)
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _onOptionSelected(option),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
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
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('Post Type', icon: Icons.sell_outlined),
              const SizedBox(height: 10),
              _buildPostTypeSelector(),
              const SizedBox(height: 20),
              _fieldLabel('Title', required: true, icon: Icons.title),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                onChanged: (_) {
                  if (_titleValidationError != null) {
                    setState(() => _titleValidationError = null);
                  }
                },
                decoration: _fieldDecoration(
                  hintText: _postType == 'Product'
                      ? 'Enter product title'
                      : 'Enter service title',
                  errorText: _titleValidationError,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategorySelection(),
              const SizedBox(height: 20),
              _fieldLabel('Description', required: true, icon: Icons.notes),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                onChanged: (_) {
                  if (_descriptionValidationError != null) {
                    setState(() => _descriptionValidationError = null);
                  }
                },
                decoration: _fieldDecoration(
                  hintText: _postType == 'Product'
                      ? 'Describe your product'
                      : 'Describe your service',
                  errorText: _descriptionValidationError,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(child: _buildImageUploadSection()),
        const SizedBox(height: 16),
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationField(),
              const SizedBox(height: 20),
              _buildTimelineExpirySection(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPriceField(),
              const SizedBox(height: 20),
              _buildBarterStatusField(),
              if (_postType == 'Product') ...[
                const SizedBox(height: 20),
                _buildClubbingOptionField(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLookingForStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _primaryLight,
            borderRadius: BorderRadius.circular(_fieldRadius),
            border: Border.all(color: _borderColor),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: _primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Looking for a service',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _labelColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('Title', required: true, icon: Icons.title),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                onChanged: (_) {
                  if (_titleValidationError != null) {
                    setState(() => _titleValidationError = null);
                  }
                },
                decoration: _fieldDecoration(
                  hintText: 'What are you looking for?',
                  errorText: _titleValidationError,
                ),
              ),
              const SizedBox(height: 20),
              _buildCategorySelection(),
              const SizedBox(height: 20),
              _fieldLabel('Description', required: true, icon: Icons.notes),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                onChanged: (_) {
                  if (_descriptionValidationError != null) {
                    setState(() => _descriptionValidationError = null);
                  }
                },
                decoration: _fieldDecoration(
                  hintText: 'Describe what you are looking for',
                  errorText: _descriptionValidationError,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(child: _buildLookingForImageUploadSection()),
        const SizedBox(height: 16),
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationField(),
              const SizedBox(height: 20),
              _buildPriceField(),
              const SizedBox(height: 20),
              _buildBarterStatusField(),
              const SizedBox(height: 20),
              _buildTimelineExpirySection(),
            ],
          ),
        ),
      ],
    );
  }

  void _validateAndSubmit() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    final amountText = _selectedOption == 1
        ? _priceController.text.trim()
        : _willPayAmountController.text.trim();

    setState(() {
      _titleValidationError = null;
      _mainCategoryValidationError = null;
      _subCategoryValidationError = null;
      _descriptionValidationError = null;
      _locationValidationError = null;
      _priceValidationError = null;
      _expiryValidationError = null;
    });

    // Validate required fields
    if (title.isEmpty) {
      setState(() {
        _titleValidationError = 'Title is required';
      });
      _showError('Please enter a title');
      return;
    }

    if (_selectedMainCategoryId == null) {
      setState(() {
        _mainCategoryValidationError = 'Please select a category';
      });
      _showError('Please select a category');
      return;
    }

    if (_selectedSubCategoryId == null) {
      setState(() {
        _subCategoryValidationError = 'Please select a sub category';
      });
      _showError('Please select a sub category');
      return;
    }

    if (description.isEmpty) {
      setState(() {
        _descriptionValidationError = 'Description is required';
      });
      _showError('Please enter a description');
      return;
    }

    // For add post (Product/Service), require at least one image
    if (_isImageRequiredForPost) {
      if (_selectedImages.length < _minRequiredProductImages) {
        setState(() {
          _showImageValidationError = true;
        });
        _showError('Please upload at least $_minRequiredProductImages image');
        return;
      }

      if (_showImageValidationError) {
        setState(() {
          _showImageValidationError = false;
        });
      }
    }

    if (_selectedImages.length > _maxAllowedImages) {
      _showErrorSnackBar('Maximum $_maxAllowedImages photos are allowed');
      return;
    }

    if (_selectedOption == 1 && location.isEmpty) {
      setState(() {
        _locationValidationError = 'Location is required';
      });
      _showError('Please enter a location');
      return;
    }

    if (_selectedExpiryUnit != 'No expiry') {
      final rawExpiry = _expiryValueController.text.trim();
      final expiryValue = int.tryParse(rawExpiry);
      if (expiryValue == null || expiryValue <= 0) {
        setState(() {
          _expiryValidationError =
              'Enter a valid ${_selectedExpiryUnit.toLowerCase()} value';
        });
        _showError(
          'Please enter a valid ${_selectedExpiryUnit.toLowerCase()} value',
        );
        return;
      }
    }

    // Price validation
    if (_selectedOption == 1) {
      if (amountText.isEmpty) {
        setState(() {
          _priceValidationError = 'Price is required';
        });
        _showError('Please enter a price');
        return;
      }
      final parsedPrice = double.tryParse(amountText);
      if (parsedPrice == null || parsedPrice <= 0) {
        setState(() {
          _priceValidationError = 'Enter a valid price';
        });
        _showError('Please enter a valid price');
        return;
      }
    } else {
      if (amountText.isEmpty) {
        setState(() {
          _priceValidationError = 'Amount is required';
        });
        _showError('Please enter the amount you are willing to pay');
        return;
      }
      final parsedAmount = double.tryParse(amountText);
      if (parsedAmount == null || parsedAmount <= 0) {
        setState(() {
          _priceValidationError = 'Enter a valid amount';
        });
        _showError('Please enter a valid amount');
        return;
      }
    }

    // Submit directly without step 2 dialog
    _submitPost();
  }

  void _showError(String message) {
    SnackbarUtils.showError(context, message);
  }

  void _showSuccessSnackBar(String message) {
    SnackbarUtils.showSuccess(context, message);
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    final normalized = message.toLowerCase();
    if (normalized.contains('maximum') && normalized.contains('photos')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    SnackbarUtils.showError(context, message);
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

      final double price = _selectedOption == 1
          ? double.parse(_priceController.text.trim())
          : double.parse(_willPayAmountController.text.trim());
      final expiryDate = _computeExpiryDate();
      final validFromIso = DateTime.now().toUtc().toIso8601String();
      final validUntilIso = expiryDate?.toUtc().toIso8601String();

      if (_selectedOption == 1) {
        // Create product/service post
        if (_postType == 'Product') {
          final request = CreateProductRequest(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            categoryId: _selectedSubCategoryId!,
            images: imageUrls,
            location: _locationController.text.trim(),
            latitude: _selectedLatitude,
            longitude: _selectedLongitude,
            barterStatus: _barterAllowed ? 'OPEN_FOR_BARTER' : 'NO_BARTER',
            canClubItems: _canBeClubbed,
            price: price,
            validFrom: validUntilIso == null ? null : validFromIso,
            validUntil: validUntilIso,
          );

          debugPrint(
            '📦 Creating product post with ${imageUrls.length} images',
          );
          await _addPostService.createProductPost(request);
          debugPrint('✅ Product created successfully');
        } else {
          debugPrint(
            '📦 Creating provider service with ${imageUrls.length} images via /api/services',
          );
          final response = await _serviceBookingService.createService(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            categoryId: _selectedSubCategoryId!,
            price: price,
            location: _locationController.text.trim(),
            images: imageUrls,
            barterStatus: _barterAllowed ? 'OPEN_FOR_BARTER' : 'NO_BARTER',
            status: 'PROVIDE_SERVICE',
            validFrom: validUntilIso == null ? null : validFromIso,
            validUntil: validUntilIso,
          );

          final data = response['data'];
          String? serviceId;
          if (data is Map<String, dynamic>) {
            if (data['service'] is Map<String, dynamic>) {
              serviceId = data['service']['id']?.toString();
            }
            serviceId ??= data['id']?.toString();
            serviceId ??= data['serviceId']?.toString();
          }

          if (serviceId == null || serviceId.isEmpty) {
            throw Exception(
              'Service created but ID was not returned by server',
            );
          }

          if (!mounted) return;

          widget.onPostAdded?.call();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceAvailabilityScreen(
                serviceId: serviceId!,
                isInitialSetup: true,
              ),
            ),
          );
          return;
        }
      } else {
        // Handle "Looking For" (service only)
        final request = CreateServiceRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          categoryId: _selectedSubCategoryId!,
          images: imageUrls,
          location: _locationController.text.trim(),
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          barterStatus: _barterAllowed ? 'OPEN_FOR_BARTER' : 'NO_BARTER',
          validUntil: validUntilIso,
          status: 'LOOKING_FOR_SERVICE',
          price: price,
        );

        debugPrint(
          '📦 Creating looking for service post with ${imageUrls.length} images (need by ${request.validUntil ?? 'not set'})',
        );
        await _addPostService.createServicePost(request);
        debugPrint('✅ Looking for service created');
      }

      // Close add post screen
      if (!mounted) return;
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