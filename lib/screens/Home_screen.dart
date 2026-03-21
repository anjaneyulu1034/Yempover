// import 'dart:math';
// import 'package:Yempover_app/utils/notification_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_places_flutter/google_places_flutter.dart';
// import 'package:google_places_flutter/model/prediction.dart';
// import 'package:provider/provider.dart';
// import 'package:Yempover_app/models/ProductPostmain.dart';
// import 'package:Yempover_app/models/get_my_profile_response.dart';
// import 'package:Yempover_app/services/api_service.dart';
// import 'package:Yempover_app/screens/PostDetailScreen.dart';
// import 'package:Yempover_app/screens/tradechatscreen/TradeChatScreen.dart';
// import 'package:Yempover_app/screens/TradeBoothScreen.dart';
// import 'package:Yempover_app/screens/HamburgerMenuScreen.dart';
// import 'package:Yempover_app/screens/MyProfileScreen.dart';
// import 'package:Yempover_app/screens/NotificationsScreen.dart';
// import 'package:Yempover_app/services/my_profile_service.dart';
// import 'package:Yempover_app/services/profile_session_manager.dart';
// import 'package:Yempover_app/services/category_service.dart';
// import 'package:Yempover_app/services/token_service.dart';
// import 'package:Yempover_app/utils/error_message_utils.dart';
// import 'package:Yempover_app/utils/snackbar_utils.dart';
// import '../services/post_action_service.dart';

// // Extended Post class with the required properties
// class ExtendedPost {
//   final Post post;
//   bool isFavorite;
//   bool isHidden;
//   String wishListCategory;
//   String? favoriteId;
//   double? distance;

//   ExtendedPost({
//     required this.post,
//     this.isFavorite = false,
//     this.isHidden = false,
//     this.wishListCategory = '',
//     this.favoriteId,
//     this.distance,
//   });

//   bool get isForBarter => post.barterStatus == BarterStatus.OPEN_FOR_BARTER;
//   bool get isForSale => post.status == PostStatus.FOR_SALE;

//   String get title => post.title;
//   String get description => post.description;
//   dynamic get category => post.category;
//   DateTime get postedDate => post.postedDate;
//   String get location => post.location;
//   String get formattedPrice => post.formattedPrice;
//   List<String> get processedImages => post.processedImages;
//   dynamic get postedBy => post.postedBy;
//   int get viewCount => post.viewCount;
//   String get id => post.id;
//   double? get latitude => post.latitude;
//   double? get longitude => post.longitude;

//   String get postTypeText {
//     switch (post.status) {
//       case PostStatus.LOOKING_FOR_SERVICE:
//         return 'Looking for a service';
//       case PostStatus.FOR_BARTER:
//         return 'Bartering a product';
//       case PostStatus.FOR_SALE:
//         return 'Selling a product';
//       case PostStatus.PROVIDE_SERVICE:
//         return 'Providing a service';
//       default:
//         return 'Post';
//     }
//   }

//   String get formattedDistance {
//     if (distance == null) return '';
//     if (distance! < 1) {
//       return '${(distance! * 1000).toStringAsFixed(0)}m away';
//     }
//     return '${distance!.toStringAsFixed(1)}km away';
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   // ignore: library_private_types_in_public_api
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   static const String _googleApiKey = 'AIzaSyAT3wIjV73qVXPAlgkyifnns38GztnbNF4';

//   final ApiService _apiService = ApiService();
//   final MyProfileService _myProfileService = MyProfileService();
//   final PostActionService _postActionService = PostActionService();
//   final CategoryService _categoryService = CategoryService();
//   final TokenService _tokenService = TokenService();
//   final TextEditingController _searchController = TextEditingController();

//   final ScrollController _scrollController = ScrollController();
//   final Map<String, Location?> _postLocationCache = {};

//   // Data states
//   List<ExtendedPost> _posts = [];
//   ProfileData? profileData;
//   List<ExtendedPost> _filteredPosts = [];
//   bool _isGuestUser = false;

//   // Loading states - separate for different sections
//   bool _isLoadingPosts = true;
//   bool _isLoadingProfile = true;
//   bool _isLoadingMore = false;
//   bool _hasMore = true;
//   int _currentPage = 1;
//   final int _limit = 20;

//   // Location states
//   Position? _currentPosition;
//   String _selectedLocation = 'Fetching location...';
//   bool _isLocationLoading = false;
//   bool _locationPermissionDenied = false;
//   double? _manualLatitude;
//   double? _manualLongitude;

//   // Filter states
//   String? _selectedTradeType;
//   String? _selectedPostType;
//   String? _selectedCategory;
//   String? _selectedWishListCategory;
//   String _selectedSortBy = 'Nearest';
//   bool _isRadiusFilterEnabled = true;
//   double _selectedRadius = 10.0;
//   String _searchQuery = '';
//   bool _isLoadingFilterCategories = false;
//   List<Map<String, String>> _filterMainCategories = [];
//   Map<String, List<Map<String, String>>> _filterSubCategories = {};

//   @override
//   void initState() {
//     super.initState();

//     _scrollController.addListener(_onScroll);

