import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:tressle_app_1/ui/Widgets/drawerOpener.dart';
import 'package:tressle_app_1/ui/hairsServiceScreen.dart';
import 'package:tressle_app_1/ui/historyScreen.dart';
import 'package:tressle_app_1/ui/nearToYouScreen.dart';
import 'package:tressle_app_1/ui/profileScreen.dart';
import 'package:tressle_app_1/ui/shopDetailScreen.dart';

class BarbershopHomeScreen extends StatefulWidget {
  const BarbershopHomeScreen({Key? key}) : super(key: key);

  @override
  State<BarbershopHomeScreen> createState() => _BarbershopHomeScreenState();
}

class _BarbershopHomeScreenState extends State<BarbershopHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? userData;
  String currentAddress = 'Loading...';
  bool isLoadingLocation = false;

  // Search controller and state
  TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  Duration _searchDebounceDuration = Duration(milliseconds: 500);

  // Filter state
  List<String> _selectedFilters = [];
  List<String> _availableServices = [
    'Shave',
    'Haircut',
    'Makeup',
    'Massage',
    'Skin Care',
    'Beard Trim',
    'Hair Color',
    'Facial',
    'Manicure',
    'Pedicure',
  ];

  // Search query state
  String _searchQuery = '';

  // Popular search terms for suggestions
  final List<String> _popularSearchTerms = [
    'Haircut',
    'Barber',
    'Salon',
    'Massage',
    'Spa',
    'Beard',
    'Shave',
    'Facial',
    'Hair Color',
    'Manicure',
    'Pedicure',
    'Skin Care',
    'Makeup',
    'Hair Style',
    'Hair Treatment',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>?;
            currentAddress = userData?['address'] ?? 'No address set';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Enhanced search matching methods
  bool _matchesSearchQuery(Map<String, dynamic> shop, String query) {
    if (query.isEmpty) return true;

    final queryLower = query.toLowerCase().trim();

    // Split query into individual words/keywords
    List<String> keywords = queryLower
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    // If it's a single word, check for partial matches
    if (keywords.length == 1) {
      return _checkPartialMatch(shop, keywords[0]);
    }

    // If multiple words, check for any word match (OR logic)
    return _checkMultiKeywordMatch(shop, keywords);
  }

  bool _checkPartialMatch(Map<String, dynamic> shop, String keyword) {
    // Check shop name
    final shopName = shop['shopName']?.toString().toLowerCase() ?? '';
    if (shopName.contains(keyword)) return true;

    // Check shop address
    final shopAddress = shop['shopAddress']?.toString().toLowerCase() ?? '';
    if (shopAddress.contains(keyword)) return true;

    // Check shop description or category if available
    final shopDescription = shop['description']?.toString().toLowerCase() ?? '';
    if (shopDescription.contains(keyword)) return true;

    // Check services
    if (_checkServicesMatch(shop, keyword)) return true;

    // Check service names
    if (_checkServiceNamesMatch(shop, keyword)) return true;

    // Check keywords/tags if stored separately
    final tags = shop['tags'] ?? shop['keywords'] ?? [];
    if (tags is List) {
      for (var tag in tags) {
        if (tag.toString().toLowerCase().contains(keyword)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _checkMultiKeywordMatch(
    Map<String, dynamic> shop,
    List<String> keywords,
  ) {
    // OR logic: match ANY of the keywords
    for (var keyword in keywords) {
      if (_checkPartialMatch(shop, keyword)) {
        return true;
      }
    }
    return false;
  }

  bool _checkServicesMatch(Map<String, dynamic> shop, String keyword) {
    final services = shop['services'] ?? [];
    if (services is List) {
      for (var service in services) {
        final serviceStr = service.toString().toLowerCase();
        if (serviceStr.contains(keyword)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _checkServiceNamesMatch(Map<String, dynamic> shop, String keyword) {
    final serviceNames = shop['serviceNames'] ?? [];
    if (serviceNames is List) {
      for (var serviceName in serviceNames) {
        final nameStr = serviceName.toString().toLowerCase();
        if (nameStr.contains(keyword)) {
          return true;
        }
      }
    }
    return false;
  }

  // Helper method to check if shop matches selected filters
  bool _matchesFilters(Map<String, dynamic> shop) {
    if (_selectedFilters.isEmpty) return true;

    final services = shop['services'] ?? [];
    if (services is! List) return false;

    final serviceList = services.map((s) => s.toString()).toList();

    // Check if any selected filter matches shop services
    for (var filter in _selectedFilters) {
      if (serviceList.any(
        (service) => service.toLowerCase().contains(filter.toLowerCase()),
      )) {
        return true;
      }
    }

    return false;
  }

  // Method to show filter bottom sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter by Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select services you\'re looking for:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _availableServices.map((service) {
                      bool isSelected = _selectedFilters.contains(service);
                      return FilterChip(
                        label: Text(service),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedFilters.add(service);
                            } else {
                              _selectedFilters.remove(service);
                            }
                          });
                        },
                        selectedColor: Colors.teal.withOpacity(0.2),
                        checkmarkColor: Colors.teal,
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.teal : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilters.clear();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Clear All',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Apply filters to the main state
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // When bottom sheet is closed, apply filters
      setState(() {});
    });
  }

  Future<void> _updateLocationAndAddress() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';

        User? user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'address': address,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            currentAddress = address;
            if (userData != null) {
              userData!['latitude'] = position.latitude;
              userData!['longitude'] = position.longitude;
              userData!['address'] = address;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location updated successfully')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating location: $e')));
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
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
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // Widget _buildSearchSuggestions() {
  //   if (_searchController.text.isEmpty) return SizedBox.shrink();

  //   final searchText = _searchController.text.toLowerCase();
  //   final suggestions = _popularSearchTerms
  //       .where((term) => term.toLowerCase().contains(searchText))
  //       .take(5)
  //       .toList();

  //   if (suggestions.isEmpty) return SizedBox.shrink();

  //   return Container(
  //     margin: EdgeInsets.symmetric(horizontal: 20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(10),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black12,
  //           blurRadius: 10,
  //           offset: Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Padding(
  //           padding: EdgeInsets.all(10),
  //           child: Text(
  //             'Suggestions',
  //             style: TextStyle(
  //               fontSize: 12,
  //               color: Colors.grey,
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //         ),
  //         ...suggestions
  //             .map(
  //               (suggestion) => ListTile(
  //                 title: Text(suggestion),
  //                 onTap: () {
  //                   _searchController.text = suggestion;
  //                   setState(() {
  //                     _searchQuery = suggestion;
  //                   });
  //                 },
  //               ),
  //             )
  //             .toList(),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildLocationBar(),
            _buildSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUpcomingAppointment(),
                    const SizedBox(height: 20),
                    _buildNearestToYou(),
                    const SizedBox(height: 20),
                    _buildTopServices(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: AppDrawer(),
    );
  }

  Widget _buildLocationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Icon(Icons.menu_rounded, size: 24),
          ),
          Row(
            children: [
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: userData?['profilePicture'] != null
                      ? NetworkImage(userData!['profilePicture'])
                      : const NetworkImage(
                              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face',
                            )
                            as ImageProvider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                // TODO: Implement map picker or remove this if not needed
                // For now, just update location
                await _updateLocationAndAddress();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isLoadingLocation
                        ? Icon(Icons.refresh, color: Colors.black, size: 16)
                        : Image.asset(
                            "assets/icons/arrow.png",
                            height: 12,
                            width: 12,
                            color: Colors.teal,
                          ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        currentAddress,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointment() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    // Clear previous timer if exists
                    if (_searchDebounceTimer != null &&
                        _searchDebounceTimer!.isActive) {
                      _searchDebounceTimer!.cancel();
                    }

                    // Set new timer
                    _searchDebounceTimer = Timer(_searchDebounceDuration, () {
                      if (mounted) {
                        setState(() {
                          _searchQuery = value;
                        });
                      }
                    });
                  },
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.black,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minHeight: 32,
                      minWidth: 32,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    hintText: 'Find Salon, Specialist...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                ),
              ),
              //const SizedBox(width: 5),
              GestureDetector(
                onTap: _showFilterBottomSheet,
                child: Container(
                  child: Image.asset(
                    "assets/icons/filter_icon_new_outlined.png",
                    width: 45,
                    height: 45,
                  ),
                ),
              ),
            ],
          ),
          // Show search suggestions
          //_buildSearchSuggestions(),
          // Show active filters if any
          if (_selectedFilters.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Filters: ${_selectedFilters.length} active',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilters.clear();
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  ..._selectedFilters.map((filter) {
                    return Container(
                      margin: const EdgeInsets.only(right: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.teal),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            filter,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilters.remove(filter);
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Upcoming Appointment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HistoryScreen()),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('appointments')
                .where('userId', isEqualTo: _auth.currentUser?.uid)
                .where('status', whereIn: ['waiting', 'processing'])
                .orderBy('appointmentDate')
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      center: Alignment.center,
                      radius: 10,
                      colors: [Colors.white, Color(0xFFD3D3D3)],
                      stops: [0.0, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No upcoming appointments',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              var appointmentDoc = snapshot.data!.docs.first;
              var appointment = appointmentDoc.data() as Map<String, dynamic>;

              DateTime appointmentDateTime = DateTime.parse(
                appointment['appointmentDate'],
              );
              String formattedDate = DateFormat(
                'dd MMMM',
              ).format(appointmentDateTime);
              String appointmentTime = appointment['appointmentTime'] ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentDetailScreen(
                        appointmentId: appointmentDoc.id,
                        appointmentData: appointment,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      center: Alignment.center,
                      radius: 10,
                      colors: [Colors.white, Color(0xFFD3D3D3)],
                      stops: [0.0, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  appointmentTime,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Spacer(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNearestToYou() {
    if (userData == null ||
        userData!['latitude'] == null ||
        userData!['longitude'] == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '   Nearest To You',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 15),
            Text('Loading location...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    double userLat = userData!['latitude'];
    double userLon = userData!['longitude'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '   Nearest To You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Neartoyouscreen()),
                  );
                },
                child: Text(
                  "See All",
                  style: TextStyle(color: Colors.teal.shade700),
                ),
              ),
            ],
          ),

          // Search results header
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Search results for "$_searchQuery"',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('shops').snapshots(),
            builder: (context, shopsSnap) {
              if (shopsSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!shopsSnap.hasData || shopsSnap.data!.docs.isEmpty) {
                return Column(
                  children: [
                    if (_searchQuery.isNotEmpty || _selectedFilters.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'No shops match your search${_searchQuery.isNotEmpty ? ' for "$_searchQuery"' : ''}${_selectedFilters.isNotEmpty ? ' with selected filters' : ''}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text(
                          'No shops available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                );
              }

              // Build rating cache
              final Map<String, Map<String, dynamic>> ratingCache = {};

              Future<void> _populateRating(
                String shopId,
                List<dynamic> reviewIds,
              ) async {
                if (reviewIds.isEmpty) {
                  ratingCache[shopId] = {'avg': 0.0, 'count': 0};
                  return;
                }

                final List<Future<DocumentSnapshot>> futures = reviewIds
                    .map((id) => _firestore.collection('reviews').doc(id).get())
                    .toList();

                final List<DocumentSnapshot> docs = await Future.wait(futures);
                double sum = 0;
                int count = 0;
                for (var doc in docs) {
                  if (doc.exists) {
                    final data = doc.data() as Map<String, dynamic>;
                    final rating =
                        data['shopRating'] ?? data['barberRating'] ?? 0;
                    if (rating is num) {
                      sum += rating.toDouble();
                      count++;
                    }
                  }
                }
                ratingCache[shopId] = {
                  'avg': count == 0 ? 0.0 : sum / count,
                  'count': count,
                };
              }

              // Filter and prepare nearby shops
              List<Map<String, dynamic>> nearbyShops = [];

              for (var doc in shopsSnap.data!.docs) {
                final shop = doc.data() as Map<String, dynamic>;
                if (shop['latitude'] == null || shop['longitude'] == null)
                  continue;

                // Apply search filter using enhanced search
                if (!_matchesSearchQuery(shop, _searchQuery)) continue;

                // Apply service filter
                if (!_matchesFilters(shop)) continue;

                final shopId = doc.id;

                // Calculate distance
                final distance = _calculateDistance(
                  userLat,
                  userLon,
                  shop['latitude'],
                  shop['longitude'],
                );

                shop['distance'] = distance;
                shop['shopId'] = shopId;
                nearbyShops.add(shop);
              }

              // Sort by distance
              nearbyShops.sort(
                (a, b) => a['distance'].compareTo(b['distance']),
              );

              if (nearbyShops.isEmpty) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'No shops match your search${_searchQuery.isNotEmpty ? ' for "$_searchQuery"' : ''}${_selectedFilters.isNotEmpty ? ' with selected filters' : ''}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                );
              }

              // Fetch ratings for all shops
              final List<Future<void>> ratingFutures = nearbyShops.map((s) {
                final List<dynamic> reviewIds = s['ratings'] ?? [];
                return _populateRating(s['shopId'], reviewIds);
              }).toList();

              return FutureBuilder(
                future: Future.wait(ratingFutures),
                builder: (context, _) {
                  return SizedBox(
                    height: 210,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: nearbyShops.length,
                      itemBuilder: (context, index) {
                        final shop = nearbyShops[index];
                        final shopId = shop['shopId'];
                        final ratingInfo =
                            ratingCache[shopId] ?? {'avg': 0.0, 'count': 0};
                        final double avgRating = ratingInfo['avg'];
                        final int reviewCount = ratingInfo['count'];

                        return Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            border: Border.all(width: 1, color: Colors.black),
                          ),
                          width: 180,
                          margin: EdgeInsets.only(
                            left: index == 0 ? 16 : 8,
                            right: index == nearbyShops.length - 1 ? 16 : 8,
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BarberShopDetailScreen(
                                    shopId: shopId,
                                    shopData: shop,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        shop['shopImage'] ??
                                            'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=300&h=200&fit=crop',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  shop['shopName'] ?? 'Shop',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        shop['shopAddress'] ?? 'Address',
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      avgRating > 0
                                          ? avgRating.toStringAsFixed(1)
                                          : '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '($reviewCount)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${shop['distance'].toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopServices(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              final double availableWidth = constraints.maxWidth;
              final double itemWidth = 100.0;
              final double itemSpacing = 10.0;
              final int itemCount = 5;

              final double totalItemsWidth =
                  (itemWidth * itemCount) + (itemSpacing * (itemCount - 1));

              if (totalItemsWidth <= availableWidth) {
                final double sideSpacing =
                    (availableWidth - totalItemsWidth) / 2;

                return SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: sideSpacing),
                      _buildServiceItem(
                        context,
                        "assets/icons/scissor_icon.png",
                        'Hair',
                        const Color(0xFF059669),
                      ),
                      SizedBox(width: itemSpacing),
                      _buildServiceItem(
                        context,
                        "assets/icons/massage_icon.png",
                        'Massage',
                        Colors.grey.shade200,
                      ),
                      SizedBox(width: itemSpacing),
                      _buildServiceItem(
                        context,
                        "assets/icons/skin_icon.png",
                        'Skin',
                        Colors.grey.shade200,
                      ),
                      SizedBox(width: itemSpacing),
                      _buildServiceItem(
                        context,
                        "assets/icons/shave_icon.png",
                        'Shaving',
                        Colors.grey.shade200,
                      ),
                      SizedBox(width: itemSpacing),
                      _buildServiceItem(
                        context,
                        "assets/icons/makeup_icon.png",
                        'Makeup',
                        Colors.grey.shade200,
                      ),
                      SizedBox(width: sideSpacing),
                    ],
                  ),
                );
              } else {
                return SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: itemCount,
                    separatorBuilder: (context, index) =>
                        SizedBox(width: itemSpacing),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildServiceItem(
                          context,
                          "assets/icons/scissor_icon.png",
                          'Hair',
                          const Color(0xFF059669),
                        );
                      }

                      final List<Map<String, dynamic>> services = [
                        {
                          'icon': "assets/icons/massage_icon.png",
                          'name': 'Massage',
                          'color': Colors.grey.shade200,
                        },
                        {
                          'icon': "assets/icons/skin_icon.png",
                          'name': 'Skin',
                          'color': Colors.grey.shade200,
                        },
                        {
                          'icon': "assets/icons/shave_icon.png",
                          'name': 'Shaving',
                          'color': Colors.grey.shade200,
                        },
                        {
                          'icon': "assets/icons/makeup_icon.png",
                          'name': 'Makeup',
                          'color': Colors.grey.shade200,
                        },
                      ];

                      return _buildServiceItem(
                        context,
                        services[index - 1]['icon'],
                        services[index - 1]['name'],
                        services[index - 1]['color'],
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(
    BuildContext context,
    String icon,
    String title,
    Color backgroundColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HairServiceScreen(serviceName: title),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(icon),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppointmentDetailScreen extends StatelessWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailScreen({
    Key? key,
    required this.appointmentId,
    required this.appointmentData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime appointmentDateTime = DateTime.parse(
      appointmentData['appointmentDate'],
    );
    String formattedDate = DateFormat(
      'EEEE, dd MMMM yyyy',
    ).format(appointmentDateTime);
    String status = appointmentData['status'] ?? 'unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(status), width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 30,
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Status: ${status.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _getStatusDescription(status),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(status),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date & Time
            _buildInfoCard(
              'Date & Time',
              '$formattedDate\n${appointmentData['appointmentTime']}',
              Icons.access_time,
            ),
            const SizedBox(height: 15),

            // Shop Details
            _buildInfoCard(
              'Shop',
              appointmentData['shopName'] ?? 'N/A',
              Icons.store,
            ),
            const SizedBox(height: 15),

            // Staff Details
            _buildInfoCard(
              'Staff',
              '${appointmentData['staffName'] ?? 'N/A'} (${appointmentData['staffDesignation'] ?? 'N/A'})',
              Icons.person,
            ),
            const SizedBox(height: 15),

            // Contact Information (if available)
            if (appointmentData['userEmail'] != null &&
                appointmentData['userEmail'].toString().isNotEmpty)
              Column(
                children: [
                  _buildInfoCard(
                    'Email',
                    appointmentData['userEmail'],
                    Icons.email,
                  ),
                  const SizedBox(height: 15),
                ],
              ),

            if (appointmentData['userPhone'] != null &&
                appointmentData['userPhone'].toString().isNotEmpty)
              Column(
                children: [
                  _buildInfoCard(
                    'Phone',
                    appointmentData['userPhone'],
                    Icons.phone,
                  ),
                  const SizedBox(height: 15),
                ],
              ),

            const Divider(thickness: 1, height: 30),

            // Services Section
            const Text(
              'Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),

            if (appointmentData['services'] != null &&
                (appointmentData['services'] as List).isNotEmpty)
              ...List.generate((appointmentData['services'] as List).length, (
                index,
              ) {
                var service = appointmentData['services'][index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['serviceName'] ?? 'Service',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Duration: ${service['duration'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${service['currency'] ?? 'PKR'} ${service['price'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                );
              })
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No services selected',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            // Subtotal for Services
            if (appointmentData['totalServicesPrice'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Services Subtotal:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${appointmentData['currency'] ?? 'PKR'} ${appointmentData['totalServicesPrice']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),

            // Products Section (if any)
            if (appointmentData['products'] != null &&
                (appointmentData['products'] as List).isNotEmpty) ...[
              const SizedBox(height: 15),
              const Divider(thickness: 1),
              const SizedBox(height: 15),
              const Text(
                'Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate((appointmentData['products'] as List).length, (
                index,
              ) {
                var product = appointmentData['products'][index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product['productName'] ?? 'Product',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${product['currency'] ?? 'PKR'} ${product['price'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Subtotal for Products
              if (appointmentData['totalProductsPrice'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Products Subtotal:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${appointmentData['currency'] ?? 'PKR'} ${appointmentData['totalProductsPrice']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 10),
            const Divider(thickness: 2),
            const SizedBox(height: 10),

            // Grand Total
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${appointmentData['currency'] ?? 'PKR'} ${appointmentData['grandTotal'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Appointment ID (for reference)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appointment ID',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    appointmentId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Action Buttons (based on status)
            if (status.toLowerCase() == 'waiting' ||
                status.toLowerCase() == 'processing')
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () {
                        _handleCancelAppointment(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel Appointment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Icons.access_time;
      case 'processing':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return 'Your appointment is waiting for confirmation';
      case 'processing':
        return 'Your appointment is being prepared';
      case 'completed':
        return 'Your appointment has been completed';
      case 'cancelled':
        return 'This appointment has been cancelled';
      default:
        return 'Status unknown';
    }
  }

  // Check if appointment can be cancelled (within 30 minutes of booking)
  bool _canCancelAppointment() {
    if (appointmentData['createdAt'] == null) {
      return false;
    }

    try {
      DateTime bookingTime;

      // Handle both Timestamp and String formats
      if (appointmentData['createdAt'] is String) {
        bookingTime = DateTime.parse(appointmentData['createdAt']);
      } else {
        // Assuming it's a Firebase Timestamp
        bookingTime = (appointmentData['createdAt'] as dynamic).toDate();
      }

      DateTime now = DateTime.now();
      Duration difference = now.difference(bookingTime);

      // Can cancel only within 30 minutes
      return difference.inMinutes <= 30;
    } catch (e) {
      print('Error parsing booking time: $e');
      return false;
    }
  }

  // Get remaining time for cancellation
  String _getRemainingCancellationTime() {
    if (appointmentData['createdAt'] == null) {
      return '';
    }

    try {
      DateTime bookingTime;

      if (appointmentData['createdAt'] is String) {
        bookingTime = DateTime.parse(appointmentData['createdAt']);
      } else {
        bookingTime = (appointmentData['createdAt'] as dynamic).toDate();
      }

      DateTime now = DateTime.now();
      Duration difference = now.difference(bookingTime);
      int remainingMinutes = 30 - difference.inMinutes;

      if (remainingMinutes > 0) {
        return '$remainingMinutes minutes';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  void _handleCancelAppointment(BuildContext context) {
    if (!_canCancelAppointment()) {
      // Show dialog that cancellation is not possible
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Unable to Cancel'),
            ],
          ),
          content: const Text(
            'Appointment cancellation can only be done within the first 30 minutes of booking. Your cancellation window has expired.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Show confirmation dialog with remaining time
      _showCancelDialog(context);
    }
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contact Shop',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF059669)),
              title: const Text('Call Shop'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling shop...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Color(0xFF059669)),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening messages...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF059669)),
              title: const Text('Send Email'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening email...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    String remainingTime = _getRemainingCancellationTime();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this appointment? This action cannot be undone.',
            ),
            if (remainingTime.isNotEmpty) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Time remaining for cancellation: $remainingTime',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Add Firebase code to update appointment status
              // Example:
              // FirebaseFirestore.instance
              //   .collection('appointments')
              //   .doc(appointmentId)
              //   .update({'status': 'cancelled'});

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment cancelled successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
