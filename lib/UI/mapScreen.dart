import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'
    hide Route;
import 'package:http/http.dart' as http;
import 'package:tressle_app_1/UI/HomeScreen.dart';
import 'dart:convert';
import 'package:tressle_app_1/UI/shopDetailScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BarberMapScreen extends StatefulWidget {
  @override
  _BarberMapScreenState createState() => _BarberMapScreenState();
}

// Custom Prediction class for Google Places
class PlacePrediction {
  final String description;
  final String placeId;

  PlacePrediction({required this.description, required this.placeId});

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
    );
  }
}

// POI Data class
class PoiData {
  final String name;
  final String address;
  final double rating;
  final LatLng latLng;
  final String placeId;
  final String? phone;
  final String? website;
  final String? businessStatus;
  final List<dynamic>? openingHours;
  final List<dynamic>? types;

  PoiData({
    required this.name,
    required this.address,
    required this.rating,
    required this.latLng,
    required this.placeId,
    this.phone,
    this.website,
    this.businessStatus,
    this.openingHours,
    this.types,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'rating': rating,
      'latLng': latLng,
      'placeId': placeId,
      'phone': phone,
      'website': website,
      'businessStatus': businessStatus,
      'openingHours': openingHours,
      'types': types,
    };
  }
}

class _BarberMapScreenState extends State<BarberMapScreen> {
  GoogleMapController? _mapController;
  TextEditingController _searchController = TextEditingController();

  // Current state: 0 = general view, 1 = user location view, 2 = shop detail popup, 3 = directions view
  int currentState = 0;

  // Selected shop for popup
  Map<String, dynamic>? selectedShop;

  // User location
  LatLng? userLocation;

  // Map markers
  Set<Marker> markers = {};
  Set<Marker> placeMarkers = {}; // For nearby places not in DB

  // Cache for custom markers
  Map<String, BitmapDescriptor> markerCache = {};

  // Polyline for directions
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  // Distance and Duration
  String? routeDistance;
  String? routeDuration;

  // API Key
  final String googleApiKey = 'AIzaSyCi2oClQ7otjaZ8VaXj0nAeASA0m8chH-Y';
  late PolylinePoints polylinePoints;

  // Firebase shops data
  List<Map<String, dynamic>> barberShops = [];
  List<Map<String, dynamic>> filteredShops = [];

  // Loading state
  bool isLoading = true;

  // Location stream subscription
  StreamSubscription<Position>? _positionStreamSubscription;

  // Search related
  FocusNode _searchFocusNode = FocusNode();
  bool _showSearchSuggestions = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<PlacePrediction> _placeSuggestions = [];

  // Filter related
  List<String> _selectedFilters = [];
  bool _showFilterSheet = false;
  final List<String> _availableFilters = [
    'Shave',
    'Haircut',
    'Makeup',
    'Massage',
    'Skin Care',
    'Facial',
    'Hair Color',
    'Beard Trim',
    'Waxing',
    'Manicure',
    'Pedicure',
    'Spa',
  ];

  // Nearby places
  List<Map<String, dynamic>> nearbyPlaces = [];

  // For Google Maps POI tap
  PoiData? _selectedPoi;
  bool _showPoiDetails = false;
  Timer? _poiTapTimer;
  LatLng? _lastTapPosition;
  bool _isCheckingPoi = false;

  // For location update
  bool _isUpdatingLocation = false;

  // For map tap location
  LatLng? _tappedLocation;
  final MarkerId _tappedLocationMarkerId = MarkerId('tapped_location');