//     // Load data in parallel for better performance
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeData();
//     });
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _initializeData() async {
//     try {
//       // Check if user is logged in
//       final isLoggedIn = await _tokenService.isLoggedIn();
//       _isGuestUser = await _tokenService.isGuestUser();

//       if (!isLoggedIn && !_isGuestUser) {
//         if (mounted) {
//           SnackbarUtils.showLoginDialog(context);
//         }
//         setState(() {
//           _isLoadingPosts = false;
//           _isLoadingProfile = false;
//         });
//         return;
//       }

//       if (_isGuestUser) {
//         setState(() {
//           profileData = ProfileData(
//             firstName: 'Guest',
//             lastName: 'User',
//             homeAddress: 'Guest Mode',
//             totalTradesCompleted: 0,
//           );
//           _isLoadingProfile = false;
//         });
//         ProfileSessionManager.instance.clearSession();
//       }

//       // Run all initial data fetching in parallel with error handling
//       await Future.wait([
//         if (!_isGuestUser)
//           _fetchMyProfile().catchError((e) {
//             debugPrint('🔴 Profile fetch error: $e');
//             if (ErrorMessageUtils.isSessionExpired(e)) {
//               _handleSessionExpired();
//             }
//             return null;
//           }),
//         _getCurrentLocation().catchError((e) {
//           debugPrint('🔴 Location error: $e');
//         }),
//         _fetchPosts().catchError((e) {
//           debugPrint('🔴 Posts fetch error: $e');
//           if (ErrorMessageUtils.isSessionExpired(e)) {
//             _handleSessionExpired();
//           }
//         }),
//         if (!_isGuestUser)
//           _loadUnreadNotificationCount().catchError((e) {
//             debugPrint('🔴 Notification error: $e');
//           }),
//         _loadFilterCategories().catchError((e) {
//           debugPrint('🔴 Filter category error: $e');
//         }),
//       ]);
//     } catch (e) {
//       debugPrint('🔴 Initialization error: $e');
//       setState(() {
//         _isLoadingPosts = false;
//         _isLoadingProfile = false;
//       });
//     }
//   }

//   void _handleSessionExpired() {
//     if (mounted) {
//       // Show session expired dialog
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => AlertDialog(
//           title: const Text('Session Expired'),
//           content: const Text('Your session has expired. Please login again.'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 // Navigate to login screen
//                 Navigator.pushReplacementNamed(context, '/login');
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   double _calculateDistance(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     const double earthRadius = 6371;
//     double dLat = _degreesToRadians(lat2 - lat1);
//     double dLon = _degreesToRadians(lon2 - lon1);
//     double a =
//         sin(dLat / 2) * sin(dLat / 2) +
//         cos(_degreesToRadians(lat1)) *
//             cos(_degreesToRadians(lat2)) *
//             sin(dLon / 2) *
//             sin(dLon / 2);
//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return earthRadius * c;
//   }

//   double _degreesToRadians(double degrees) {
//     return degrees * pi / 180;
//   }

//   double? get _activeLatitude => _manualLatitude ?? _currentPosition?.latitude;
//   double? get _activeLongitude =>
//       _manualLongitude ?? _currentPosition?.longitude;

//   void _updatePostDistances() {
//     final refLat = _activeLatitude;
//     final refLng = _activeLongitude;
//     if (refLat == null || refLng == null || _posts.isEmpty) return;

//     for (var post in _posts) {
//       if (post.latitude != null && post.longitude != null) {
//         post.distance = _calculateDistance(
//           refLat,
//           refLng,
//           post.latitude!,
//           post.longitude!,
//         );
//       }
//     }
//     _sortPostsByDistance();
//     _applyFilters();
//   }

//   Future<void> _updatePostDistancesFromGeocoding() async {
//     final refLat = _activeLatitude;
//     final refLng = _activeLongitude;
//     if (refLat == null || refLng == null || _posts.isEmpty) return;

//     bool hasUpdates = false;

//     for (final post in _posts) {
//       if (post.distance != null) continue;
//       if ((post.latitude != null && post.longitude != null) ||
//           post.location.trim().isEmpty) {
//         continue;
//       }

//       final normalizedLocation = post.location.trim().toLowerCase();

//       Location? geocodedLocation;
//       if (_postLocationCache.containsKey(normalizedLocation)) {
//         geocodedLocation = _postLocationCache[normalizedLocation];
//       } else {
//         try {
//           final locations = await locationFromAddress(post.location.trim());
//           geocodedLocation = locations.isNotEmpty ? locations.first : null;
//           _postLocationCache[normalizedLocation] = geocodedLocation;
//         } catch (_) {
//           _postLocationCache[normalizedLocation] = null;
//           continue;
//         }
//       }

//       if (geocodedLocation != null) {
//         post.distance = _calculateDistance(
//           refLat,
//           refLng,
//           geocodedLocation.latitude,
//           geocodedLocation.longitude,
//         );
//         hasUpdates = true;
//       }
//     }

//     if (!mounted || !hasUpdates) return;

//     _sortPostsByDistance();
//     _applyFilters();
//   }

//   void _sortPostsByDistance() {
//     _posts.sort((a, b) {
//       if (a.distance == null && b.distance == null) return 0;
//       if (a.distance == null) return 1;
//       if (b.distance == null) return -1;
//       return a.distance!.compareTo(b.distance!);
//     });
//   }

//   void _onScroll() {
//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent - 200) {
//       if (!_isLoadingMore && _hasMore && !_isLoadingPosts) {
//         _fetchPosts(loadMore: true);
//       }
//     }
//   }

//   Future<void> _loadUnreadNotificationCount() async {
//     try {
//       final provider = Provider.of<NotificationProvider>(
//         context,
//         listen: false,
//       );
//       await provider.loadUnreadCount();
//     } catch (e) {
//       debugPrint('🔴 Error loading unread count: $e');
//     }
//   }

//   Future<void> _getCurrentLocation() async {
//     setState(() {
//       _isLocationLoading = true;
//       _locationPermissionDenied = false;
//     });

//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() {
//           _selectedLocation = 'Location services are disabled.';
//           _isLocationLoading = false;
//           _locationPermissionDenied = true;
//         });
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           setState(() {
//             _selectedLocation = 'Location permissions are denied.';
//             _isLocationLoading = false;
//             _locationPermissionDenied = true;
//           });
//           return;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         setState(() {
//           _selectedLocation = 'Location permissions are permanently denied.';
//           _isLocationLoading = false;
//           _locationPermissionDenied = true;
//         });
//         return;
//       }

//       Position position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//         ),
//       );

//       setState(() {
//         _currentPosition = position;
//         _manualLatitude = null;
//         _manualLongitude = null;
//       });

//       _updatePostDistances();
//       _updatePostDistancesFromGeocoding();

//       await _getAddressFromLatLng(position);
//     } catch (e) {
//       setState(() {
//         _selectedLocation = 'Failed to get location';
//         _isLocationLoading = false;
//       });
//       debugPrint('🔴 Error getting location: $e');
//     }
//   }

//   Future<void> _getAddressFromLatLng(Position position) async {
//     try {
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );

//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks[0];
//         String address =
//             [
//                   place.street,
//                   place.locality,
//                   place.administrativeArea,
//                   place.country,
//                 ]
//                 .where((element) => element != null && element.isNotEmpty)
//                 .join(', ')
//                 .replaceAll(RegExp(r',\s*,'), ',');

//         setState(() {
//           _selectedLocation = address.isNotEmpty ? address : "Current Location";
//           _isLocationLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _selectedLocation = "Current Location";
//         _isLocationLoading = false;
//       });
//       debugPrint("🔴 Error getting address: $e");
//     }
//   }

//   Future<void> _fetchMyProfile() async {
//     try {
//       if (_isGuestUser) {
//         setState(() => _isLoadingProfile = false);
//         return;
//       }

//       final isLoggedIn = await _tokenService.isLoggedIn();
//       if (!isLoggedIn) {
//         setState(() => _isLoadingProfile = false);
//         return;
//       }

//       final response = await _myProfileService.getMyProfile();
//       setState(() {
//         profileData = response.data;
//         ProfileSessionManager.instance.setProfile(profileData);
//         _isLoadingProfile = false;
//       });
//     } catch (e) {
//       setState(() => _isLoadingProfile = false);
//       debugPrint('🔴 Error fetching profile: $e');

//       if (ErrorMessageUtils.isSessionExpired(e)) {
//         _handleSessionExpired();
//       } else if (mounted) {
//         SnackbarUtils.showError(
//           context,
//           e,
//           fallback: 'Unable to load profile right now. Please try again.',
//         );
//       }
//     }
//   }

//   Future<void> _fetchPosts({bool loadMore = false}) async {
//     try {
//       final isLoggedIn = await _tokenService.isLoggedIn();
//       final canBrowse = isLoggedIn || _isGuestUser;
//       if (!canBrowse) {
//         setState(() {
//           _isLoadingPosts = false;
//           _isLoadingMore = false;
//         });
//         return;
//       }

//       if (!loadMore) {
//         setState(() {
//           _isLoadingPosts = true;
//           _currentPage = 1;
//           _hasMore = true;
//         });
//       } else {
//         setState(() => _isLoadingMore = true);
//       }

//       final int requestPage = loadMore ? _currentPage + 1 : 1;

//       String? status;
//       if (_selectedTradeType == 'Barter') {
//         status = 'FOR_BARTER';
//       } else if (_selectedTradeType == 'Sales') {
//         status = 'FOR_SALE';
//       }

//       String? backendPostType;
//       if (_selectedPostType == 'Looking for a product/service') {
//         backendPostType = 'looking_for';
//       }

//       double? latitude;
//       double? longitude;
//       if (_activeLatitude != null && _activeLongitude != null) {
//         latitude = _activeLatitude;
//         longitude = _activeLongitude;
//       }

//       final response = await _apiService.getPosts(
//         page: requestPage,
//         limit: _limit,
//         categoryId: _selectedWishListCategory ?? _selectedCategory,
//         search: _searchQuery.isNotEmpty ? _searchQuery : null,
//         status: status,
//         postType: backendPostType,
//         latitude: latitude,
//         longitude: longitude,
//         radius: _selectedRadius,
//       );

//       final List<ExtendedPost> extendedPosts = response.posts.map((post) {
//         double? distance;
//         if (_activeLatitude != null &&
//             _activeLongitude != null &&
//             post.latitude != null &&
//             post.longitude != null) {
//           distance = _calculateDistance(
//             _activeLatitude!,
//             _activeLongitude!,
//             post.latitude!,
//             post.longitude!,
//           );
//         } else if (post.distance != null) {
//           distance = post.distance;
//         }

//         return ExtendedPost(post: post, isFavorite: false, distance: distance);
//       }).toList();

//       extendedPosts.sort((a, b) {
//         if (a.distance == null && b.distance == null) return 0;
//         if (a.distance == null) return 1;
//         if (b.distance == null) return -1;
//         return a.distance!.compareTo(b.distance!);
//       });

//       if (loadMore) {
//         final existingIds = _posts.map((post) => post.id).toSet();
//         final uniquePosts = extendedPosts
//             .where((post) => !existingIds.contains(post.id))
//             .toList();

//         setState(() {
//           _posts.addAll(uniquePosts);
//           _currentPage = requestPage;
//           _applyFilters();
//           _hasMore = response.pagination.page < response.pagination.pages;
//           _isLoadingMore = false;
//         });
//         _updatePostDistancesFromGeocoding();
//       } else {
//         setState(() {
//           _posts = extendedPosts;
//           _currentPage = requestPage;
//           _applyFilters();
//           _hasMore = response.pagination.page < response.pagination.pages;
//           _isLoadingPosts = false;
//           _isLoadingMore = false;
//         });
//         _updatePostDistancesFromGeocoding();
//       }
//     } catch (e) {
//       setState(() {
//         _isLoadingPosts = false;
//         _isLoadingMore = false;
//       });
//       debugPrint('🔴 Error fetching posts: $e');

//       if (ErrorMessageUtils.isSessionExpired(e)) {
//         _handleSessionExpired();
//       } else if (mounted) {
//         SnackbarUtils.showError(
//           context,
//           e,
//           fallback: 'Unable to load posts right now. Please try again.',
//         );
//       }
//     }
//   }

//   Future<void> _refreshPosts() async {
//     await _fetchPosts();
//   }

//   Future<void> _loadFilterCategories() async {
//     if (_isLoadingFilterCategories) return;

//     setState(() {
//       _isLoadingFilterCategories = true;
//     });

//     try {
//       final Map<String, Map<String, String>> mainCategoriesById = {};
//       final Map<String, List<Map<String, String>>> subCategoriesByMain = {};

//       for (final type in ['product', 'service']) {
//         final response = await _categoryService.getCategories(type: type);

//         for (final parent in response.data) {
//           mainCategoriesById[parent.id] = {
//             'id': parent.id,
//             'name': parent.name,
//           };

//           final subCategories = parent.children
//               .map((child) => {'id': child.id, 'name': child.name})
//               .toList();

//           if (subCategoriesByMain.containsKey(parent.id)) {
//             final existing = subCategoriesByMain[parent.id]!;
//             for (final sub in subCategories) {
//               if (!existing.any((e) => e['id'] == sub['id'])) {
//                 existing.add(sub);
//               }
//             }
//           } else {
//             subCategoriesByMain[parent.id] = subCategories;
//           }
//         }
//       }

//       final mainList = mainCategoriesById.values.toList()
//         ..sort(
//           (a, b) => (a['name'] ?? '').toLowerCase().compareTo(
//             (b['name'] ?? '').toLowerCase(),
//           ),
//         );

//       for (final entry in subCategoriesByMain.entries) {
//         entry.value.sort(
//           (a, b) => (a['name'] ?? '').toLowerCase().compareTo(
//             (b['name'] ?? '').toLowerCase(),
//           ),
//         );
//       }

//       if (!mounted) return;
//       setState(() {
//         _filterMainCategories = mainList;
//         _filterSubCategories = subCategoriesByMain;
//         _isLoadingFilterCategories = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _isLoadingFilterCategories = false;
//       });
//     }
//   }

//   void _applyFilters() {
//     setState(() {
//       _filteredPosts = _posts.where((post) {
//         if (_selectedTradeType != null) {
//           if (_selectedTradeType == 'Barter' && !post.isForBarter) return false;
//           if (_selectedTradeType == 'Sales' && !post.isForSale) return false;
//         }

//         if (_selectedPostType != null) {
//           if (_selectedPostType == 'Looking for a product/service' &&
//               post.post.status != PostStatus.LOOKING_FOR_SERVICE) {
//             return false;
//           }
//           if (_selectedPostType == 'Barter/selling a product/service' &&
//               post.post.status != PostStatus.PROVIDE_SERVICE &&
//               !post.isForBarter &&
//               !post.isForSale) {
//             return false;
//           }
//         }

//         if (_selectedCategory != null) {
//           final postCategory = post.category;
//           final belongsToMain =
//               postCategory.id == _selectedCategory ||
//               postCategory.parentId == _selectedCategory;

//           if (!belongsToMain) return false;
//         }

//         if (_selectedWishListCategory != null &&
//             post.category.id != _selectedWishListCategory) {
//           return false;
//         }

//         if (_searchQuery.isNotEmpty) {
//           final query = _searchQuery.toLowerCase();
//           if (!post.title.toLowerCase().contains(query) &&
//               !post.description.toLowerCase().contains(query) &&
//               !post.category.name.toLowerCase().contains(query)) {
//             return false;
//           }
//         }

//         if (_isRadiusFilterEnabled &&
//             _activeLatitude != null &&
//             _activeLongitude != null &&
//             post.distance != null &&
//             post.distance! > _selectedRadius) {
//           return false;
//         }

//         return true;
//       }).toList();

//       _sortFilteredPosts();
//     });
//   }

//   void _sortFilteredPosts() {
//     int compareDistance(ExtendedPost a, ExtendedPost b) {
//       if (a.distance == null && b.distance == null) return 0;
//       if (a.distance == null) return 1;
//       if (b.distance == null) return -1;
//       return a.distance!.compareTo(b.distance!);
//     }

//     _filteredPosts.sort((a, b) {
//       switch (_selectedSortBy) {
//         case 'Newest':
//           return b.postedDate.compareTo(a.postedDate);
//         case 'Oldest':
//           return a.postedDate.compareTo(b.postedDate);
//         case 'Price: Low to High':
//           return a.post.price.compareTo(b.post.price);
//         case 'Price: High to Low':
//           return b.post.price.compareTo(a.post.price);
//         case 'Nearest':
//         default:
//           return compareDistance(a, b);
//       }
//     });
//   }

//   Future<void> _clearAllFilters() async {
//     if (!mounted) return;

//     setState(() {
//       _selectedTradeType = null;
//       _selectedPostType = null;
//       _selectedCategory = null;
//       _selectedWishListCategory = null;
//       _selectedSortBy = 'Nearest';
//       _isRadiusFilterEnabled = false;
//       _selectedRadius = 10.0;
//       _searchQuery = '';
//       _searchController.clear();
//     });

//     // Always reload from API after clearing because previous filters may have
//     // limited server-side results and left _posts empty.
//     await _fetchPosts();
//   }

//   void _showLocationOptions() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.my_location, color: Colors.blue),
//               title: const Text('Use My Current Location'),
//               onTap: () async {
//                 Navigator.pop(context);
//                 await _getCurrentLocation();
//               },
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(
//                 Icons.edit_location_alt,
//                 color: Colors.orange,
//               ),
//               title: const Text('Enter Location Manually'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showManualLocationInput();
//               },
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.refresh, color: Colors.green),
//               title: const Text('Refresh Location'),
//               onTap: () async {
//                 Navigator.pop(context);
//                 await _getCurrentLocation();
//               },
//             ),
//             if (_locationPermissionDenied) ...[
//               const Divider(),
//               ListTile(
//                 leading: const Icon(Icons.settings, color: Colors.grey),
//                 title: const Text('Open Location Settings'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   Geolocator.openAppSettings();
//                 },
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _showManualLocationInput() async {
//     final controller = TextEditingController(
//       text: _selectedLocation == 'Fetching location...'
//           ? ''
//           : _selectedLocation,
//     );
//     double? selectedLat;
//     double? selectedLng;

//     final result = await showModalBottomSheet<Map<String, dynamic>>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (sheetContext) {
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
//           ),
//           child: Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//             ),
//             padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
//             child: SafeArea(
//               top: false,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 44,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade300,
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 14),
//                   Row(
//                     children: const [
//                       Icon(Icons.edit_location_alt, color: Colors.blue),
//                       SizedBox(width: 8),
//                       Text(
//                         'Enter Location',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Search and pick your city or area',
//                     style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
//                   ),
//                   const SizedBox(height: 12),
//                   Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.grey.shade300),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withValues(alpha: 0.04),
//                           blurRadius: 10,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: GooglePlaceAutoCompleteTextField(
//                       textEditingController: controller,
//                       googleAPIKey: _googleApiKey,
//                       debounceTime: 400,
//                       isLatLngRequired: true,
//                       countries: const ['in', 'us', 'ca', 'gb', 'au'],
//                       inputDecoration: InputDecoration(
//                         hintText: 'Type location (min 4 characters)',
//                         border: InputBorder.none,
//                         prefixIcon: Icon(
//                           Icons.search,
//                           color: Colors.grey.shade600,
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 14,
//                           vertical: 14,
//                         ),
//                       ),
//                       getPlaceDetailWithLatLng: (Prediction prediction) {
//                         selectedLat = double.tryParse(prediction.lat ?? '');
//                         selectedLng = double.tryParse(prediction.lng ?? '');
//                       },
//                       itemClick: (Prediction prediction) {
//                         controller.text = prediction.description ?? '';
//                         controller.selection = TextSelection.fromPosition(
//                           TextPosition(offset: controller.text.length),
//                         );
//                       },
//                       seperatedBuilder: const Divider(height: 1),
//                       containerHorizontalPadding: 0,
//                     ),
//                   ),
//                   const SizedBox(height: 14),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: () => Navigator.of(sheetContext).pop(),
//                           style: OutlinedButton.styleFrom(
//                             minimumSize: const Size.fromHeight(46),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           child: const Text('Cancel'),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () {
//                             Navigator.of(sheetContext).pop({
//                               'address': controller.text,
//                               'lat': selectedLat,
//                               'lng': selectedLng,
//                             });
//                           },
//                           style: ElevatedButton.styleFrom(
//                             minimumSize: const Size.fromHeight(46),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           child: const Text('Apply'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );

//     final manualAddress = result?['address']?.toString().trim() ?? '';
//     selectedLat = result?['lat'] as double?;
//     selectedLng = result?['lng'] as double?;
//     if (manualAddress.isEmpty) return;

//     setState(() {
//       _isLocationLoading = true;
//       _locationPermissionDenied = false;
//     });

//     try {
//       double? resolvedLat = selectedLat;
//       double? resolvedLng = selectedLng;

//       if (resolvedLat == null || resolvedLng == null) {
//         final locations = await locationFromAddress(manualAddress);
//         if (locations.isEmpty) {
//           throw Exception('Location not found');
//         }
//         resolvedLat = locations.first.latitude;
//         resolvedLng = locations.first.longitude;
//       }

//       if (!mounted) return;

//       setState(() {
//         _manualLatitude = resolvedLat;
//         _manualLongitude = resolvedLng;
//         _selectedLocation = manualAddress;
//         _isLocationLoading = false;
//       });

//       await _fetchPosts();
//       _updatePostDistances();
//       _updatePostDistancesFromGeocoding();
//     } catch (_) {
//       if (!mounted) return;
//       setState(() {
//         _isLocationLoading = false;
//       });
//       SnackbarUtils.showError(
//         context,
//         'Could not resolve that location. Try a clearer address.',
//       );
//     }
//   }

//   Future<void> _showFilterDialog() async {
//     if (_filterMainCategories.isEmpty && !_isLoadingFilterCategories) {
//       await _loadFilterCategories();
//     }

//     if (!mounted) return;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//       ),
//       builder: (context) => FilterScreen(
//         selectedTradeType: _selectedTradeType,
//         selectedPostType: _selectedPostType,
//         selectedCategory: _selectedCategory,
//         selectedWishListCategory: _selectedWishListCategory,
//         selectedSortBy: _selectedSortBy,
//         isRadiusFilterEnabled: _isRadiusFilterEnabled,
//         selectedRadius: _selectedRadius,
//         mainCategories: _filterMainCategories,
//         subCategoriesByMain: _filterSubCategories,
//         isLoadingCategories: _isLoadingFilterCategories,
//         onRetryLoadCategories: _loadFilterCategories,
//         onApply:
//             (
//               tradeType,
//               postType,
//               category,
//               wishListCategory,
//               sortBy,
//               isRadiusFilterEnabled,
//               radius,
//             ) {
//               setState(() {
//                 _selectedTradeType = tradeType;
//                 _selectedPostType = postType;
//                 _selectedCategory = category;
//                 _selectedWishListCategory = wishListCategory;
//                 _selectedSortBy = sortBy;
//                 _isRadiusFilterEnabled = isRadiusFilterEnabled;
//                 _selectedRadius = radius;
//               });
//               _fetchPosts();
//               Navigator.pop(context);
//             },
//         onClear: () {
//           _clearAllFilters();
//         },
//       ),
//     );
//   }

//   Future<void> _hidePost(ExtendedPost post) async {
//     try {
//       final isLoggedIn = await _tokenService.isLoggedIn();
//       if (_isGuestUser || !isLoggedIn) {
//         _showPleaseLoginMessage();
//         return;
//       }

//       await _postActionService.hidePost(post.id);

//       if (!mounted) return;
//       setState(() {
//         _posts.removeWhere((element) => element.id == post.id);
//         _filteredPosts.removeWhere((element) => element.id == post.id);
//       });

//       SnackbarUtils.showSuccess(context, 'Post hidden successfully');
//     } catch (e) {
//       if (!mounted) return;
//       SnackbarUtils.showError(
//         context,
//         e,
//         fallback: 'Unable to hide this post right now. Please try again.',
//       );
//     }
//   }

//   Future<void> _confirmHidePost(ExtendedPost post) async {
//     final isLoggedIn = await _tokenService.isLoggedIn();
//     if (!mounted) return;
//     if (_isGuestUser || !isLoggedIn) {
//       _showPleaseLoginMessage();
//       return;
//     }

//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Hide Post'),
//         content: const Text('Do you want to hide this post from your feed?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Hide'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       await _hidePost(post);
//     }
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inMinutes < 60) {
//       return '${difference.inMinutes}m ago';
//     } else if (difference.inHours < 24) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inDays < 7) {
//       return '${difference.inDays}d ago';
//     } else {
//       return '${(difference.inDays / 7).floor()}w ago';
//     }
//   }

//   String _getBarterStatus(ExtendedPost post) {
//     if (post.isForBarter) return 'Open for barter';
//     if (post.isForSale) return 'For sale';
//     return '';
//   }

//   String _getReturnType(ExtendedPost post) {
//     if (post.isForBarter) {
//       return post.wishListCategory.isNotEmpty
//           ? post.wishListCategory
//           : 'Open for barter';
//     }
//     return post.formattedPrice;
//   }

//   void _showPleaseLoginMessage() {
//     if (!mounted) return;
//     SnackbarUtils.showInfo(context, 'Please login to continue');
//   }

//   void _navigateToHamburgerMenu() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const HamburgerMenuScreen()),
//     );
//   }

//   void _navigateToMyProfile() async {
//     final isLoggedIn = await _tokenService.isLoggedIn();
//     if (!mounted) return;
//     if (_isGuestUser || !isLoggedIn) {
//       _showPleaseLoginMessage();
//       return;
//     }

//     await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const MyProfileScreen()),
//     );

//     if (mounted) {
//       _fetchMyProfile();
//     }
//   }

//   void _navigateToTradeChat() async {
//     final isLoggedIn = await _tokenService.isLoggedIn();
//     if (!mounted) return;
//     if (_isGuestUser || !isLoggedIn) {
//       _showPleaseLoginMessage();
//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const TradeChatScreen()),
//     );
//   }

//   void _navigateToTradeBooth() async {
//     final isLoggedIn = await _tokenService.isLoggedIn();
//     if (!mounted) return;
//     if (_isGuestUser || !isLoggedIn) {
//       _showPleaseLoginMessage();
//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const TradeBoothScreen()),
//     );
//   }

//   void _showNotificationScreen() async {
//     final isLoggedIn = await _tokenService.isLoggedIn();
//     if (!mounted) return;
//     if (_isGuestUser || !isLoggedIn) {
//       _showPleaseLoginMessage();
//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => NotificationsScreen(
//           notifications: const [],
//           onNotificationTap: (p1) {},
//         ),
//       ),
//     ).then((_) => _loadUnreadNotificationCount());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, result) async {
//         if (didPop) return;
//         final shouldExit =
//             await showDialog<bool>(
//               context: context,
//               builder: (context) => AlertDialog(
//                 title: const Text('Exit App'),
//                 content: const Text('Are you sure you want to exit?'),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.of(context).pop(false),
//                     child: const Text('No'),
//                   ),
//                   TextButton(
//                     onPressed: () => Navigator.of(context).pop(true),
//                     child: const Text('Yes'),
//                   ),
//                 ],
//               ),
//             ) ??
//             false;

//         if (shouldExit) {
//           SystemNavigator.pop();
//         }
//       },
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF7F8FF),
//         body: SafeArea(
//           child: Column(
//             children: [
//               _buildHeader(),
//               _buildLocationRow(),
//               _buildSearchBar(),
//               Expanded(
//                 child: _isLoadingPosts
//                     ? _buildShimmerLoading()
//                     : _filteredPosts.isEmpty
//                     ? _buildEmptyState()
//                     : RefreshIndicator(
//                         onRefresh: _refreshPosts,
//                         child: ListView.builder(
//                           controller: _scrollController,
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           itemCount: _filteredPosts.length + 1,
//                           itemBuilder: (context, index) {
//                             if (index == _filteredPosts.length) {
//                               return _buildLoadingMoreIndicator();
//                             }
//                             return _buildProductCard(_filteredPosts[index]);
//                           },
//                         ),
//                       ),
//               ),
//             ],
//           ),
//         ),
//         bottomNavigationBar: _buildBottomNav(),
//       ),
//     );
//   }

//   Widget _buildShimmerLoading() {
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       itemCount: 3,
//       itemBuilder: (context, index) {
//         return Container(
//           margin: const EdgeInsets.only(bottom: 20),
//           height: 350,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//           ),
//           child: const Center(child: CircularProgressIndicator()),
//         );
//       },
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
//           const SizedBox(height: 16),
//           Text(
//             'No posts found',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Try adjusting your filters',
//             style: TextStyle(color: Colors.grey.shade500),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _clearAllFilters,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text('Clear Filters'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingMoreIndicator() {
//     if (!_isLoadingMore && !_hasMore) {
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 20),
//         child: Center(
//           child: Text(
//             'No more posts',
//             style: TextStyle(color: Colors.grey.shade600),
//           ),
//         ),
//       );
//     }
//     if (_isLoadingMore) {
//       return const Padding(
//         padding: EdgeInsets.symmetric(vertical: 20),
//         child: Center(child: CircularProgressIndicator()),
//       );
//     }
//     return const SizedBox.shrink();
//   }

//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Row(
//         children: [
//           GestureDetector(
//             onTap: _navigateToMyProfile,
//             child: Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.blue, width: 2),
//               ),
//               child: _isLoadingProfile
//                   ? const Center(
//                       child: SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                     )
//                   : CircleAvatar(
//                       radius: 20,
//                       backgroundImage: profileData?.profileImage != null
//                           ? NetworkImage(profileData!.profileImage!)
//                           : null,
//                       child: profileData?.profileImage == null
//                           ? Text(
//                               profileData?.firstName?.isNotEmpty == true
//                                   ? profileData!.firstName![0].toUpperCase()
//                                   : 'U',
//                               style: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.blue,
//                               ),
//                             )
//                           : null,
//                     ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _isLoadingProfile
//                       ? 'Loading...'
//                       : "${profileData?.firstName ?? ''} ${profileData?.lastName ?? ''}"
//                             .trim(),
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//                 const Text(
//                   'Welcome to Yempover',
//                   style: TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           Consumer<NotificationProvider>(
//             builder: (context, provider, child) {
//               return Stack(
//                 children: [
//                   IconButton(
//                     icon: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.shade50,
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.notifications_none_outlined,
//                         color: Colors.blue,
//                         size: 24,
//                       ),
//                     ),
//                     onPressed: _showNotificationScreen,
//                   ),
//                   if (provider.unreadCount > 0)
//                     Positioned(
//                       right: 8,
//                       top: 8,
//                       child: Container(
//                         padding: const EdgeInsets.all(2),
//                         decoration: const BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                         constraints: const BoxConstraints(
//                           minWidth: 18,
//                           minHeight: 18,
//                         ),
//                         child: Center(
//                           child: Text(
//                             provider.unreadCount > 9
//                                 ? '9+'
//                                 : '${provider.unreadCount}',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               );
//             },
//           ),
//           const SizedBox(width: 8),
//           GestureDetector(
//             onTap: _navigateToHamburgerMenu,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(Icons.menu, size: 24, color: Colors.grey),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLocationRow() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: InkWell(
//         onTap: _showLocationOptions,
//         borderRadius: BorderRadius.circular(10),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.location_on_outlined,
//                 size: 18,
//                 color: Colors.blue.shade700,
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   _isLocationLoading ? 'Updating...' : _selectedLocation,
//                   style: const TextStyle(fontSize: 14, color: Colors.black87),
//                   overflow: TextOverflow.ellipsis,
//                   maxLines: 1,
//                 ),
//               ),
//               if (_isLocationLoading)
//                 const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//               else
//                 Icon(
//                   Icons.keyboard_arrow_down,
//                   size: 20,
//                   color: Colors.grey.shade600,
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.05),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 controller: _searchController,
//                 onChanged: (value) {
//                   setState(() => _searchQuery = value);
//                   _applyFilters();
//                 },
//                 decoration: InputDecoration(
//                   hintText: 'Search products, services...',
//                   hintStyle: const TextStyle(color: Colors.grey),
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 14,
//                   ),
//                   prefixIcon: const Icon(Icons.search, color: Colors.grey),
//                   suffixIcon: _searchController.text.isNotEmpty
//                       ? IconButton(
//                           icon: const Icon(Icons.close, color: Colors.grey),
//                           onPressed: () {
//                             _searchController.clear();
//                             setState(() => _searchQuery = '');
//                             _applyFilters();
//                           },
//                         )
//                       : null,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(15),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: IconButton(
//               icon: Icon(
//                 Icons.tune,
//                 color:
//                     _selectedTradeType != null ||
//                         _selectedPostType != null ||
//                         _selectedCategory != null
//                     ? Colors.blue
//                     : Colors.grey,
//               ),
//               onPressed: _showFilterDialog,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProductCard(ExtendedPost post) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) =>
//                 PostDetailScreen(post: post.post, userItems: const []),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(24),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.04),
//               blurRadius: 15,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(24),
//                   ),
//                   child:
//                       post.processedImages.isNotEmpty &&
//                           post.processedImages.first.trim().isNotEmpty
//                       ? Image.network(
//                           post.processedImages.first,
//                           height: 200,
//                           width: double.infinity,
//                           fit: BoxFit.cover,
//                           loadingBuilder: (context, child, loadingProgress) {
//                             if (loadingProgress == null) return child;
//                             return Container(
//                               height: 200,
//                               color: Colors.grey.shade200,
//                               child: const Center(
//                                 child: CircularProgressIndicator(),
//                               ),
//                             );
//                           },
//                           errorBuilder: (context, error, stackTrace) {
//                             return Container(
//                               height: 200,
//                               color: Colors.grey.shade200,
//                               child: const Icon(
//                                 Icons.image_not_supported,
//                                 size: 48,
//                                 color: Colors.grey,
//                               ),
//                             );
//                           },
//                         )
//                       : Container(
//                           height: 200,
//                           width: double.infinity,
//                           color: Colors.grey.shade200,
//                           child: const Icon(
//                             Icons.image_not_supported,
//                             size: 48,
//                             color: Colors.grey,
//                           ),
//                         ),
//                 ),
//                 if (post.postTypeText.contains('Looking for'))
//                   Positioned(
//                     top: 15,
//                     left: 0,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFD32F2F),
//                         borderRadius: const BorderRadius.only(
//                           topRight: Radius.circular(12),
//                           bottomRight: Radius.circular(12),
//                         ),
//                       ),
//                       child: Text(
//                         'Looking for',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.black.withValues(alpha: 0.45),
//                       shape: BoxShape.circle,
//                     ),
//                     child: IconButton(
//                       icon: const Icon(
//                         Icons.visibility_off_outlined,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                       tooltip: 'Hide Post',
//                       onPressed: () => _confirmHidePost(post),
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   bottom: 12,
//                   left: 12,
//                   right: 12,
//                   child: Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withValues(alpha: 0.5),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       children: [
//                         CircleAvatar(
//                           radius: 18,
//                           backgroundColor: Colors.grey.shade200,
//                           backgroundImage: post.postedBy.profileImage != null
//                               ? NetworkImage(post.postedBy.profileImage!)
//                               : null,
//                           child: post.postedBy.profileImage == null
//                               ? Text(
//                                   post.postedBy.firstName.isNotEmpty
//                                       ? post.postedBy.firstName[0].toUpperCase()
//                                       : 'U',
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.blue,
//                                   ),
//                                 )
//                               : null,
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 post.postedBy.fullName,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               Row(
//                                 children: [
//                                   Text(
//                                     _formatDate(post.postedDate),
//                                     style: const TextStyle(
//                                       color: Colors.white70,
//                                       fontSize: 11,
//                                     ),
//                                   ),
//                                   if (post.distance != null) ...[
//                                     const Padding(
//                                       padding: EdgeInsets.symmetric(
//                                         horizontal: 4,
//                                       ),
//                                       child: Text(
//                                         '•',
//                                         style: TextStyle(color: Colors.white70),
//                                       ),
//                                     ),
//                                     Text(
//                                       post.formattedDistance,
//                                       style: const TextStyle(
//                                         color: Colors.white70,
//                                         fontSize: 11,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ],
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.shade50,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           post.category.name,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.blue.shade800,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       if (_getBarterStatus(post).isNotEmpty)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFE8EAF6),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 Icons.sync_alt,
//                                 size: 14,
//                                 color: const Color(0xFF3F51B5),
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 _getBarterStatus(post),
//                                 style: const TextStyle(
//                                   fontSize: 11,
//                                   color: Color(0xFF3F51B5),
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       if (post.post.canClubItems)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFE0F2F1),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: const Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 Icons.all_inclusive,
//                                 size: 14,
//                                 color: Color(0xFF00695C),
//                               ),
//                               SizedBox(width: 4),
//                               Text(
//                                 'Can be clubbed',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Color(0xFF00695C),
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     post.title,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'In Return: ${_getReturnType(post)}',
//                     style: const TextStyle(
//                       color: Colors.black87,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   if (post.distance != null) ...[
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.location_on_outlined,
//                           size: 16,
//                           color: Colors.grey.shade700,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           post.formattedDistance,
//                           style: TextStyle(
//                             color: Colors.grey.shade700,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomNav() {
//     final bottomInset = MediaQuery.of(context).viewPadding.bottom;

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 10,
//           ),
//         ],
//       ),
//       child: SizedBox(
//         height: 70 + bottomInset,
//         child: Padding(
//           padding: EdgeInsets.only(bottom: bottomInset),
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _navItem(Icons.home_filled, 'Marketplace', true),
//                   const SizedBox(width: 40),
//                   Consumer<NotificationProvider>(
//                     builder: (context, provider, child) {
//                       return _navItem(
//                         Icons.chat_bubble_outline,
//                         'Chat',
//                         false,
//                         badge: provider.unreadCount,
//                       );
//                     },
//                   ),
//                 ],
//               ),
//               Positioned(
//                 top: -1,
//                 child: GestureDetector(
//                   onTap: _navigateToTradeBooth,
//                   child: Column(
//                     children: [
//                       Container(
//                         height: 50,
//                         width: 50,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF2E5BFF),
//                           borderRadius: BorderRadius.circular(18),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.blue.withValues(alpha: 0.4),
//                               blurRadius: 10,
//                               offset: const Offset(0, 6),
//                             ),
//                           ],
//                         ),
//                         child: const Icon(
//                           Icons.swap_horiz,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       const Text(
//                         'Trade',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.grey,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _navItem(IconData icon, String label, bool isActive, {int badge = 0}) {
//     return GestureDetector(
//       onTap: label == 'Chat' ? _navigateToTradeChat : null,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Stack(
//             children: [
//               Icon(
//                 icon,
//                 color: isActive ? Colors.blue : Colors.grey.shade400,
//                 size: 28,
//               ),
//               if (badge > 0)
//                 Positioned(
//                   right: -4,
//                   top: -4,
//                   child: Container(
//                     padding: const EdgeInsets.all(2),
//                     decoration: const BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                     constraints: const BoxConstraints(
//                       minWidth: 16,
//                       minHeight: 16,
//                     ),
//                     child: Center(
//                       child: Text(
//                         badge > 9 ? '9+' : '$badge',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 9,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 2),
//           Text(
//             label,
//             style: TextStyle(
//               color: isActive ? Colors.blue : Colors.grey.shade400,
//               fontSize: 11,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class FilterScreen extends StatefulWidget {
//   final String? selectedTradeType;
//   final String? selectedPostType;
//   final String? selectedCategory;
//   final String? selectedWishListCategory;
//   final String selectedSortBy;
//   final bool isRadiusFilterEnabled;
//   final double selectedRadius;
//   final List<Map<String, String>> mainCategories;
//   final Map<String, List<Map<String, String>>> subCategoriesByMain;
//   final bool isLoadingCategories;
//   final Future<void> Function() onRetryLoadCategories;
//   final Function(String?, String?, String?, String?, String, bool, double)
//   onApply;
//   final VoidCallback onClear;

