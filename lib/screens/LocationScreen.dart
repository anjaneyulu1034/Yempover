// lib/screens/LocationScreen.dart
import 'package:flutter/material.dart';
import 'package:yempover_app/screens/LoginScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

class LocationScreen extends StatefulWidget {
  final Function(String, double, double)? onLocationSelected;

  const LocationScreen({super.key, this.onLocationSelected});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Location variables
  String _currentAddress = '';
  double? _currentLatitude;
  double? _currentLongitude;
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  String? _locationError;

  // Search results
  List<Prediction> _searchPredictions = [];
  bool _isLoadingPredictions = false;

  // Google Places API Key
  static const String _googleApiKey = "AIzaSyAT3wIjV73qVXPAlgkyifnns38GztnbNF4";

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.length >= 3) {
      if (!_isSearching) {
        setState(() {
          _isSearching = true;
        });
      }
    } else {
      setState(() {
        _isSearching = false;
        _searchPredictions.clear();
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      await _getCurrentLocation();
    } catch (e) {
      setState(() {
        _locationError = 'Error checking location permission: $e';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      await _getAddressFromLatLng(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: $e';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        // localeIdentifier: 'en_US',
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        List<String> addressParts = [];

        if (place.street?.isNotEmpty ?? false) {
          addressParts.add(place.street!);
        }
        if (place.subLocality?.isNotEmpty ?? false) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality?.isNotEmpty ?? false) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea?.isNotEmpty ?? false) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country?.isNotEmpty ?? false) {
          addressParts.add(place.country!);
        }
        if (place.postalCode?.isNotEmpty ?? false) {
          addressParts.add(place.postalCode!);
        }

        setState(() {
          _currentAddress = addressParts.join(', ');
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress =
            '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  void _selectLocation(String address, double lat, double lng) {
    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(address, lat, lng);
      Navigator.pop(context, {
        'address': address,
        'latitude': lat,
        'longitude': lng,
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Please enable location services to use this feature.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Yempover needs access to your location to show nearby items and set your current location. '
            'Please grant location permission in settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentLocationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              if (_locationError != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF1A73E8)),
                  onPressed: _checkLocationPermission,
                  tooltip: 'Retry',
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_isLoadingLocation)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Getting your location...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else if (_locationError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _locationError!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _checkLocationPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                        ),
                        child: const Text('Try Again'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _showPermissionDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                        ),
                        child: const Text('Settings'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else if (_currentAddress.isNotEmpty)
            InkWell(
              onTap: () {
                if (_currentLatitude != null && _currentLongitude != null) {
                  _selectLocation(
                    _currentAddress,
                    _currentLatitude!,
                    _currentLongitude!,
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A73E8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Use Current Location',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A73E8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentAddress,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF1A73E8),
                    ),
                  ],
                ),
              ),
            )
          else
            const Center(
              child: Column(
                children: [
                  Text('Unable to get location'),
                  SizedBox(height: 8),
                  Text('Tap retry to try again'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search your location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // Google Places Autocomplete
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GooglePlaceAutoCompleteTextField(
            textEditingController: _searchController,
            googleAPIKey: _googleApiKey,
            inputDecoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter your location',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              prefixIcon: Icon(
                Icons.search_outlined,
                color: Colors.grey.shade500,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _isSearching = false;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            debounceTime: 400,
            countries: ["us", "in", "ca", "gb", "au"],
            isLatLngRequired: true,

            getPlaceDetailWithLatLng: (Prediction prediction) {
              debugPrint('📍 Selected: ${prediction.description}');
              debugPrint('📍 Lat: ${prediction.lat}, Lng: ${prediction.lng}');

              if (prediction.lat != null && prediction.lng != null) {
                _selectLocation(
                  prediction.description ?? 'Unknown location',
                  double.parse(prediction.lat!),
                  double.parse(prediction.lng!),
                );
              }
            },

            itemClick: (Prediction prediction) {
              _searchController.text = prediction.description ?? '';
              setState(() {
                _isSearching = false;
              });
            },

            seperatedBuilder: const Divider(),
            containerHorizontalPadding: 10,
          ),
        ),

        // // Google Places Autocomplete
        // Container(
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(12),
        //     border: Border.all(color: Colors.grey.shade300, width: 1),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black.withOpacity(0.05),
        //         blurRadius: 10,
        //         offset: const Offset(0, 4),
        //       ),
        //     ],
        //   ),
        //   child: GooglePlaceAutoCompleteTextField(
        //     textEditingController: _searchController,
        //     googleAPIKey: _googleApiKey,
        //     inputDecoration: InputDecoration(
        //       border: InputBorder.none,
        //       hintText: 'Enter your location',
        //       hintStyle: TextStyle(
        //         color: Colors.grey.shade500,
        //         fontSize: 16,
        //       ),
        //       prefixIcon: Icon(
        //         Icons.search_outlined,
        //         color: Colors.grey.shade500,
        //       ),
        //       suffixIcon: _searchController.text.isNotEmpty
        //           ? IconButton(
        //               icon: const Icon(Icons.clear, color: Colors.grey),
        //               onPressed: () {
        //                 _searchController.clear();
        //                 setState(() {
        //                   _searchPredictions.clear();
        //                   _isSearching = false;
        //                 });
        //               },
        //             )
        //           : null,
        //       contentPadding: const EdgeInsets.symmetric(
        //         horizontal: 16,
        //         vertical: 16,
        //       ),
        //     ),
        //     debounceTime: 400,
        //     countries: ["us", "in", "ca", "gb", "au"], // Add more countries as needed
        //     isLatLngRequired: true,
        //     getPlaceDetailWithLatLng: (Prediction prediction) {
        //       debugPrint('📍 Selected: ${prediction.description}');
        //       debugPrint('📍 Lat: ${prediction.lat}, Lng: ${prediction.lng}');

        //       if (prediction.lat != null && prediction.lng != null) {
        //         _selectLocation(
        //           prediction.description ?? 'Unknown location',
        //           double.parse(prediction.lat!),
        //           double.parse(prediction.lng!),
        //         );
        //       }
        //     },
        //     itemClick: (Prediction prediction) {
        //       _searchController.text = prediction.description ?? '';
        //       setState(() {
        //         _searchPredictions.clear();
        //         _isSearching = false;
        //       });
        //     },
        //     seperatedBuilder: const Divider(),
        //     containerHorizontalPadding: 10,
        //     itemsFound: (List<Prediction> predictions) {
        //       setState(() {
        //         _searchPredictions = predictions;
        //         _isLoadingPredictions = false;
        //       });
        //     },
        //   ),
        // ),

        // Search Results
        if (_isSearching && _searchPredictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchPredictions.length,
              itemBuilder: (context, index) {
                final prediction = _searchPredictions[index];
                return ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF1A73E8),
                  ),
                  title: Text(
                    prediction.description ?? 'Unknown location',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle:
                      prediction.structuredFormatting?.secondaryText != null
                      ? Text(
                          prediction.structuredFormatting!.secondaryText!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )
                      : null,
                  onTap: () {
                    _searchController.text = prediction.description ?? '';
                    setState(() {
                      _searchPredictions.clear();
                      _isSearching = false;
                    });

                    if (prediction.lat != null && prediction.lng != null) {
                      _selectLocation(
                        prediction.description ?? 'Unknown location',
                        double.parse(prediction.lat!),
                        double.parse(prediction.lng!),
                      );
                    }
                  },
                );
              },
            ),
          ),

        if (_isSearching &&
            _searchPredictions.isEmpty &&
            _searchController.text.length >= 3)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No locations found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Search Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                setState(() {
                  _isSearching = true;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text(
              'Search Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildCurrentLocationSection(),
                const SizedBox(height: 40),

                // OR Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                _buildSearchSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