  @override
  void initState() {
    super.initState();
    polylinePoints = PolylinePoints(apiKey: googleApiKey);
    addCustomIcon();
    _initializeData();

    // Listen to search focus
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() {
          _showSearchSuggestions = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _poiTapTimer?.cancel();
    super.dispose();
  }

  List<Map<String, String>> _priceRanges = [
    {'label': 'Under 500 PKR', 'min': '0', 'max': '500'},
    {'label': '500 - 1000 PKR', 'min': '500', 'max': '1000'},
    {'label': '1000 - 2000 PKR', 'min': '1000', 'max': '2000'},
    {'label': '2000 - 5000 PKR', 'min': '2000', 'max': '5000'},
    {'label': 'Above 5000 PKR', 'min': '5000', 'max': '999999'},
  ];
  String? _selectedPriceRange;
  bool _hasShopsIn10km = true;

  // Update the _initializeData method to check for shops within 10km
  Future<void> _initializeData() async {
    // First get user location and show it
    await _getUserLocation();
    await _fetchShopsFromFirebase();

    // Check if there are any shops within 10km
    _checkShopsIn10km();

    _createMarkers();

    // Start location tracking after initial load
    _startLocationTracking();

    setState(() {
      isLoading = false;
      // Set initial state to show user location
      currentState = 1;
    });

    // Move camera to user location
    if (_mapController != null && userLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation!, 16.0),
      );
    }
  }

  // Add this method to check for shops within 10km
  void _checkShopsIn10km() {
    if (userLocation == null) return;

    bool foundShopIn10km = false;

    for (var shop in barberShops) {
      if (shop['latitude'] != null && shop['longitude'] != null) {
        double distance = _calculateDistance(
          userLocation!.latitude,
          userLocation!.longitude,
          shop['latitude'].toDouble(),
          shop['longitude'].toDouble(),
        );

        // Convert to km (distance is in meters)
        double distanceInKm = distance / 1000;

        if (distanceInKm <= 10) {
          foundShopIn10km = true;
          break;
        }
      }
    }

    setState(() {
      _hasShopsIn10km = foundShopIn10km;
    });
  }

  // Navigate to HomeScreen and remove all stacks
  void _navigateToHomeScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainScreen(index: 0)),
      (route) => false,
    );
  }

  // Function to get current location, convert to address, and update Firebase
  Future<void> _updateCurrentLocationToFirebase() async {
    if (_isUpdatingLocation) return;

    setState(() {
      _isUpdatingLocation = true;
    });

    try {
      // Show getting location message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 10),
              Text('Getting your current location...'),
            ],
          ),
          duration: Duration(seconds: 5),
        ),
      );

      // Get current location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        LatLng currentLocation = LatLng(position.latitude, position.longitude);

        // Show converting to address message
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 10),
                Text('Converting coordinates to address...'),
              ],
            ),
            duration: Duration(seconds: 5),
          ),
        );

        // USE GEOCODING PACKAGE TO CONVERT COORDINATES TO ADDRESS (LIKE THAT SCREEN)
        String address = 'Unknown location';

        try {
          // Convert coordinates to placemarks using geocoding package
          List<Placemark> placemarks = await placemarkFromCoordinates(
            currentLocation.latitude,
            currentLocation.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];

            // Build address string from placemark (same as that screen)
            List<String> addressParts = [];

            // Street address
            if (place.street != null && place.street!.isNotEmpty) {
              addressParts.add(place.street!);
            }

            // Sub-locality (area)
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              addressParts.add(place.subLocality!);
            }

            // Locality (city)
            if (place.locality != null && place.locality!.isNotEmpty) {
              addressParts.add(place.locality!);
            }

            // Administrative area (state)
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty) {
              addressParts.add(place.administrativeArea!);
            }

            // Country
            if (place.country != null && place.country!.isNotEmpty) {
              addressParts.add(place.country!);
            }

            // If we have address parts, join them
            if (addressParts.isNotEmpty) {
              address = addressParts.join(', ');
            } else {
              // Fallback: try to get formatted address from Google Geocoding
              address = await _getAddressFromLatLng(currentLocation);
            }
          } else {
            // Fallback to Google Geocoding if geocoding package returns empty
            address = await _getAddressFromLatLng(currentLocation);
          }
        } catch (e) {
          print("Geocoding error: $e");
          // Fallback to Google Geocoding
          address = await _getAddressFromLatLng(currentLocation);
        }

        print(
          "Coordinates: ${currentLocation.latitude}, ${currentLocation.longitude}",
        );
        print("Converted Address: $address");

        // Update Firebase with the ADDRESS
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
                'latitude': currentLocation.latitude,
                'longitude': currentLocation.longitude,
                'address': address, // Store the converted address
                'updatedAt': FieldValue.serverTimestamp(),
              });

          // Update local state
          setState(() {
            userLocation = currentLocation;
            _isUpdatingLocation = false;
            _tappedLocation = null;
            markers.removeWhere(
              (marker) => marker.markerId == _tappedLocationMarkerId,
            );
          });

          // Show success message with the address
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Location updated successfully!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Address: $address',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );

          // Re-center map on new location
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(currentLocation, 16.0),
          );

          // Update markers
          _createMarkers();
        } else {
          throw Exception("User not logged in");
        }
      } else {
        throw Exception("Location permission denied");
      }
    } catch (e) {
      print("Error updating current location: $e");

      setState(() {
        _isUpdatingLocation = false;
      });

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to update location: ${e.toString().split(':').last}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Function to update location from tapped point on map
  Future<void> _updateTappedLocationToFirebase(LatLng tappedLocation) async {
    if (_isUpdatingLocation) return;

    setState(() {
      _isUpdatingLocation = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 10),
              Text('Converting tapped location to address...'),
            ],
          ),
          duration: Duration(seconds: 5),
        ),
      );

      // First try to get address using geocoding package (like the other function)
      String address = 'Unknown location';

      try {
        // Convert coordinates to placemarks using geocoding package
        List<Placemark> placemarks = await placemarkFromCoordinates(
          tappedLocation.latitude,
          tappedLocation.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];

          // Build address string from placemark (same as that screen)
          List<String> addressParts = [];

          // Street address
          if (place.street != null && place.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }

          // Sub-locality (area)
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }

          // Locality (city)
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }

          // Administrative area (state)
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }

          // Country
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }

          // If we have address parts, join them
          if (addressParts.isNotEmpty) {
            address = addressParts.join(', ');
          } else {
            // Fallback: try to get formatted address from Google Geocoding
            address = await _getAddressFromLatLng(tappedLocation);
          }
        } else {
          // Fallback to Google Geocoding if geocoding package returns empty
          address = await _getAddressFromLatLng(tappedLocation);
        }
      } catch (e) {
        print("Geocoding error: $e");
        // Fallback to Google Geocoding
        address = await _getAddressFromLatLng(tappedLocation);
      }

      print(
        "Tapped Location: ${tappedLocation.latitude}, ${tappedLocation.longitude}",
      );
      print("Converted Address: $address");

      // Update Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'latitude': tappedLocation.latitude,
              'longitude': tappedLocation.longitude,
              'address': address,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Update local state
        setState(() {
          userLocation = tappedLocation;
          _isUpdatingLocation = false;
          _tappedLocation = null;

          // Remove the tapped location marker
          markers.removeWhere(
            (marker) => marker.markerId == _tappedLocationMarkerId,
          );
        });

        // Show success message
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Location updated from map tap!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Address: $address',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // Re-center map on new location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(tappedLocation, 16.0),
        );

        // Update markers
        _createMarkers();
      } else {
        throw Exception("User not logged in");
      }
    } catch (e) {
      print("Error updating tapped location: $e");

      setState(() {
        _isUpdatingLocation = false;
      });

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to update location: ${e.toString().split(':').last}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${latLng.latitude},${latLng.longitude}'
        '&key=$googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'] ??
              '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
        }
      }

      return '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
    } catch (e) {
      print("Google Geocoding error: $e");
      return '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
    }
  }

  Future<Map<String, dynamic>> _fetchShopRating(
    String shopId,
    List<dynamic>? ratingIds,
  ) async {
    try {
      if (ratingIds == null || ratingIds.isEmpty) {
        return {'avg': 0.0, 'count': 0};
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where(FieldPath.documentId, whereIn: ratingIds)
          .get();

      double totalRating = 0;
      int count = 0;

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        var shopRating = data['shopRating'];

        if (shopRating != null) {
          totalRating += (shopRating is int)
              ? shopRating.toDouble()
              : (shopRating as double);
          count++;
        }
      }

      return {'avg': count == 0 ? 0.0 : totalRating / count, 'count': count};
    } catch (e) {
      print("Error fetching shop rating: $e");
      return {'avg': 0.0, 'count': 0};
    }
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
        });
        // Fetch nearby places after getting location
        if (userLocation != null) {
          _fetchNearbyPlaces();
        }
      } else {
        // Default location if permission denied
        setState(() {
          userLocation = LatLng(33.6844, 73.0479); // Islamabad
        });
      }
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        userLocation = LatLng(33.6844, 73.0479); // Default to Islamabad
      });
    }
  }

  Future<void> _fetchNearbyPlaces() async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${userLocation!.latitude},${userLocation!.longitude}'
        '&radius=5000'
        '&type=hair_care|beauty_salon|spa'
        '&key=$googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          List<Map<String, dynamic>> places = [];

          for (var place in data['results']) {
            // Check if place is not already in our database
            bool isInDb = barberShops.any(
              (shop) =>
                  (shop['latitude'] - place['geometry']['location']['lat'])
                          .abs() <
                      0.001 &&
                  (shop['longitude'] - place['geometry']['location']['lng'])
                          .abs() <
                      0.001,
            );

            if (!isInDb) {
              places.add({
                'name': place['name'],
                'latitude': place['geometry']['location']['lat'],
                'longitude': place['geometry']['location']['lng'],
                'address': place['vicinity'] ?? '',
                'rating': place['rating']?.toDouble() ?? 0.0,
                'isGooglePlace': true,
                'placeId': place['place_id'],
              });
            }
          }

          setState(() {
            nearbyPlaces = places;
          });
          _createPlaceMarkers();
        }
      }
    } catch (e) {
      print("Error fetching nearby places: $e");
    }
  }

  void _startLocationTracking() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        );

        _positionStreamSubscription =
            Geolocator.getPositionStream(
              locationSettings: locationSettings,
            ).listen((Position position) {
              setState(() {
                userLocation = LatLng(position.latitude, position.longitude);
              });

              _updateUserLocationMarker();

              if (currentState == 3 && selectedShop != null) {
                _updateRouteInRealTime();
              }

              print(
                "Location updated: ${position.latitude}, ${position.longitude}",
              );
            });
      }
    } catch (e) {
      print("Error starting location tracking: $e");
    }
  }

  void _updateUserLocationMarker() {
    if (userLocation == null) return;

    markers.removeWhere((marker) => marker.markerId.value == 'user_location');

    if (currentState == 1 || currentState == 3) {
      markers.add(
        Marker(
          markerId: MarkerId('user_location'),
          position: userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Your Location'),
        ),
      );

      setState(() {});
    }
  }

  Future<void> _updateRouteInRealTime() async {
    if (selectedShop == null || userLocation == null) return;

    LatLng destination = LatLng(
      selectedShop!['latitude'].toDouble(),
      selectedShop!['longitude'].toDouble(),
    );

    await _getDistanceAndDuration(userLocation!, destination);
  }

  Future<void> _fetchShopsFromFirebase() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('shops')
          .get();

      setState(() {
        barberShops = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        filteredShops = List.from(barberShops);
      });
    } catch (e) {
      print("Error fetching shops: $e");
    }
  }

  void _createMarkers() async {
    Set<Marker> newMarkers = {};

    // Add shop markers with shop names
    for (var shop in filteredShops) {
      if (shop['latitude'] != null && shop['longitude'] != null) {
        BitmapDescriptor customMarkerWithLabel = await _createMarkerWithLabel(
          shop['shopName'] ?? 'Shop',
        );

        newMarkers.add(
          Marker(
            markerId: MarkerId(shop['id']),
            position: LatLng(
              shop['latitude'].toDouble(),
              shop['longitude'].toDouble(),
            ),
            icon: customMarkerWithLabel,
            infoWindow: InfoWindow(
              title: shop['shopName'] ?? 'Unknown Shop',
              snippet: shop['shopAddress'] ?? '',
            ),
            onTap: () {
              _onMarkerTap(shop);
            },
          ),
        );
      }
    }

    // Add user location marker if in state 1 or 3
    if ((currentState == 1 || currentState == 3) && userLocation != null) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('user_location'),
          position: userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Your Location'),
        ),
      );
    }

    setState(() {
      markers = newMarkers;
    });
  }

  void _createPlaceMarkers() {
    Set<Marker> newPlaceMarkers = {};

    for (var place in nearbyPlaces) {
      newPlaceMarkers.add(
        Marker(
          markerId: MarkerId('place_${place['placeId']}'),
          position: LatLng(
            place['latitude'].toDouble(),
            place['longitude'].toDouble(),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: place['name'],
            snippet: place['address'],
          ),
          onTap: () {
            _onPlaceMarkerTap(place);
          },
        ),
      );
    }

    setState(() {
      placeMarkers = newPlaceMarkers;
    });
  }

  void _onMarkerTap(Map<String, dynamic> shop) {
    setState(() {
      selectedShop = shop;
      currentState = 2;
      _showSearchSuggestions = false;
      _showPoiDetails = false;
      _searchFocusNode.unfocus();
    });

    // Zoom to marker
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(shop['latitude'].toDouble(), shop['longitude'].toDouble()),
        16.0,
      ),
    );
  }

  void _onPlaceMarkerTap(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place['name'],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(place['address'], style: TextStyle(color: Colors.grey)),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 5),
                  Text(place['rating'].toString()),
                  SizedBox(width: 10),
                  Text('(Google Places)', style: TextStyle(color: Colors.blue)),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _zoomToPlace(place);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('View on Map'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to check if tap is on a Google Maps POI
  Future<void> _checkForPoiTap(LatLng position) async {
    if (_isCheckingPoi) return;

    _isCheckingPoi = true;
    _lastTapPosition = position;

    try {
      // First, check if this is near any existing marker
      bool isNearMarker = false;

      // Check custom markers
      for (var marker in markers) {
        final markerPos = marker.position;
        final distance = _calculateDistance(
          position.latitude,
          position.longitude,
          markerPos.latitude,
          markerPos.longitude,
        );

        if (distance < 0.0005) {
          // Very close to marker
          isNearMarker = true;
          break;
        }
      }

      // Check place markers
      if (!isNearMarker) {
        for (var marker in placeMarkers) {
          final markerPos = marker.position;
          final distance = _calculateDistance(
            position.latitude,
            position.longitude,
            markerPos.latitude,
            markerPos.longitude,
          );

          if (distance < 0.0005) {
            // Very close to marker
            isNearMarker = true;
            break;
          }
        }
      }

      // If not near any marker, check for nearby places using Google Places API
      if (!isNearMarker) {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${position.latitude},${position.longitude}'
          '&radius=50' // Very small radius to get exact location
          '&key=$googleApiKey',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            final place = data['results'][0];
            final placeLat = place['geometry']['location']['lat'];
            final placeLng = place['geometry']['location']['lng'];

            // Check if tap is close to this place
            final distance = _calculateDistance(
              position.latitude,
              position.longitude,
              placeLat,
              placeLng,
            );

            if (distance < 0.001) {
              // Close enough to consider as POI tap
              // Get place details
              final placeId = place['place_id'];
              await _fetchAndShowPoiDetails(
                placeId,
                LatLng(placeLat, placeLng),
                place['name'],
              );
              return;
            }
          }
        }

        // If no specific place found, try reverse geocoding to get address
        await _showReverseGeocodingInfo(position);
      }
    } catch (e) {
      print("Error checking POI tap: $e");
    } finally {
      _isCheckingPoi = false;
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000.0; // Earth's radius in meters
    final lat1Rad = lat1 * 3.141592653589793 / 180;
    final lat2Rad = lat2 * 3.141592653589793 / 180;
    final deltaLatRad = (lat2 - lat1) * 3.141592653589793 / 180;
    final deltaLonRad = (lon2 - lon1) * 3.141592653589793 / 180;

    final a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLonRad / 2) *
            sin(deltaLonRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // Distance in meters
  }

  Future<void> _fetchAndShowPoiDetails(
    String placeId,
    LatLng latLng,
    String name,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=name,formatted_address,rating,formatted_phone_number,website,business_status,opening_hours,types'
        '&key=$googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final place = data['result'];

          setState(() {
            _selectedPoi = PoiData(
              name: place['name'] ?? name,
              address: place['formatted_address'] ?? 'Address not available',
              rating: place['rating']?.toDouble() ?? 0.0,
              latLng: latLng,
              placeId: placeId,
              phone: place['formatted_phone_number'],
              website: place['website'],
              businessStatus: place['business_status'],
              openingHours: place['opening_hours']?['weekday_text'],
              types: place['types'],
            );
            _showPoiDetails = true;
            _showSearchSuggestions = false;
            _searchFocusNode.unfocus();
          });

          // Zoom to POI
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(latLng, 16.0),
          );

          // Auto-hide after 8 seconds
          _poiTapTimer?.cancel();
          _poiTapTimer = Timer(Duration(seconds: 8), () {
            if (mounted) {
              setState(() {
                _showPoiDetails = false;
              });
            }
          });
        }
      }
    } catch (e) {
      print("Error fetching POI details: $e");
      // Show basic info if API call fails
      setState(() {
        _selectedPoi = PoiData(
          name: name,
          address: 'Tap to see details',
          rating: 0.0,
          latLng: latLng,
          placeId: placeId,
        );
        _showPoiDetails = true;
      });

      // Auto-hide after 8 seconds
      _poiTapTimer?.cancel();
      _poiTapTimer = Timer(Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            _showPoiDetails = false;
          });
        }
      });
    }
  }

  Future<void> _showReverseGeocodingInfo(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${position.latitude},${position.longitude}'
        '&key=$googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];

          setState(() {
            _selectedPoi = PoiData(
              name: result['types']?.isNotEmpty == true
                  ? result['types'][0].toString().replaceAll('_', ' ')
                  : 'Location',
              address: result['formatted_address'] ?? 'No address available',
              rating: 0.0,
              latLng: position,
              placeId: result['place_id'] ?? 'no_id',
              types: result['types'],
            );
            _showPoiDetails = true;
          });

          // Auto-hide after 8 seconds
          _poiTapTimer?.cancel();
          _poiTapTimer = Timer(Duration(seconds: 8), () {
            if (mounted) {
              setState(() {
                _showPoiDetails = false;
              });
            }
          });
        }
      }
    } catch (e) {
      print("Error in reverse geocoding: $e");
    }
  }

  Future<BitmapDescriptor> _createMarkerWithLabel(String shopName) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      final ByteData iconData = await rootBundle.load(
        'assets/icons/location_s_icon.png',
      );
      final Uint8List iconBytes = iconData.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(
        iconBytes,
        targetWidth: 240,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image markerImage = frameInfo.image;

      const double markerWidth = 200;
      const double markerHeight = 210;
      const double labelPadding = 20;
      const double labelHeight = 50;

      final textSpan = TextSpan(
        text: shopName.length > 15
            ? '${shopName.substring(0, 15)}...'
            : shopName,
        style: TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      final double labelWidth = textPainter.width + (labelPadding * 2);
      final double totalWidth = labelWidth > markerWidth
          ? labelWidth
          : markerWidth;
      final double totalHeight = markerHeight + labelHeight + 5;

      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (totalWidth - labelWidth) / 2,
          0,
          labelWidth,
          labelHeight,
        ),
        Radius.circular(15),
      );

      final Paint labelPaint = Paint()
        ..color = Color(0xFF1976D2)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(labelRect, labelPaint);

      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRRect(labelRect, borderPaint);

      textPainter.paint(
        canvas,
        Offset(
          (totalWidth - textPainter.width) / 2,
          (labelHeight - textPainter.height) / 2,
        ),
      );

      canvas.drawImage(
        markerImage,
        Offset((totalWidth - markerWidth) / 2, labelHeight + 5),
        Paint(),
      );

      final ui.Image markerAsImage = await pictureRecorder
          .endRecording()
          .toImage(totalWidth.toInt(), totalHeight.toInt());

      final ByteData? byteData = await markerAsImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List uint8List = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(uint8List);
    } catch (e) {
      print("Error creating marker with label: $e");
      return markerIcon;
    }
  }

  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;

  void addCustomIcon() {
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(40, 40)),
      "assets/icons/location_s_icon.png",
    ).then((icon) {
      setState(() {
        markerIcon = icon;
      });
    });
  }

  Future<Uint8List> _resizeImage(
    Uint8List data, {
    int width = 80,
    int height = 80,
  }) async {
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    final resizedImage = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return resizedImage!.buffer.asUint8List();
  }

  Future<void> _getDistanceAndDuration(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=${origin.latitude},${origin.longitude}'
        '&destinations=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['rows'] != null &&
            data['rows'].isNotEmpty &&
            data['rows'][0]['elements'] != null &&
            data['rows'][0]['elements'].isNotEmpty) {
          final element = data['rows'][0]['elements'][0];

          if (element['status'] == 'OK') {
            setState(() {
              routeDistance = element['distance']['text'];
              routeDuration = element['duration']['text'];
            });
          }
        }
      }
    } catch (e) {
      print("Error getting distance and duration: $e");
    }
  }

  Future<void> _getDirections() async {
    if (selectedShop == null || userLocation == null) return;

    setState(() {
      currentState = 3;
      polylineCoordinates.clear();
      polylines.clear();
      routeDistance = null;
      routeDuration = null;
    });

    LatLng destination = LatLng(
      selectedShop!['latitude'].toDouble(),
      selectedShop!['longitude'].toDouble(),
    );

    await _getDistanceAndDuration(userLocation!, destination);

    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(userLocation!.latitude, userLocation!.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        List<LatLng> points = [];
        result.points.forEach((PointLatLng point) {
          points.add(LatLng(point.latitude, point.longitude));
        });

        setState(() {
          polylineCoordinates = points;
          polylines.add(
            Polyline(
              polylineId: PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: polylineCoordinates,
            ),
          );
        });

        double minLat = userLocation!.latitude < destination.latitude
            ? userLocation!.latitude
            : destination.latitude;
        double maxLat = userLocation!.latitude > destination.latitude
            ? userLocation!.latitude
            : destination.latitude;
        double minLng = userLocation!.longitude < destination.longitude
            ? userLocation!.longitude
            : destination.longitude;
        double maxLng = userLocation!.longitude > destination.longitude
            ? userLocation!.longitude
            : destination.longitude;

        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find route. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          currentState = 2;
        });
      }
    } catch (e) {
      print("Error getting directions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting directions: $e'),
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        currentState = 2;
      });
    }

    _createMarkers();
  }

  // Search Methods
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _placeSuggestions.clear();
      });
      return;
    }

    // Search in local database first
    List<Map<String, dynamic>> localResults = barberShops
        .where(
          (shop) =>
              (shop['shopName']?.toString().toLowerCase() ?? '').contains(
                query.toLowerCase(),
              ) ||
              (shop['shopAddress']?.toString().toLowerCase() ?? '').contains(
                query.toLowerCase(),
              ),
        )
        .toList();

    setState(() {
      _searchResults = localResults;
    });

    // Also get Google Places suggestions
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$query'
        '&location=${userLocation!.latitude},${userLocation!.longitude}'
        '&radius=5000'
        '&key=$googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          List<PlacePrediction> predictions = [];
          for (var prediction in data['predictions']) {
            predictions.add(PlacePrediction.fromJson(prediction));
          }
          setState(() {
            _placeSuggestions = predictions;
          });
        }
      }
    } catch (e) {
      print("Error getting place suggestions: $e");
    }
  }

  Future<void> _onSearchItemTap(Map<String, dynamic> shop) async {
    // Auto-fill the search bar with the shop name
    _searchController.text = shop['shopName'] ?? '';

    setState(() {
      selectedShop = shop;
      currentState = 2;
      _showSearchSuggestions = false;
      _showPoiDetails = false;
      _searchFocusNode.unfocus();
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(shop['latitude'].toDouble(), shop['longitude'].toDouble()),
        16.0,
      ),
    );
  }

  Future<void> _onPlaceSuggestionTap(PlacePrediction prediction) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${prediction.placeId}'
        '&fields=name,geometry,formatted_address,rating'
        '&key=$googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final place = data['result'];

          // Auto-fill the search bar with the place name
          _searchController.text = place['name'] ?? prediction.description;

          setState(() {
            _showSearchSuggestions = false;
            _showPoiDetails = false;
            _searchFocusNode.unfocus();
          });

          _zoomToPlace({
            'name': place['name'],
            'latitude': place['geometry']['location']['lat'],
            'longitude': place['geometry']['location']['lng'],
            'address': place['formatted_address'],
            'rating': place['rating']?.toDouble() ?? 0.0,
            'isGooglePlace': true,
          });
        }
      }
    } catch (e) {
      print("Error getting place details: $e");
      // Even if API fails, auto-fill with the prediction description
      _searchController.text = prediction.description;
      setState(() {
        _showSearchSuggestions = false;
        _showPoiDetails = false;
        _searchFocusNode.unfocus();
      });
    }
  }

  void _zoomToPlace(Map<String, dynamic> place) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(place['latitude'].toDouble(), place['longitude'].toDouble()),
        15.0,
      ),
    );
  }

  // Filter Methods
  void _applyFilters() {
    if (_selectedFilters.isEmpty && _selectedPriceRange == null) {
      setState(() {
        filteredShops = List.from(barberShops);
      });
    } else {
      setState(() {
        filteredShops = barberShops.where((shop) {
          bool passesServiceFilter = true;
          bool passesPriceFilter = true;

          // Apply service filter if any selected
          if (_selectedFilters.isNotEmpty) {
            final services = shop['services']?.toString().toLowerCase() ?? '';
            final description =
                shop['description']?.toString().toLowerCase() ?? '';

            passesServiceFilter = _selectedFilters.any(
              (filter) =>
                  services.contains(filter.toLowerCase()) ||
                  description.contains(filter.toLowerCase()),
            );
          }

          // Apply price filter if selected
          if (_selectedPriceRange != null) {
            final priceRange = _priceRanges.firstWhere(
              (range) => range['label'] == _selectedPriceRange,
            );
            final minPrice = double.tryParse(priceRange['min'] ?? '0') ?? 0;
            final maxPrice =
                double.tryParse(priceRange['max'] ?? '999999') ?? 999999;

            // Check if shop has services with prices
            final services = shop['services'] ?? [];
            if (services is List) {
              bool hasPriceInRange = false;

              // Check each service price
              for (var service in services) {
                if (service is Map) {
                  final priceStr = service['price']?.toString() ?? '';
                  final price = double.tryParse(priceStr) ?? 0;

                  if (price >= minPrice && price <= maxPrice) {
                    hasPriceInRange = true;
                    break;
                  }
                }
              }
              passesPriceFilter = hasPriceInRange;
            } else {
              // If no service prices found, show the shop (don't filter out)
              passesPriceFilter = true;
            }
          }

          return passesServiceFilter && passesPriceFilter;
        }).toList();
      });
    }

    // Show snackbar if no shops found after filtering
    if (filteredShops.isEmpty) {
      String filterMessage = '';

      if (_selectedFilters.isNotEmpty && _selectedPriceRange != null) {
        filterMessage =
            'with selected services (${_selectedFilters.join(', ')}) and price range (${_selectedPriceRange})';
      } else if (_selectedFilters.isNotEmpty) {
        filterMessage =
            'with selected services (${_selectedFilters.join(', ')})';
      } else if (_selectedPriceRange != null) {
        filterMessage = 'in price range (${_selectedPriceRange})';
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.search_off, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No shop found $filterMessage',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange[800],
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Clear Filters',
              textColor: Colors.white,
              onPressed: () {
                _clearFilters();
              },
            ),
          ),
        );
      });
    }

    _createMarkers();
    _showFilterSheet = false;
  }

  void _clearFilters() {
    setState(() {
      _selectedFilters.clear();
      _selectedPriceRange = null;
      filteredShops = List.from(barberShops);
      _showFilterSheet = false;
    });
    _createMarkers();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (isLoading || userLocation == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainScreen(index: 0)),
          (Route<dynamic> route) => false,
        );
        return false; // Prevents default back button behavior
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Google Map
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                // Move camera to user location when map is created
                if (userLocation != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(userLocation!, 16.0),
                  );
                }
              },
              initialCameraPosition: CameraPosition(
                target: userLocation!,
                zoom: 16.0,
              ),
              markers: markers.union(placeMarkers),
              polylines: polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onTap: (LatLng position) {
                // Add a marker at the tapped location
                setState(() {
                  _tappedLocation = position;

                  // Remove any existing tapped location marker
                  markers.removeWhere(
                    (marker) => marker.markerId == _tappedLocationMarkerId,
                  );

                  // Add new marker for tapped location
                  markers.add(
                    Marker(
                      markerId: _tappedLocationMarkerId,
                      position: position,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                      infoWindow: InfoWindow(title: 'Selected Location'),
                      draggable: true,
                      onDragEnd: (newPosition) {
                        setState(() {
                          _tappedLocation = newPosition;
                        });
                      },
                    ),
                  );
                });

                // Original POI check code
                _checkForPoiTap(position);

                if (currentState == 2) {
                  setState(() {
                    currentState = currentState == 1 ? 1 : 0;
                    selectedShop = null;
                    _showSearchSuggestions = false;
                    _searchFocusNode.unfocus();
                  });
                } else {
                  setState(() {
                    _showSearchSuggestions = false;
                    _searchFocusNode.unfocus();
                  });
                }
              },
            ),
            if (!_hasShopsIn10km && !isLoading && currentState == 1)
              Positioned(
                top: MediaQuery.of(context).padding.top + 120,
                left: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_off,
                            color: Colors.orange,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'No Tressle Registered Shops Nearby',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'There are no Tressle registered shops within your Area.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'You can still browse Google Places results below.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _hasShopsIn10km = true; // Hide the message
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.blue),
                              ),
                              child: Text(
                                'Hide Message',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Fetch more shops or increase radius
                                _fetchNearbyPlaces();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Searching for more shops...',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: Text(
                                'Search Wider',
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
            // Distance and Duration Info Card
            if (currentState == 3 &&
                routeDistance != null &&
                routeDuration != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                left: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.straighten,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Distance',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                routeDistance!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.access_time,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duration',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                routeDuration!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Top search bar and back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _performSearch,
                            onTap: () {
                              setState(() {
                                _showSearchSuggestions = true;
                                _showPoiDetails = false;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Search shops or places...",
                              hintStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: "Adamina",
                              ),
                              suffixIcon: Container(
                                margin: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: Colors.grey[600],
                                  size: 18,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        margin: EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            IconButton(
                              icon: Icon(Icons.filter_alt_outlined, size: 20),
                              onPressed: () {
                                setState(() {
                                  _showFilterSheet = true;
                                  _showSearchSuggestions = false;
                                  _showPoiDetails = false;
                                  _searchFocusNode.unfocus();
                                });
                              },
                            ),
                            // Show badge if filters are active
                            if (_selectedFilters.isNotEmpty ||
                                _selectedPriceRange != null)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_selectedFilters.length + (_selectedPriceRange != null ? 1 : 0)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Search Suggestions
                  if (_showSearchSuggestions &&
                      (_searchResults.isNotEmpty ||
                          _placeSuggestions.isNotEmpty))
                    Container(
                      margin: EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(maxHeight: 300),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          // Local Shop Results
                          if (_searchResults.isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(
                                'Our Shops',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            ..._searchResults.map(
                              (shop) => ListTile(
                                leading: Icon(Icons.store, color: Colors.blue),
                                title: Text(shop['shopName'] ?? 'Unknown'),
                                subtitle: Text(shop['shopAddress'] ?? ''),
                                onTap: () => _onSearchItemTap(shop),
                              ),
                            ),
                            Divider(height: 1),
                          ],

                          // Google Places Suggestions
                          if (_placeSuggestions.isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(
                                'Nearby Places',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            ..._placeSuggestions.map(
                              (prediction) => ListTile(
                                leading: Icon(Icons.place, color: Colors.green),
                                title: Text(prediction.description),
                                onTap: () => _onPlaceSuggestionTap(prediction),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Google Maps POI Details Card
            if (_showPoiDetails && _selectedPoi != null)
              Positioned(
                bottom: 90,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    // Extend visibility when tapped
                    _poiTapTimer?.cancel();
                    _poiTapTimer = Timer(Duration(seconds: 8), () {
                      if (mounted) {
                        setState(() {
                          _showPoiDetails = false;
                        });
                      }
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedPoi!.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  _showPoiDetails = false;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // Type badges
                        if (_selectedPoi!.types != null &&
                            _selectedPoi!.types!.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _selectedPoi!.types!.take(3).map((type) {
                              return Chip(
                                label: Text(
                                  type.toString().replaceAll('_', ' '),
                                  style: TextStyle(fontSize: 10),
                                ),
                                backgroundColor: Colors.grey[100],
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),

                        SizedBox(height: 8),

                        Text(
                          _selectedPoi!.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 8),

                        // Rating and status
                        Row(
                          children: [
                            if (_selectedPoi!.rating > 0)
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _selectedPoi!.rating.toStringAsFixed(1),
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),

                            if (_selectedPoi!.businessStatus != null &&
                                _selectedPoi!.businessStatus!.isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(left: 12),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _selectedPoi!.businessStatus ==
                                          'OPERATIONAL'
                                      ? Colors.green[50]
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color:
                                        _selectedPoi!.businessStatus ==
                                            'OPERATIONAL'
                                        ? Colors.green[100]!
                                        : Colors.orange[100]!,
                                  ),
                                ),
                                child: Text(
                                  _selectedPoi!.businessStatus!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        _selectedPoi!.businessStatus ==
                                            'OPERATIONAL'
                                        ? Colors.green[800]
                                        : Colors.orange[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Opening hours
                        if (_selectedPoi!.openingHours != null &&
                            _selectedPoi!.openingHours!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Text(
                                'Opening Hours:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              ..._selectedPoi!.openingHours!.take(2).map((
                                hour,
                              ) {
                                return Text(
                                  hour.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                );
                              }),
                            ],
                          ),

                        SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Zoom to POI
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      _selectedPoi!.latLng,
                                      17.0,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[50],
                                  foregroundColor: Colors.blue[700],
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: Text('Zoom In'),
                              ),
                            ),
                            SizedBox(width: 8),
                            if (_selectedPoi!.website != null &&
                                _selectedPoi!.website!.isNotEmpty)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Open website
                                    // You can use url_launcher package here
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[50],
                                    foregroundColor: Colors.green[700],
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: Text('Website'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 20,
              left: 16,
              right: 86,
              child: SizedBox(
                height: 45,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdatingLocation
                      ? null
                      : () {
                          // If there's a tapped location, use that, otherwise get current location
                          if (_tappedLocation != null) {
                            _updateTappedLocationToFirebase(_tappedLocation!);
                          } else {
                            _updateCurrentLocationToFirebase();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
                    backgroundColor: _tappedLocation != null
                        ? Colors.green
                        : Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUpdatingLocation
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _tappedLocation != null
                              ? 'Set tapped location as current'
                              : 'Set this as your current location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),

            // Home Button and Location Update Button
            Positioned(
              bottom: 66,
              right: 16,
              child: Container(
                margin: EdgeInsets.only(bottom: 16),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _navigateToHomeScreen,
                  icon: Icon(Icons.home, color: Colors.blue, size: 24),
                  tooltip: 'Go to Home',
                ),
              ),
            ),

            // FAB for centering on current location
            if (currentState != 2 && currentState != 3 && !_showPoiDetails)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    if (userLocation != null) {
                      setState(() {
                        currentState = 1;
                        _showSearchSuggestions = false;
                        _showPoiDetails = false;
                        _searchFocusNode.unfocus();

                        // Clear tapped location when going to current location
                        _tappedLocation = null;
                        markers.removeWhere(
                          (marker) =>
                              marker.markerId == _tappedLocationMarkerId,
                        );
                      });
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(userLocation!, 16.0),
                      );
                      _createMarkers();
                    }
                  },
                  elevation: 2,
                  backgroundColor: Colors.teal[700],
                  shape: const CircleBorder(),
                  child: Icon(Icons.my_location, color: Colors.white),
                ),
              ),

            // Shop detail popup
            if (currentState == 2 && selectedShop != null && !_showPoiDetails)
              Positioned(
                bottom: 90,
                left: screenWidth * 1 / 13,
                child: Container(
                  width: screenWidth * 4 / 5,
                  height: 280,
                  child: Stack(
                    children: [
                      // Background image
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: NetworkImage(
                              selectedShop!['shopImage'] ??
                                  'https://via.placeholder.com/400x300',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      // Content overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedShop!['shopName'] ?? 'Unknown Shop',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 5),
                              FutureBuilder<Map<String, dynamic>>(
                                future: _fetchShopRating(
                                  selectedShop!['id'],
                                  selectedShop!['ratings'],
                                ),
                                builder: (context, snapshot) {
                                  double avgRating = 0.0;
                                  int reviewCount = 0;

                                  if (snapshot.hasData) {
                                    avgRating = snapshot.data!['avg'];
                                    reviewCount = snapshot.data!['count'];
                                  }

                                  List<Widget> _buildStars(double rating) {
                                    return List.generate(5, (i) {
                                      if (i < rating.floor()) {
                                        return Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        );
                                      } else if (i < rating) {
                                        return Icon(
                                          Icons.star_half,
                                          color: Colors.amber,
                                          size: 16,
                                        );
                                      } else {
                                        return Icon(
                                          Icons.star_border,
                                          color: Colors.amber,
                                          size: 16,
                                        );
                                      }
                                    });
                                  }

                                  return Row(
                                    children: [
                                      ..._buildStars(avgRating),
                                      SizedBox(width: 4),
                                      Text(
                                        reviewCount > 0
                                            ? "${avgRating.toStringAsFixed(1)} ($reviewCount)"
                                            : "No ratings yet",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              SizedBox(height: 5),
                              Text(
                                selectedShop!['timings'] ?? 'No timing info',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                selectedShop!['shopAddress'] ?? 'No address',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 40,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _getDirections();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF1976D2),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          "Directions",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      height: 40,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BarberShopDetailScreen(
                                                    shopId: selectedShop!['id'],
                                                    shopData: selectedShop!,
                                                  ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF4CAF50),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        icon: Icon(
                                          Icons.calendar_today_outlined,
                                          size: 18,
                                        ),
                                        label: Text(
                                          "Book Online",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
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
                    ],
                  ),
                ),
              ),

            // Filter Bottom Sheet
            if (_showFilterSheet)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFilterSheet = false;
                    });
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Filter',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _showFilterSheet = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1),

                              // Service Filters Section
                              Container(
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Services',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: GridView.builder(
                                  padding: EdgeInsets.all(16),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 2.5,
                                      ),
                                  itemCount: _availableFilters.length,
                                  itemBuilder: (context, index) {
                                    final filter = _availableFilters[index];
                                    final isSelected = _selectedFilters
                                        .contains(filter);

                                    return FilterChip(
                                      label: Text(filter),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedFilters.add(filter);
                                          } else {
                                            _selectedFilters.remove(filter);
                                          }
                                        });
                                      },
                                      backgroundColor: Colors.grey[200],
                                      selectedColor: Colors.blue[100],
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.black,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    );
                                  },
                                ),
                              ),

                              Divider(height: 1),

                              // Price Filters Section
                              Container(
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Price Range (PKR)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _priceRanges.length,
                                  itemBuilder: (context, index) {
                                    final priceRange = _priceRanges[index];
                                    final isSelected =
                                        _selectedPriceRange ==
                                        priceRange['label'];

                                    return RadioListTile<String?>(
                                      title: Text(priceRange['label']!),
                                      value: priceRange['label'],
                                      groupValue: _selectedPriceRange,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPriceRange = value;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.trailing,
                                      activeColor: Colors.blue,
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    );
                                  },
                                ),
                              ),

                              // Clear All button for price filter
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedPriceRange = null;
                                      });
                                    },
                                    child: Text(
                                      'Clear Price Filter',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Container(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _clearFilters,
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                          side: BorderSide(color: Colors.grey),
                                        ),
                                        child: Text('Clear All Filters'),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _applyFilters,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF1976D2),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                        ),
                                        child: Text('Apply Filters'),
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
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
