import 'dart:async';
import 'dart:math';
import 'package:YemPover_app/utils/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:provider/provider.dart';
import 'package:YemPover_app/models/ProductPostmain.dart';
import 'package:YemPover_app/models/get_my_profile_response.dart';
import 'package:YemPover_app/services/api_service.dart';
import 'package:YemPover_app/screens/PostDetailScreen.dart';
import 'package:YemPover_app/screens/tradechatscreen/TradeChatScreen.dart';
import 'package:YemPover_app/screens/TradeBoothScreen.dart';
import 'package:YemPover_app/screens/HamburgerMenuScreen.dart';
import 'package:YemPover_app/screens/MyProfileScreen.dart';
import 'package:YemPover_app/screens/NotificationsScreen.dart';
import 'package:YemPover_app/screens/CoinsWalletScreen.dart';
import 'package:YemPover_app/widgets/coin_icon.dart';
import 'package:YemPover_app/widgets/safe_network_image.dart';
import 'package:YemPover_app/services/my_profile_service.dart';
import 'package:YemPover_app/services/profile_session_manager.dart';
import 'package:YemPover_app/services/category_service.dart';
import 'package:YemPover_app/services/token_service.dart';
import 'package:YemPover_app/utils/error_message_utils.dart';
import 'package:YemPover_app/utils/snackbar_utils.dart';
import '../services/post_action_service.dart';
import 'package:YemPover_app/utils/blocked_users_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Extended Post class with the required properties
class ExtendedPost {
  final Post post;
  bool isFavorite;
  bool isHidden;
  String wishListCategory;
  String? favoriteId;
  double? distance;

  ExtendedPost({
    required this.post,
    this.isFavorite = false,
    this.isHidden = false,
    this.wishListCategory = '',
    this.favoriteId,
    this.distance,
  });

  bool get isForBarter =>
      post.barterStatus == BarterStatus.OPEN_FOR_BARTER ||
      post.status == PostStatus.FOR_BARTER;

  bool get isForSale => post.status == PostStatus.FOR_SALE;

  /// Sale-only listing (not open for barter).
  bool get isNotBarterSale =>
      !isForBarter &&
      (post.type == PostType.service || post.status == PostStatus.FOR_SALE);

  String get title => post.title;
  String get description => post.description;
  dynamic get category => post.category;
  DateTime get postedDate => post.postedDate;
  String get location => post.location;
  String get formattedPrice => post.formattedPrice;
  List<String> get processedImages => post.processedImages;
  dynamic get postedBy => post.postedBy;
  int get viewCount => post.viewCount;
  String get id => post.id;
  double? get latitude => post.latitude;
  double? get longitude => post.longitude;
  DateTime? get validUntil => post.validUntil;
  String? get remainingTime => post.remainingTime;
  bool get hasExpired => post.hasExpired;

  String get postTypeText {
    switch (post.status) {
      case PostStatus.LOOKING_FOR_SERVICE:
        return 'Looking for a service';
      case PostStatus.FOR_BARTER:
        return 'Bartering a product';
      case PostStatus.FOR_SALE:
        return 'Selling a product';
      case PostStatus.PROVIDE_SERVICE:
        return 'Providing a service';
      default:
        return 'Post';
    }
  }

