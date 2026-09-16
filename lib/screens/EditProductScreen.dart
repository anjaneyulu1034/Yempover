import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yempover_app/widgets/app_text_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/api_constants.dart';
import 'package:yempover_app/widgets/coin_icon.dart';
import '../models/my_post_model.dart';
import '../services/add_post_service.dart';
import '../services/category_service.dart';
import '../services/location_service.dart';
import '../services/my_posts_service.dart';
import '../models/service_availability_plan.dart';
import '../utils/api_exceptions.dart';
import '../utils/error_message_utils.dart';
import '../utils/validators.dart';
import 'service/ServiceAvailabilityScreen.dart';

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
  static const int _maxPostImages = 5;
  static const String _expiredExpiryUnit = 'Expired';
  static const List<String> _expiryUnits = [
    'Minutes',
    'Hours',
    'Days',
    'Months',
    'Years',
    'No expiry',
  ];

  final _formKey = GlobalKey<FormState>();
  final MyPostsService _postsService = MyPostsService();
  final AddPostService _addPostService = AddPostService();
  final CategoryService _categoryService = CategoryService();
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _expiryValueController;

  late String _selectedStatus;
  late String _selectedBarterStatus;
  late String _selectedCategoryId;
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  late String _postType;
  late bool _isListed;
  late bool _canBeClubbed;
  late List<String> _images;
  double? _selectedLatitude;
  double? _selectedLongitude;
  // Set when the user picks a new weekly schedule via "Manage Availability"
  // — held locally and sent as part of the single _saveChanges() PUT rather
  // than saved separately, so a service edit is one save action.
  List<Map<String, dynamic>>? _pendingAvailabilitySlots;

  List<Map<String, dynamic>> _mainCategories = [];
  List<Map<String, dynamic>> _subCategories = [];
  bool _isLoadingCategories = false;
  String? _categoryLoadError;

  bool _isSaving = false;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String _selectedExpiryUnit = 'No expiry';
  String? _expiryValidationError;

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
    _expiryValueController = TextEditingController();

    _selectedStatus = widget.post.status;
    _selectedBarterStatus = _normalizeBarterStatus(widget.post.barterStatus);
    _selectedCategoryId = widget.post.categoryId;
    _postType = widget.post.type;
    _isListed = widget.post.isListed;
    _canBeClubbed = widget.post.isClubbable;
    _selectedLatitude = widget.post.latitude;
    _selectedLongitude = widget.post.longitude;
    _images = List.from(widget.post.images.take(_maxPostImages));
    _initializeTimelineFields();
    // Captured once, right after the fields are first populated from the
    // saved post — the revert target if the BUG-4 confirmation dialog below
    // is cancelled.
    _originalExpiryUnit = _selectedExpiryUnit;
    _originalExpiryValueText = _expiryValueController.text;
    _validateStatus();
  }

  String _originalExpiryUnit = 'No expiry';
  String _originalExpiryValueText = '';

  void _initializeTimelineFields() {
    final validUntil = widget.post.validUntil;
    if (validUntil == null) {
      _selectedExpiryUnit = 'No expiry';
      _expiryValueController.clear();
      return;
    }

    final now = DateTime.now();
    if (!validUntil.isAfter(now)) {
      _selectedExpiryUnit = _expiredExpiryUnit;
      _expiryValueController.clear();
      return;
    }

    final diff = validUntil.difference(now);
    final absDiff = diff;

    if (absDiff.inMinutes < 60) {
      final minutes = ((absDiff.inSeconds / 60).ceil()).clamp(1, 9999);
      _selectedExpiryUnit = 'Minutes';
      _expiryValueController.text = minutes.toString();
      return;
    }

    if (absDiff.inHours < 24) {
      _selectedExpiryUnit = 'Hours';
      _expiryValueController.text = absDiff.inHours.clamp(1, 9999).toString();
      return;
    }

    if (absDiff.inDays < 30) {
      _selectedExpiryUnit = 'Days';
      _expiryValueController.text = absDiff.inDays.clamp(1, 9999).toString();
      return;
    }

    final months = (absDiff.inDays / 30).ceil().clamp(1, 1200);
    _selectedExpiryUnit = 'Months';
    _expiryValueController.text = months.toString();
  }

  String _formatTimelineDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      final minutes = ((duration.inSeconds / 60).ceil()).clamp(1, 9999);
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }

    if (duration.inHours < 24) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '$hours hour${hours == 1 ? '' : 's'} $minutes minute${minutes == 1 ? '' : 's'}';
      }
      return '$hours hour${hours == 1 ? '' : 's'}';
    }

    if (duration.inDays < 30) {
      final days = duration.inDays;
      final remHours = duration.inHours % 24;
      if (remHours > 0) {
        return '$days day${days == 1 ? '' : 's'} $remHours hour${remHours == 1 ? '' : 's'}';
      }
      return '$days day${days == 1 ? '' : 's'}';
    }

    final months = (duration.inDays / 30).floor().clamp(1, 1200);
    final remDays = duration.inDays % 30;
    if (remDays > 0) {
      return '$months month${months == 1 ? '' : 's'} $remDays day${remDays == 1 ? '' : 's'}';
    }
    return '$months month${months == 1 ? '' : 's'}';
  }

  bool _isExpired(DateTime? validUntil) {
    if (validUntil == null) return false;
    return !validUntil.isAfter(DateTime.now());
  }

  String _getCurrentExpiryText(DateTime? validUntil) {
    if (validUntil == null) {
      return 'Current: No expiry is set';
    }

    final now = DateTime.now();

    if (!validUntil.isAfter(now)) {
      final elapsed = now.difference(validUntil);
      return 'Current: Expired ${_formatTimelineDuration(elapsed)} ago';
    }

    final remaining = validUntil.difference(now);
    return 'Current: Expires in ${_formatTimelineDuration(remaining)}';
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
        _categoryLoadError = ErrorMessageUtils.sanitize(e);
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
      return ['PROVIDE_SERVICE'];
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
    _expiryValueController.dispose();
    super.dispose();
  }

  void _onExpiryUnitChanged(String value) {
    setState(() {
      _selectedExpiryUnit = value;
      _expiryValidationError = null;
      if (value == 'No expiry' || value == _expiredExpiryUnit) {
        _expiryValueController.clear();
      }
    });
  }

  int _maxExpiryValueFor(String unit) {
    switch (unit) {
      case 'Minutes':
        return 60;
      case 'Hours':
        return 24;
      case 'Days':
        return 99;
      case 'Months':
        return 999;
      case 'Years':
        return 9999;
      default:
        return 9999;
    }
  }

  /// Minutes/Hours/Days are whole-number units (no decimal precision).
  /// Months/Years allow a single decimal digit (e.g. "6.5" months).
  bool get _isIntegerOnlyExpiryUnit =>
      _selectedExpiryUnit == 'Minutes' ||
      _selectedExpiryUnit == 'Hours' ||
      _selectedExpiryUnit == 'Days';

  DateTime? _computeEditedExpiryDate() {
    if (_selectedExpiryUnit == _expiredExpiryUnit) {
      return widget.post.validUntil;
    }

    if (_selectedExpiryUnit == 'No expiry') {
      return null;
    }

    final rawValue = _expiryValueController.text.trim();
    if (rawValue.isEmpty) {
      return null;
    }

    final value = double.tryParse(rawValue);
    if (value == null || value <= 0) {
      return null;
    }

    final now = DateTime.now();
    switch (_selectedExpiryUnit) {
      case 'Minutes':
        return now.add(Duration(minutes: value.round()));
      case 'Hours':
        return now.add(Duration(hours: value.round()));
      case 'Days':
        return now.add(
          Duration(seconds: (value * Duration.secondsPerDay).round()),
        );
      case 'Months':
        {
          final wholeMonths = value.truncate();
          final fraction = value - wholeMonths;
          var date = DateTime(
            now.year,
            now.month + wholeMonths,
            now.day,
            now.hour,
            now.minute,
            now.second,
          );
          if (fraction > 0) {
            date = date.add(
              Duration(
                seconds: (fraction * 30 * Duration.secondsPerDay).round(),
              ),
            );
          }
          return date;
        }
      case 'Years':
        {
          final wholeYears = value.truncate();
          final fraction = value - wholeYears;
          var date = DateTime(
            now.year + wholeYears,
            now.month,
            now.day,
            now.hour,
            now.minute,
            now.second,
          );
          if (fraction > 0) {
            date = date.add(
              Duration(
                seconds: (fraction * 365 * Duration.secondsPerDay).round(),
              ),
            );
          }
          return date;
        }
      default:
        return null;
    }
  }

  bool _validateTimelineInput() {
    if (_selectedExpiryUnit == 'No expiry' ||
        _selectedExpiryUnit == _expiredExpiryUnit) {
      setState(() {
        _expiryValidationError = null;
      });
      return true;
    }

    final value = double.tryParse(_expiryValueController.text.trim());
    if (value == null || value <= 0) {
      setState(() {
        _expiryValidationError =
            'Please enter a valid ${_selectedExpiryUnit.toLowerCase()} value';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid ${_selectedExpiryUnit.toLowerCase()} value',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final maxExpiryValue = _maxExpiryValueFor(_selectedExpiryUnit);
    if (value > maxExpiryValue) {
      final message =
          '$_selectedExpiryUnit must be between 1 and $maxExpiryValue';
      setState(() {
        _expiryValidationError = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return false;
    }

    setState(() {
      _expiryValidationError = null;
    });
    return true;
  }

  Future<void> _pickImage() async {
    try {
      if (_images.length >= _maxPostImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 5 images allowed'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

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
          if (_images.length < _maxPostImages) {
            _images.add(image.path);
          }
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        _showLocationServiceDialog();
        return;
      }

      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get your current location'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final address = await _locationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _locationController.text = (address != null && address.isNotEmpty)
            ? address
            : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get current location'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
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
          'Please enable location services to use current location.',
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

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _openManageAvailability() async {
    // Preview the plan for whatever expiry is currently in the form (which
    // may not be saved yet) rather than the one on `widget.post` — otherwise
    // this screen could open in the wrong mode while the seller is mid-edit.
    final preview = await _fetchAvailabilityPreview();

    if (!mounted) return;
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceAvailabilityScreen(
          serviceId: widget.post.id,
          pickerMode: true,
          initialAvailabilitySlots: _pendingAvailabilitySlots,
          expiryValidUntil: _computeEditedExpiryDate(),
          initialPlan: preview?.plan,
          knownNoExpiry: _selectedExpiryUnit == 'No expiry',
        ),
      ),
    );

    if (result == null || !mounted) return;
    setState(() => _pendingAvailabilitySlots = result);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Availability updated — tap Save to apply your changes.',
        ),
      ),
    );
  }

  // The unit/value the plan-preview and save calls send — `null` for both
  // when the sentinel "already expired, keep as-is" unit is selected, since
  // that case is carried entirely by `validUntil` (see
  // _computeEditedExpiryDate).
  String? get _expiryUnitParam {
    if (_selectedExpiryUnit == _expiredExpiryUnit) return null;
    return _selectedExpiryUnit == 'No expiry'
        ? 'no expiry'
        : _selectedExpiryUnit.toLowerCase();
  }

  int? get _expiryValueParam {
    if (_selectedExpiryUnit == _expiredExpiryUnit ||
        _selectedExpiryUnit == 'No expiry') {
      return null;
    }
    final raw = double.tryParse(_expiryValueController.text.trim());
    if (raw == null) return null;
    // The server's expiryValue field is integer-only; a fractional
    // Months/Years value (e.g. "6.5") is still carried correctly via
    // `validUntil` alone, which the server treats as authoritative anyway.
    return raw == raw.roundToDouble() ? raw.round() : null;
  }

  // Best-effort preview of the plan for whatever expiry is currently in the
  // form — used to open Set Availability in the right mode and to detect a
  // mode-change confirmation (QA BUG-1/4) before the seller commits to Save.
  // Never blocks the save itself: if this fails, the save's own request
  // still carries the real expiry and the server enforces everything there.
  Future<AvailabilityPlanResponse?> _fetchAvailabilityPreview() async {
    try {
      return await _postsService.getServiceAvailabilityPlan(
        serviceId: widget.post.id,
        expiryUnit: _expiryUnitParam,
        expiryValue: _expiryValueParam,
        validUntil: _computeEditedExpiryDate()?.toUtc().toIso8601String(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _showAvailabilityConfirmationDialog(
    AvailabilityConfirmation confirmation,
  ) {
    final isBlocked = confirmation.action == 'BLOCKED';
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(confirmation.title),
        content: Text(confirmation.message),
        actions: isBlocked
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    confirmation.cancelLabel.isNotEmpty
                        ? confirmation.cancelLabel
                        : 'OK',
                  ),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(confirmation.cancelLabel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(confirmation.confirmLabel),
                ),
              ],
      ),
    );
  }

  // The seller has seen and accepted the confirmation dialog this save
  // should carry `confirmAvailabilityChange: true` for.
  bool _confirmAvailabilityChangeOnSave = false;

  // QA BUG-4: changing the expiry can swap the availability mode (e.g. a
  // weekly schedule replaced by a single "Available now" window). The
  // server — not a client-side heuristic — decides whether that's actually
  // happening, via the plan-preview's `confirmation` object.
  Future<bool> _confirmExpiryScheduleImpactIfNeeded() async {
    _confirmAvailabilityChangeOnSave = false;

    final preview = await _fetchAvailabilityPreview();
    final confirmation = preview?.confirmation;
    if (confirmation == null) return true; // No mode change - nothing to confirm.

    if (!mounted) return true;

    if (confirmation.action == 'REQUIRE_WEEKLY_SETUP') {
      // Reverse direction (short -> long expiry): the seller needs to build
      // a real weekly schedule themselves — the server can't invent one.
      final proceed = await _showAvailabilityConfirmationDialog(confirmation);
      if (proceed != true) {
        setState(() {
          _selectedExpiryUnit = _originalExpiryUnit;
          _expiryValueController.text = _originalExpiryValueText;
        });
        return false;
      }
      _confirmAvailabilityChangeOnSave = true;
      if (!mounted) return true;
      final result = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceAvailabilityScreen(
            serviceId: widget.post.id,
            pickerMode: true,
            initialPlan: confirmation.plan,
          ),
        ),
      );
      if (result != null && mounted) {
        setState(() => _pendingAvailabilitySlots = result);
      }
      return true;
    }

    final confirmed = await _showAvailabilityConfirmationDialog(confirmation);
    if (confirmed != true) {
      // Cancel discards the expiry change — revert to whatever was loaded
      // from the saved post, not just abort this one save attempt.
      if (mounted) {
        setState(() {
          _selectedExpiryUnit = _originalExpiryUnit;
          _expiryValueController.text = _originalExpiryValueText;
        });
      }
      return false;
    }
    if (confirmation.action == 'BLOCKED') {
      // Acknowledged, but nothing to save — the seller must fix the expiry
      // or schedule first.
      return false;
    }
    // REPLACE_WITH_AVAILABLE_NOW / REPLACE_WITH_DATES: the server rebuilds
    // the schedule itself once `confirmAvailabilityChange: true` is sent —
    // no availabilitySlots to attach here.
    _confirmAvailabilityChangeOnSave = true;
    return true;
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

    // Sub-category is mandatory whenever the selected category actually has
    // sub-categories to choose from — the dropdown itself is only rendered
    // in that case, so this mirrors the UI rather than blocking edits on
    // categories that have none.
    if (_subCategories.isNotEmpty &&
        (_selectedSubCategoryId == null || _selectedSubCategoryId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a sub category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_validateTimelineInput()) {
      return;
    }

    if (_postType == 'service') {
      final shouldProceed = await _confirmExpiryScheduleImpactIfNeeded();
      if (!shouldProceed) return;
    }

    await _runSave(confirmAvailabilityChange: _confirmAvailabilityChangeOnSave);
  }

  // QA BUG-4 reactive path: a save that changes validUntil without having
  // gone through the confirmation preview (e.g. some other edit shifted it)
  // still comes back 409 AVAILABILITY_MODE_CHANGE — treat that as "show the
  // dialog", not a generic error toast, then retry once confirmed.
  Future<void> _runSave({required bool confirmAvailabilityChange}) async {
    setState(() => _isSaving = true);

    try {
      await _submitUpdate(confirmAvailabilityChange: confirmAvailabilityChange);
    } on AvailabilityChangeRequiredException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      final confirmed = await _showAvailabilityConfirmationDialog(
        e.confirmation,
      );
      if (confirmed == true && e.confirmation.action != 'BLOCKED') {
        await _runSave(confirmAvailabilityChange: true);
      } else if (mounted) {
        setState(() {
          _selectedExpiryUnit = _originalExpiryUnit;
          _expiryValueController.text = _originalExpiryValueText;
        });
      }
      return;
    } catch (e) {
      if (mounted) _showSaveError(e);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _submitUpdate({required bool confirmAvailabilityChange}) async {
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

    // A photo is mandatory for a Product listing, but not for a Service —
    // matches the same rule on the Add Post flow.
    if (preparedImages.isEmpty && _postType != 'service') {
      throw Exception('Please add at least one image');
    }

    if (preparedImages.length > _maxPostImages) {
      throw Exception('Maximum 5 images allowed');
    }

    final updatedExpiryDate = _computeEditedExpiryDate();
    final validFromIso = updatedExpiryDate == null
        ? null
        : DateTime.now().toUtc().toIso8601String();
    final validUntilIso = updatedExpiryDate?.toUtc().toIso8601String();

    // Create request with type explicitly set
    final requestData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'images': preparedImages,
      'status': _selectedStatus,
      'barterStatus': _normalizeBarterStatus(_selectedBarterStatus),
      'categoryId': _selectedCategoryId,
      'isListed': _isListed,
      if (_postType != 'service') ...{
        'canBeClubbed': _canBeClubbed,
        'isClubbable': _canBeClubbed,
        'canClubItems': _canBeClubbed,
      },
      'type': _postType, // IMPORTANT: Include the post type
      'validFrom': validFromIso,
      'validUntil': validUntilIso,
      if (_postType == 'service' && _expiryUnitParam != null)
        'expiryUnit': _expiryUnitParam,
      if (_postType == 'service' && _expiryValueParam != null)
        'expiryValue': _expiryValueParam,
    };

    // Price is mandatory for edit flows (product/service).
    requestData['price'] = double.parse(_priceController.text.trim());

    requestData['location'] = _locationController.text.trim();
    if (_selectedLatitude != null) {
      requestData['latitude'] = _selectedLatitude;
    }
    if (_selectedLongitude != null) {
      requestData['longitude'] = _selectedLongitude;
    }
    if (_postType == 'service' && _pendingAvailabilitySlots != null) {
      requestData['availabilitySlots'] = _pendingAvailabilitySlots;
    }
    // QA BUG-4: the seller has seen and accepted the mode-change dialog.
    if (confirmAvailabilityChange) {
      requestData['confirmAvailabilityChange'] = true;
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
  }

  // express-validator dumps look like "field[0].sub: Invalid value,
  // field[1].sub: Invalid value, ..." — a comma-joined list of raw field
  // paths, never something a seller wrote or should read as-is.
  bool _looksLikeRawValidatorDump(String message) {
    return message.contains('Invalid value') ||
        RegExp(r'\[\d+\]\.\w+\s*:').hasMatch(message);
  }

  void _showSaveError(Object e) {
    final raw = e.toString().toLowerCase();
    String message;
    if (raw.contains('please add at least one image') ||
        raw.contains('at least one image')) {
      message = 'Please add at least one image to continue.';
    } else if (raw.contains('maximum 5 images')) {
      message = 'You can upload a maximum of 5 images.';
    } else if (e is ApiCodedException) {
      // QA BUG-3: backend-authored, user-safe validation message — shown
      // verbatim, not run through the generic network/auth sanitizer.
      // Exception: express-validator's own field-path dump (e.g.
      // "availabilitySlots[0].breakStartTime: Invalid value, [1]...") isn't
      // curated copy — it's raw technical output, unreadable as a toast.
      message = _looksLikeRawValidatorDump(e.message)
          ? 'Some availability details are invalid. Please check your schedule and try again.'
          : e.message;
    } else {
      // Surface the real reason (validation error, session expiry, network
      // issue, etc.) instead of always showing the same generic message
      // no matter what actually went wrong.
      message = ErrorMessageUtils.sanitize(
        e,
        fallback: 'Unable to save changes right now. Please try again.',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final saveButtonHeight = (50 * textScale.clamp(1.0, 1.25)).toDouble();

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
        backgroundColor: Colors.white,
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
                        isRequired: true,
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
                        isRequired: true,
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
                        isRequired: true,
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
                          isRequired: true,
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
                        prefixIcon: coinInputPrefix(),
                        prefixIconConstraints: coinPrefixIconConstraints,
                        isRequired: true,
                        inputFormatters: Validators.amountInputFormatters(),
                        validator: (value) {
                          final priceText = value?.trim() ?? '';
                          if (priceText.isEmpty) {
                            return 'Price is required';
                          }

                          final parsedPrice = double.tryParse(priceText);
                          if (parsedPrice == null) {
                            return 'Please enter a valid number';
                          }

                          if (parsedPrice <= 0) {
                            return 'Price must be greater than 0';
                          }

                          if (priceText.length > Validators.maxAmountLength) {
                            return 'Price is too large';
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

                      if (_postType == 'service') ...[
                        const SizedBox(height: 16),
                        _buildManageAvailabilitySection(),
                      ],

                      const SizedBox(height: 16),

                      _buildTimelineExpirySection(),

                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Location',
                        controller: _locationController,
                        maxLines: 2,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Location is required';
                          }
                          return null;
                        },
                        suffixIcon: _isGettingLocation
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: _getCurrentLocation,
                                icon: const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Use current location',
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter location manually or tap the target icon to use your current location.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
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

                      // Clubbing only applies to products offered in a
                      // barter — not services.
                      if (_postType != 'service') ...[
                        const SizedBox(height: 16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Can be clubbed',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _canBeClubbed
                                          ? 'This item can be combined with your other items in a single exchange.'
                                          : 'This item can only be offered on its own.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _canBeClubbed,
                                onChanged: (value) {
                                  setState(() {
                                    _canBeClubbed = value;
                                  });
                                },
                                activeThumbColor: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: saveButtonHeight,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: Size.fromHeight(saveButtonHeight),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                                    height: 1.2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
    if (_images.length > _maxPostImages) {
      _images = _images.take(_maxPostImages).toList();
    }

    final canAddMoreImages = _images.length < _maxPostImages;

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
              itemCount: canAddMoreImages ? _images.length + 1 : _images.length,
              itemBuilder: (context, index) {
                if (canAddMoreImages && index == _images.length) {
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

  Widget _buildManageAvailabilitySection() {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Availability Slots',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Edit the weekly time slots customers can book for this service.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _openManageAvailability,
            icon: const Icon(Icons.schedule, size: 18),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepPurple,
              side: const BorderSide(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineExpirySection() {
    final validUntil = widget.post.validUntil;
    final currentExpiryText = _getCurrentExpiryText(validUntil);
    final isExpired = _isExpired(validUntil);

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
            'Timeline Post Expiry',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentExpiryText,
            style: TextStyle(
              fontSize: 12,
              color: isExpired ? Colors.red.shade700 : Colors.black54,
              fontWeight: isExpired ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedExpiryUnit,
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
            items: _expiryUnits
                .followedBy(isExpired ? [_expiredExpiryUnit] : const <String>[])
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
          if (_selectedExpiryUnit != 'No expiry' &&
              _selectedExpiryUnit != _expiredExpiryUnit) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _expiryValueController,
              keyboardType: _isIntegerOnlyExpiryUnit
                  ? TextInputType.number
                  : const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: Validators.boundedCounterFormatters(
                max: _maxExpiryValueFor(_selectedExpiryUnit),
                allowDecimal: !_isIntegerOnlyExpiryUnit,
              ),
              onChanged: (_) {
                if (_expiryValidationError != null) {
                  setState(() {
                    _expiryValidationError = null;
                  });
                }
              },
              decoration: AppInputDecoration.build(
                label: _selectedExpiryUnit == 'Minutes'
                    ? 'Minutes'
                    : _selectedExpiryUnit == 'Hours'
                    ? 'Hours'
                    : _selectedExpiryUnit == 'Days'
                    ? 'Days'
                    : _selectedExpiryUnit == 'Months'
                    ? 'Months'
                    : 'Years',
                hint: 'Enter value',
                errorText: _expiryValidationError,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefix,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
    Widget? suffixIcon,
    bool isRequired = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
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
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            decoration: AppInputDecoration.build(
              label: isRequired ? '$label *' : label,
              prefixText: prefixIcon == null ? prefix : null,
              prefixIcon: prefixIcon,
              prefixIconConstraints: prefixIconConstraints,
              suffixIcon: suffixIcon,
              fillColor: Colors.white,
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
    bool isRequired = false,
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
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
              ],
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
