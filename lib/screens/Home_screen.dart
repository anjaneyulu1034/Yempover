import 'package:Yempover_app/utils/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:Yempover_app/models/ProductPostmain.dart';
import 'package:Yempover_app/models/get_my_profile_response.dart';
import 'package:Yempover_app/services/api_service.dart';
import 'package:Yempover_app/screens/PostDetailScreen.dart';
import 'package:Yempover_app/screens/tradechatscreen/TradeChatScreen.dart';
import 'package:Yempover_app/screens/TradeBoothScreen.dart';
import 'package:Yempover_app/screens/HamburgerMenuScreen.dart';
import 'package:Yempover_app/screens/NotificationsScreen.dart';
import 'package:Yempover_app/services/my_profile_service.dart';
import 'package:Yempover_app/services/profile_session_manager.dart';
import 'package:Yempover_app/services/token_service.dart';
import 'package:Yempover_app/utils/snackbar_utils.dart';
import '../services/post_action_service.dart';

// Extended Post class with the required properties
class ExtendedPost {
  final Post post;
  bool isFavorite;
  bool isHidden;
  String wishListCategory;
  String? favoriteId; // Store favorite ID for removal

  ExtendedPost({
    required this.post,
    this.isFavorite = false,
    this.isHidden = false,
    this.wishListCategory = '',
    this.favoriteId,
  });

  // Getter for isForBarter
  bool get isForBarter => post.status == PostStatus.FOR_BARTER;

  // Getter for isForSale
  bool get isForSale => post.status == PostStatus.FOR_SALE;

  // Delegate other properties to the original post
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

  // Post type based on status
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
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final MyProfileService _MyProfileService = MyProfileService();
  final PostActionService _postActionService = PostActionService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // API state variables - using ExtendedPost
  List<ExtendedPost> _posts = [];
  ProfileData? profileData;
  List<ExtendedPost> _filteredPosts = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;
  Map<String, String> _favoriteIds = {}; // Map productId to favoriteId

  // UI state variables from original code
  bool _showPushNotificationDialog = false;
  bool _pushNotificationGranted = false;
  String _selectedLocation = 'Fetching location...';
  bool _useCurrentLocation = true;

  // Location variables
  Position? _currentPosition;
  String _currentAddress = '';
  bool _isLocationLoading = false;
  bool _locationPermissionDenied = false;

  // Filter states from original code
  String? _selectedTradeType;
  String? _selectedPostType;
  String? _selectedCategory;
  String? _selectedWishListCategory;
  double _selectedRadius = 10.0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    debugPrint("111");

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _checkFirstTimeUser();
      await _fetchMyProfile();
      await _getCurrentLocation();
      await _fetchPosts();
      await _loadUserFavorites();
      await _loadHiddenPosts();