  String get formattedDistance {
    if (distance == null) return '';
    if (distance! < 1) {
      return '${(distance! * 1000).toStringAsFixed(0)}m away';
    }
    return '${distance!.toStringAsFixed(1)}km away';
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeFilterPrefs {
  static const savedKey = 'home_filters_saved';
  static const tradeType = 'home_filter_trade_type';
  static const postType = 'home_filter_post_type';
  static const category = 'home_filter_category';
  static const wishListCategory = 'home_filter_wishlist_category';
  static const sortBy = 'home_filter_sort_by';
  static const radiusEnabled = 'home_filter_radius_enabled';
  static const radius = 'home_filter_radius';
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _googleApiKey = 'AIzaSyAT3wIjV73qVXPAlgkyifnns38GztnbNF4';

  final ApiService _apiService = ApiService();
  final MyProfileService _myProfileService = MyProfileService();
  final PostActionService _postActionService = PostActionService();
  final CategoryService _categoryService = CategoryService();
  final TokenService _tokenService = TokenService();
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final Map<String, Location?> _postLocationCache = {};
  Timer? _expiryTicker;

  // Data states
  List<ExtendedPost> _posts = [];
  ProfileData? profileData;
  List<ExtendedPost> _filteredPosts = [];
  bool _isGuestUser = false;

  // Loading states
  bool _isLoadingPosts = true;
  bool _isLoadingProfile = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 20;

  // Location states
  Position? _currentPosition;
  String _selectedLocation = 'Fetching location...';
  bool _isLocationLoading = false;
  bool _locationPermissionDenied = false;
  double? _manualLatitude;
  double? _manualLongitude;

  // Filter states
  String? _selectedTradeType;
  String? _selectedPostType;
  String? _selectedCategory;
  String? _selectedWishListCategory;
  String _selectedSortBy = 'Nearest';
  bool _isRadiusFilterEnabled = true;
  double _selectedRadius = 10.0;
  String _searchQuery = '';
  bool _isLoadingFilterCategories = false;
  List<Map<String, String>> _filterMainCategories = [];
  Map<String, List<Map<String, String>>> _filterSubCategories = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    BlockedUsersCache.instance.addListener(_onBlockedUsersChanged);
    _startExpiryTicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _onBlockedUsersChanged() {
    if (!mounted) return;
    setState(() {
      _posts = BlockedUsersCache.instance.filterByOwner(
        _posts,
        (post) => post.post.postedBy.id.isNotEmpty
            ? post.post.postedBy.id
            : post.post.postedById,
      );
      _applyFilters();
    });
  }

  @override
  void dispose() {
    BlockedUsersCache.instance.removeListener(_onBlockedUsersChanged);
    _expiryTicker?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startExpiryTicker() {
    _expiryTicker?.cancel();
    _expiryTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        // Rebuild to refresh countdown labels.
      });
    });
  }

  Future<void> _loadPersistedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_HomeFilterPrefs.savedKey) ?? false)) return;
    if (!mounted) return;

    setState(() {
      _selectedTradeType = _normalizePersistedTradeType(
        prefs.getString(_HomeFilterPrefs.tradeType),
      );
      _selectedPostType = _normalizePersistedPostType(
        prefs.getString(_HomeFilterPrefs.postType),
      );
      _selectedCategory = prefs.getString(_HomeFilterPrefs.category);
      _selectedWishListCategory = prefs.getString(
        _HomeFilterPrefs.wishListCategory,
      );
      _selectedSortBy =
          prefs.getString(_HomeFilterPrefs.sortBy) ?? _selectedSortBy;
      _isRadiusFilterEnabled =
          prefs.getBool(_HomeFilterPrefs.radiusEnabled) ??
          _isRadiusFilterEnabled;
      _selectedRadius =
          prefs.getDouble(_HomeFilterPrefs.radius) ?? _selectedRadius;
    });
  }

  String? _normalizePersistedTradeType(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value == 'For sale') return 'Not Barter';
    const allowed = ['Barter', 'Not Barter'];
    return allowed.contains(value) ? value : null;
  }

  String? _normalizePersistedPostType(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'Product' || 'Service' => value,
      'Looking for a product/service' => 'Service',
      'Offering for barter' || 'Barter/selling a product/service' => 'Product',
      _ => null,
    };
  }

  Future<void> _savePersistedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAnyFilter =
        _selectedTradeType != null ||
        _selectedPostType != null ||
        _selectedCategory != null ||
        _selectedWishListCategory != null ||
        _selectedSortBy != 'Nearest' ||
        _isRadiusFilterEnabled ||
        _searchQuery.isNotEmpty;

    if (!hasAnyFilter) {
      await _clearPersistedFilters();
      return;
    }

    await prefs.setBool(_HomeFilterPrefs.savedKey, true);
    await _writeOptionalString(
      prefs,
      _HomeFilterPrefs.tradeType,
      _selectedTradeType,
    );
    await _writeOptionalString(
      prefs,
      _HomeFilterPrefs.postType,
      _selectedPostType,
    );
    await _writeOptionalString(prefs, _HomeFilterPrefs.category, _selectedCategory);
    await _writeOptionalString(
      prefs,
      _HomeFilterPrefs.wishListCategory,
      _selectedWishListCategory,
    );
    await prefs.setString(_HomeFilterPrefs.sortBy, _selectedSortBy);
    await prefs.setBool(
      _HomeFilterPrefs.radiusEnabled,
      _isRadiusFilterEnabled,
    );
    await prefs.setDouble(_HomeFilterPrefs.radius, _selectedRadius);
  }

  Future<void> _writeOptionalString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }

  Future<void> _clearPersistedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_HomeFilterPrefs.savedKey);
    await prefs.remove(_HomeFilterPrefs.tradeType);
    await prefs.remove(_HomeFilterPrefs.postType);
    await prefs.remove(_HomeFilterPrefs.category);
    await prefs.remove(_HomeFilterPrefs.wishListCategory);
    await prefs.remove(_HomeFilterPrefs.sortBy);
    await prefs.remove(_HomeFilterPrefs.radiusEnabled);
    await prefs.remove(_HomeFilterPrefs.radius);
  }

  Future<void> _initializeData() async {
    try {
      await _loadPersistedFilters();

      final isLoggedIn = await _tokenService.isLoggedIn();
      _isGuestUser = await _tokenService.isGuestUser();

      if (!isLoggedIn && !_isGuestUser) {
        if (mounted) {
          SnackbarUtils.showLoginDialog(context);
        }
        setState(() {
          _isLoadingPosts = false;
          _isLoadingProfile = false;
        });
        return;
      }

      if (_isGuestUser) {
        setState(() {
          profileData = ProfileData(
            firstName: 'Guest',
            lastName: 'User',
            homeAddress: 'Guest Mode',
            totalTradesCompleted: 0,
          );
          _isLoadingProfile = false;
        });
        if (mounted) {
          Provider.of<NotificationProvider>(context, listen: false).reset();
        }
        ProfileSessionManager.instance.clearSession();
      }

      await Future.wait([
        if (!_isGuestUser)
          BlockedUsersCache.instance.ensureLoaded().catchError((e) {
            debugPrint('🔴 Blocked users load error: $e');
          }),
        if (!_isGuestUser)
          _fetchMyProfile().catchError((e) {
            debugPrint('🔴 Profile fetch error: $e');
            if (ErrorMessageUtils.isSessionExpired(e)) {
              _handleSessionExpired();
            }
            return null;
          }),
        _getCurrentLocation().catchError((e) {
          debugPrint('🔴 Location error: $e');
        }),
        _fetchPosts().catchError((e) {
          debugPrint('🔴 Posts fetch error: $e');
          if (ErrorMessageUtils.isSessionExpired(e)) {
            _handleSessionExpired();
          }
        }),
        if (!_isGuestUser)
          _loadUnreadNotificationCount().catchError((e) {
            debugPrint('🔴 Notification error: $e');
          }),
        _loadFilterCategories().catchError((e) {
          debugPrint('🔴 Filter category error: $e');
        }),
      ]);
    } catch (e) {
      debugPrint('🔴 Initialization error: $e');
      setState(() {
        _isLoadingPosts = false;
        _isLoadingProfile = false;
      });
    }
  }

  void _handleSessionExpired() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Session Expired'),
          content: const Text('Your session has expired. Please login again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  double? get _activeLatitude => _manualLatitude ?? _currentPosition?.latitude;
  double? get _activeLongitude =>
      _manualLongitude ?? _currentPosition?.longitude;

  void _updatePostDistances() {
    final refLat = _activeLatitude;
    final refLng = _activeLongitude;
    if (refLat == null || refLng == null || _posts.isEmpty) return;

    for (var post in _posts) {
      if (post.latitude != null && post.longitude != null) {
        post.distance = _calculateDistance(
          refLat,
          refLng,
          post.latitude!,
          post.longitude!,
        );
      }
    }
    _sortPostsByDistance();
    _applyFilters();
  }

  Future<void> _updatePostDistancesFromGeocoding() async {
    final refLat = _activeLatitude;
    final refLng = _activeLongitude;
    if (refLat == null || refLng == null || _posts.isEmpty) return;

    bool hasUpdates = false;

    for (final post in _posts) {
      if (post.distance != null) continue;
      if ((post.latitude != null && post.longitude != null) ||
          post.location.trim().isEmpty) {
        continue;
      }

      final normalizedLocation = post.location.trim().toLowerCase();

      Location? geocodedLocation;
      if (_postLocationCache.containsKey(normalizedLocation)) {
        geocodedLocation = _postLocationCache[normalizedLocation];
      } else {
        try {
          final locations = await locationFromAddress(post.location.trim());
          geocodedLocation = locations.isNotEmpty ? locations.first : null;
          _postLocationCache[normalizedLocation] = geocodedLocation;
        } catch (_) {
          _postLocationCache[normalizedLocation] = null;
          continue;
        }
      }

      if (geocodedLocation != null) {
        post.distance = _calculateDistance(
          refLat,
          refLng,
          geocodedLocation.latitude,
          geocodedLocation.longitude,
        );
        hasUpdates = true;
      }
    }

    if (!mounted || !hasUpdates) return;

    _sortPostsByDistance();
    _applyFilters();
  }

  void _sortPostsByDistance() {
    _posts.sort((a, b) {
      if (a.distance == null && b.distance == null) return 0;
      if (a.distance == null) return 1;
      if (b.distance == null) return -1;
      return a.distance!.compareTo(b.distance!);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !_isLoadingPosts) {
        _fetchPosts(loadMore: true);
      }
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      await provider.loadUnreadCount();
    } catch (e) {
      debugPrint('🔴 Error loading unread count: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationPermissionDenied = false;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _selectedLocation = 'Location services are disabled.';
          _isLocationLoading = false;
          _locationPermissionDenied = true;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _selectedLocation = 'Location permissions are denied.';
            _isLocationLoading = false;
            _locationPermissionDenied = true;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _selectedLocation = 'Location permissions are permanently denied.';
          _isLocationLoading = false;
          _locationPermissionDenied = true;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _manualLatitude = null;
        _manualLongitude = null;
      });

      _updatePostDistances();
      _updatePostDistancesFromGeocoding();

      await _getAddressFromLatLng(position);
    } catch (e) {
      setState(() {
        _selectedLocation = 'Failed to get location';
        _isLocationLoading = false;
      });
      debugPrint('🔴 Error getting location: $e');
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            [
                  place.street,
                  place.locality,
                  place.administrativeArea,
                  place.country,
                ]
                .where((element) => element != null && element.isNotEmpty)
                .join(', ')
                .replaceAll(RegExp(r',\s*,'), ',');

        setState(() {
          _selectedLocation = address.isNotEmpty ? address : "Current Location";
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedLocation = "Current Location";
        _isLocationLoading = false;
      });
      debugPrint("🔴 Error getting address: $e");
    }
  }

  Future<void> _fetchMyProfile() async {
    try {
      if (_isGuestUser) {
        setState(() => _isLoadingProfile = false);
        return;
      }

      final isLoggedIn = await _tokenService.isLoggedIn();
      if (!isLoggedIn) {
        setState(() => _isLoadingProfile = false);
        return;
      }

      final response = await _myProfileService.getMyProfile();
      setState(() {
        profileData = response.data;
        ProfileSessionManager.instance.setProfile(profileData);
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() => _isLoadingProfile = false);
      debugPrint('🔴 Error fetching profile: $e');

      if (ErrorMessageUtils.isSessionExpired(e)) {
        _handleSessionExpired();
      } else if (mounted) {
        SnackbarUtils.showError(
          context,
          e,
          fallback: 'Unable to load profile right now. Please try again.',
        );
      }
    }
  }

  Future<void> _fetchPosts({bool loadMore = false}) async {
    try {
      final isLoggedIn = await _tokenService.isLoggedIn();
      final canBrowse = isLoggedIn || _isGuestUser;
      if (!canBrowse) {
        setState(() {
          _isLoadingPosts = false;
          _isLoadingMore = false;
        });
        return;
      }

      if (!loadMore) {
        setState(() {
          _isLoadingPosts = true;
          _currentPage = 1;
          _hasMore = true;
        });
      } else {
        setState(() => _isLoadingMore = true);
      }

      final int requestPage = loadMore ? _currentPage + 1 : 1;

      String? tradeType;
      if (_selectedTradeType == 'Barter') {
        tradeType = 'barter';
      } else if (_selectedTradeType == 'Not Barter') {
        tradeType = 'sale';
      }

      String? backendPostType;
      if (_selectedPostType == 'Product') {
        backendPostType = 'product';
      } else if (_selectedPostType == 'Service') {
        backendPostType = 'service';
      }

      double? latitude;
      double? longitude;
      if (_activeLatitude != null && _activeLongitude != null) {
        latitude = _activeLatitude;
        longitude = _activeLongitude;
      }

      final response = await _apiService.getPosts(
        page: requestPage,
        limit: _limit,
        categoryId: _selectedWishListCategory ?? _selectedCategory,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        tradeType: tradeType,
        postType: backendPostType,
        latitude: latitude,
        longitude: longitude,
        radius: _selectedRadius,
      );

      final List<ExtendedPost> extendedPosts = response.posts.map((post) {
        double? distance;
        if (_activeLatitude != null &&
            _activeLongitude != null &&
            post.latitude != null &&
            post.longitude != null) {
          distance = _calculateDistance(
            _activeLatitude!,
            _activeLongitude!,
            post.latitude!,
            post.longitude!,
          );
        } else if (post.distance != null) {
          distance = post.distance;
        }

        return ExtendedPost(post: post, isFavorite: false, distance: distance);
      }).toList();

      extendedPosts.sort((a, b) {
        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        return a.distance!.compareTo(b.distance!);
      });

      if (loadMore) {
        final existingIds = _posts.map((post) => post.id).toSet();
        final uniquePosts = extendedPosts
            .where((post) => !existingIds.contains(post.id))
            .toList();

        setState(() {
          _posts.addAll(
            BlockedUsersCache.instance.filterByOwner(
              uniquePosts,
              (post) => post.post.postedBy.id.isNotEmpty
                  ? post.post.postedBy.id
                  : post.post.postedById,
            ),
          );
          _currentPage = requestPage;
          _applyFilters();
          _hasMore = response.pagination.page < response.pagination.pages;
          _isLoadingMore = false;
        });
        _updatePostDistancesFromGeocoding();
      } else {
        setState(() {
          _posts = BlockedUsersCache.instance.filterByOwner(
            extendedPosts,
            (post) => post.post.postedBy.id.isNotEmpty
                ? post.post.postedBy.id
                : post.post.postedById,
          );
          _currentPage = requestPage;
          _applyFilters();
          _hasMore = response.pagination.page < response.pagination.pages;
          _isLoadingPosts = false;
          _isLoadingMore = false;
        });
        _updatePostDistancesFromGeocoding();
      }
    } catch (e) {
      setState(() {
        _isLoadingPosts = false;
        _isLoadingMore = false;
      });
      debugPrint('🔴 Error fetching posts: $e');

      if (ErrorMessageUtils.isSessionExpired(e)) {
        _handleSessionExpired();
      } else if (mounted) {
        SnackbarUtils.showError(
          context,
          e,
          fallback: 'Unable to load posts right now. Please try again.',
        );
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _fetchPosts();
  }

  Future<void> _loadFilterCategories() async {
    if (_isLoadingFilterCategories) return;

    setState(() {
      _isLoadingFilterCategories = true;
    });

    try {
      final Map<String, Map<String, String>> mainCategoriesById = {};
      final Map<String, List<Map<String, String>>> subCategoriesByMain = {};

      for (final type in ['product', 'service']) {
        final response = await _categoryService.getCategories(type: type);

        for (final parent in response.data) {
          mainCategoriesById[parent.id] = {
            'id': parent.id,
            'name': parent.name,
          };

          final subCategories = parent.children
              .map((child) => {'id': child.id, 'name': child.name})
              .toList();

          if (subCategoriesByMain.containsKey(parent.id)) {
            final existing = subCategoriesByMain[parent.id]!;
            for (final sub in subCategories) {
              if (!existing.any((e) => e['id'] == sub['id'])) {
                existing.add(sub);
              }
            }
          } else {
            subCategoriesByMain[parent.id] = subCategories;
          }
        }
      }

      final mainList = mainCategoriesById.values.toList()
        ..sort(
          (a, b) => (a['name'] ?? '').toLowerCase().compareTo(
            (b['name'] ?? '').toLowerCase(),
          ),
        );

      for (final entry in subCategoriesByMain.entries) {
        entry.value.sort(
          (a, b) => (a['name'] ?? '').toLowerCase().compareTo(
            (b['name'] ?? '').toLowerCase(),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _filterMainCategories = mainList;
        _filterSubCategories = subCategoriesByMain;
        _isLoadingFilterCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingFilterCategories = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPosts = _posts.where((post) {
        if (!_isGuestUser) {
          final ownerId = post.post.postedBy.id.isNotEmpty
              ? post.post.postedBy.id
              : post.post.postedById;
          if (BlockedUsersCache.instance.isBlocked(ownerId)) {
            return false;
          }
        }

        if (_selectedTradeType == 'Barter' && !post.isForBarter) {
          return false;
        }
        if (_selectedTradeType == 'Not Barter' && !post.isNotBarterSale) {
          return false;
        }

        if (_selectedPostType == 'Product' &&
            post.post.type != PostType.product) {
          return false;
        }
        if (_selectedPostType == 'Service' &&
            post.post.type != PostType.service) {
          return false;
        }

        if (_selectedCategory != null) {
          final postCategory = post.category;
          final belongsToMain =
              postCategory.id == _selectedCategory ||
              postCategory.parentId == _selectedCategory;

          if (!belongsToMain) return false;
        }

        if (_selectedWishListCategory != null &&
            post.category.id != _selectedWishListCategory) {
          return false;
        }

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!post.title.toLowerCase().contains(query) &&
              !post.description.toLowerCase().contains(query) &&
              !post.category.name.toLowerCase().contains(query)) {
            return false;
          }
        }

        if (_isRadiusFilterEnabled &&
            _activeLatitude != null &&
            _activeLongitude != null &&
            post.distance != null &&
            post.distance! > _selectedRadius) {
          return false;
        }

        return true;
      }).toList();

      _sortFilteredPosts();
    });
  }

  void _sortFilteredPosts() {
    int compareDistance(ExtendedPost a, ExtendedPost b) {
      if (a.distance == null && b.distance == null) return 0;
      if (a.distance == null) return 1;
      if (b.distance == null) return -1;
      return a.distance!.compareTo(b.distance!);
    }

    _filteredPosts.sort((a, b) {
      switch (_selectedSortBy) {
        case 'Newest':
          return b.postedDate.compareTo(a.postedDate);
        case 'Oldest':
          return a.postedDate.compareTo(b.postedDate);
        case 'Price: Low to High':
          return a.post.price.compareTo(b.post.price);
        case 'Price: High to Low':
          return b.post.price.compareTo(a.post.price);
        case 'Nearest':
        default:
          return compareDistance(a, b);
      }
    });
  }

  Future<void> _clearAllFilters() async {
    if (!mounted) return;

    setState(() {
      _selectedTradeType = null;
      _selectedPostType = null;
      _selectedCategory = null;
      _selectedWishListCategory = null;
      _selectedSortBy = 'Nearest';
      _isRadiusFilterEnabled = false;
      _selectedRadius = 10.0;
      _searchQuery = '';
      _searchController.clear();
    });

    await _clearPersistedFilters();
    await _fetchPosts();
  }

  bool get _hasActiveFilters =>
      _selectedTradeType != null ||
      _selectedPostType != null ||
      _selectedCategory != null ||
      _selectedWishListCategory != null ||
      _selectedSortBy != 'Nearest' ||
      _isRadiusFilterEnabled;

  void _showLocationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Location',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildLocationOption(
              icon: Icons.my_location,
              iconColor: Colors.blue,
              title: 'Use My Current Location',
              subtitle: 'Automatically detect your location',
              onTap: () async {
                Navigator.pop(context);
                await _getCurrentLocation();
              },
            ),
            _buildLocationOption(
              icon: Icons.edit_location_alt,
              iconColor: Colors.orange,
              title: 'Enter Location Manually',
              subtitle: 'Search for a specific place',
              onTap: () {
                Navigator.pop(context);
                _showManualLocationInput();
              },
            ),

            if (_locationPermissionDenied) ...[
              const Divider(height: 30),
              _buildLocationOption(
                icon: Icons.settings,
                iconColor: Colors.grey,
                title: 'Open Location Settings',
                subtitle: 'Enable location permissions',
                onTap: () {
                  Navigator.pop(context);
                  Geolocator.openAppSettings();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      onTap: onTap,
    );
  }

  Future<void> _showManualLocationInput() async {
    final controller = TextEditingController(
      text: _selectedLocation == 'Fetching location...'
          ? ''
          : _selectedLocation,
    );
    double? selectedLat;
    double? selectedLng;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_location_alt,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Enter Location',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search and pick your city or area',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                    ),
                    child: GooglePlaceAutoCompleteTextField(
                      textEditingController: controller,
                      googleAPIKey: _googleApiKey,
                      debounceTime: 400,
                      isLatLngRequired: true,
                      countries: const ['in', 'us', 'ca', 'gb', 'au'],
                      boxDecoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      inputDecoration: InputDecoration(
                        hintText: 'Search for a location...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade600,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      getPlaceDetailWithLatLng: (Prediction prediction) {
                        selectedLat = double.tryParse(prediction.lat ?? '');
                        selectedLng = double.tryParse(prediction.lng ?? '');
                      },
                      itemClick: (Prediction prediction) {
                        final selectedAddress = prediction.description ?? '';
                        if (selectedAddress.isEmpty) return;
                        selectedLat = double.tryParse(prediction.lat ?? '');
                        selectedLng = double.tryParse(prediction.lng ?? '');
                        Navigator.of(sheetContext).pop({
                          'address': selectedAddress,
                          'lat': selectedLat,
                          'lng': selectedLng,
                        });
                      },
                      seperatedBuilder: const Divider(height: 1),
                      containerHorizontalPadding: 0,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );

    final manualAddress = result?['address']?.toString().trim() ?? '';
    selectedLat = result?['lat'] as double?;
    selectedLng = result?['lng'] as double?;
    if (manualAddress.isEmpty) return;

    setState(() {
      _isLocationLoading = true;
      _locationPermissionDenied = false;
    });

    try {
      double? resolvedLat = selectedLat;
      double? resolvedLng = selectedLng;

      if (resolvedLat == null || resolvedLng == null) {
        final locations = await locationFromAddress(manualAddress);
        if (locations.isEmpty) {
          throw Exception('Location not found');
        }
        resolvedLat = locations.first.latitude;
        resolvedLng = locations.first.longitude;
      }

      if (!mounted) return;

      setState(() {
        _manualLatitude = resolvedLat;
        _manualLongitude = resolvedLng;
        _selectedLocation = manualAddress;
        _isLocationLoading = false;
      });

      await _fetchPosts();
      _updatePostDistances();
      _updatePostDistancesFromGeocoding();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLocationLoading = false;
      });
      SnackbarUtils.showError(
        context,
        'Could not resolve that location. Try a clearer address.',
      );
    }
  }

  Future<void> _showFilterDialog() async {
    if (_filterMainCategories.isEmpty && !_isLoadingFilterCategories) {
      await _loadFilterCategories();
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => FilterScreen(
        selectedTradeType: _selectedTradeType,
        selectedPostType: _selectedPostType,
        selectedCategory: _selectedCategory,
        selectedWishListCategory: _selectedWishListCategory,
        selectedSortBy: _selectedSortBy,
        isRadiusFilterEnabled: _isRadiusFilterEnabled,
        selectedRadius: _selectedRadius,
        mainCategories: _filterMainCategories,
        subCategoriesByMain: _filterSubCategories,
        isLoadingCategories: _isLoadingFilterCategories,
        onRetryLoadCategories: _loadFilterCategories,
        onApply:
            (
              tradeType,
              postType,
              category,
              wishListCategory,
              sortBy,
              isRadiusFilterEnabled,
              radius,
            ) {
              setState(() {
                _selectedTradeType = tradeType;
                _selectedPostType = postType;
                _selectedCategory = category;
                _selectedWishListCategory = wishListCategory;
                _selectedSortBy = sortBy;
                _isRadiusFilterEnabled = isRadiusFilterEnabled;
                _selectedRadius = radius;
              });
              unawaited(_savePersistedFilters());
              _fetchPosts();
              Navigator.pop(context);
            },
        onClear: () {
          _clearAllFilters();
        },
      ),
    );
  }

  Future<void> _hidePost(ExtendedPost post) async {
    try {
      final isLoggedIn = await _tokenService.isLoggedIn();
      if (_isGuestUser || !isLoggedIn) {
        _showPleaseLoginMessage();
        return;
      }

      await _postActionService.hidePost(post.id);

      if (!mounted) return;
      setState(() {
        _posts.removeWhere((element) => element.id == post.id);
        _filteredPosts.removeWhere((element) => element.id == post.id);
      });

      SnackbarUtils.showSuccess(context, 'Post hidden successfully');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        e,
        fallback: 'Unable to hide this post right now. Please try again.',
      );
    }
  }

  Future<void> _confirmHidePost(ExtendedPost post) async {
    final isLoggedIn = await _tokenService.isLoggedIn();
    if (!mounted) return;
    if (_isGuestUser || !isLoggedIn) {
      _showPleaseLoginMessage();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hide Post',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Do you want to hide this post from your feed?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Hide'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _hidePost(post);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  String _getBarterStatus(ExtendedPost post) {
    if (post.isForBarter) return 'Open for barter';
    if (post.isForSale) return 'For sale';
    return '';
  }

  String _getReturnType(ExtendedPost post) {
    if (post.isForBarter) {
      return post.wishListCategory.isNotEmpty
          ? post.wishListCategory
          : 'Open for barter';
    }
    return post.formattedPrice;
  }

  /// Avoid duplicating barter status (e.g. "Open for barter" chip + "In Return: Open for barter").
  bool _shouldShowInReturnChip(ExtendedPost post) {
    final returnType = _getReturnType(post).trim();
    if (returnType.isEmpty) return false;

    final barterStatus = _getBarterStatus(post).trim();
    if (barterStatus.isNotEmpty &&
        returnType.toLowerCase() == barterStatus.toLowerCase()) {
      return false;
    }

    if (post.isForBarter) {
      return post.wishListCategory.trim().isNotEmpty;
    }

    return returnType != post.formattedPrice.trim();
  }

  String _getTimelineLabel(ExtendedPost post) {
    final validUntil = post.validUntil;
    if (validUntil == null) {
      return 'No expiry';
    }

    final now = DateTime.now();
    if (!validUntil.isAfter(now)) {
      return 'Expired';
    }

    final difference = validUntil.difference(now);

    final totalMinutes = difference.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final seconds = difference.inSeconds % 60;
    final days = difference.inDays;

    if (hours < 24) {
      return 'Expires in ${hours}h:${minutes.toString().padLeft(2, '0')}m:${seconds.toString().padLeft(2, '0')}s';
    }
    if (days < 30) {
      final dayHours = difference.inHours % 24;
      return dayHours > 0
          ? 'Expires in ${days}d ${dayHours}h'
          : 'Expires in ${days}d';
    }

    final months = (days / 30).floor();
    final remDays = days % 30;
    return remDays > 0
        ? 'Expires in ${months}mo ${remDays}d'
        : 'Expires in ${months}mo';
  }

  Color _getTimelineChipBgColor(ExtendedPost post) {
    final validUntil = post.validUntil;
    if (validUntil == null) {
      return Colors.blueGrey.shade50;
    }

    final now = DateTime.now();
    if (!validUntil.isAfter(now)) {
      return Colors.red.shade50;
    }

    final difference = validUntil.difference(now);
    if (difference.inHours < 1) {
      return Colors.red.shade50;
    }
    if (difference.inHours < 24) {
      return Colors.orange.shade50;
    }
    return Colors.green.shade50;
  }

  Color _getTimelineChipFgColor(ExtendedPost post) {
    final validUntil = post.validUntil;
    if (validUntil == null) {
      return Colors.blueGrey.shade700;
    }

    final now = DateTime.now();
    if (!validUntil.isAfter(now)) {
      return Colors.red.shade700;
    }

    final difference = validUntil.difference(now);
    if (difference.inHours < 1) {
      return Colors.red.shade700;
    }
    if (difference.inHours < 24) {
      return Colors.orange.shade700;
    }
    return Colors.green.shade700;
  }

  void _showPleaseLoginMessage() {
    if (!mounted) return;
    SnackbarUtils.showGuestLoginRequired(context);
  }

  void _navigateToHamburgerMenu() {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HamburgerMenuScreen()),
    );
  }

  void _navigateToMyProfile() async {
    final isLoggedIn = await _tokenService.isLoggedIn();
    if (!mounted) return;
    if (_isGuestUser || !isLoggedIn) {
      _showPleaseLoginMessage();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyProfileScreen()),
    );

    if (mounted) {
      _fetchMyProfile();
    }
  }

  void _navigateToTradeChat() async {
    final isLoggedIn = await _tokenService.isLoggedIn();
    if (!mounted) return;
    if (_isGuestUser || !isLoggedIn) {
      _showPleaseLoginMessage();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TradeChatScreen()),
    );
  }

  void _navigateToTradeBooth() async {
    final isLoggedIn = await _tokenService.isLoggedIn();
    if (!mounted) return;
    if (_isGuestUser || !isLoggedIn) {
      _showPleaseLoginMessage();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TradeBoothScreen()),
    );
  }

  void _showNotificationScreen() async {
    final isLoggedIn = await _tokenService.isLoggedIn();
    if (!mounted) return;
    if (_isGuestUser || !isLoggedIn) {
      _showPleaseLoginMessage();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          notifications: const [],
          onNotificationTap: (p1) {},
        ),
      ),
    ).then((_) => _loadUnreadNotificationCount());
  }

  void _showCoinsWalletScreen() async {
    final isLoggedIn = await _tokenService.isLoggedIn();
    if (!mounted) return;
    if (_isGuestUser || !isLoggedIn) {
      _showPleaseLoginMessage();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CoinsWalletScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit =
            await showDialog<bool>(
              context: context,
              barrierColor: Colors.black.withValues(alpha: 0.52),
              builder: (context) => Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.exit_to_app_rounded,
                              color: Color(0xFFE53935),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Exit App',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Are you sure you want to close YemPover now?',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: Colors.black.withValues(alpha: 0.68),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Stay',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: const Color(0xFFE53935),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Exit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ) ??
            false;

        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildLocationRow(),
              _buildSearchBar(),
              Expanded(
                child: _isLoadingPosts
                    ? _buildShimmerLoading()
                    : _filteredPosts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshPosts,
                        color: const Color(0xFF2E5BFF),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        strokeWidth: 2.2,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _filteredPosts.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _filteredPosts.length) {
                              return _buildLoadingMoreIndicator();
                            }
                            return _buildProductCard(_filteredPosts[index]);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off,
                      size: 80,
                      color: Colors.blue.shade300,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No posts found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Try adjusting your filters or search query',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _clearAllFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingMoreIndicator() {
    if (!_isLoadingMore && !_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No more posts',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
      );
    }
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A5AA8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2A7BC9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A5AA8).withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _navigateToMyProfile,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _isLoadingProfile
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 23,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: profileData?.profileImage != null
                            ? NetworkImage(profileData!.profileImage!)
                            : null,
                        child: profileData?.profileImage == null
                            ? Text(
                                profileData?.firstName?.isNotEmpty == true
                                    ? profileData!.firstName![0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A5AA8),
                                ),
                              )
                            : null,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoadingProfile
                        ? 'Hi, User'
                        : "${profileData?.firstName ?? ''} ${profileData?.lastName ?? ''}"
                              .trim(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Welcome to YemPover',
                    style: TextStyle(
                      color: Color(0xFFE1EEFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                final badgeCount = _isGuestUser ? 0 : provider.unreadCount;
                return Stack(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.26),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.notifications_none_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: _showNotificationScreen,
                      ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFF0A5AA8),
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              badgeCount > 9 ? '9+' : '$badgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.26)),
              ),
              child: IconButton(
                icon: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/image.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                onPressed: _showCoinsWalletScreen,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _navigateToHamburgerMenu,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.26)),
                ),
                child: const Icon(Icons.menu, size: 24, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: InkWell(
        onTap: _showLocationOptions,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE6FF)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      _isLocationLoading ? 'Updating...' : _selectedLocation,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              if (_isLocationLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 22,
                  color: Colors.grey.shade600,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _applyFilters();
                },
                decoration: InputDecoration(
                  hintText: 'Search products, services...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade500),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _applyFilters();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Builder(
            builder: (context) {
              final hasActiveFilters = _hasActiveFilters;

              return Container(
                decoration: BoxDecoration(
                  gradient: hasActiveFilters
                      ? const LinearGradient(
                          colors: [Color(0xFF2E5BFF), Color(0xFF4A7AFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: hasActiveFilters ? null : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: hasActiveFilters
                          ? Colors.blue.withOpacity(0.25)
                          : Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: _showFilterDialog,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.tune,
                        color: hasActiveFilters
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ExtendedPost post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PostDetailScreen(post: post.post, userItems: const []),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE6ECFF), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: const Color(0x332E5BFF),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child:
                      post.processedImages.isNotEmpty &&
                          post.processedImages.first.trim().isNotEmpty
                      ? SafeNetworkImage(
                          url: post.processedImages.first,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            height: 220,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          errorWidget: Container(
                            height: 220,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 220,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
                // Looking for tag
                if (post.postTypeText.contains('Looking for'))
                  Positioned(
                    top: 20,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Looking for',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Hide button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.visibility_off_outlined,
                        color: Colors.grey,
                        size: 22,
                      ),
                      onPressed: () => _confirmHidePost(post),
                    ),
                  ),
                ),
              ],
            ),
            // Content Section (field order matches Trade Booth: title → chips → location → description → footer)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          post.category.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEFF1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              post.post.type == PostType.service
                                  ? Icons.handyman_outlined
                                  : Icons.inventory_2_outlined,
                              size: 14,
                              color: const Color(0xFF37474F),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post.post.type == PostType.service
                                  ? 'Service'
                                  : 'Product',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF37474F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_getBarterStatus(post).isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EAF6),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync_alt,
                                size: 14,
                                color: const Color(0xFF3F51B5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getBarterStatus(post),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF3F51B5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (post.post.canClubItems)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.all_inclusive,
                                size: 14,
                                color: const Color(0xFF00695C),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Can be clubbed',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF00695C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (post.post.price > 0)
                        CoinPriceLabel(
                          text:
                              '${post.formattedPrice}${post.formattedPrice == 'Free' ? '' : ' coins'}',
                          iconSize: 14,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                    ],
                  ),
                  if (post.location.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (post.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      post.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: _getTimelineChipFgColor(post),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getTimelineLabel(post),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getTimelineChipFgColor(post),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (post.formattedDistance.isNotEmpty) ...[
                        Icon(
                          Icons.near_me_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.formattedDistance,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _formatDate(post.postedDate),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (_shouldShowInReturnChip(post)) ...[
                    const SizedBox(height: 10),
                    // Wish-list / return value when it adds info beyond chips above
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'In Return: ${_getReturnType(post)}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 80 + bottomInset,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.home_filled, 'Marketplace', true),
                  const SizedBox(width: 40),
                  Consumer<NotificationProvider>(
                    builder: (context, provider, child) {
                      final badgeCount = _isGuestUser ? 0 : provider.unreadCount;
                      return _navItem(
                        Icons.chat_bubble_outline,
                        'Chat',
                        false,
                        badge: badgeCount,
                        iconAssetPath: 'assets/chat_icons.png',
                      );
                    },
                  ),
                ],
              ),
              Positioned(
                top: -20,
                child: GestureDetector(
                  onTap: _navigateToTradeBooth,
                  child: Column(
                    children: [
                      Container(
                        height: 65,
                        width: 65,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E5BFF), Color(0xFF4A7AFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Trade Booth',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
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

  Widget _navItem(
    IconData icon,
    String label,
    bool isActive, {
    int badge = 0,
    String? iconAssetPath,
  }) {
    return GestureDetector(
      onTap: label == 'Chat' ? _navigateToTradeChat : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              iconAssetPath != null
                  ? Opacity(
                      opacity: isActive ? 1 : 0.7,
                      child: Image.asset(
                        iconAssetPath,
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(
                      icon,
                      color: isActive ? Colors.blue : Colors.grey.shade400,
                      size: 28,
                    ),
              if (badge > 0)
                Positioned(
                  right: -1,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.blue : Colors.grey.shade400,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class FilterScreen extends StatefulWidget {
  final String? selectedTradeType;
  final String? selectedPostType;
  final String? selectedCategory;
  final String? selectedWishListCategory;
  final String selectedSortBy;
  final bool isRadiusFilterEnabled;
  final double selectedRadius;
  final List<Map<String, String>> mainCategories;
  final Map<String, List<Map<String, String>>> subCategoriesByMain;
  final bool isLoadingCategories;
  final Future<void> Function() onRetryLoadCategories;
  final Function(String?, String?, String?, String?, String, bool, double)
  onApply;
  final VoidCallback onClear;

  const FilterScreen({
    super.key,
    required this.selectedTradeType,
    required this.selectedPostType,
    required this.selectedCategory,
    required this.selectedWishListCategory,
    required this.selectedSortBy,
    required this.isRadiusFilterEnabled,
    required this.selectedRadius,
    required this.mainCategories,
    required this.subCategoriesByMain,
    required this.isLoadingCategories,
    required this.onRetryLoadCategories,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

enum _CategoryPickerField { none, main, sub }

class _FilterScreenState extends State<FilterScreen> {
  static const Color _accent = Color(0xFF2E5BFF);
  static const Color _surface = Color(0xFFF7F9FF);
  static const Color _border = Color(0xFFE6ECFF);
  static const double _categoryListMaxHeight = 220;

  _CategoryPickerField _openCategoryPicker = _CategoryPickerField.none;

  late String? _selectedTradeType;
  late String? _selectedPostType;
  late String? _selectedCategory;
  late String? _selectedWishListCategory;
  late String _selectedSortBy;
  late bool _isRadiusFilterEnabled;
  late double _selectedRadius;

  final List<String> _sortOptions = [
    'Nearest',
    'Newest',
    'Oldest',
  ];
  final List<String> _tradeTypes = [
    'Barter',
    'Not Barter',
  ];
  final List<String> _postTypes = [
    'Product',
    'Service',
  ];

  int get _activeFilterCount {
    var count = 0;
    if (_selectedTradeType != null) count++;
    if (_selectedPostType != null) count++;
    if (_selectedCategory != null) count++;
    if (_selectedWishListCategory != null) count++;
    if (_isRadiusFilterEnabled) count++;
    if (_selectedSortBy != 'Nearest') count++;
    return count;
  }

  String? _normalizeIncomingTradeType(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value == 'For sale') return 'Not Barter';
    return _tradeTypes.contains(value) ? value : null;
  }

  String? _normalizeIncomingPostType(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'Product' || 'Service' => value,
      'Looking for a product/service' => 'Service',
      'Offering for barter' || 'Barter/selling a product/service' => 'Product',
      _ => _postTypes.contains(value) ? value : null,
    };
  }

  void _syncFromWidget() {
    _selectedTradeType = _normalizeIncomingTradeType(widget.selectedTradeType);
    _selectedPostType = _normalizeIncomingPostType(widget.selectedPostType);
    _selectedCategory = widget.selectedCategory;
    _selectedWishListCategory = widget.selectedWishListCategory;
    _selectedSortBy = widget.selectedSortBy;
    _isRadiusFilterEnabled = widget.isRadiusFilterEnabled;
    _selectedRadius = widget.selectedRadius;
  }

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant FilterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTradeType != widget.selectedTradeType ||
        oldWidget.selectedPostType != widget.selectedPostType ||
        oldWidget.selectedCategory != widget.selectedCategory ||
        oldWidget.selectedWishListCategory != widget.selectedWishListCategory ||
        oldWidget.selectedSortBy != widget.selectedSortBy ||
        oldWidget.isRadiusFilterEnabled != widget.isRadiusFilterEnabled ||
        oldWidget.selectedRadius != widget.selectedRadius) {
      _syncFromWidget();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedTradeType = null;
      _selectedPostType = null;
      _selectedCategory = null;
      _selectedWishListCategory = null;
      _selectedSortBy = 'Nearest';
      _isRadiusFilterEnabled = false;
      _selectedRadius = 10.0;
      _openCategoryPicker = _CategoryPickerField.none;
    });
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (_activeFilterCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_activeFilterCount active',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _accent,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
                children: [
                  _buildFilterSection(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Trade type',
                    options: _tradeTypes,
                    selectedValue: _selectedTradeType,
                    onChanged: (value) {
                      setState(() => _selectedTradeType = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildFilterSection(
                    icon: Icons.article_outlined,
                    title: 'Post type',
                    options: _postTypes,
                    selectedValue: _selectedPostType,
                    onChanged: (value) {
                      setState(() => _selectedPostType = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildCategoryDropdowns(),
                  const SizedBox(height: 14),
                  _buildRadiusFilter(),
                  const SizedBox(height: 14),
                  _buildFilterSection(
                    icon: Icons.sort_rounded,
                    title: 'Sort by',
                    options: _sortOptions,
                    selectedValue: _selectedSortBy,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedSortBy = value);
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: _border),
                        foregroundColor: const Color(0xFF374151),
                      ),
                      child: const Text(
                        'Clear all',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E5BFF), Color(0xFF4A7AFF)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withOpacity(0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply(
                            _selectedTradeType,
                            _selectedPostType,
                            _selectedCategory,
                            _selectedWishListCategory,
                            _selectedSortBy,
                            _isRadiusFilterEnabled,
                            _selectedRadius,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text(
                          'Apply filters',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
    );
  }

  Widget _buildFilterCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
    );
  }

  List<Map<String, String>> _validCategoryOptions(
    List<Map<String, String>> options,
  ) {
    return options
        .where(
          (item) =>
              (item['id'] ?? '').isNotEmpty && (item['name'] ?? '').isNotEmpty,
        )
        .toList();
  }

  String? _labelForCategoryId(
    List<Map<String, String>> options,
    String? id,
  ) {
    if (id == null) return null;
    for (final item in options) {
      if (item['id'] == id) return item['name'];
    }
    return null;
  }

  void _toggleCategoryPicker(_CategoryPickerField field) {
    setState(() {
      _openCategoryPicker =
          _openCategoryPicker == field ? _CategoryPickerField.none : field;
    });
  }

  Widget _buildInlineCategoryPicker({
    required String hint,
    required String? selectedId,
    required List<Map<String, String>> options,
    required _CategoryPickerField field,
    required ValueChanged<String?> onChanged,
  }) {
    final validOptions = _validCategoryOptions(options);
    final isOpen = _openCategoryPicker == field;
    final selectedLabel = _labelForCategoryId(validOptions, selectedId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _toggleCategoryPicker(field),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: _dropdownDecoration(hint).copyWith(
                suffixIcon: Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                ),
              ),
              child: Text(
                selectedLabel ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: selectedLabel != null
                      ? const Color(0xFF111827)
                      : Colors.grey.shade500,
                  fontWeight: selectedLabel != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
        if (isOpen) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(
              maxHeight: _categoryListMaxHeight,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: validOptions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'No categories available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: validOptions.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: _border.withValues(alpha: 0.8),
                    ),
                    itemBuilder: (context, index) {
                      final item = validOptions[index];
                      final id = item['id']!;
                      final name = item['name']!;
                      final isSelected = selectedId == id;
                      return ListTile(
                        dense: true,
                        title: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? _accent
                                : const Color(0xFF111827),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: _accent, size: 20)
                            : null,
                        onTap: () {
                          onChanged(id);
                          setState(
                            () => _openCategoryPicker =
                                _CategoryPickerField.none,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryDropdowns() {
    if (widget.isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(
            color: _accent,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (widget.mainCategories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Unable to load categories',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onRetryLoadCategories,
                style: TextButton.styleFrom(foregroundColor: _accent),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final subCategories = _selectedCategory != null
        ? (widget.subCategoriesByMain[_selectedCategory!] ??
            const <Map<String, String>>[])
        : const <Map<String, String>>[];

    return _buildFilterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category_outlined, size: 20, color: _accent),
              const SizedBox(width: 8),
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInlineCategoryPicker(
            hint: 'Select category',
            selectedId: _selectedCategory,
            options: widget.mainCategories,
            field: _CategoryPickerField.main,
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _selectedWishListCategory = null;
                _openCategoryPicker = _CategoryPickerField.none;
              });
            },
          ),
          if (_selectedCategory != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  size: 20,
                  color: _accent,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Subcategory',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (subCategories.isEmpty)
              Text(
                'No subcategories available',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              )
            else
              _buildInlineCategoryPicker(
                hint: 'Select subcategory',
                selectedId: _selectedWishListCategory,
                options: subCategories,
                field: _CategoryPickerField.sub,
                onChanged: (value) {
                  setState(() => _selectedWishListCategory = value);
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required IconData icon,
    required String title,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    String Function(String value)? optionLabelBuilder,
    bool Function(String value)? optionSelectedByValue,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();

    return _buildFilterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((option) {
                  final isSelected =
                      optionSelectedByValue?.call(option) ??
                      selectedValue == option;
                  final label = optionLabelBuilder?.call(option) ?? option;
                  final isLongLabel = label.length > 22;

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isLongLabel
                          ? constraints.maxWidth
                          : constraints.maxWidth,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onChanged(isSelected ? null : option),
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _accent.withOpacity(0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? _accent : _border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: _accent,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? _accent
                                        : const Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusFilter() {
    return _buildFilterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 20, color: _accent),
              const SizedBox(width: 8),
              const Text(
                'Distance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: _isRadiusFilterEnabled,
                activeColor: _accent,
                onChanged: (value) {
                  setState(() => _isRadiusFilterEnabled = value);
                },
              ),
            ],
          ),
          Text(
            _isRadiusFilterEnabled
                ? 'Within ${_selectedRadius.toStringAsFixed(0)} km of your location'
                : 'Show posts from any distance',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          if (_isRadiusFilterEnabled) ...[
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _accent,
                inactiveTrackColor: _border,
                thumbColor: _accent,
                overlayColor: _accent.withOpacity(0.12),
              ),
              child: Slider(
                value: _selectedRadius,
                min: 1,
                max: 50,
                divisions: 49,
                label: '${_selectedRadius.toStringAsFixed(0)} km',
                onChanged: (value) {
                  setState(() => _selectedRadius = value);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 km', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedRadius.toStringAsFixed(0)} km',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
                Text('50 km', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
