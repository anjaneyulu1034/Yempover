import 'dart:convert';
import 'dart:io';
import 'package:yempover_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/models/get_my_profile_response.dart';
import 'package:yempover_app/models/profile_update_request.dart';
import 'package:yempover_app/services/profile_service.dart';
import 'package:yempover_app/services/profile_session_manager.dart';
import 'package:yempover_app/utils/loading_overlay.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yempover_app/widgets/app_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const int _emailMaxLength = 30;

  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _homeAddressController;

  bool _isLoading = false;
  bool _isUploadingImage = false;

  ProfileData? _profile;
  File? _selectedImageFile;
  String? _base64Image;
  String? _imageMimeType;

  bool get _isBusy => _isLoading || _isUploadingImage;

  @override
  void initState() {
    super.initState();
    _profile = ProfileSessionManager.instance.profile;
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(
      text: _profile?.firstName ?? '',
    );
    _lastNameController = TextEditingController(text: _profile?.lastName ?? '');
    _emailController = TextEditingController(text: _profile?.email ?? '');
    _homeAddressController = TextEditingController(
      text: _profile?.homeAddress?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _homeAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final File imageFile = File(pickedFile.path);

        // Read image file as bytes
        final bytes = await imageFile.readAsBytes();

        // Convert to base64
        final base64Image = base64Encode(bytes);

        // Get mime type from file extension
        final extension = pickedFile.path.split('.').last.toLowerCase();
        String mimeType;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          default:
            mimeType = 'image/jpeg';
        }

        setState(() {
          _selectedImageFile = imageFile;
          _base64Image = base64Image;
          _imageMimeType = mimeType;
          _isUploadingImage = false;
        });

        // Optional: Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _detectMimeTypeFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _ensureImagePreparedForUpload() async {
    if (_selectedImageFile == null) return;

    if (_base64Image != null &&
        _base64Image!.isNotEmpty &&
        _imageMimeType != null &&
        _imageMimeType!.isNotEmpty) {
      return;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final bytes = await _selectedImageFile!.readAsBytes();
      _base64Image = base64Encode(bytes);
      _imageMimeType = _detectMimeTypeFromPath(_selectedImageFile!.path);
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: const Text('Choose where to pick the image from'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: AppConstants.primaryColor),
                  SizedBox(width: 8),
                  Text('Camera'),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, color: AppConstants.primaryColor),
                  SizedBox(width: 8),
                  Text('Gallery'),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    if (_isBusy) return;

    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for image processing to finish'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _ensureImagePreparedForUpload();

      // If there's a selected image, upload it first
      if (_selectedImageFile != null) {
        if (_base64Image == null ||
            _base64Image!.isEmpty ||
            _imageMimeType == null ||
            _imageMimeType!.isEmpty) {
          throw Exception('Unable to process selected image. Please retry.');
        }

        final apiService = ApiService();
        final imageResponse = await apiService.uploadProfileImageBase64(
          base64Image: _base64Image!,
          mimeType: _imageMimeType!,
        );

        print('Profile image uploaded: ${imageResponse.data.url}');

        ProfileSessionManager.instance.updateProfile(
          profileImage: imageResponse.data.url,
        );
        if (mounted) {
          setState(() {
            _profile = ProfileSessionManager.instance.profile;
          });
        }
      }

      // Then update the rest of the profile data
      final request = ProfileUpdateRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        homeAddress: _homeAddressController.text.trim().isEmpty
            ? null
            : _homeAddressController.text.trim(),
        // Note: You don't need to send base64 here as it's already uploaded
        // profileImage: _base64Image, // Remove this
        // profileImageMimeType: _imageMimeType, // Remove this
      );

      await _profileService.updateProfile(request);
      final updatedProfile = await _profileService.fetchProfile();

      if (mounted) {
        // Clear the selected image after successful update
        setState(() {
          _selectedImageFile = null;
          _base64Image = null;
          _imageMimeType = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updatedProfile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return ErrorMessages.emptyField;
    }
    if (email.length > _emailMaxLength) {
      return 'Email must be 30 characters or less';
    }
    if (!ValidationRegex.emailRegex.hasMatch(email)) {
      return ErrorMessages.invalidEmail;
    }
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.emptyField;
    }
    if (!ValidationRegex.nameRegex.hasMatch(value)) {
      return 'Please enter a valid $fieldName';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _isBusy ? null : _updateProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppConstants.primaryColor,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(child: _buildProfileImage()),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppConstants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: _isUploadingImage
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  onPressed: _isBusy
                                      ? null
                                      : _showImageSourceDialog,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Personal Information Section
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                AppTextField(
                  label: 'First Name',
                  hint: 'Enter your first name',
                  controller: _firstNameController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) => _validateName(value, 'first name'),
                ),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  controller: _lastNameController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) => _validateName(value, 'last name'),
                ),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(_emailMaxLength),
                  ],
                  validator: _validateEmail,
                ),

                const SizedBox(height: 16),

                // Phone Number (Read-only)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: TextFormField(
                    initialValue: _profile?.mobileNumber ?? 'Not provided',
                    readOnly: true,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 20),

                // Address Section
                const Text(
                  'Address Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                AppTextField(
                  label: 'Home Address',
                  hint: 'Enter your home address',
                  controller: _homeAddressController,
                  maxLines: 3,
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 50),
                    child: Icon(Icons.location_on_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_selectedImageFile != null) {
      // Show selected image
      return Image.file(
        _selectedImageFile!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (_profile?.profileImage != null &&
        _profile!.profileImage!.isNotEmpty) {
      // Show existing profile image from network
      return Image.network(
        _profile!.profileImage!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to initials if image fails to load
          return _buildInitialsAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else {
      // Show initials avatar
      return _buildInitialsAvatar();
    }
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.blue.shade100,
      child: Center(
        child: Text(
          _getInitials(),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (_profile?.firstName == null && _profile?.lastName == null) {
      return '?';
    }
    final first = _profile?.firstName?.isNotEmpty == true
        ? _profile!.firstName![0]
        : '';
    final last = _profile?.lastName?.isNotEmpty == true
        ? _profile!.lastName![0]
        : '';
    return '$first$last'.toUpperCase();
  }
}