//   const FilterScreen({
//     super.key,
//     required this.selectedTradeType,
//     required this.selectedPostType,
//     required this.selectedCategory,
//     required this.selectedWishListCategory,
//     required this.selectedSortBy,
//     required this.isRadiusFilterEnabled,
//     required this.selectedRadius,
//     required this.mainCategories,
//     required this.subCategoriesByMain,
//     required this.isLoadingCategories,
//     required this.onRetryLoadCategories,
//     required this.onApply,
//     required this.onClear,
//   });

//   @override
//   State<FilterScreen> createState() => _FilterScreenState();
// }

// class _FilterScreenState extends State<FilterScreen> {
//   late String? _selectedTradeType;
//   late String? _selectedPostType;
//   late String? _selectedCategory;
//   late String? _selectedWishListCategory;
//   late String _selectedSortBy;
//   late bool _isRadiusFilterEnabled;
//   late double _selectedRadius;

//   final List<String> _sortOptions = [
//     'Nearest',
//     'Newest',
//     'Oldest',
//     'Price: Low to High',
//     'Price: High to Low',
//   ];
//   final List<String> _tradeTypes = ['Barter', 'Sales'];
//   final List<String> _postTypes = [
//     'Looking for a product/service',
//     'Barter/selling a product/service',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _selectedTradeType = widget.selectedTradeType;
//     _selectedPostType = widget.selectedPostType;
//     _selectedCategory = widget.selectedCategory;
//     _selectedWishListCategory = widget.selectedWishListCategory;
//     _selectedSortBy = widget.selectedSortBy;
//     _isRadiusFilterEnabled = widget.isRadiusFilterEnabled;
//     _selectedRadius = widget.selectedRadius;
//   }