      // Load unread notification count
      _loadUnreadNotificationCount();
    });
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

  String? _errorMessage;

  // Load user's favorites
  Future<void> _loadUserFavorites() async {
    try {
      final favorites = await _postActionService.getFavorites();
      setState(() {
        _favoriteIds = {};
        for (var favorite in favorites) {
          if (favorite.productId.isNotEmpty) {
            _favoriteIds[favorite.productId] = favorite.id;
          }
        }

        // Update posts with favorite status
        for (var post in _posts) {
          post.isFavorite = _favoriteIds.containsKey(post.id);
          post.favoriteId = _favoriteIds[post.id];
        }
        _applyFilters();
      });
    } catch (e) {
      debugPrint('🔴 Error loading favorites: $e');
    }
  }

  // Load hidden posts
  Future<void> _loadHiddenPosts() async {
    try {
      final hiddenPostIds = await _postActionService.getHiddenPostIds();
      setState(() {
        for (var post in _posts) {
          post.isHidden = hiddenPostIds.contains(post.id);
        }
        _applyFilters();
      });
    } catch (e) {
      debugPrint('🔴 Error loading hidden posts: $e');
    }
  }

  // Location Methods
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationPermissionDenied = false;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _selectedLocation = 'Location services are disabled.';
          _isLocationLoading = false;
          _locationPermissionDenied = true;
        });
        return;
      }

      // Check and request permission
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

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Get address from coordinates
      await _getAddressFromLatLng(position);
    } catch (e) {
      setState(() {
        _selectedLocation = 'Failed to get location: ${e.toString()}';
        _isLocationLoading = false;
        _locationPermissionDenied = true;
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
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country} ${place.postalCode}"
                .replaceAll("null", "")
                .replaceAll(RegExp(r"\s+"), " ")
                .replaceAll(RegExp(r",\s*,"), ",")
                .trim();

        setState(() {
          _currentAddress = address;
          _selectedLocation = address.isNotEmpty ? address : "Current Location";
          _isLocationLoading = false;
          _useCurrentLocation = true;
        });

        await _fetchPosts();
      }
    } catch (e) {
      setState(() {
        _selectedLocation =
            "Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})";
        _isLocationLoading = false;
      });
      debugPrint("🔴 Error getting address: $e");
    }
  }

  Future<void> _updateLocationFromSearch(String newLocation) async {
    setState(() {
      _selectedLocation = newLocation;
      _useCurrentLocation = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location set to: $newLocation'),
        duration: const Duration(seconds: 2),
      ),
    );

    await _fetchPosts();
  }

  Future<void> _refreshLocation() async {
    await _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Handle back button press
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FF),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  _buildLocationRow(),
                  _buildSearchBar(),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: _refreshPosts,
                            child: _filteredPosts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No posts found',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Try changing your filters or search terms',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _clearAllFilters,
                                          child: const Text(
                                            'Clear All Filters',
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    itemCount: _filteredPosts.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Near You',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (_selectedTradeType != null ||
                                                  _selectedPostType != null ||
                                                  _selectedCategory != null)
                                                Chip(
                                                  label: const Text(
                                                    'Filters Active',
                                                  ),
                                                  backgroundColor:
                                                      Colors.blue[50],
                                                  deleteIcon: const Icon(
                                                    Icons.close,
                                                    size: 16,
                                                  ),
                                                  onDeleted: _clearAllFilters,
                                                ),
                                            ],
                                          ),
                                        );
                                      }
                                      return _buildProductCard(
                                        _filteredPosts[index - 1],
                                      );
                                    },
                                  ),
                          ),
                  ),
                ],
              ),

              // Push Notification Permission Dialog
              if (_showPushNotificationDialog) _buildPushNotificationDialog(),

              // Location Loading Indicator
              if (_isLocationLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    // Show confirmation dialog
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Don't exit
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Exit
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false; // If dialog is dismissed, return false
  }

  Future<void> _fetchMyProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isLoggedIn = await TokenService().isLoggedIn();
      if (!isLoggedIn) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login to view your posts';
        });
        if (mounted) {
          SnackbarUtils.showLoginDialog(context);
        }
        return;
      }

      final response = await _MyProfileService.getMyProfile();
      setState(() {
        profileData = response.data;
        ProfileSessionManager.instance.setProfile(profileData);
      });

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      if (_errorMessage!.contains('Session expired') ||
          _errorMessage!.contains('Unauthorized') ||
          _errorMessage!.contains('No authentication token')) {
        if (mounted) {
          SnackbarUtils.showLoginDialog(context);
        }
      } else {
        SnackbarUtils.showError(context, _errorMessage!);
      }
    }
  }

  void _checkFirstTimeUser() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showPushNotificationDialog = true;
        });
      }
    });
  }

  Future<void> _fetchPosts({bool loadMore = false}) async {
    try {
      // Check if user is logged in
      final isLoggedIn = await TokenService().isLoggedIn();
      if (!isLoggedIn) {
        setState(() {
          _isLoading = false;
        });
        return; // Don't fetch posts if not logged in
      }

      if (!loadMore) {
        setState(() {
          _isLoading = true;
          _currentPage = 1;
          _hasMore = true;
        });
      } else {
        if (!_hasMore) return;
        setState(() {
          _currentPage++;
        });
      }

      // Prepare query parameters
      String? status;
      if (_selectedTradeType == 'Barter') {
        status = 'FOR_BARTER';
      } else if (_selectedTradeType == 'Sales') {
        status = 'FOR_SALE';
      }

      // Add location parameters if we have current position
      double? latitude;
      double? longitude;

      if (_useCurrentLocation && _currentPosition != null) {
        latitude = _currentPosition!.latitude;
        longitude = _currentPosition!.longitude;
      }

      // Fetch posts from API with location
      final response = await _apiService.getPosts(
        page: _currentPage,
        limit: _limit,
        category: _selectedCategory,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: status,
        latitude: latitude,
        longitude: longitude,
        radius: _selectedRadius,
      );

      // Convert API posts to ExtendedPost
      final List<ExtendedPost> extendedPosts = (response.posts).map((post) {
        return ExtendedPost(
          post: post,
          isFavorite: _favoriteIds.containsKey(post.id),
          favoriteId: _favoriteIds[post.id],
          isHidden: false,
          wishListCategory: '',
        );
      }).toList();

      if (loadMore) {
        setState(() {
          _posts.addAll(extendedPosts);
          _applyFilters();
          _hasMore = extendedPosts.length >= _limit;
        });
      } else {
        setState(() {
          _posts = extendedPosts;
          _applyFilters();
          _hasMore = extendedPosts.length >= _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('🔴 HomeScreen: Error fetching posts: $e');
    }
  }

  Future<void> _refreshPosts() async {
    await _fetchPosts();
    await _loadUserFavorites();
    await _loadHiddenPosts();
  }

  void _handlePushNotificationPermission(bool granted) {
    setState(() {
      _pushNotificationGranted = granted;
      _showPushNotificationDialog = false;
    });

    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications enabled! You will now receive alerts for all activities.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPosts = _posts.where((extendedPost) {
        // Filter by trade type
        if (_selectedTradeType != null) {
          if (_selectedTradeType == 'Barter' && !extendedPost.isForBarter) {
            return false;
          }
          if (_selectedTradeType == 'Sales' && !extendedPost.isForSale) {
            return false;
          }
        }

        // Filter by post type (map API status to post types)
        if (_selectedPostType != null) {
          if (_selectedPostType == 'Looking for a product/service' &&
              extendedPost.post.status != PostStatus.LOOKING_FOR_SERVICE) {
            return false;
          }
          if (_selectedPostType == 'Barter/selling a product/service' &&
              !extendedPost.isForBarter &&
              !extendedPost.isForSale) {
            return false;
          }
        }

        // Filter by category
        if (_selectedCategory != null &&
            extendedPost.category.name != _selectedCategory) {
          return false;
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!extendedPost.title.toLowerCase().contains(query) &&
              !extendedPost.description.toLowerCase().contains(query) &&
              !extendedPost.category.name.toLowerCase().contains(query)) {
            return false;
          }
        }

        // Filter out hidden posts
        if (extendedPost.isHidden) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedTradeType = null;
      _selectedPostType = null;
      _selectedCategory = null;
      _selectedWishListCategory = null;
      _selectedRadius = 10.0;
      _searchQuery = '';
      _searchController.clear();
      _filteredPosts = List.from(_posts);
    });
  }

  Future<void> _toggleFavorite(ExtendedPost extendedPost) async {
    try {
      setState(() {
        // Optimistic update
        final index = _posts.indexWhere(
          (p) => p.post.id == extendedPost.post.id,
        );
        if (index != -1) {
          _posts[index].isFavorite = !_posts[index].isFavorite;
          _filteredPosts = List.from(_posts);
        }
      });

      if (extendedPost.isFavorite) {
        // Add to favorites
        final response = await _postActionService.addToFavorites(
          extendedPost.id,
        );

        setState(() {
          final index = _posts.indexWhere(
            (p) => p.post.id == extendedPost.post.id,
          );
          if (index != -1) {
            _posts[index].favoriteId = response.data.favorite.id;
            _favoriteIds[extendedPost.id] = response.data.favorite.id;
          }
        });

        if (mounted) {
          SnackbarUtils.showSuccess(context, response.message);
        }
      } else {
        // Remove from favorites
        if (extendedPost.favoriteId != null) {
          final response = await _postActionService.removeFromFavorites(
            extendedPost.favoriteId!,
          );

          setState(() {
            final index = _posts.indexWhere(
              (p) => p.post.id == extendedPost.post.id,
            );
            if (index != -1) {
              _posts[index].favoriteId = null;
              _favoriteIds.remove(extendedPost.id);
            }
          });

          if (mounted) {
            SnackbarUtils.showSuccess(context, response.message);
          }
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        final index = _posts.indexWhere(
          (p) => p.post.id == extendedPost.post.id,
        );
        if (index != -1) {
          _posts[index].isFavorite = !_posts[index].isFavorite;
          _filteredPosts = List.from(_posts);
        }
      });

      if (mounted) {
        SnackbarUtils.showError(context, e.toString());
      }
    }
  }

  Future<void> _hidePost(ExtendedPost extendedPost) async {
    try {
      final response = await _postActionService.hidePost(extendedPost.id);

      setState(() {
        final index = _posts.indexWhere(
          (p) => p.post.id == extendedPost.post.id,
        );
        if (index != -1) {
          _posts[index].isHidden = true;
          _filteredPosts.removeWhere((p) => p.post.id == extendedPost.post.id);
        }
      });

      if (mounted) {
        SnackbarUtils.showSuccess(context, response.message);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, e.toString());
      }
    }
  }

  Future<void> _reportPost(
    ExtendedPost extendedPost,
    String reason, [
    String? description,
  ]) async {
    try {
      final response = await _postActionService.reportPost(
        productId: extendedPost.id,
        reason: reason,
        description: description,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Report Submitted'),
            content: Text(
              'You have reported "${extendedPost.title}" for: $reason\n\nOur team will review this post within 24 hours.\n\nReport ID: ${response.data.report.id}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, e.toString());
      }
    }
  }

  void _showLocationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.my_location, color: Colors.blue),
              title: const Text('Use My Current Location'),
              subtitle: const Text(
                'Browse posts based on your current location',
              ),
              onTap: () async {
                Navigator.pop(context);
                await _refreshLocation();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.green),
              title: const Text('Refresh Location'),
              subtitle: const Text('Update your current location'),
              onTap: () async {
                Navigator.pop(context);
                await _refreshLocation();
              },
            ),
            const Divider(),
            if (_locationPermissionDenied)
              Column(
                children: [
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.grey),
                    title: const Text('Open Location Settings'),
                    subtitle: const Text('Enable location permissions'),
                    onTap: () {
                      Navigator.pop(context);
                      Geolocator.openAppSettings();
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(ExtendedPost extendedPost) {
    String selectedReason = 'Spam';
    TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select reason for reporting this post:'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedReason,
              items: const [
                DropdownMenuItem(value: 'Spam', child: Text('Spam')),
                DropdownMenuItem(
                  value: 'Inappropriate',
                  child: Text('Inappropriate Content'),
                ),
                DropdownMenuItem(
                  value: 'Wrong Category',
                  child: Text('Wrong Category'),
                ),
                DropdownMenuItem(value: 'Fake', child: Text('Fake Post')),
                DropdownMenuItem(
                  value: 'Duplicate',
                  child: Text('Duplicate Post'),
                ),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                selectedReason = value ?? 'Spam';
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reportController,
              decoration: const InputDecoration(
                hintText: 'Additional details (optional)...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _reportPost(
                extendedPost,
                selectedReason,
                reportController.text.isNotEmpty ? reportController.text : null,
              );
              Navigator.pop(context);
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(ExtendedPost extendedPost) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                extendedPost.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: extendedPost.isFavorite ? Colors.red : Colors.grey,
              ),
              title: Text(
                extendedPost.isFavorite
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
              ),
              onTap: () {
                _toggleFavorite(extendedPost);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.grey),
              title: const Text('Hide Post'),
              onTap: () {
                _hidePost(extendedPost);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(extendedPost);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    if (query.isEmpty) {
      setState(() {
        _filteredPosts = List.from(_posts);
      });
      return;
    }
    _applyFilters();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Navigate to Hamburger Menu
  void _navigateToHamburgerMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HamburgerMenuScreen()),
    );
  }

  // Navigate to Trade Chat Screen
  void _navigateToTradeChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TradeChatScreen()),
    );
  }

  // Navigate to Trade Booth Screen
  void _navigateToTradeBooth() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TradeBoothScreen()),
    );
  }

  // Navigate to Notifications Screen
  void _showNotificationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          notifications: const [],
          onNotificationTap: (p1) {},
        ),
      ),
    ).then((_) {
      // Refresh unread count when returning from notifications screen
      _loadUnreadNotificationCount();
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => FilterScreen(
        selectedTradeType: _selectedTradeType,
        selectedPostType: _selectedPostType,
        selectedCategory: _selectedCategory,
        selectedWishListCategory: _selectedWishListCategory,
        selectedRadius: _selectedRadius,
        onApply: (tradeType, postType, category, wishListCategory, radius) {
          setState(() {
            _selectedTradeType = tradeType;
            _selectedPostType = postType;
            _selectedCategory = category;
            _selectedWishListCategory = wishListCategory;
            _selectedRadius = radius;
          });
          _applyFilters();
          Navigator.pop(context);
        },
        onClear: () {
          _clearAllFilters();
          // Navigator.pop(context);
        },
      ),
    );
  }

  // Helper methods
  String _getBarterStatus(ExtendedPost extendedPost) {
    if (extendedPost.isForBarter) {
      return 'Open for barter';
    } else if (extendedPost.isForSale) {
      return 'For sale';
    }
    return 'No Barter';
  }

  // String _getDistance(ExtendedPost extendedPost) {
  //   // You would implement actual distance calculation here
  //   return '1.7 Km';
  // }

  String _getReturnType(ExtendedPost extendedPost) {
    if (extendedPost.isForBarter) {
      return extendedPost.wishListCategory.isNotEmpty
          ? extendedPost.wishListCategory
          : 'Open for barter';
    } else if (extendedPost.isForSale) {
      return extendedPost.formattedPrice;
    }
    return extendedPost.formattedPrice;
  }

  Widget _buildPushNotificationDialog() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Enable Push Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Receive alerts for all platform activities including messages, trades, and updates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handlePushNotificationPermission(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Not Now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handlePushNotificationPermission(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Allow',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _navigateToHamburgerMenu,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: profileData != null
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: profileData?.profileImage != null
                          ? NetworkImage(profileData!.profileImage!)
                          : null,
                      child: profileData?.profileImage == null
                          ? Text(
                              profileData?.firstName?.isNotEmpty == true
                                  ? profileData!.firstName![0]
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    )
                  : Container(),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${profileData?.firstName ?? ''} ${profileData?.lastName ?? ''}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Welcome to Yempover',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Notification Icon with Badge using Provider
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_outlined,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    onPressed: _showNotificationScreen,
                  ),
                  if (provider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
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
                        child: Text(
                          provider.unreadCount > 99
                              ? '99+'
                              : '${provider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(width: 8),
          GestureDetector(
            onTap: _navigateToHamburgerMenu,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu, size: 24, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: _showLocationOptions,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isLocationLoading
                      ? 'Updating location...'
                      : _selectedLocation,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (_isLocationLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search products, services, categories...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.grey),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ExtendedPost extendedPost) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PostDetailScreen(post: extendedPost.post, userItems: []),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Image carousel
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: extendedPost.processedImages.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: Image.network(
                              extendedPost.processedImages[index],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.photo,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      // Image indicator
                      if (extendedPost.processedImages.length > 1)
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '1/${extendedPost.processedImages.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Post Type Badge
                if (extendedPost.postTypeText.contains('Looking for'))
                  Positioned(
                    top: 15,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: Text(
                        extendedPost.postTypeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // 3Dot Menu Button
                Positioned(
                  top: 15,
                  right: 15,
                  child: InkWell(
                    onTap: () => _showPostOptions(extendedPost),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
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
                      child: const Icon(Icons.more_horiz, color: Colors.grey),
                    ),
                  ),
                ),

                // User info overlay - FIXED: Now using dynamic profile image
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // FIXED: Dynamic user image similar to PostDetailScreen
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              extendedPost.postedBy.profileImage != null
                              ? NetworkImage(
                                  extendedPost.postedBy.profileImage!,
                                )
                              : null,
                          child: extendedPost.postedBy.profileImage == null
                              ? Text(
                                  extendedPost.postedBy.firstName.isNotEmpty
                                      ? extendedPost.postedBy.firstName[0]
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                extendedPost.postedBy.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatDate(extendedPost.postedDate),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (extendedPost.isFavorite)
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(extendedPost.postedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Post details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          extendedPost.category.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EAF6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sync_alt,
                              size: 14,
                              color: Color(0xFF3F51B5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getBarterStatus(extendedPost),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF3F51B5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Text(
                  //       extendedPost.title,
                  //       style: const TextStyle(
                  //         fontWeight: FontWeight.bold,
                  //         fontSize: 16,
                  //       ),
                  //     ),
                  //     if (_useCurrentLocation && _currentPosition != null)
                  //       // Text(
                  //       //   _getDistance(extendedPost),
                  //       //   style: const TextStyle(
                  //       //     color: Colors.grey,
                  //       //     fontSize: 12,
                  //       //   ),
                  //       // ),
                  //   ],
                  // ),
                  const SizedBox(height: 6),
                  Text(
                    'In Return: ${_getReturnType(extendedPost)}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (extendedPost.wishList != null &&
                      extendedPost.wishList!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Wish List: ${extendedPost.wishList!.map((w) => w.title).join(', ')}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
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

  Widget _buildBottomNav() {
    return Container(
      height: 85,
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_filled, 'Marketplace', true),
              const SizedBox(width: 60),
              // Chat navigation item with badge
              Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  // Count unread messages - you'd need to implement this
                  // For now, we'll use the same unread count or 0
                  return _navItem(
                    Icons.chat_bubble_outline,
                    'Chat',
                    false,
                    badge: provider.unreadCount > 0 ? provider.unreadCount : 0,
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
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E5BFF),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Trade booth',
                    style: TextStyle(
                      fontSize: 11,
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
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive, {int badge = 0}) {
    return GestureDetector(
      onTap: label == 'Chat' ? _navigateToTradeChat : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : Colors.grey.shade400,
                size: 28,
              ),
              if (badge > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E5BFF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
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
              color: isActive ? Colors.black : Colors.grey.shade400,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

extension on ExtendedPost {
  get wishList => null;
}

class FilterScreen extends StatefulWidget {
  final String? selectedTradeType;
  final String? selectedPostType;
  final String? selectedCategory;
  final String? selectedWishListCategory;
  final double selectedRadius;
  final Function(String?, String?, String?, String?, double) onApply;
  final VoidCallback onClear;

  const FilterScreen({
    Key? key,
    required this.selectedTradeType,
    required this.selectedPostType,
    required this.selectedCategory,
    required this.selectedWishListCategory,
    required this.selectedRadius,
    required this.onApply,
    required this.onClear,
  }) : super(key: key);

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  bool _isLoading = true;
  late String? _selectedTradeType;
  late String? _selectedPostType;
  late String? _selectedCategory;
  late String? _selectedWishListCategory;
  late double _selectedRadius;

  final List<String> _tradeTypes = ['Barter', 'Sales'];
  final List<String> _postTypes = [
    'Looking for a product/service',
    'Barter/selling a product/service',
  ];
  final List<String> _categories = ['Furniture', 'Plumbing', 'Electronics'];
  final List<String> _wishListCategories = ['', '', '', ''];

  @override
  void initState() {
    super.initState();
    _selectedTradeType = widget.selectedTradeType;
    _selectedPostType = widget.selectedPostType;
    _selectedCategory = widget.selectedCategory;
    _selectedWishListCategory = widget.selectedWishListCategory;
    _selectedRadius = widget.selectedRadius;
    debugPrint("2222filter ");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                // Trade Type Filter
                _buildFilterSection(
                  title: 'Trade Type',
                  options: _tradeTypes,
                  selectedValue: _selectedTradeType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTradeType = value;
                      if (value != 'Barter') {
                        _selectedWishListCategory = null;
                      }
                    });
                  },
                ),

                // Post Type Filter
                _buildFilterSection(
                  title: 'Post Type',
                  options: _postTypes,
                  selectedValue: _selectedPostType,
                  onChanged: (value) {
                    setState(() {
                      _selectedPostType = value;
                    });
                  },
                ),

                // Category Filter
                _buildFilterSection(
                  title: 'Category',
                  options: _categories,
                  selectedValue: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),

                // Wish List Filter (only shown when Barter is selected)
                if (_selectedTradeType == 'Barter')
                  _buildFilterSection(
                    title: 'Wish List Category',
                    options: _wishListCategories,
                    selectedValue: _selectedWishListCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedWishListCategory = value;
                      });
                    },
                  ),

                // Location Radius Filter
                _buildRadiusFilter(),
              ],
            ),
          ),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      _selectedTradeType,
                      _selectedPostType,
                      _selectedCategory,
                      _selectedWishListCategory,
                      _selectedRadius,
                    );
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(selected ? option : null);
              },
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue,
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRadiusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text('Within ${_selectedRadius.toStringAsFixed(0)} km'),
        Slider(
          value: _selectedRadius,
          min: 1,
          max: 50,
          divisions: 49,
          onChanged: (value) {
            setState(() {
              _selectedRadius = value;
            });
          },
          label: '${_selectedRadius.toStringAsFixed(0)} km',
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