//   void _clearFilters() {
//     setState(() {
//       _selectedTradeType = null;
//       _selectedPostType = null;
//       _selectedCategory = null;
//       _selectedWishListCategory = null;
//       _selectedSortBy = 'Nearest';
//       _isRadiusFilterEnabled = false;
//       _selectedRadius = 10.0;
//     });
//     widget.onClear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
//         height: MediaQuery.of(context).size.height * 0.7,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Filters',
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: ListView(
//                 padding: EdgeInsets.only(
//                   bottom: 110 + MediaQuery.of(context).viewPadding.bottom,
//                 ),
//                 children: [
//                   _buildFilterSection(
//                     title: 'Sort By',
//                     options: _sortOptions,
//                     selectedValue: _selectedSortBy,
//                     onChanged: (value) {
//                       if (value == null) return;
//                       setState(() => _selectedSortBy = value);
//                     },
//                   ),
//                   _buildFilterSection(
//                     title: 'Trade Type',
//                     options: _tradeTypes,
//                     selectedValue: _selectedTradeType,
//                     onChanged: (value) {
//                       setState(() => _selectedTradeType = value);
//                     },
//                   ),
//                   _buildFilterSection(
//                     title: 'Post Type',
//                     options: _postTypes,
//                     selectedValue: _selectedPostType,
//                     onChanged: (value) {
//                       setState(() => _selectedPostType = value);
//                     },
//                   ),
//                   _buildFilterSection(
//                     title: 'Category',
//                     options: widget.mainCategories
//                         .map((category) => category['name'] ?? '')
//                         .where((name) => name.isNotEmpty)
//                         .toList(),
//                     selectedValue: _selectedCategory,
//                     onChanged: (value) {
//                       final selected = widget.mainCategories.firstWhere(
//                         (category) => category['name'] == value,
//                         orElse: () => {},
//                       );
//                       setState(() {
//                         _selectedCategory = selected['id'];
//                         _selectedWishListCategory = null;
//                       });
//                     },
//                     optionLabelBuilder: (value) => value,
//                     optionSelectedByValue: (value) {
//                       final selected = widget.mainCategories.firstWhere(
//                         (category) => category['id'] == _selectedCategory,
//                         orElse: () => {},
//                       );
//                       return selected['name'] == value;
//                     },
//                   ),
//                   if (widget.isLoadingCategories)
//                     const Padding(
//                       padding: EdgeInsets.only(bottom: 20),
//                       child: Center(child: CircularProgressIndicator()),
//                     ),
//                   if (!widget.isLoadingCategories &&
//                       widget.mainCategories.isEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 20),
//                       child: Row(
//                         children: [
//                           const Expanded(
//                             child: Text(
//                               'Unable to load categories',
//                               style: TextStyle(color: Colors.grey),
//                             ),
//                           ),
//                           TextButton(
//                             onPressed: widget.onRetryLoadCategories,
//                             child: const Text('Retry'),
//                           ),
//                         ],
//                       ),
//                     ),
//                   if (_selectedCategory != null)
//                     _buildFilterSection(
//                       title: 'Subcategory',
//                       options:
//                           (widget.subCategoriesByMain[_selectedCategory] ??
//                                   const <Map<String, String>>[])
//                               .map((subCategory) => subCategory['name'] ?? '')
//                               .where((name) => name.isNotEmpty)
//                               .toList(),
//                       selectedValue: _selectedWishListCategory,
//                       onChanged: (value) {
//                         final selectedSub =
//                             (widget.subCategoriesByMain[_selectedCategory] ??
//                                     const <Map<String, String>>[])
//                                 .firstWhere(
//                                   (subCategory) => subCategory['name'] == value,
//                                   orElse: () => {},
//                                 );
//                         setState(() {
//                           _selectedWishListCategory = selectedSub['id'];
//                         });
//                       },
//                       optionLabelBuilder: (value) => value,
//                       optionSelectedByValue: (value) {
//                         final selectedSub =
//                             (widget.subCategoriesByMain[_selectedCategory] ??
//                                     const <Map<String, String>>[])
//                                 .firstWhere(
//                                   (subCategory) =>
//                                       subCategory['id'] ==
//                                       _selectedWishListCategory,
//                                   orElse: () => {},
//                                 );
//                         return selectedSub['name'] == value;
//                       },
//                     ),
//                   _buildRadiusFilter(),
//                 ],
//               ),
//             ),
//             SafeArea(
//               top: false,
//               child: Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: _clearFilters,
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text('Clear All'),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () {
//                           widget.onApply(
//                             _selectedTradeType,
//                             _selectedPostType,
//                             _selectedCategory,
//                             _selectedWishListCategory,
//                             _selectedSortBy,
//                             _isRadiusFilterEnabled,
//                             _selectedRadius,
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text('Apply'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFilterSection({
//     required String title,
//     required List<String> options,
//     required String? selectedValue,
//     required ValueChanged<String?> onChanged,
//     String Function(String value)? optionLabelBuilder,
//     bool Function(String value)? optionSelectedByValue,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 10),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: options.map((option) {
//             final isSelected =
//                 optionSelectedByValue?.call(option) ?? selectedValue == option;

//             return FilterChip(
//               label: Text(optionLabelBuilder?.call(option) ?? option),
//               selected: isSelected,
//               onSelected: (selected) {
//                 onChanged(selected ? option : null);
//               },
//               selectedColor: Colors.blue.shade100,
//               checkmarkColor: Colors.blue,
//             );
//           }).toList(),
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   Widget _buildRadiusFilter() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Distance Radius',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 10),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Expanded(
//               child: Text(
//                 'Enable distance radius filter',
//                 style: TextStyle(fontWeight: FontWeight.w500),
//               ),
//             ),
//             Switch(
//               value: _isRadiusFilterEnabled,
//               onChanged: (value) {
//                 setState(() => _isRadiusFilterEnabled = value);
//               },
//             ),
//           ],
//         ),
//         const SizedBox(height: 4),
//         if (!_isRadiusFilterEnabled)
//           Padding(
//             padding: const EdgeInsets.only(bottom: 12),
//             child: Text(
//               'Showing full list (all distances).',
//               style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//             ),
//           ),
//         if (_isRadiusFilterEnabled) ...[
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text('Within ${_selectedRadius.toStringAsFixed(0)} km'),
//               Text(
//                 '${_selectedRadius.toStringAsFixed(0)} km',
//                 style: const TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.blue,
//                 ),
//               ),
//             ],
//           ),
//           Slider(
//             value: _selectedRadius,
//             min: 1,
//             max: 50,
//             divisions: 49,
//             label: '${_selectedRadius.toStringAsFixed(0)} km',
//             onChanged: (value) {
//               setState(() => _selectedRadius = value);
//             },
//           ),
//         ],
//         const SizedBox(height: 20),
//       ],
//     );
//   }
// }

import 'dart:math';
import 'package:Yempover_app/utils/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:provider/provider.dart';
import 'package:Yempover_app/models/ProductPostmain.dart';
import 'package:Yempover_app/models/get_my_profile_response.dart';
import 'package:Yempover_app/services/api_service.dart';
import 'package:Yempover_app/screens/PostDetailScreen.dart';
import 'package:Yempover_app/screens/tradechatscreen/TradeChatScreen.dart';
import 'package:Yempover_app/screens/TradeBoothScreen.dart';
import 'package:Yempover_app/screens/HamburgerMenuScreen.dart';
import 'package:Yempover_app/screens/MyProfileScreen.dart';
import 'package:Yempover_app/screens/NotificationsScreen.dart';
import 'package:Yempover_app/services/my_profile_service.dart';
import 'package:Yempover_app/services/profile_session_manager.dart';
import 'package:Yempover_app/services/category_service.dart';
import 'package:Yempover_app/services/token_service.dart';
import 'package:Yempover_app/utils/error_message_utils.dart';
import 'package:Yempover_app/utils/snackbar_utils.dart';
import '../services/post_action_service.dart';

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

  bool get isForBarter => post.barterStatus == BarterStatus.OPEN_FOR_BARTER;
  bool get isForSale => post.status == PostStatus.FOR_SALE;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
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
        ProfileSessionManager.instance.clearSession();
      }

      await Future.wait([
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

      String? status;
      if (_selectedTradeType == 'Barter') {
        status = 'FOR_BARTER';
      } else if (_selectedTradeType == 'Sales') {
        status = 'FOR_SALE';
      }

      String? backendPostType;
      if (_selectedPostType == 'Looking for a product/service') {
        backendPostType = 'looking_for';
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
        status: status,
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
          _posts.addAll(uniquePosts);
          _currentPage = requestPage;
          _applyFilters();
          _hasMore = response.pagination.page < response.pagination.pages;
          _isLoadingMore = false;
        });
        _updatePostDistancesFromGeocoding();
      } else {
        setState(() {
          _posts = extendedPosts;
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
        if (_selectedTradeType != null) {
          if (_selectedTradeType == 'Barter' && !post.isForBarter) return false;
          if (_selectedTradeType == 'Sales' && !post.isForSale) return false;
        }

        if (_selectedPostType != null) {
          if (_selectedPostType == 'Looking for a product/service' &&
              post.post.status != PostStatus.LOOKING_FOR_SERVICE) {
            return false;
          }
          if (_selectedPostType == 'Barter/selling a product/service' &&
              post.post.status != PostStatus.PROVIDE_SERVICE &&
              !post.isForBarter &&
              !post.isForSale) {
            return false;
          }
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

    await _fetchPosts();
  }

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
            _buildLocationOption(
              icon: Icons.refresh,
              iconColor: Colors.green,
              title: 'Refresh Location',
              subtitle: 'Update your current location',
              onTap: () async {
                Navigator.pop(context);
                await _getCurrentLocation();
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
      backgroundColor: Colors.transparent,
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                      border: Border.all(color: Colors.grey.shade200),
                      color: Colors.grey.shade50,
                    ),
                    child: GooglePlaceAutoCompleteTextField(
                      textEditingController: controller,
                      googleAPIKey: _googleApiKey,
                      debounceTime: 400,
                      isLatLngRequired: true,
                      countries: const ['in', 'us', 'ca', 'gb', 'au'],
                      inputDecoration: InputDecoration(
                        hintText: 'Search for a location...',
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
                        controller.text = prediction.description ?? '';
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                      },
                      seperatedBuilder: const Divider(height: 1),
                      containerHorizontalPadding: 0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop({
                              'address': controller.text,
                              'lat': selectedLat,
                              'lng': selectedLng,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
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
      builder: (context) => AlertDialog(
        title: const Text('Hide Post'),
        content: const Text('Do you want to hide this post from your feed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hide'),
          ),
        ],
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

  void _showPleaseLoginMessage() {
    if (!mounted) return;
    SnackbarUtils.showInfo(context, 'Please login to continue');
  }

  void _navigateToHamburgerMenu() {
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit App'),
                content: const Text('Are you sure you want to exit?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes'),
                  ),
                ],
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
                        color: Colors.blue,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
    return Center(
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
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text('Clear Filters'),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _navigateToMyProfile,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                          color: Colors.blue,
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
                                color: Colors.blue,
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
                      ? 'Loading...'
                      : "${profileData?.firstName ?? ''} ${profileData?.lastName ?? ''}"
                            .trim(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Welcome to Yempover',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.notifications_none_outlined,
                        color: Colors.blue.shade700,
                        size: 26,
                      ),
                      onPressed: _showNotificationScreen,
                    ),
                  ),
                  if (provider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            provider.unreadCount > 9
                                ? '9+'
                                : '${provider.unreadCount}',
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
              );
            },
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _navigateToHamburgerMenu,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(Icons.menu, size: 24, color: Colors.grey.shade700),
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
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
      padding: const EdgeInsets.all(16),
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
          Container(
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
                    color:
                        _selectedTradeType != null ||
                            _selectedPostType != null ||
                            _selectedCategory != null
                        ? Colors.blue
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                      ? Image.network(
                          post.processedImages.first,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 220,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.blue,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
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
                            );
                          },
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
                // User info overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // On very tiny transient widths, skip rendering to avoid flex overflow.
                        if (constraints.maxWidth < 80) {
                          return const SizedBox.shrink();
                        }

                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage:
                                  post.postedBy.profileImage != null
                                  ? NetworkImage(post.postedBy.profileImage!)
                                  : null,
                              child: post.postedBy.profileImage == null
                                  ? Text(
                                      post.postedBy.firstName.isNotEmpty
                                          ? post.postedBy.firstName[0]
                                                .toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 18,
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
                                    post.postedBy.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _formatDate(post.postedDate),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      if (post.distance != null) ...[
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            '•',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            post.formattedDistance,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Return type
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
                      return _navItem(
                        Icons.chat_bubble_outline,
                        'Chat',
                        false,
                        badge: provider.unreadCount,
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
                        'Trade',
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

  Widget _navItem(IconData icon, String label, bool isActive, {int badge = 0}) {
    return GestureDetector(
      onTap: label == 'Chat' ? _navigateToTradeChat : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.blue : Colors.grey.shade400,
                size: 28,
              ),
              if (badge > 0)
                Positioned(
                  right: -4,
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

class _FilterScreenState extends State<FilterScreen> {
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
    'Price: Low to High',
    'Price: High to Low',
  ];
  final List<String> _tradeTypes = ['Barter', 'Sales'];
  final List<String> _postTypes = [
    'Looking for a product/service',
    'Barter/selling a product/service',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTradeType = widget.selectedTradeType;
    _selectedPostType = widget.selectedPostType;
    _selectedCategory = widget.selectedCategory;
    _selectedWishListCategory = widget.selectedWishListCategory;
    _selectedSortBy = widget.selectedSortBy;
    _isRadiusFilterEnabled = widget.isRadiusFilterEnabled;
    _selectedRadius = widget.selectedRadius;
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
    });
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.grey.shade700),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: 120 + MediaQuery.of(context).viewPadding.bottom,
                ),
                children: [
                  _buildFilterSection(
                    title: 'Sort By',
                    options: _sortOptions,
                    selectedValue: _selectedSortBy,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedSortBy = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    title: 'Trade Type',
                    options: _tradeTypes,
                    selectedValue: _selectedTradeType,
                    onChanged: (value) {
                      setState(() => _selectedTradeType = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    title: 'Post Type',
                    options: _postTypes,
                    selectedValue: _selectedPostType,
                    onChanged: (value) {
                      setState(() => _selectedPostType = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    title: 'Category',
                    options: widget.mainCategories
                        .map((category) => category['name'] ?? '')
                        .where((name) => name.isNotEmpty)
                        .toList(),
                    selectedValue: _selectedCategory,
                    onChanged: (value) {
                      final selected = widget.mainCategories.firstWhere(
                        (category) => category['name'] == value,
                        orElse: () => {},
                      );
                      setState(() {
                        _selectedCategory = selected['id'];
                        _selectedWishListCategory = null;
                      });
                    },
                    optionLabelBuilder: (value) => value,
                    optionSelectedByValue: (value) {
                      final selected = widget.mainCategories.firstWhere(
                        (category) => category['id'] == _selectedCategory,
                        orElse: () => {},
                      );
                      return selected['name'] == value;
                    },
                  ),
                  if (widget.isLoadingCategories)
                    const Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      ),
                    ),
                  if (!widget.isLoadingCategories &&
                      widget.mainCategories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Unable to load categories',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onRetryLoadCategories,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  if (_selectedCategory != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: _buildFilterSection(
                        title: 'Subcategory',
                        options:
                            (widget.subCategoriesByMain[_selectedCategory] ??
                                    const <Map<String, String>>[])
                                .map((subCategory) => subCategory['name'] ?? '')
                                .where((name) => name.isNotEmpty)
                                .toList(),
                        selectedValue: _selectedWishListCategory,
                        onChanged: (value) {
                          final selectedSub =
                              (widget.subCategoriesByMain[_selectedCategory] ??
                                      const <Map<String, String>>[])
                                  .firstWhere(
                                    (subCategory) =>
                                        subCategory['name'] == value,
                                    orElse: () => {},
                                  );
                          setState(() {
                            _selectedWishListCategory = selectedSub['id'];
                          });
                        },
                        optionLabelBuilder: (value) => value,
                        optionSelectedByValue: (value) {
                          final selectedSub =
                              (widget.subCategoriesByMain[_selectedCategory] ??
                                      const <Map<String, String>>[])
                                  .firstWhere(
                                    (subCategory) =>
                                        subCategory['id'] ==
                                        _selectedWishListCategory,
                                    orElse: () => {},
                                  );
                          return selectedSub['name'] == value;
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildRadiusFilter(),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearFilters,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Clear All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    String Function(String value)? optionLabelBuilder,
    bool Function(String value)? optionSelectedByValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected =
                optionSelectedByValue?.call(option) ?? selectedValue == option;

            return FilterChip(
              label: Text(
                optionLabelBuilder?.call(option) ?? option,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(selected ? option : null);
              },
              selectedColor: Colors.blue.shade50,
              checkmarkColor: Colors.blue,
              backgroundColor: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.grey.shade200,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRadiusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distance Radius',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Enable radius filter',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: _isRadiusFilterEnabled,
                    onChanged: (value) {
                      setState(() => _isRadiusFilterEnabled = value);
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              if (!_isRadiusFilterEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Showing all posts regardless of distance',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              if (_isRadiusFilterEnabled) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Within ${_selectedRadius.toStringAsFixed(0)} km',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_selectedRadius.toStringAsFixed(0)} km',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _selectedRadius,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '${_selectedRadius.toStringAsFixed(0)} km',
                  onChanged: (value) {
                    setState(() => _selectedRadius = value);
                  },
                  activeColor: Colors.blue,
                  inactiveColor: Colors.grey.shade300,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
